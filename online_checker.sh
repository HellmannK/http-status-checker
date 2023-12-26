#!/bin/bash

# Requirements: mailutils, curl

# Load the config file
CONFIG_FILE="/path/to/credentials.conf"
source $CONFIG_FILE

# Load http-code file
HTTP_FILE="/path/to/http_statuscode.conf"
source $HTTP_FILE

# Email to notify
SENT_TO_EMAIL="your-email@domain.com"
FROM_EMAIL="from@domain.com"

  # Check if HTTP status code is in the list of codes to watch
  if [[ " ${HTTP_CODES[*]} " == *"$HTTP_STATUS"* ]]; then
    # Determine the type of the resource (lxc or qemu)
    if [[ ${LXC[i]} == "YES" ]]; then
        TYPE="lxc"
    elif [[ ${VM[i]} == "YES" ]]; then
        TYPE="qemu"
    else
        echo "Neither LXC nor VM is set to YES for index $i"
        continue
    fi

    # Stop and start the VM or LXC and send email
    curl -s -X POST -H "Authorization: PVEAPIToken=$API_TOKEN" -H "Content-Type: application/json" -d '{}' "${API_URL}/nodes/${NODE[i]}/${TYPE}/${VMID[i]}/status/stop"
    sleep 5
    curl -s -X POST -H "Authorization: PVEAPIToken=$API_TOKEN" -H "Content-Type: application/json" -d '{}' "${API_URL}/nodes/${NODE[i]}/${TYPE}/${VMID[i]}/status/start"
    # Send Email if machine had http error code
    echo "VM ${VMID[i]} on node ${NODE[i]} has been restarted due to HTTP error $HTTP_STATUS on website ${URL[i]}" | mail -r "$FROM_EMAIL" -s "VM Restarted" "$SENT_TO_EMAIL"
  fi
done