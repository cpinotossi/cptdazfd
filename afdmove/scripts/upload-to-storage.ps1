# PowerShell script to upload walk.txt to Azure Storage using Service Principal
# This script uses Azure CLI with service principal authentication and reads values from Terraform

# Get Terraform outputs and variables
Write-Host "Reading Terraform configuration..." -ForegroundColor Cyan

# Read variables from terraform.tfvars
$tfvarsContent = Get-Content "terraform.tfvars" -Raw
$subscriptionId = ($tfvarsContent | Select-String 'subscription_id\s*=\s*"([^"]+)"').Matches.Groups[1].Value
$clientId = ($tfvarsContent | Select-String 'client_id\s*=\s*"([^"]+)"').Matches.Groups[1].Value
$clientSecret = ($tfvarsContent | Select-String 'client_secret\s*=\s*"([^"]+)"').Matches.Groups[1].Value
$tenantId = ($tfvarsContent | Select-String 'tenant_id\s*=\s*"([^"]+)"').Matches.Groups[1].Value
$prefix = ($tfvarsContent | Select-String 'prefix\s*=\s*"([^"]+)"').Matches.Groups[1].Value

# Validate values were extracted
if (-not $subscriptionId -or -not $clientId -or -not $clientSecret -or -not $tenantId -or -not $prefix) {
    Write-Host "Error: Failed to extract required values from terraform.tfvars" -ForegroundColor Red
    exit 1
}

# Login with Service Principal
Write-Host "Logging in with Service Principal..." -ForegroundColor Cyan
az login --service-principal -u $clientId -p $clientSecret --tenant $tenantId

# Set subscription
Write-Host "Setting subscription..." -ForegroundColor Cyan
az account set --subscription $subscriptionId

# Get storage account details
$storageAccount = $prefix
$containerName = "`$web"
$files = @("index.html", "error.html")

Write-Host "Storage Account: $storageAccount" -ForegroundColor Green
Write-Host "Container: $containerName" -ForegroundColor Green
Write-Host "Files to upload: $($files -join ', ')" -ForegroundColor Green

# Check if files exist
foreach ($file in $files) {
    if (-not (Test-Path ".\$file")) {
        Write-Host "Error: File $file not found!" -ForegroundColor Red
        exit 1
    }
}

# Create container if it doesn't exist (container is created automatically with static_website block)
Write-Host "Ensuring container exists..." -ForegroundColor Cyan
az storage container create `
    --name $containerName `
    --account-name $storageAccount `
    --auth-mode login `
    2>$null

# Upload files to blob storage
foreach ($file in $files) {
    Write-Host "Uploading $file to blob storage..." -ForegroundColor Cyan
    az storage blob upload `
        --account-name $storageAccount `
        --container-name $containerName `
        --name $file `
        --file ".\$file" `
        --auth-mode login `
        --overwrite `
        --content-type "text/html"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "File $file uploaded successfully!" -ForegroundColor Green
    } else {
        Write-Host "Upload of $file failed!" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Static Website URL: https://$storageAccount.z6.web.core.windows.net/" -ForegroundColor Yellow

# Logout
Write-Host "Logging out..." -ForegroundColor Cyan
az logout
