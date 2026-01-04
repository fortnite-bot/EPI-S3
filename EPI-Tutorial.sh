#/usr/bin/bash

# Configuration
AZURE_USER="Jan"
AZURE_IP="00.00.00.00"
REMOTE_PORT=6767
LOCAL_PORT=22
PASSWORD="JanMarcel#67"

# Infinite loop to retry connection every 1 second
while true; do
    echo "$(date): Trying to connect to Azure VM..."
    
    # Use sshpass to provide password non-interactively
    sshpass -p "$PASSWORD" ssh -o "StrictHostKeyChecking=no" -o "ServerAliveInterval=30" -o "ServerAliveCountMax=3" -N -R ${REMOTE_PORT}:localhost:${LOCAL_PORT} ${AZURE_USER}@${AZURE_IP}
    
    # If SSH exits, wait 1 second and retry
    sleep 1
done
