#!/usr/bin/env bash
# Source this file from the notebook; paths do not depend on the notebook working directory.
export EDGE_REPO_ROOT
EDGE_REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
export AZURE_SUBSCRIPTION_ID=09808f31-065f-4231-914d-776c2d6bbe34
export RESOURCE_GROUP=rg-cptmtls
export PROFILE=afd-cptmtls-upload
export ENDPOINT=cptmtls-uploadp
export HOST=uploadp.cptdaz.org
export DOMAIN=uploadp-cptdaz-org
export STORAGE=stcptmtlsuploadpizhwq
export CONTAINER=upload
export EDGE_ACTION=eacptmtlsupload
export EDGE_VERSION="v$(sha256sum "$EDGE_REPO_ROOT/projects/mtlsupload/edge/upload-policy.js" | cut -c1-12)"
export EDGE_API=2026-10-01
export AFD_API=2026-10-01
export CERT="$HOME/mtls-pki/client-valid.crt"
export KEY="$HOME/mtls-pki/client-valid.key"
export DEVICE_ID=device-042
export RUN_ID="edge-$(date -u +%Y%m%dT%H%M%S)-$$"
export DEMO_DIR="/tmp/$RUN_ID"
export TELEMETRY_FILE="$DEMO_DIR/telemetry.json"
export DIAGNOSTICS_FILE="$DEMO_DIR/diagnostics.zip"
export OVERSIZE_FILE="$DEMO_DIR/oversize.json"
export TELEMETRY_BLOB="edge/$RUN_ID.json"
export DIAGNOSTICS_BLOB="edge/$RUN_ID.zip"
export BASELINE_BLOB="$RUN_ID-baseline.txt"
export EDGE_URL="https://$HOST/$CONTAINER/edge"
export ARM_ROOT="https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Cdn"
export VERSION_URL="$ARM_ROOT/edgeActions/$EDGE_ACTION/versions/$EDGE_VERSION?api-version=$EDGE_API"
export AZCOPY_AUTO_LOGIN_TYPE=AZCLI
export AZCOPY_LOG_LOCATION="$DEMO_DIR/azcopy-logs"
export AZCOPY_JOB_PLAN_LOCATION="$DEMO_DIR/azcopy-plans"
export PAGER=cat
