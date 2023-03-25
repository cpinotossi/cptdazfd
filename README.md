# Azure Frontdoor Demo

## Frontdoor and Private Link

Setup Azure Frontdoor with Private Link and Internal Loadbalancer:
~~~ mermaid
classDiagram
AzFrontdoor --> PrivateLinkService
PrivateLinkService --> StandardLB
StandardLB --> VM
AzFrontdoor: www.cptdazfd.org
StandardLB: FEIP 10.0.0.5
VM: IP 10.0.0.4
PrivateLinkService: 10.0.0.6
~~~

### Setup Env:

~~~ bash
# Define some env variables
prefix=cptdazfd
location=eastus
myip=$(curl ifconfig.io) # Just in case we like to whitelist our own ip.
myobjectid=$(az ad user list --query '[?displayName==`ga`].id' -o tsv) 

# az group delete -n $prefix --yes
az group create -n $prefix -l $location
# Create base components
az deployment group create -n ${prefix}-base -g $prefix --mode incremental --template-file deploybase.bicep -p prefix=$prefix myobjectid=$myobjectid location=$location myip=$myip
# Add vm to lb backend pool
az network nic ip-config address-pool add --address-pool $prefix --ip-config-name $prefix --nic-name $prefix -g $prefix --lb-name $prefix
# Add AFD
az deployment group create -n ${prefix}-afd -g $prefix --mode incremental --template-file deployafd.bicep -p prefix=$prefix myobjectid=$myobjectid location=$location myip=$myip
## Approve Private Link Service
plsid=$(az afd origin show --origin-group-name $prefix --origin-name $prefix --profile-name $prefix -g $prefix --query sharedPrivateLinkResource.privateLink.id -o tsv)
pecid=$(az network private-endpoint-connection list  --id $plsid --query [0].id -o tsv)
az network private-endpoint-connection approve -d $prefix --id $pecid
~~~

### Verify setup

~~~ bash
az vm list-ip-addresses -g $prefix -n $prefix -o table
# proof we are using only privat ips with our lb
az network lb show -n $prefix -g $prefix --query frontendIPConfigurations[].privateIPAddress -o table # expect 10.0.0.5
# what is the ip of our private link service?
az network private-link-service show -n $prefix -g $prefix --query ipConfigurations[].privateIpAddress # expect 10.0.0.6
# Get details about our AFD profile
az afd origin show --origin-group-name $prefix --origin-name $prefix --profile-name $prefix -g $prefix --query "{hostName:hostName, originHostHeader:originHostHeader, privateLink:sharedPrivateLinkResource.privateLink.id}" | sed -e "s#subscriptions\/.*\/resourceGroups#rg#"
~~~

### Setup Web Server at VM

~~~ bash
# ssh into vm
vmid=$(az vm show -g $prefix -n $prefix --query id -o tsv)
az network bastion ssh -n cptdazbastion -g cptdazbastion --target-resource-id $vmid --auth-type AAD
# Create web server
mkdir www
cd www
echo "hello world" > index.html
echo "hello azure" > azure.html
python -m SimpleHTTPServer 9000
python -m SimpleHTTPServer 9000 &
~~~

### Test

Open new terminal

~~~ bash
prefix=cptdazfd #you need to set the ENV var again

# retrieve AFD FQDN
fdfqdn=$(az afd endpoint show --endpoint-name $prefix --profile-name $prefix -g $prefix --query hostName -o tsv)
echo $fdfqdn
# retrieve AFD custom domains
fdcd0=$(az afd custom-domain list -g $prefix --profile-name $prefix --query [0].hostName -o tsv)
echo $fdcd0
fdcd1=$(az afd custom-domain list -g $prefix --profile-name $prefix --query [1].hostName -o tsv)
echo $fdcd1

curl -v  https://$fdfqdn/azure.html # expect 200 ok
curl -v  https://$fdcd0/azure.html # expect 200 ok
curl -v -H"X-Azure-DebugInfo: 1" https://$fdcd0/azure.html # expect 200 ok

# retrieve AFD Edge PoP IP
fdip=$(dig $fdfqdn +short | tail -n1)
echo $fdip


dig cptdazfd.cptdev.com
traceroute cptdazfd.cptdev.com
curl ipinfo.io/$fdip
~~~

- X-Azure-OriginStatusCode
 - This header contains the HTTP status code returned by the backend. Using this header you can identify the HTTP status code returned by the application running in your backend without going through backend logs. This status code might be different from the HTTP status code in the response sent to the client by Front Door. This header allows you to determine if the backend is misbehaving or if the issue is with the Front Door service.
- X-Azure-InternalError	This header will contain the error code that Front Door comes across when processing the request. This error indicates the issue is  internal to the Front Door service/infrastructure. Report issue to support.
- X-Azure-ExternalError	
 - X-Azure-ExternalError: 0x830c1011, The certificate authority is unfamiliar.
 - This header shows the error code that Front Door servers come across while establishing connectivity to the backend server to process a request. This header will help identify issues in the connection between Front Door and the backend application. This header will include a detailed error message to help you identify connectivity issues to your backend (for example, DNS resolution, invalid cert, and so on.).

### Clean up
~~~ bash
az group delete -n $prefix --yes --no-wait 
~~~

### NOTE:
(Azure FD and SSL Certificate)[https://github.com/brwilkinson/AzureDeploymentFramework/blob/73df5f8f1dfc32415ca6d5051512edb7348a52b6/ADF/bicep/FD-frontDoor.bicep#L167]
- (Azure FD, Private Link and Container Apps)[https://github.com/sebafo/frontdoor-container-apps]

## Frontdoor and Traffic Manager Demo

~~~ bash
prefix=cptdazfd
location=eastus
myip=$(curl ifconfig.io) # Just in case we like to whitelist our own ip.
myobjectid=$(az ad user list --query '[?displayName==`ga`].id' -o tsv) # just in case we like to assing

az group delete -n $prefix --yes
az group create -n $prefix -l $location
az deployment group create -n $prefix -g $prefix --mode incremental --template-file deploy.bicep -p prefix=$prefix myobjectid=$myobjectid location=$location myip=$myip
~~~



## Two Origins one Hostname Demo

> IMPORTANT: This demo does include DNS settings which are done under an already exisiting DNS zone.
You will need to create your Azure public DNS zone already beforehand and replace the cptdev.com .

Define certain variables which we will need.

~~~ text
prefix=cptdafd
rg=${prefix}
myobjectid=$(az ad user list --query '[?displayName==`ga`].objectId' -o tsv)
myip=$(curl ifconfig.io)
~~~

Create the azure resources.

~~~ text
az group create -n $rg -l eastus
az deployment group create -n create-vnet -g $rg --template-file bicep/deploy1.bicep -p myobjectid=$myobjectid myip=$myip
~~~

The following steps are a workaround because I did not manage to assigne the azure front door rules during the initial deployment.

~~~ text
rulesid=$(az network front-door rules-engine show -f $prefix -g $rg -n $prefix --query id -o tsv)
az network front-door routing-rule update -f $prefix -g $rg -n ${prefix}routing --rules-engine $rulesid
az network front-door routing-rule show -f $prefix -g $rg -n ${prefix}routing --query rulesEngine.id -o tsv
~~~

> TODO: Need to figure out how to get this done already during the first deployment instead of having to call azure cli afterwards.

### Test

RuleEngine is setup as follow.

~~~mermaid
stateDiagram-v2
    state if_state1 <<choice>>
    state if_state2 <<choice>>
    [*] --> Cookie=red
    Cookie=red --> if_state1
    if_state1 --> cookie=blue
    if_state1 --> cookie=null
    if_state1 --> cookie=red
    cookie=red --> Backend=Red
    cookie=blue --> Backend=Blue
    cookie=null --> if_state2
    if_state2 --> path=red
    if_state2 --> path=blue 
    path=red --> Backend=Red
~~~

Test are done via curl. Because we use azure front door all test can be done via the public internet.

~~~ text
fep=${prefix}fep
host=$(az network front-door frontend-endpoint show -g $rg -n $fep -f $prefix --query frontendEndpoints[] --query hostName -o tsv)
echo $host
curl -v -H"X-Azure-DebugInfo: 1" http://$host/
curl -v -H"X-Azure-DebugInfo: 1" http://$host/hello/blue.test
curl -v -H"X-Azure-DebugInfo: 1" http://$host/hello/blue/
curl -v -H"X-Azure-DebugInfo: 1" http://$host/red/
curl -v -H"cookie: red=true" -H"X-Azure-DebugInfo: 1" http://$host/
curl -v -H"cookie: red=true" -H"X-Azure-DebugInfo: 1" http://$host/red/
curl -v -H"cookie: red=true" -H"cookie: blue=true" -H"X-Azure-DebugInfo: 1" http://$host/
curl -v -H"cookie: blue=true" -H"cookie: red=true" -H"X-Azure-DebugInfo: 1" http://$host/
curl -v -H"X-Azure-DebugInfo: 1" http://$host/red
curl -v -H"X-Azure-DebugInfo: 1" http://$host/red.test
~~~

> NOTE: All test are done via HTTP, not via TLS/HTTPS. That is because self signed certificates are not supported at the backend via azure front door. But our backend´s are setup with self signed server certificates.

Each of the test should result into an 200 OK.
In case you receive 503 Service Unavailable, this could be because one of the three VMs at the backend did not load the cloud-init file correctly. This did happen several times during my testing.

> TODO: Need to consider to replace the vm based backend through azure kubernetes services.


### Clean up

Delete DNS entries first. 

> NOTE: You will need to delete the DNS records first otherwise you will not be able to delete azure front door.

~~~ text
echo $rg
az network dns zone list -g ga-rg
az network dns record-set cname list -g ga-rg -z cptdev.com -o table
az network dns record-set cname delete -g ga-rg -z cptdev.com -n afdverify.cptdafdblue -y
az network dns record-set cname delete -g ga-rg -z cptdev.com -n afdverify.cptdafdred -y
az network dns record-set cname list -g ga-rg -z cptdev.com -o table
~~~

Delete the azure front door setup.

~~~ text
az group delete -n $rg -y
~~~

### TODO

Get it done with resource script instead like here:
https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.storage/storage-static-website/scripts/enable-static-website.ps1

[Bicep Script Resource](https://docs.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts?tabs=bicep)


## MISC

### curl

~~~bash
# dns spoofing via curl
curl -v -H"X-Azure-DebugInfo: 1" http://$fdfqdn/azure.html --resolve $fdfqdn:80:$fdip # expect 200 ok
~~~

### wsl time sync
~~~bash
sudo hwclock -s
sudo ntpdate time.windows.com
~~~

### change chmod at wsl

Based on 
- https://stackoverflow.com/questions/46610256/chmod-wsl-bash-doesnt-work
- https://devblogs.microsoft.com/commandline/automatically-configuring-wsl/

~~~bash
sudo cat /etc/wsl.conf
sudo touch /etc/wsl.conf
sudo nano /etc/wsl.conf
~~~

Add
~~~ text
[automount]
options = "metadata"
~~~

~~~bash
# chmod does not work straight away at WSL.
ls -la azbicep/ssh/chpinoto.key # should be -rwxrwxrwx
sudo chmod 600 azbicep/ssh/chpinoto.key
ls -la azbicep/ssh/chpinoto.key # should be -rw------- now
~~~

### github
~~~ bash
gh repo create $prefix --public
git init
git remote remove origin
git remote add origin https://github.com/cpinotossi/$prefix.git
git submodule add https://github.com/cpinotossi/azbicep
git submodule init
git submodule update
git submodule update --init
git status
git add .gitignore
git add *
git commit -m"azure frontdoor private link demo update cptdazfd"
git push origin main
git push --recurse-submodules=on-demand
git rm README.md # unstage
git --help
git config advice.addIgnoredFile false
git pull origin main
git merge 
origin main
git config pull.rebase false
git init
gh repo create cptdafd --public
git remote add origin https://github.com/cpinotossi/cptdafd.git
git status
git add *
git commit -m"Demo of custom domains and multi origin via http. Version with some hick ups which are mentioned inside the readme docs."
git log --oneline --decorate // List commits
git tag -a v1 e1284bf //tag my last commit
git push origin master


git tag //list local repo tags
git ls-remote --tags origin //list remote repo tags
git fetch --all --tags // get all remote tags into my local repo

git log --pretty=oneline //list commits


git checkout v1
git switch - //switch back to current version
co //Push all my local tags
git push origin <tagname> //Push a specific tag
git commit -m"not transient"
git tag v1
git push origin v1
git tag -l
git fetch --tags
git clone -b <git-tagname> <repository-url> 
~~~