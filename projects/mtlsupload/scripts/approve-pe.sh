#!/usr/bin/env bash
# Approves pending private endpoint connections that Front Door created on the given resources.
# usage: approve-pe.sh <resourceId> [<resourceId> ...]   (waits up to ~10 minutes for the connections to appear)
set -euo pipefail
for ID in "$@"; do
  echo "== $ID"
  for i in $(seq 1 40); do
    PENDING=$(az network private-endpoint-connection list --id "$ID" \
      --query "[?properties.privateLinkServiceConnectionState.status=='Pending'].id" -o tsv)
    [ -n "$PENDING" ] && break
    # nothing pending: fine if everything is already approved
    APPROVED=$(az network private-endpoint-connection list --id "$ID" \
      --query "[?properties.privateLinkServiceConnectionState.status=='Approved' && contains(properties.privateLinkServiceConnectionState.description || '', 'afd')] | length(@)" -o tsv)
    [ "${APPROVED:-0}" -gt 0 ] && echo "already approved" && break
    sleep 15
  done
  for P in $PENDING; do
    echo "approving $P"
    az network private-endpoint-connection approve --id "$P" --description "approved by pipeline (afd)" -o none
  done
done
