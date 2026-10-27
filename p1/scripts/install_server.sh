#!/bin/bash
set -euo pipefail 

TOKEN="kkraft_token_server"
IP=192.168.56.110

log() {
    if [[ ! $# -eq 1 ]]; then
        return 1
    fi

    local message=$1

    echo "[$(date +"%Y-%m-%d %H:%M:%S")] - ${message}" | sudo tee -a /var/log/install_server.log
}

sudo restorecon -v /etc/NetworkManager/system-connections/enp0s8.nmconnection
sudo nmcli connection modify enp0s8 ipv4.never-default yes
sudo nmcli connection up enp0s8

curl -sfL https://get.k3s.io | K3S_TOKEN="$TOKEN" sh -s - server \
--write-kubeconfig-mode=644 \
--node-ip="$IP"

log "Server initialized"

sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --reload

if sudo firewall-cmd --zone=public --query-port=6443/tcp; then
    log "Port 6443 exposed"
else
    log "Error on port 6443 exposition"
    exit 1
fi

log "Server k3s ready"
