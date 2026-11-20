#!/usr/bin/env bash
# Runs on the VM (Bicep runCommand). Seeds the private storage accounts through their private endpoints
# using the VM's system-assigned managed identity (shared key access is disabled by policy).
set -uo pipefail
HELLO_HOST="__HELLO_HOST__"; MEDIA_HOST="__MEDIA_HOST__"

token() {
  curl -s -H Metadata:true "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/" \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])'
}

put_blob() { # host file-content content-type blob-name
  local code
  for i in $(seq 1 40); do
    code=$(curl -sS -o /tmp/put.out -w "%{http_code}" -X PUT \
      -H "Authorization: Bearer $(token)" -H "x-ms-version: 2023-11-03" -H "x-ms-blob-type: BlockBlob" \
      -H "Content-Type: $3" --data-binary "$2" "https://$1/%24root/$4" || true)
    echo "PUT $1/$4 -> $code"
    [ "$code" = "201" ] && return 0
    sleep 15 # RBAC and private DNS propagation
  done
  cat /tmp/put.out; return 1
}

put_blob "$HELLO_HOST" "Hello World" "text/plain" "hello.txt"
put_blob "$MEDIA_HOST" "body { font-family: sans-serif; background: #eef6ff; color: #05396b; margin: 4rem; }
h1 { border-bottom: 3px solid #5cdb95; }" "text/css" "style.css"
