#!/bin/bash
set -euo pipefail 

TOKEN="kkraft_token_server"
SERVER_IP=192.168.56.110
IP=192.168.56.111

log() {
    if [[ ! $# -eq 1 ]]; then
        return 1
    fi

    local message=$1

    echo "[$(date +"%Y-%m-%d %H:%M:%S")] - ${message}" | sudo tee -a /var/log/install_agent.log
}

if ping -c3 192.168.56.110; then
    log "Communication to server ready"
else
    log "Communication to sever not initialize"
    exit 1
fi

sudo restorecon -v /etc/NetworkManager/system-connections/enp0s8.nmconnection
sudo nmcli connection modify enp0s8 ipv4.never-default yes
sudo nmcli connection up enp0s8

if curl -k -m 5 https://192.168.56.110:6443; then
    log "Port 6443 expose and ready for communication"
else
    log "Port 6443 not expose and not ready for communication"
    exit 1
fi

curl -sfL https://get.k3s.io | \
K3S_URL=https://${SERVER_IP}:6443 \
K3S_TOKEN="$TOKEN" \
sh -s - agent --node-ip="$IP"

echo "export KUBECONFIG='/vagrant/confs/agent.yaml'" > /etc/profile.d/kubeconfig.sh

log "Agent k3s ready"