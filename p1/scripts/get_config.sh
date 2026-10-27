#!/bin/bash
set -euo pipefail

echo "[get_config] Fetching the kubeconfig from kkraftS..."

vagrant ssh kkraftS -c 'cat /etc/rancher/k3s/k3s.yaml' > confs/agent.yaml

sed 's|https://127.0.0.1:6443|https://192.168.56.110:6443|' confs/agent.yaml -i

if ! grep -q "https://192.168.56.110:6443" confs/agent.yaml; then
    echo "[get_config] ERROR: server address not replaced in confs/agent.yaml" >&2
    exit 1
fi

echo "[get_config] Kubeconfig written to confs/agent.yaml, server set to https://192.168.56.110:6443"