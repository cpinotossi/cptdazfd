#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
RG="${RESOURCE_GROUP:-rg-cptmtls}"
SUB="${AZURE_SUBSCRIPTION_ID:-09808f31-065f-4231-914d-776c2d6bbe34}"
PROFILE="${PROFILE:-afd-cptmtls-upload}"
ENDPOINT="${ENDPOINT:-cptmtls-uploadp}"
HOST="${HOST:-uploadp.cptdaz.org}"
ACTION="${EDGE_ACTION:-eacptmtlsupload}"
API=2026-10-01
CODE="$ROOT/projects/mtlsupload/edge/upload-policy.js"
VERSION="v$(sha256sum "$CODE" | cut -c1-12)"

az deployment group create --subscription "$SUB" -g "$RG" -n afd-upload-edge-action \
  --template-file "$ROOT/projects/mtlsupload/afd/upload-edge-action.bicep" \
  --parameters edgeActionName="$ACTION" -o none

ACTION_ID="/subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Cdn/edgeActions/$ACTION"
VERSION_ID="$ACTION_ID/versions/$VERSION"
VERSIONS=$(az rest --method get --url "$ACTION_ID/versions?api-version=$API")
EXISTS=$(jq --arg version "$VERSION" '[.value[] | select(.name == $version)] | length' <<< "$VERSIONS")
if [[ "$EXISTS" == 0 ]]; then
  if [[ "$(jq '.value | length' <<< "$VERSIONS")" -ge 3 ]]; then
    echo "Edge Action has three versions. Remove an unused non-default version before deploying new code." >&2
    exit 1
  fi
  az rest --method put --url "$VERSION_ID?api-version=$API" \
    --body '{"location":"global","properties":{"deploymentType":"file","isDefaultVersion":"False"}}' -o none
  az resource wait --subscription "$SUB" --ids "$VERSION_ID" --api-version "$API" \
    --created --interval 10 --timeout 1200
  PAYLOAD=$(jq -n --arg content "$(base64 -w0 "$CODE")" '{name:"edge_action.js",content:$content}')
  az rest --method post --url "$VERSION_ID/deployVersionCode?api-version=$API" \
    --body "$PAYLOAD" -o none
fi
az resource wait --subscription "$SUB" --ids "$VERSION_ID" --api-version "$API" \
  --custom "properties.provisioningState=='Succeeded' && properties.validationStatus=='Succeeded'" \
  --interval 10 --timeout 1200

PACKAGE=$(mktemp --suffix=.zip)
trap 'rm -f "$PACKAGE"' EXIT
az rest --method post --url "$VERSION_ID/getVersionCode?api-version=$API" \
  --query content -o tsv | base64 -d > "$PACKAGE"
unzip -p "$PACKAGE" edge_action.js | cmp - "$CODE"

DEFAULT=$(az rest --method get --url "$VERSION_ID?api-version=$API" --query properties.isDefaultVersion -o tsv)
if [[ "$DEFAULT" != True ]]; then
  az rest --method post --url "$VERSION_ID/swapDefault?api-version=$API" -o none
  az resource wait --subscription "$SUB" --ids "$VERSION_ID" --api-version "$API" \
    --custom "properties.isDefaultVersion=='True' && properties.provisioningState=='Succeeded'" \
    --interval 10 --timeout 1200
fi

az deployment group create --subscription "$SUB" -g "$RG" -n afd-upload-edge-route \
  --template-file "$ROOT/projects/mtlsupload/afd/upload-edge-route.bicep" \
  --parameters profileName="$PROFILE" endpointName="$ENDPOINT" hostName="$HOST" edgeActionName="$ACTION" \
  -o none

echo "Deployed https://$HOST/upload/edge/*; allow time for Front Door propagation."
