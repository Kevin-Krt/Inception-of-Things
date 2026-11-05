#!/bin/bash
set -Eeuo pipefail

LOG_FILE=/var/log/deploy_apps.log

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

export PATH="/usr/local/bin:$PATH"

log INFO "Deploy: starting application deployment"

log INFO "app1: applying ConfigMap nginx-config-map from /vagrant/confs/app1/html/"
kubectl create configmap nginx-config-map --from-file=/vagrant/confs/app1/html/ --dry-run=client -o yaml | kubectl apply -f -
log INFO "app1: ConfigMap nginx-config-map applied"

log INFO "app1: applying Deployment from /vagrant/confs/app1/deployment.yaml"
kubectl apply -f /vagrant/confs/app1/deployment.yaml
log INFO "app1: Deployment applied"

log INFO "Deploy: all applications applied"