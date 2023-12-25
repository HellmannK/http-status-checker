#!/bin/bash

# Check if the script is running as root, if not, request root access
if [ "$EUID" -ne 0 ]; then
  echo "Requesting root access..."
  exec sudo "$0" "$@"
fi

# Load the ini file
CONFIG_FILE="watchdog_config.ini"

# Parse the ini file
eval "$(cat $CONFIG_FILE | awk -F'=' '{if (! ($0 ~ /^;/) && $0 ~ /./) print $1}' | awk '/\[/{if (l!="") printf("%s\n",l); l=""; next} {if (l!="") l=l ","; l=l $0} END{if (l!="") printf("%s\n",l)}' | awk -F',' '{printf "["; for(i=1;i<=NF;i++) printf "%s\"%s\" ",$i,$i; printf "]\n"}')"

# Email to notify
EMAIL="your-email@domain.com"

# Loop through each website block
for WEBSITE in "${!URL[@]}"; do
  # Skip the api block
  if [ "$WEBSITE" == "api" ]; then
    continue
  fi

  # Get HTTP status code
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${URL[$WEBSITE]})

  # Check if website is not reachable
  if [ $HTTP_STATUS -ne 200 ]; then
    # Stop and start the VM and send email
    curl -s -X POST -H "Authorization: PVEAPIToken=${API_TOKEN[api]}" -H "Content-Type: application/json" -d '{}' "${API_URL[api]}/nodes/${NODE[$WEBSITE]}/qemu/${VMID[$WEBSITE]}/status/stop"
    sleep 5
    curl -s -X POST -H "Authorization: PVEAPIToken=${API_TOKEN[api]}" -H "Content-Type: application/json" -d '{}' "${API_URL[api]}/nodes/${NODE[$WEBSITE]}/qemu/${VMID[$WEBSITE]}/status/start"
    echo "VM ${VMID[$WEBSITE]} on node ${NODE[$WEBSITE]} has been restarted due to HTTP error $HTTP_STATUS on website ${URL[$WEBSITE]}" | mail -s "VM Restarted" $EMAIL
  fi
done
