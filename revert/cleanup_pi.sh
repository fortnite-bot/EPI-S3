#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

echo "Starting Raspberry Pi Revert Process..."

# Stop and Disable Service
echo "Stopping reverse-tunnel.service..."
systemctl stop reverse-tunnel.service
systemctl disable reverse-tunnel.service

# Remove Service File
SERVICE_PATH="/etc/systemd/system/reverse-tunnel.service"
if [ -f "$SERVICE_PATH" ]; then
    echo "Removing service file: $SERVICE_PATH"
    rm "$SERVICE_PATH"
fi

# Reload Daemon
systemctl daemon-reload

# Remove Connection Script
SCRIPT_PATH="/var/tmp/EPI-Tutorial.sh"
if [ -f "$SCRIPT_PATH" ]; then
    echo "Removing connection script: $SCRIPT_PATH"
    rm "$SCRIPT_PATH"
fi

# # Uninstall Packages (Optional - prompt user?)
# # Since we installed these, we can remove them.
# echo "Removing installed packages (openssh-server, sshpass)..."
# apt remove openssh-server sshpass -y
# apt autoremove -y

# Restore logs (Optional cleanup)
LOG_FILE="./log.log"
if [ -f "$LOG_FILE" ]; then
    echo "Removing log file: $LOG_FILE"
    rm "$LOG_FILE"
fi

echo "Raspberry Pi Reverted. (Note: System updates cannot be undone easily)"
