#!/bin/bash

# Log function for consistent debug output
LOG_FILE="./log.log"
log_debug() {
    local msg="[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

log_debug "Starting script execution: setup_pi_verbose.sh"

# Ensure the script is run as root
log_debug "Checking root privileges..."
if [ "$EUID" -ne 0 ]; then
  log_debug "User is not root. EUID: $EUID"
  echo "Please run as root (use sudo)"
  exit 1
fi
log_debug "Root privilege check passed."

# Raspberry Pi Setup Script for Reverse SSH Proxy
# Run this on your Raspberry Pi

# Prompt for Variables
log_debug "Prompting for user input..."
read -p "Enter Azure VM Username: " AZURE_USER
log_debug "Read AZURE_USER: $AZURE_USER"

read -p "Enter Azure VM Public IP: " AZURE_IP
log_debug "Read AZURE_IP: $AZURE_IP"

read -p "Enter Connection Password (for Azure VM User): " PASSWORD
# Create a mask of asterisks matching the password length
MASKED_PASS=""
for ((i=0; i<${#PASSWORD}; i++)); do MASKED_PASS="${MASKED_PASS}*"; done
log_debug "Read PASSWORD: $MASKED_PASS"

read -p "Enter Remote Port (default 2222): " REMOTE_PORT
REMOTE_PORT=${REMOTE_PORT:-2222}
log_debug "Using REMOTE_PORT: $REMOTE_PORT"

echo "Starting Raspberry Pi Setup..."

# Step 1: Update System
echo "Updating System (Step 1)..."
log_debug "Starting system update..."
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

# Step 2: Install SSH & sshpass
echo "Installing SSH and sshpass (Step 2)..."
log_debug "Installing openssh-server and sshpass..."
sudo apt install openssh-server sshpass -y
if [ $? -eq 0 ]; then
    log_debug "Package installation successful."
else
    log_debug "Package installation failed!"
    exit 1
fi

log_debug "Enabling ssh service..."
sudo systemctl enable ssh
if [ $? -eq 0 ]; then log_debug "SSH enabled."; else log_debug "SSH enable failed!"; fi

log_debug "Starting ssh service..."
sudo systemctl start ssh
if [ $? -eq 0 ]; then log_debug "SSH started."; else log_debug "SSH start failed!"; fi


# Step 5: Configure Reverse SSH
echo "Configuring Reverse Tunnel (Step 5)..."

SCRIPT_PATH="/var/tmp/EPI-Tutorial.sh"
SERVICE_PATH="/etc/systemd/system/reverse-tunnel.service"
log_debug "Script Path: $SCRIPT_PATH"
log_debug "Service Path: $SERVICE_PATH"

# Create the script
echo "Creating connection script at $SCRIPT_PATH..."
log_debug "Writing content to $SCRIPT_PATH..."

# Note: Generating the original script content
cat <<EOF | sudo tee $SCRIPT_PATH
#!/bin/bash

# Configuration
AZURE_USER="$AZURE_USER"
AZURE_IP="$AZURE_IP"
REMOTE_PORT=$REMOTE_PORT
LOCAL_PORT=22
PASSWORD="$PASSWORD"

# Infinite loop to retry connection every 1 second
while true; do
    echo "\$(date): Trying to connect to Azure VM..."
    
    # Use sshpass to provide password non-interactively
    sshpass -p "\$PASSWORD" ssh -o "StrictHostKeyChecking=no" -o "ServerAliveInterval=30" -o "ServerAliveCountMax=3" -N -R \${REMOTE_PORT}:localhost:\${LOCAL_PORT} \${AZURE_USER}@\${AZURE_IP}
    
    # If SSH exits, wait 1 second and retry
    sleep 1
done
EOF

if [ $? -eq 0 ]; then
    log_debug "Script content written successfully."
else
    log_debug "Failed to write script content!"
    exit 1
fi

log_debug "Making script executable..."
sudo chmod +x $SCRIPT_PATH
if [ $? -eq 0 ]; then log_debug "chmod successful."; else log_debug "chmod failed!"; fi

# Create the service
echo "Creating systemd service at $SERVICE_PATH..."
log_debug "Writing systemd unit file..."

cat <<EOF | sudo tee $SERVICE_PATH
[Unit]
Description=Reverse SSH Tunnel to Azure VM
After=network.target

[Service]
User=root
ExecStart=$SCRIPT_PATH
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

if [ $? -eq 0 ]; then
    log_debug "Service file written successfully."
else
    log_debug "Failed to write service file!"
    exit 1
fi

# Enable and Start Service
echo "Enabling and Starting Service..."
log_debug "Reloading systemd daemon..."
sudo systemctl daemon-reload
if [ $? -eq 0 ]; then log_debug "daemon-reload successful."; else log_debug "daemon-reload failed!"; fi

log_debug "Enabling reverse-tunnel.service..."
sudo systemctl enable reverse-tunnel.service
if [ $? -eq 0 ]; then log_debug "Service enable successful."; else log_debug "Service enable failed!"; fi

log_debug "Starting reverse-tunnel.service..."
sudo systemctl start reverse-tunnel.service
if [ $? -eq 0 ]; then log_debug "Service start successful."; else log_debug "Service start failed!"; fi

echo "Setup Complete!"
echo "Check status with: systemctl status reverse-tunnel.service"
log_debug "Running systemctl status check..."
systemctl status reverse-tunnel.service --no-pager
log_debug "Script finished."
