#!/usr/bin/env bash
# Issue a blob-scoped, read-only user delegation SAS from a host with private Storage access.
# usage: bash new-download-sas.sh <blob-name> [minutes-valid] [cache-seconds]
set -euo pipefail

if [[ $# -lt 1 || $# -gt 3 || -z "$1" ]]; then
  echo "Usage: new-download-sas.sh <blob-name> [minutes-valid: 1..60] [cache-seconds: 1..3600]" >&2
  exit 2
fi
BLOB="$1"
MINUTES="${2:-5}"
CACHE_SECONDS="${3:-600}"
if [[ ! "$MINUTES" =~ ^[1-9][0-9]?$ ]] || (( MINUTES > 60 )); then
  echo "minutes-valid must be an integer from 1 to 60." >&2
  exit 2
fi
if [[ ! "$CACHE_SECONDS" =~ ^[1-9][0-9]{0,3}$ ]] || (( CACHE_SECONDS > 3600 )); then
  echo "cache-seconds must be an integer from 1 to 3600." >&2
  exit 2
fi
ACCOUNT="${DOWNLOAD_STORAGE:?set DOWNLOAD_STORAGE to the private storage account name}"
CONTAINER="${DOWNLOAD_CONTAINER:-signed-downloads}"
SUB="${AZURE_SUBSCRIPTION_ID:-09808f31-065f-4231-914d-776c2d6bbe34}"
EXPIRY=$(date -u -d "+${MINUTES} minutes" +%Y-%m-%dT%H:%MZ)

SAS=$(az storage blob generate-sas --subscription "$SUB" \
  --account-name "$ACCOUNT" --container-name "$CONTAINER" --name "$BLOB" \
  --as-user --auth-mode login --permissions r --https-only --expiry "$EXPIRY" \
  --cache-control "max-age=0, s-maxage=$CACHE_SECONDS" --only-show-errors -o tsv)
if [[ -z "$SAS" || "$SAS" == None || "$SAS" == null ]]; then
  echo "Azure CLI returned no SAS; no download link was issued." >&2
  exit 1
fi
printf '%s\n' "$SAS"
