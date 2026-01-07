#!/bin/bash

# Log function for consistent debug output
log_debug() {
    echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_debug "Starting script execution: setup_azure_vm_verbose.sh"

# Ensure the script is run as root
log_debug "Checking root privileges..."
if [ "$EUID" -ne 0 ]; then
  log_debug "User is not root. EUID: $EUID"
  echo "Please run as root (use sudo)"
  exit 1
fi
log_debug "Root privilege check passed."

# Azure VM Setup Script for Reverse SSH Proxy
# Run this on your Azure Linux VM

echo "Starting Azure VM Setup..."
log_debug "Starting update process."

# Update system
echo "Updating system..."
log_debug "Running 'apt update -y'..."
sudo apt update -y
if [ $? -eq 0 ]; then
    log_debug "apt update successful."
else
    log_debug "apt update failed!"
    exit 1
fi

log_debug "Running 'apt upgrade -y'..."
sudo apt upgrade -y
if [ $? -eq 0 ]; then
    log_debug "apt upgrade successful."
else
    log_debug "apt upgrade failed!"
    exit 1
fi

# Configure SSH
SSH_CONFIG="/etc/ssh/sshd_config"
echo "Configuring SSH..."
log_debug "Target SSH config file: $SSH_CONFIG"

# Backup config
log_debug "Checking if SSH config file exists..."
if [ -f "$SSH_CONFIG" ]; then
    log_debug "File exists. Creating backup at ${SSH_CONFIG}.bak"
    sudo cp $SSH_CONFIG "$SSH_CONFIG.bak"
    if [ $? -eq 0 ]; then
        log_debug "Backup created successfully."
    else
        log_debug "Failed to create backup!"
        exit 1
    fi
else
    log_debug "Error: $SSH_CONFIG not found."
    echo "Error: $SSH_CONFIG not found."
    exit 1
fi

# Function to force a setting to yes (regardless of current state)
enable() {
    local param=$1
    log_debug "Creating/Updating SSH setting: $param"
    
    log_debug "Checking if param '$param' exists in config..."
    if grep -q "^\s*#*\s*$param" "$SSH_CONFIG"; then
        log_debug "Param '$param' found. Attempting to uncomment/replace..."
        # Replace existing line (commented or not) with "Param yes"
        sudo sed -i "s/^\s*#*\s*$param.*/$param yes/" "$SSH_CONFIG"
        if [ $? -eq 0 ]; then
             log_debug "Successfully updated '$param' to yes."
        else
             log_debug "Failed to update '$param'!"
        fi
    else
        log_debug "Param '$param' NOT found. Appending to end of file..."
        # Append if not found
        echo "$param yes" | sudo tee -a "$SSH_CONFIG" > /dev/null
         if [ $? -eq 0 ]; then
             log_debug "Successfully appended '$param' to yes."
        else
             log_debug "Failed to append '$param'!"
        fi
    fi
}

log_debug "Enabling SSH Forwarding options and Password Auth..."
enable "AllowAgentForwarding"
enable "AllowTcpForwarding"
enable "GatewayPorts"
enable "X11Forwarding"
enable "PasswordAuthentication"
enable "PermitRootLogin"

echo "SSH Configuration updated."
log_debug "SSH Configuration logical update complete."

# Restart SSH service
echo "Restarting SSH service..."
log_debug "Attempting to restart ssh service..."
sudo systemctl restart ssh
if [ $? -eq 0 ]; then
    log_debug "Service ssh restarted successfully."
else
    log_debug "Service ssh failed to restart!"
    exit 1
fi

log_debug "Attempting to enable ssh service on boot..."
sudo systemctl enable ssh
if [ $? -eq 0 ]; then
    log_debug "Service ssh enabled successfully."
else
    log_debug "Service ssh failed to enable!"
fi

log_debug "Script execution finished successfully."
echo "Azure VM Setup Complete! Note your Public IP and proceed to Raspberry Pi setup."
