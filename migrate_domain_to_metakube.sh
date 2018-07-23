#!/usr/bin/env bash

POSITIONAL=()
HELP="Usage: $0 [-h] [kubeconfig]
  Migrate MetaKube cluster to new domain.  If not asked to, you don't need to
  use this script.

Parameters:
  -h|--help: Print this help text.
Positional:
  kubeconfig: Path to kubeconfig for the cluster you want to migrate."

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
      printf '%s\n' "${HELP}"
      exit 0
      ;;
    -*)
      printf 'Unknown paramter: %s\n%s\n' "$1" "$HELP"
      exit 1
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done
set -- "${POSITIONAL[@]}"

if [ -n "$1" ]; then
  printf 'Using kubeconfig %s\n' "$1"
  export KUBECONFIG=$1
fi

printf 'Will update cluster %s. Press <Ctrl+C> to abort! Waiting 5 seconds...\n' "$(kubectl config view -o jsonpath='{.current-context}')"
sleep 5

printf 'Upating configmap\n'
kubectl -n kube-public get configmap cluster-info -o yaml \
  | sed 's/k8s.01.syseleven.de/metakube.syseleven.de/g' \
  | kubectl apply -f - 2>/dev/null

for node_name in $(kubectl get nodes -o jsonpath='{ .items[*].metadata.name }'); do
  printf 'Updating Node %s\n' "${node_name}"
  node_ip="$(kubectl get node ${node_name} -o jsonpath='{ .status.addresses[?(@.type=="ExternalIP")].address }')"
  ssh ubuntu@${node_ip} \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
     'sudo sed -i "s/k8s.01.syseleven.de/metakube.syseleven.de/g" /etc/kubernetes/kubelet.conf; \
      sudo systemctl restart kubelet' \
    2>/dev/null
done
