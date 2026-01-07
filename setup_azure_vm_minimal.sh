#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  exit 1
fi

apt update -y && apt upgrade -y

SSH_CONFIG="/etc/ssh/sshd_config"

if [ -f "$SSH_CONFIG" ]; then
    cp $SSH_CONFIG "$SSH_CONFIG.bak"
else
    exit 1
fi

enable() {
    local param=$1
    if grep -q "^\s*#*\s*$param" "$SSH_CONFIG"; then
        sed -i "s/^\s*#*\s*$param.*/$param yes/" "$SSH_CONFIG"
    else
        echo "$param yes" | tee -a "$SSH_CONFIG"
    fi
}

enable "AllowAgentForwarding"
enable "AllowTcpForwarding"
enable "GatewayPorts"
enable "X11Forwarding"
enable "PasswordAuthentication"
enable "PermitRootLogin"

systemctl restart ssh
systemctl enable ssh
