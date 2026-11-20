#!/usr/bin/env bash
# Source once at the start of signed-url.ipynb. This file contains no credentials.
export SIGNED_REPO_ROOT
SIGNED_REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
export SIGNED_SUB=09808f31-065f-4231-914d-776c2d6bbe34
export SIGNED_RG=rg-cptmtls
export SIGNED_PROFILE=afd-cptmtls-public
export SIGNED_ENDPOINT=cptmtls-signed-url
export SIGNED_STORAGE=stcptmtlsmediaizhwq
export SIGNED_CONTAINER=signed-downloads
export SIGNED_LOCATION=westeurope
export SIGNED_SAS_MINUTES=3
export SIGNED_CACHE_SECONDS=600
export SIGNED_READY_ATTEMPTS=120
export SIGNED_POLL_SECONDS=15
export SIGNED_RUN_ID="signed-$(date -u +%Y%m%d%H%M%S)-$$"
export SIGNED_BLOB="$SIGNED_RUN_ID.txt"
export SIGNED_OTHER_BLOB="$SIGNED_RUN_ID-other.txt"
export SIGNED_DEPLOYMENT=afd-signed-url
export SIGNED_TEMPLATE="$SIGNED_REPO_ROOT/projects/mtlsupload/afd/signed-url.bicep"
export SIGNED_ISSUER="$SIGNED_REPO_ROOT/projects/mtlsupload/scripts/new-download-sas.sh"
export PAGER=cat
