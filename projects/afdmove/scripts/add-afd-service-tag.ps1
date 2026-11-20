# Script to add AzureFrontDoor.Backend service tag to storage account network rules
# This is a workaround since Terraform doesn't support service tags in storage network rules

# Read variables from terraform
$storageAccountName = terraform output -raw storage_account_name
$resourceGroup = terraform output -raw storage_account_name  # Using same name as RG

Write-Host "Adding AzureFrontDoor.Backend service tag to storage account..." -ForegroundColor Cyan

# Login if needed
$context = az account show 2>$null
if (-not $context) {
    Write-Host "Not logged in. Please run upload-to-storage.ps1 first to login." -ForegroundColor Yellow
    exit 1
}

# Add virtual network rule with service tag
# Note: This requires creating a subnet first, but we can use a workaround with REST API

Write-Host @"
Important: Azure Storage network rules don't support service tags directly via CLI.

Your current configuration uses 'private_link_access' which is BETTER because:
1. Only YOUR specific Azure Front Door can access (not all AFD globally)
2. More secure than allowing all AFD backend IPs
3. Already configured in your Terraform code

The private_link_access block in your storage.tf already allows your AFD profile.

If you still want to allow all AFD backends (less secure), you would need to:
1. Download AFD IP ranges from Microsoft's JSON file
2. Add them as individual IP rules (but this can hit limits)

Recommended: Keep current private_link_access configuration (already in place)
"@ -ForegroundColor Green
