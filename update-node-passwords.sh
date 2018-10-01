#!/usr/bin/env bash

HELP="Usage: $0 [-h]
  Update password for each Node in a MetaKube Cluster.

Parameters:
  -h|--help: Print this help text."

while [[ $# -gt 0 ]]; do
  key="${1}"
  case ${key} in
    -h|--help)
      printf '%s\n' "${HELP}"
      exit 0
      ;;
    *)
      printf 'Unknown paramter: %s\n%s\n' "${1}" "${HELP}"
      exit 1
      ;;
  esac
done

printf 'Will update cluster %s. Press <Ctrl+C> to abort or enter new password: ' "$(kubectl config view -o jsonpath='{.current-context}')"
read -r password

if [ -z "${password}" ]; then
  echo "Empty password. Aborting!"
  exit 1
fi
# escape " and \ characters; then safe escape whole string; then replace ' with
# \x27 (to safely pass through)
password="$(printf "%q" "$(echo ${password} \
    |sed 's/\\/\\\\/g' \
    |sed 's/"/\\"/g')" \
  |sed "s/'/\\x27/g"
)"

# Get node IPs. Only start updating if all IPs could be gathered successfully.
# Try kubelet and fall back to openstack in case of https://github.com/kubernetes/kubernetes/issues/68270
IFS=$'\n' nodes=( "$(kubectl get nodes -o custom-columns=:.metadata.name --no-headers)" )
node_ips=()
for node in ${nodes[@]}; do
  ip="$(kubectl get nodes ${node} -o jsonpath='{.status.addresses[?(@.type=="ExternalIP")].address}')"
  if [ -z ${ip} ]; then
    echo -n "External IP for node ${node} not known to kubelet"
    if [ -z "$(which openstack)" ]; then
      echo " and OpenStack client not installed. Aborting!"
      exit 1
    fi
    if [ -z "${OS_AUTH_URL}" ]; then
      echo " and OpenStack credentials not set. Aborting!"
      exit 1
    fi
    echo ". Falling back to OpenStack."
    ip="$(openstack server show ${node} -c addresses -f value |tr ', ' '\n' |grep -vE '=|^$')"
    if [ -z "${ip}" ]; then
      echo "External IP for node ${node} not found. Aborting!"
      exit 1
    fi
  fi
  node_ips+=("${node};${ip}")
done

for node_ip in ${node_ips[@]}; do
  node="$(cut -d';' -f1 <<< "${node_ip}")"
  ip="$(cut -d';' -f2 <<< "${node_ip}")"

  echo "Updating node ${node} (${ip})"
  # TODO For now we limit ourselfs to ubuntu nodes
  user=ubuntu

  ssh ${user}@${ip} "sudo sed -i 's/^password = .*$/password = \"${password}\"/g' /etc/kubernetes/cloud-config 2>/dev/null"
  ssh ${user}@${ip} "sudo systemctl restart kubelet 2>/dev/null"
  SECONDS=0; TIMEOUT=60
  until ssh ${user}@${ip} sudo systemctl is-active --quiet kubelet 2>/dev/null; do
    if [ ${SECONDS} -ge ${TIMEOUT} ]; then
      echo "Node ${node} not ready after ${TIMEOUT} seconds. Check Node and run script again. Aborting!"
      exit 1
    fi
    sleep 1
  done
done
