# list_all_proxmox_guests.sh v1.1

#!/bin/bash
set -euo pipefail


# Query proxmox and save the followings as environment variables:
# API_HOST
# USERNAME
# APITOKENID
# API_SECRET




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

