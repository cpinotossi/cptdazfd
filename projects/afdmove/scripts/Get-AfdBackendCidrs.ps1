<#
.SYNOPSIS
    Retrieves Azure Front Door Backend IP ranges for a specified region.

.DESCRIPTION
    This script queries Azure service tags to get all AFD Backend IP ranges,
    filters them to only include valid CIDR ranges for Azure Storage Account
    network rules (IPv4 with /0-/30 prefix), and outputs them in various formats.

.PARAMETER Region
    The Azure region to filter AFD backend IPs for. Default is 'westeurope'.

.PARAMETER OutputFormat
    The output format: 'List', 'CommaSeparated', 'TerraformArray', or 'Json'.
    Default is 'List'.

.PARAMETER OutputFile
    Optional file path to save the output.

.EXAMPLE
    .\Get-AfdBackendCidrs.ps1
    Lists all valid AFD backend CIDRs for West Europe.

.EXAMPLE
    .\Get-AfdBackendCidrs.ps1 -Region westeurope -OutputFormat TerraformArray
    Outputs CIDRs in Terraform array format.

.EXAMPLE
    .\Get-AfdBackendCidrs.ps1 -OutputFile afd-cidrs.txt -OutputFormat CommaSeparated
    Saves comma-separated CIDRs to a file.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Region = "westeurope",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('List', 'CommaSeparated', 'TerraformArray', 'Json')]
    [string]$OutputFormat = "List",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

Write-Host "Retrieving Azure Front Door Backend IP ranges for region: $Region" -ForegroundColor Cyan
Write-Host "Filtering to IPv4 ranges with /0-/30 prefix only (Storage Account compatible)" -ForegroundColor Cyan
Write-Host ""

try {
    # Query Azure service tags for AFD Backend
    $serviceTags = az network list-service-tags --location $Region --query "values[?name=='AzureFrontDoor.Backend'].properties.addressPrefixes[]" -o tsv
    
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) {
        throw "Failed to retrieve service tags. Exit code: $LASTEXITCODE"
    }
    
    # Filter to IPv4 addresses with /0-/30 prefix (Azure Storage Account network rules limitation)
    # Exclude /31 and /32 as they are not supported by storage account IP rules
    $filteredCidrs = $serviceTags | Where-Object { 
        $_ -match '^\d+\.' -and $_ -match '/([0-9]|[12][0-9]|30)$' 
    } | Sort-Object
    
    $totalCount = ($serviceTags | Where-Object { $_ -match '^\d+\.' }).Count
    $filteredCount = $filteredCidrs.Count
    $excludedCount = $totalCount - $filteredCount
    
    Write-Host "Total IPv4 ranges found: $totalCount" -ForegroundColor Green
    Write-Host "Valid ranges (/0-/30): $filteredCount" -ForegroundColor Green
    Write-Host "Excluded ranges (/31-/32): $excludedCount" -ForegroundColor Yellow
    Write-Host ""
    
    # Generate output based on format
    $output = switch ($OutputFormat) {
        'List' {
            $filteredCidrs -join "`n"
        }
        'CommaSeparated' {
            '"' + ($filteredCidrs -join '","') + '"'
        }
        'TerraformArray' {
            $indent = "      "
            $formatted = $filteredCidrs | ForEach-Object { "`"$_`"" }
            "ip_rules = [`n$indent" + ($formatted -join ",`n$indent") + "`n    ]"
        }
        'Json' {
            $filteredCidrs | ConvertTo-Json -Compress
        }
    }
    
    # Output to console
    if ($OutputFormat -eq 'TerraformArray') {
        Write-Host "Terraform format:" -ForegroundColor Cyan
    }
    Write-Host $output
    Write-Host ""
    
    # Save to file if specified
    if ($OutputFile) {
        $output | Set-Content -Path $OutputFile -Encoding UTF8
        Write-Host "Output saved to: $OutputFile" -ForegroundColor Green
    }
    
    # Return the array for programmatic use
    return $filteredCidrs
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
