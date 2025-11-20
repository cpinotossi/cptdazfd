#!/bin/bash
# Import existing Azure resources into Terraform state

PREFIX="cptdazafdmove"
SUBSCRIPTION_ID="4b353dc5-a216-485d-8f77-a0943546b42c"
RG_NAME="$PREFIX"

echo "Starting import of existing resources..."

# 1. Resource Group
echo "Importing Resource Group..."
terraform import azurerm_resource_group.cptdazafdmove \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME" 2>/dev/null || echo "  Already imported or failed, continuing..."

# 2. Storage Account
echo "Importing Storage Account..."
terraform import azurerm_storage_account.cptdazafdmove \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$PREFIX" 2>/dev/null || echo "  Already imported or failed, continuing..."

# 3. Static Website Configuration
echo "Importing Static Website Configuration..."
terraform import azurerm_storage_account_static_website.cptdazafdmove \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$PREFIX" 2>/dev/null || echo "  Already imported or failed, continuing..."

# 4. Role Assignment (get the actual assignment ID first)
echo "Importing Role Assignment..."
ROLE_ASSIGNMENT_ID=$(az role assignment list \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME" \
  --query "[?roleDefinitionName=='Storage Blob Data Contributor'].id" -o tsv | head -n 1)
if [ -n "$ROLE_ASSIGNMENT_ID" ]; then
  terraform import azurerm_role_assignment.sp_blob_contributor "$ROLE_ASSIGNMENT_ID" 2>/dev/null || echo "  Already imported or failed, continuing..."
else
  echo "  WARNING: Role assignment not found, skipping..."
fi

# 5. Log Analytics Workspace
echo "Importing Log Analytics Workspace..."
terraform import azurerm_log_analytics_workspace.cptdazafdmove \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.OperationalInsights/workspaces/$PREFIX" 2>/dev/null || echo "  Already imported or failed, continuing..."

# 6. Front Door Profile
echo "Importing Front Door Profile..."
terraform import azurerm_cdn_frontdoor_profile.cptdazafdmove \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Cdn/profiles/$PREFIX" 2>/dev/null || echo "  Already imported or failed, continuing..."

# 7. Front Door Endpoint
echo "Importing Front Door Endpoint..."
AFD_ENDPOINT=$(az afd endpoint list \
  --profile-name "$PREFIX" \
  --resource-group "$RG_NAME" \
  --query "[0].name" -o tsv 2>/dev/null)
if [ -n "$AFD_ENDPOINT" ]; then
  terraform import azurerm_cdn_frontdoor_endpoint.cptdazafdmove \
    "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Cdn/profiles/$PREFIX/afdEndpoints/$AFD_ENDPOINT" 2>/dev/null || echo "  Already imported or failed, continuing..."
else
  echo "  WARNING: Endpoint not found, skipping..."
fi

# 8. Front Door Origin Group
echo "Importing Front Door Origin Group..."
AFD_ORIGIN_GROUP=$(az afd origin-group list \
  --profile-name "$PREFIX" \
  --resource-group "$RG_NAME" \
  --query "[0].name" -o tsv 2>/dev/null)
if [ -n "$AFD_ORIGIN_GROUP" ]; then
  terraform import azurerm_cdn_frontdoor_origin_group.cptdazafdmove \
    "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Cdn/profiles/$PREFIX/originGroups/$AFD_ORIGIN_GROUP" 2>/dev/null || echo "  Already imported or failed, continuing..."
else
  echo "  WARNING: Origin group not found, skipping..."
fi

# 9. Front Door Origin
echo "Importing Front Door Origin..."
if [ -n "$AFD_ORIGIN_GROUP" ]; then
  AFD_ORIGIN=$(az afd origin list \
    --origin-group-name "$AFD_ORIGIN_GROUP" \
    --profile-name "$PREFIX" \
    --resource-group "$RG_NAME" \
    --query "[0].name" -o tsv 2>/dev/null)
  if [ -n "$AFD_ORIGIN" ]; then
    terraform import azurerm_cdn_frontdoor_origin.cptdazafdmove \
      "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Cdn/profiles/$PREFIX/originGroups/$AFD_ORIGIN_GROUP/origins/$AFD_ORIGIN" 2>/dev/null || echo "  Already imported or failed, continuing..."
  else
    echo "  WARNING: Origin not found, skipping..."
  fi
else
  echo "  WARNING: Skipping (no origin group), continuing..."
fi

# 10. Front Door Rule Set
echo "Importing Front Door Rule Set..."
AFD_RULESET=$(az afd rule-set list \
  --profile-name "$PREFIX" \
  --resource-group "$RG_NAME" \
  --query "[0].name" -o tsv 2>/dev/null)
if [ -n "$AFD_RULESET" ]; then
  terraform import azurerm_cdn_frontdoor_rule_set.cptdazafdmove \
    "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Cdn/profiles/$PREFIX/ruleSets/$AFD_RULESET" 2>/dev/null || echo "  Already imported or failed, continuing..."
else
  echo "  WARNING: Rule set not found, skipping..."
fi

# 11. Front Door Route
echo "Importing Front Door Route..."
if [ -n "$AFD_ENDPOINT" ]; then
  AFD_ROUTE=$(az afd route list \
    --endpoint-name "$AFD_ENDPOINT" \
    --profile-name "$PREFIX" \
    --resource-group "$RG_NAME" \
    --query "[0].name" -o tsv 2>/dev/null)
  if [ -n "$AFD_ROUTE" ]; then
    terraform import azurerm_cdn_frontdoor_route.cptdazafdmove \
      "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Cdn/profiles/$PREFIX/afdEndpoints/$AFD_ENDPOINT/routes/$AFD_ROUTE" 2>/dev/null || echo "  Already imported or failed, continuing..."
  else
    echo "  WARNING: Route not found, skipping..."
  fi
else
  echo "  WARNING: Skipping (no endpoint), continuing..."
fi

# 12. Diagnostic Setting - Storage Blob
echo "Importing Diagnostic Setting for Storage Blob..."
terraform import azurerm_monitor_diagnostic_setting.storage_blob \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$PREFIX/blobServices/default|$PREFIX-blob-diagnostics" 2>/dev/null || echo "  Already imported or failed, continuing..."

# 13. Diagnostic Setting - Front Door
echo "Importing Diagnostic Setting for Front Door..."
terraform import azurerm_monitor_diagnostic_setting.frontdoor \
  "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Cdn/profiles/$PREFIX|$PREFIX-afd-diagnostics" 2>/dev/null || echo "  Already imported or failed, continuing..."

echo ""
echo "Import complete! Run 'terraform plan' to verify everything is in sync."
