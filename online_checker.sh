#!/bin/bash

# Check if the script is running as root, if not, request root access
if [ "$EUID" -ne 0 ]; then
  echo "Requesting root access..."
  exec sudo "$0" "$@"
fi

# Load the ini file
CONFIG_FILE="watchdog_config.ini"
source $CONFIG_FILE

# Email to notify
EMAIL="your-email@domain.com"

# Loop through each website block
for ((i=1;i<=WEBSITE_COUNT;i++)); do
  # Get HTTP status code
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${URL[i]})

  # Check if website is not reachable
  if [ $HTTP_STATUS -ne 200 ]; then
    # Stop and start the VM and send email
    curl -s -X POST -H "Authorization: PVEAPIToken=$API_TOKEN" -H "Content-Type: application/json" -d '{}' "${API_URL}/nodes/${NODE[i]}/qemu/${VMID[i]}/status/stop"
    sleep 5
    curl -s -X POST -H "Authorization: PVEAPIToken=$API_TOKEN" -H "Content-Type: application/json" -d '{}' "${API_URL}/nodes/${NODE[i]}/qemu/${VMID[i]}/status/start"
    echo "VM ${VMID[i]} on node ${NODE[i]} has been restarted due to HTTP error $HTTP_STATUS on website ${URL[i]}" | mail -s "VM Restarted" $EMAIL
  fi
done
