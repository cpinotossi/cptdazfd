#!/usr/bin/env bash
# Stage 1 of the upload: issues a short-lived user delegation SAS for the private upload storage account.
# The storage account is private, so the SAS is generated on the VM (managed identity, through the private endpoint).
# usage: new-upload-sas.sh [minutes-valid]   -> prints the SAS query string
set -euo pipefail
MINUTES="${1:-60}"
RG="${RESOURCE_GROUP:-rg-cptmtls}"
SUB="${AZURE_SUBSCRIPTION_ID:-09808f31-065f-4231-914d-776c2d6bbe34}"
VM="${VM_NAME:-vm-cptmtls}"
ACCOUNT="${UPLOAD_STORAGE:?set UPLOAD_STORAGE to the upload storage account name}"
EXPIRY=$(date -u -d "+${MINUTES} minutes" +%Y-%m-%dT%H:%MZ)

RESULT=$(az vm run-command invoke --subscription "$SUB" -g "$RG" -n "$VM" --command-id RunShellScript \
  --scripts "az login --identity -o none && az storage container generate-sas --as-user --auth-mode login --account-name $ACCOUNT -n upload --permissions cw --expiry $EXPIRY --https-only -o tsv" \
  --query "value[0].message" -o tsv)
# run-command wraps output in [stdout]/[stderr] sections
echo "$RESULT" | sed -n '/\[stdout\]/,/\[stderr\]/p' | grep -v -E '^\[(stdout|stderr)\]' | tr -d '"' | head -1
