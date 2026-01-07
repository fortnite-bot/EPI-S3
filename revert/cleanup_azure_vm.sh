#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

echo "Starting Azure VM Revert Process..."

# Restore SSH Configuration
SSH_CONFIG="/etc/ssh/sshd_config"

if [ -f "$SSH_CONFIG.bak" ]; then
    echo "Restoring sshd_config from backup..."
    cp "$SSH_CONFIG.bak" "$SSH_CONFIG"
    if [ $? -eq 0 ]; then
        echo "Configuration restored."
        rm "$SSH_CONFIG.bak"
    else
        echo "Failed to restore backup!"
        exit 1
    fi
else
    echo "No backup file found at $SSH_CONFIG.bak. Cannot revert specific SSH changes automatically."
    echo "You may need to manually reset these settings in $SSH_CONFIG:"
    echo "  - AllowAgentForwarding"
    echo "  - AllowTcpForwarding"
    echo "  - GatewayPorts"
    echo "  - X11Forwarding"
    echo "  - PasswordAuthentication"
    echo "  - PermitRootLogin"
fi

# Restart SSH service
echo "Restarting SSH service..."
systemctl restart ssh

echo "Azure VM Reverted. (Note: System updates cannot be undone easily)"
