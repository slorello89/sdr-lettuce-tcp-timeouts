# TCP Lettuce Timeouts in Spring Data Redis

This is an example testing TCP socket timeouts in Spring Data Redis using lettuce

## How to run

1. create a copy of `example.tfvars` (e.g. `mv example.tfvars .tfvars`)
2. Fill in the values in `.tfvars`
3. Run `terraformm init`
4. Run `terraform apply --var-file=.tfvars`
5. SSH to your azure instance using `ssh aminuser@<public-ip>` - for the `app` vm (of if you have a working dns zone/name you can ssh to `ssh adminuser@app.subdomain`) and enter your password (from your `.tfvars` file )
6. Run `REDIS_HOST=lettuce-cutoff-redis REDIS_PORT=10001 java -jar ./app.jar` to run the app
7. In a separate ssh instance on the same vm you can cut off traffic to redis by running `./drop-outbound.bash` (you may need to run `chmod +x drop-outbound.bash reopen.bash`) to fix the acls on the files
8. You can reopen the traffic by running `./reopen.bash`
9. You can observe how long the app takes to timeout by observing the running CLI app, Also note the timeout type, e.g. a 1 minute `CommandTimeoutException` is much different from a `ConnectionTimeoutException`
