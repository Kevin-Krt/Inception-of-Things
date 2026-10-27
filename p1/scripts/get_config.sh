#!/bin/bash
set -euo pipefail

vagrant ssh kkraftS -c 'cat /etc/rancher/k3s/k3s.yaml' > confs/agent.yaml
sed 's|https://127.0.0.1:6443|https://192.168.56.110:6443|' confs/agent.yaml -i