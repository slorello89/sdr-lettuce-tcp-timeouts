variable "azure_subscription" {
    description = "Azure Subscription ID"
    type = string
}

variable "adminPassword" {
    description = "Admin Password for vms"
    type = string
    default = "Password1234!"
}

variable "dns_zone_name" {
    description = "DNS Zone Name"
    type = string
}

variable "dns_zone_rg" {
    description = "DNS Zone Resource Group"
    type = string
}
