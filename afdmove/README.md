# Move AFD between Subscriptions

~~~powershell
tf init
tf fmt
tf validate
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

# Azure Resource Move Guide

## Prerequisites
- Both subscriptions must be in the same Azure AD tenant
- You need appropriate permissions on both source and destination subscriptions

## PowerShell Commands

```powershell
# Set subscription IDs
$sourceSubscription = "4b353dc5-a216-485d-8f77-a0943546b42c" # onprem
$destinationSubscription = "389ea3d5-15a1-4e36-8d91-83238e71c34a" # lz-identity

# Get current resource values from Terraform (if in Terraform directory)
$sourceResourceGroup = terraform output -raw resource_group_name
$frontDoorName = terraform output -raw frontdoor_profile_name
$storageAccountName = terraform output -raw storage_account_name
$logAnalyticsName = terraform output -raw log_analytics_workspace_name

# Set destination resource group name
$destinationResourceGroup = "cptdazafdmove2"  # Change this to your desired destination name

# Get current location from source resource group
$location = az group show --name $sourceResourceGroup --subscription $sourceSubscription --query location -o tsv

# Pre-check: Verify Front Door managed identity status. If response is not empty, the move will run into issues
$afdIdentity = az cdn profile show --name $frontDoorName -g $sourceResourceGroup --subscription $sourceSubscription --query "identity"

# Retrieve resource IDs directly from Azure
$frontDoorResourceId = az cdn profile show --name $frontDoorName -g $sourceResourceGroup --subscription $sourceSubscription --query id -o tsv
$storageAccountResourceId = az storage account show --name $storageAccountName -g $sourceResourceGroup --subscription $sourceSubscription --query id -o tsv
$logAnalyticsResourceId = az monitor log-analytics workspace show --workspace-name $logAnalyticsName -g $sourceResourceGroup --subscription $sourceSubscription --query id -o tsv

# 1. Verify both subscriptions are in same tenant
az account show --subscription $sourceSubscription --query tenantId
az account show --subscription $destinationSubscription --query tenantId

# 2. Switch to destination subscription
az account set -s $destinationSubscription

# 3. Register required providers in destination
az provider register --namespace Microsoft.Cdn
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.OperationalInsights

# 4. Create destination resource group
az group create --name $destinationResourceGroup --location $location

# 5. Check current role assignments on source subscription
$spObjectId = az ad signed-in-user show --query id -o tsv  # Get your service principal object ID
az role assignment list --subscription $sourceSubscription --scope "/subscriptions/$sourceSubscription/resourceGroups/$sourceResourceGroup" --query "[].{Principal:principalName, Role:roleDefinitionName, Scope:scope}" -o table

# 6. Assign RBAC role to service principal on destination resource group
az role assignment create --assignee $spObjectId --role "Storage Blob Data Contributor" --scope "/subscriptions/$destinationSubscription/resourceGroups/$destinationResourceGroup" --subscription $destinationSubscription

# 7. Verify role assignment on destination
az role assignment list --scope "/subscriptions/$destinationSubscription/resourceGroups/$destinationResourceGroup" --assignee $spObjectId --query "[].{Role:roleDefinitionName, Scope:scope}" -o table

# 8. Switch back to source subscription
az account set -s $sourceSubscription

# 9. Move resources
az resource move --destination-group $destinationResourceGroup --destination-subscription-id $destinationSubscription --ids $frontDoorResourceId $storageAccountResourceId $logAnalyticsResourceId
```

## Post-Move Tasks

1. **Recreate role assignment** for service principal in destination subscription
2. **Update Terraform state** files with new subscription/resource group
3. **Verify Front Door** is functioning correctly
4. **Test application** end-to-end
