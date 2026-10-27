#!/bin/bash
set -Eeuo pipefail 

LOG_FILE=/var/log/install_server.log
TOKEN="kkraft_token_server"
IP=192.168.56.110

log() {
    [[ $# -eq 2 ]] || return 1
    local line="[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2"
    if [[ $1 == ERROR ]]; then
        echo "$line" | tee -a "$LOG_FILE" >&2
    else
        echo "$line" | tee -a "$LOG_FILE"
    fi
}

trap 'log ERROR "line $LINENO failed: $BASH_COMMAND"' ERR

log INFO  "Network: preventing enp0s8 from holding the default route"
sudo restorecon -v /etc/NetworkManager/system-connections/enp0s8.nmconnection
sudo nmcli connection modify enp0s8 ipv4.never-default yes
sudo nmcli connection up enp0s8
log INFO  "Network ready: default route via $(ip route show default | awk '{print $3}')"

log INFO  "Installing K3s in server mode (node IP: $IP)..."
curl -sfL https://get.k3s.io | K3S_TOKEN="$TOKEN" sh -s - server \
--write-kubeconfig-mode=644 \
--node-ip="$IP"
log INFO  "K3s server running, API answering on https://$IP:6443"

log INFO  "Firewall: opening 6443/tcp (K3s API)..."
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --reload

if sudo firewall-cmd --zone=public --query-port=6443/tcp; then
    log INFO  "Firewall: 6443/tcp open"
else
    log ERROR "Firewall: 6443/tcp still closed after reload"
    exit 1
fi

log INFO  "Server provisioning complete"
