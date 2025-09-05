# list_all_proxmox_guests.sh v1.1

#!/bin/bash
set -euo pipefail


# this script queries proxmox for all vms and containers.

# save the followings as environment variables to run this script:
# API_HOST
# USERNAME
# APITOKENID
# API_SECRET

#example for env vars:

#export API_HOST="192.168.1.10"          # Proxmox API server (use FQDN or IP)
#export REALM="pam"                   # e.g., "pve" or your realm
#export USERNAME="root@$REALM"    # e.g., root@pam or user@pve
#export APITOKENID="tokenname"     # e.g., user!mytoken
#export API_SECRET="super-secret-token"      # the token secret




for var in API_HOST USERNAME APITOKENID API_SECRET; do
  if [ -z "${!var:-}" ]; then
    echo "❌ Missing required environment variable: $var"
    exit 1
  fi
done

TOKEN_HEADER="PVEAPIToken=${USERNAME}!${APITOKENID}=${API_SECRET}"

echo "=== Querying nodes from Proxmox cluster ==="
nodes=$(curl -s --insecure -H "Authorization: $TOKEN_HEADER" \
  "https://${API_HOST}:8006/api2/json/nodes" | jq -r '.data[].node')

for node in $nodes; do
  echo "=== Node: $node ==="

  echo "--- QEMU VMs ---"
  qemu_json=$(curl -s --insecure -H "Authorization: $TOKEN_HEADER" \
    "https://${API_HOST}:8006/api2/json/nodes/${node}/qemu")

  echo "Raw qemu response:" 
  echo "$qemu_json" | jq .

  echo "$qemu_json" | jq -r '.data[] | "VMID: \(.vmid) | Name: \(.name) | Status: \(.status)"' || true

  echo "--- LXC containers ---"
  lxc_json=$(curl -s --insecure -H "Authorization: $TOKEN_HEADER" \
    "https://${API_HOST}:8006/api2/json/nodes/${node}/lxc")

  echo "Raw lxc response:" 
  echo "$lxc_json" | jq .

  echo "$lxc_json" | jq -r '.data[] | "CTID: \(.vmid) | Name: \(.name) | Status: \(.status)"' || true

done

