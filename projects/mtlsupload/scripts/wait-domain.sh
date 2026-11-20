#!/usr/bin/env bash
# Waits until a Front Door custom domain is validated and its certificate is provisioned.
# usage: wait-domain.sh <resource-group> <profile> <domain-name> [timeout-minutes]
set -euo pipefail
RG="$1"; PROFILE="$2"; DOMAIN="$3"; TIMEOUT="${4:-30}"
for i in $(seq 1 $((TIMEOUT * 2))); do
  read -r VAL PROV DEPLOY < <(az afd custom-domain show -g "$RG" --profile-name "$PROFILE" --custom-domain-name "$DOMAIN" \
    --query "join(' ', [domainValidationState,provisioningState,deploymentStatus])" -o tsv)
  echo "$DOMAIN: validation=$VAL provisioning=$PROV deployment=$DEPLOY"
  [ "$VAL" = "Approved" ] && [ "$PROV" = "Succeeded" ] && [ "$DEPLOY" = "Succeeded" ] && exit 0
  sleep 30
done
echo "timeout waiting for $DOMAIN" >&2; exit 1
