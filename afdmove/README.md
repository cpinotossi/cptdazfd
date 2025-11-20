
~~~powershell
tf destroy -auto-approve
tf apply -auto-approve

# Get Front Door endpoint URL from Terraform output
$fdDomain = terraform output -raw frontdoor_endpoint_host;
# Test Front Door endpoint
http https://$fdDomain
# Get Storage Account static website URL from Terraform output
$storageDomain = terraform output -raw static_website_host;
# Test Storage Account static website endpoint
http https://$storageDomain
~~~