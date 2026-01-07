#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  exit 1
fi

read -p "Enter Azure VM Username: " AZURE_USER
read -p "Enter Azure VM Public IP: " AZURE_IP
read -p "Enter Connection Password (for Azure VM User): " PASSWORD
read -p "Enter Remote Port (default 2222): " REMOTE_PORT
REMOTE_PORT=${REMOTE_PORT:-2222}

apt update -y
apt upgrade -y

apt install openssh-server sshpass -y
systemctl enable ssh
systemctl start ssh

SCRIPT_PATH="/var/tmp/EPI-Tutorial.sh"
SERVICE_PATH="/etc/systemd/system/reverse-tunnel.service"

cat <<EOF | tee $SCRIPT_PATH
#!/bin/bash
AZURE_USER="$AZURE_USER"
AZURE_IP="$AZURE_IP"
REMOTE_PORT=$REMOTE_PORT
LOCAL_PORT=22
PASSWORD="$PASSWORD"
while true; do
    sshpass -p "\$PASSWORD" ssh -o "StrictHostKeyChecking=no" -o "ServerAliveInterval=30" -o "ServerAliveCountMax=3" -N -R \${REMOTE_PORT}:localhost:\${LOCAL_PORT} \${AZURE_USER}@\${AZURE_IP}
    sleep 1
done
EOF

chmod +x $SCRIPT_PATH

cat <<EOF | tee $SERVICE_PATH
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

systemctl daemon-reload
systemctl enable reverse-tunnel.service
systemctl start reverse-tunnel.service
