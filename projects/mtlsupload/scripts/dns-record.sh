#!/usr/bin/env bash
# Creates/updates a DNS record in the cptdaz.org zone (other subscription).
# usage: dns-record.sh cname <label> <target>   |   dns-record.sh txt <name> <value>
set -euo pipefail
TYPE="$1"; NAME="$2"; VALUE="$3"
[ -n "$VALUE" ] || { echo "empty value for $TYPE $NAME" >&2; exit 1; }
SUB="${AZURE_DNS_SUBSCRIPTION_ID:-ff0bb075-6c44-44ee-bb64-d46ce828c62f}"
RG="${DNS_RESOURCE_GROUP:-domains}"
ZONE="${DNS_ZONE:-cptdaz.org}"
case "$TYPE" in
  cname)
    az network dns record-set cname set-record --subscription "$SUB" -g "$RG" -z "$ZONE" -n "$NAME" -c "$VALUE" --ttl 300 -o none ;;
  txt)
    az network dns record-set txt create --subscription "$SUB" -g "$RG" -z "$ZONE" -n "$NAME" --ttl 300 -o none 2>/dev/null || true
    az network dns record-set txt add-record --subscription "$SUB" -g "$RG" -z "$ZONE" -n "$NAME" -v "$VALUE" -o none 2>/dev/null || true ;;
  *) echo "unknown type $TYPE" >&2; exit 1 ;;
esac
echo "$TYPE $NAME.$ZONE -> $VALUE"
