provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription
}
resource "azurerm_resource_group" "lettuce-cutoff-rg" {
  name     = "lettuce-cutoff-rg"
  location = "Central US"
}

resource "azurerm_virtual_network" "lettuce-cutoff-vn" {
  name = "lettuce-cutoff-vn"
  location = azurerm_resource_group.lettuce-cutoff-rg.location
  resource_group_name = azurerm_resource_group.lettuce-cutoff-rg.name
  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "lettuce-cutoff-subnet" {
  name = "lettuce-cutoff-subnet"
  resource_group_name = azurerm_resource_group.lettuce-cutoff-rg.name
  virtual_network_name = azurerm_virtual_network.lettuce-cutoff-vn.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "lettuce-cutoff-vm-public-ip" {
  name = "lettuce-cutoff-vm-public-ip"
  location = azurerm_resource_group.lettuce-cutoff-rg.location
  resource_group_name = azurerm_resource_group.lettuce-cutoff-rg.name
  allocation_method = "Static"
  sku = "Basic"
}

resource "azurerm_network_interface" "lettuce-cutoff-network-interface" {
  name = "lettuce-cutoff-network-interface"
  location = azurerm_resource_group.lettuce-cutoff-rg.location
  resource_group_name = azurerm_resource_group.lettuce-cutoff-rg.name

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.lettuce-cutoff-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.lettuce-cutoff-vm-public-ip.id
  }
}


resource "azurerm_public_ip" "lettuce-cutoff-redis-public-ip" {
  name = "lettuce-cutoff-redis-public-ip"
  location = azurerm_resource_group.lettuce-cutoff-rg.location
  resource_group_name = azurerm_resource_group.lettuce-cutoff-rg.name
  allocation_method = "Static"
  sku = "Basic"
}

resource "azurerm_network_interface" "lettuce-cutoff-redis-network-interface" {
  name = "lettuce-cutoff-redis-network-interface"
  location = azurerm_resource_group.lettuce-cutoff-rg.location
  resource_group_name = azurerm_resource_group.lettuce-cutoff-rg.name

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.lettuce-cutoff-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.lettuce-cutoff-redis-public-ip.id
  }
}

resource "azurerm_virtual_machine" "lettuce-cutoff-vm" {
  name                  = "lettuce-cutoff-vm"
  location              = azurerm_resource_group.lettuce-cutoff-rg.location
  resource_group_name   = azurerm_resource_group.lettuce-cutoff-rg.name
  network_interface_ids = [azurerm_network_interface.lettuce-cutoff-network-interface.id]
  vm_size               = "Standard_B1s"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = "lettuce-cutoff-vm-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "lettuce-cutoff-vm"
    admin_username = "adminuser"
    admin_password = var.adminPassword
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine" "lettuce-cutoff-redis" {
  name                  = "lettuce-cutoff-redis"
  location              = azurerm_resource_group.lettuce-cutoff-rg.location
  resource_group_name   = azurerm_resource_group.lettuce-cutoff-rg.name
  network_interface_ids = [azurerm_network_interface.lettuce-cutoff-redis-network-interface.id]
  vm_size               = "Standard_B1s"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = "lettuce-cutoff-redis-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "lettuce-cutoff-redis"
    admin_username = "adminuser"
    admin_password = var.adminPassword
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}


resource "null_resource" "remote_setup" {
  depends_on = [azurerm_virtual_machine.lettuce-cutoff-vm, azurerm_public_ip.lettuce-cutoff-vm-public-ip, azurerm_virtual_machine.lettuce-cutoff-vm]

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.lettuce-cutoff-vm-public-ip.ip_address
    user        = "adminuser"
    password    = var.adminPassword
    timeout     = "2m"
  }

  provisioner "local-exec" {
    command = "./gradlew clean bootjar"
  }

  provisioner "file" {
    source      = "./build/libs/testLettuce-1.0-SNAPSHOT.jar"
    destination = "/home/adminuser/app.jar"
  }

  provisioner "file" {
    source      = "./drop-outbound.bash"
    destination = "/home/adminuser/drop-outbound.bash"
  }

  provisioner "file" {
    source      = "./reopen.bash"
    destination = "/home/adminuser/reopen.bash"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install openjdk-17-jdk -y",
      "chmod +x /home/adminuser/app.jar"
    ]
  }
}

#create dns record
resource "azurerm_dns_a_record" "app-dns-record" {
  depends_on = [azurerm_public_ip.lettuce-cutoff-vm-public-ip, azurerm_virtual_machine.lettuce-cutoff-vm]
  name                = "app"  # This will create test.sub.example.com
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_rg
  ttl                 = 300

  records = [azurerm_public_ip.lettuce-cutoff-vm-public-ip.ip_address]
}

#create dns record
resource "azurerm_dns_a_record" "redis-dns-record" {
  depends_on          = [azurerm_public_ip.lettuce-cutoff-redis-public-ip, azurerm_virtual_machine.lettuce-cutoff-redis]
  name                = "redis"  # This will create test.sub.example.com
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_rg
  ttl                 = 300

  records = [azurerm_public_ip.lettuce-cutoff-redis-public-ip.ip_address]
}

resource "null_resource" "install_redis" {
    depends_on = [azurerm_virtual_machine.lettuce-cutoff-redis, azurerm_public_ip.lettuce-cutoff-redis-public-ip, azurerm_virtual_machine.lettuce-cutoff-redis]

    connection {
        type        = "ssh"
        host        = azurerm_public_ip.lettuce-cutoff-redis-public-ip.ip_address
        user        = "adminuser"
        password    = var.adminPassword
        timeout     = "2m"
    }

    provisioner "remote-exec" {
        inline = [
          "sudo apt-get update",
          "sudo apt-get install -y git docker.io docker-compose",
          "sudo mkdir -p /usr/local/lib/docker/cli-plugins",
          "sudo curl -SL https://github.com/docker/compose/releases/download/v2.22.0/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose",
          "sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose",
          "sudo systemctl start docker",
          "sudo systemctl enable docker",
          "sudo usermod -aG docker $USER",
          "export $(grep -v '^#' ./docker/.env | xargs)",
          "envsubst < ./docker/prometheus/prometheus.template.yml > ./docker/prometheus/prometheus.yml",
#          "sudo docker compose -f ./docker/docker-compose.yml up -d",
          "sudo docker run -d -p 10001:6379 --name redis redis"
        ]
    }
}

output "public_ip" {
  value = azurerm_public_ip.lettuce-cutoff-vm-public-ip.ip_address
}

