#!/usr/bin/env bash
# Creates a test PKI: trusted root CA + valid client cert, and an untrusted CA + client cert (negative test).
# Private keys stay in $PKI_DIR (outside the repo); only the public CA cert is copied to pki/ca.crt.
set -euo pipefail
PKI_DIR="${PKI_DIR:-$HOME/mtls-pki}"
REPO_PKI="$(cd "$(dirname "$0")/../pki" && pwd)"
mkdir -p "$PKI_DIR" && cd "$PKI_DIR"

mkca() { # name
  [ -f "$1-ca.key" ] && return
  openssl req -x509 -newkey rsa:4096 -nodes -keyout "$1-ca.key" -out "$1-ca.crt" -days 365 \
    -subj "/CN=cptmtls $1 root CA" \
    -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign"
}
mkclient() { # ca name
  [ -f "$2.key" ] && return
  openssl req -newkey rsa:2048 -nodes -keyout "$2.key" -out "$2.csr" -subj "/CN=$2"
  printf "basicConstraints=CA:FALSE\nkeyUsage=digitalSignature\nextendedKeyUsage=clientAuth\n" > "$2.ext"
  openssl x509 -req -in "$2.csr" -CA "$1-ca.crt" -CAkey "$1-ca.key" -CAcreateserial -out "$2.crt" -days 180 -extfile "$2.ext"
  rm -f "$2.csr" "$2.ext"
}
mkca trusted
mkclient trusted client-valid
mkca untrusted
mkclient untrusted client-invalid
cp trusted-ca.crt "$REPO_PKI/ca.crt"
echo "PKI in $PKI_DIR; public CA copied to $REPO_PKI/ca.crt"
