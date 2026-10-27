#!/bin/bash
set -Eeuo pipefail 

LOG_FILE=/var/log/install_agent.log
TOKEN="kkraft_token_server"
SERVER_IP=192.168.56.110
IP=192.168.56.111

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

log INFO  "Checking that the server $SERVER_IP is reachable..."

if ping -c3 192.168.56.110; then
    log INFO  "Server $SERVER_IP reachable"
else
    log ERROR "Server $SERVER_IP unreachable: check the private network (192.168.56.0/24)"
    exit 1
fi

log INFO  "Network: preventing enp0s8 from holding the default route"
sudo restorecon -v /etc/NetworkManager/system-connections/enp0s8.nmconnection
sudo nmcli connection modify enp0s8 ipv4.never-default yes
sudo nmcli connection up enp0s8
log INFO  "Network ready: default route via $(ip route show default | awk '{print $3}')"

log INFO  "Checking the K3s API at https://$SERVER_IP:6443..."
if curl -k -m 5 https://192.168.56.110:6443; then
    log INFO  "K3s API reachable"
else
    log ERROR "K3s API unreachable at https://$SERVER_IP:6443: is 6443/tcp open on the server?"
    exit 1
fi

log INFO  "Installing K3s in agent mode (node IP: $IP, server: $SERVER_IP)..."
curl -sfL https://get.k3s.io | \
K3S_URL=https://${SERVER_IP}:6443 \
K3S_TOKEN="$TOKEN" \
sh -s - agent --node-ip="$IP"
log INFO  "K3s agent running and connected to the server"

log INFO  "KUBECONFIG set for all users in /etc/profile.d/kubeconfig.sh"
echo "export KUBECONFIG='/vagrant/confs/agent.yaml'" > /etc/profile.d/kubeconfig.sh

log INFO  "Agent provisioning complete"