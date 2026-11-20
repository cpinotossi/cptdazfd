# microhack.status.ps1
# Script to check which Private DNS Zones linked to an AKS VNet have A records
# Prerequisites: Already logged in with Azure CLI (az login)

param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$VNetName,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId
)

# Set subscription if provided
if ($SubscriptionId) {
    az account set --subscription $SubscriptionId
}

Write-Host "`n=== Private DNS Zone A Record Status ===" -ForegroundColor Cyan
Write-Host "Checking for A records in Private DNS Zones...`n" -ForegroundColor Gray

# Get all Private DNS Zones in the subscription (or resource group if specified)
if ($ResourceGroupName) {
    $dnsZones = az network private-dns zone list --resource-group $ResourceGroupName --query "[].{name:name, resourceGroup:resourceGroup, id:id}" -o json | ConvertFrom-Json
} else {
    $dnsZones = az network private-dns zone list --query "[].{name:name, resourceGroup:resourceGroup, id:id}" -o json | ConvertFrom-Json
}

if (-not $dnsZones -or $dnsZones.Count -eq 0) {
    Write-Host "No Private DNS Zones found." -ForegroundColor Yellow
    exit 0
}

# Results collection
$results = @()

foreach ($zone in $dnsZones) {
    $zoneName = $zone.name
    $zoneRg = $zone.resourceGroup
    
    # Check VNet links if VNetName is specified
    $isLinkedToVNet = $true
    if ($VNetName) {
        $links = az network private-dns link vnet list --zone-name $zoneName --resource-group $zoneRg --query "[].virtualNetwork.id" -o json 2>$null | ConvertFrom-Json
        $isLinkedToVNet = $links | Where-Object { $_ -like "*/$VNetName" }
        
        if (-not $isLinkedToVNet) {
            continue  # Skip zones not linked to the specified VNet
        }
    }
    
    # Get A records for this zone
    $aRecords = az network private-dns record-set a list --zone-name $zoneName --resource-group $zoneRg --query "[].{name:name, fqdn:fqdn, ttl:ttl, ipAddresses:aRecords[].ipv4Address}" -o json 2>$null | ConvertFrom-Json
    
    $recordCount = if ($aRecords) { $aRecords.Count } else { 0 }
    
    $results += [PSCustomObject]@{
        Zone          = $zoneName
        ResourceGroup = $zoneRg
        ARecordCount  = $recordCount
        HasRecords    = if ($recordCount -gt 0) { "Yes" } else { "No" }
        ARecords      = $aRecords
    }
}

# Display summary table
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "-" * 100

$results | Format-Table -Property Zone, ResourceGroup, ARecordCount, HasRecords -AutoSize

# Display detailed A records for zones that have them
$zonesWithRecords = $results | Where-Object { $_.ARecordCount -gt 0 }

if ($zonesWithRecords) {
    Write-Host "`nDetailed A Records:" -ForegroundColor Yellow
    Write-Host "-" * 100
    
    foreach ($zone in $zonesWithRecords) {
        Write-Host "`n[$($zone.Zone)]" -ForegroundColor Green
        Write-Host "  Resource Group: $($zone.ResourceGroup)" -ForegroundColor Gray
        
        foreach ($record in $zone.ARecords) {
            $ips = $record.ipAddresses -join ", "
            Write-Host "  - $($record.name)" -ForegroundColor White -NoNewline
            Write-Host " -> $ips" -ForegroundColor Cyan -NoNewline
            Write-Host " (TTL: $($record.ttl)s)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "`nNo A records found in any Private DNS Zone." -ForegroundColor Yellow
}

# Statistics
Write-Host "`n=== Statistics ===" -ForegroundColor Cyan
Write-Host "Total Private DNS Zones checked: $($results.Count)" -ForegroundColor White
Write-Host "Zones with A records: $(($zonesWithRecords | Measure-Object).Count)" -ForegroundColor Green
Write-Host "Zones without A records: $(($results | Where-Object { $_.ARecordCount -eq 0 } | Measure-Object).Count)" -ForegroundColor Gray

# Return results for programmatic use
return $results
