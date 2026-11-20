#!/usr/bin/env bash
# Runs on the VM (Bicep runCommand). Installs the VS Code CLI and runs `code tunnel` as a systemd service.
# First start prints a GitHub device login code: sudo journalctl -u code-tunnel -n 20 --no-pager
set -euo pipefail
TUNNEL_NAME="__TUNNEL_NAME__"

if [ ! -x /usr/local/bin/code ]; then
  for i in $(seq 1 10); do
    curl -fsSL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64" -o /tmp/vscode-cli.tar.gz && break
    sleep 15
  done
  tar -xzf /tmp/vscode-cli.tar.gz -C /usr/local/bin code
  rm -f /tmp/vscode-cli.tar.gz
fi

cat > /etc/systemd/system/code-tunnel.service <<UNIT
[Unit]
Description=VS Code tunnel
After=network-online.target

[Service]
User=azureuser
Environment=HOME=/home/azureuser
ExecStart=/usr/local/bin/code tunnel --accept-server-license-terms --name ${TUNNEL_NAME}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now code-tunnel
sleep 15
journalctl -u code-tunnel -n 20 --no-pager
