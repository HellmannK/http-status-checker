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

for ((i=0;i<${#HTTP_CODES[@]};i++)); do
   HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" "${URL[i]}")    
    # Check if HTTP status code is in the list of codes to watch
    for ((j=0;j<${#HTTP_CODES[@]};j++)); do
        if [[ "${HTTP_CODES[j]}" == "$HTTP_STATUS" ]]; then
            # Determine the type of the resource (lxc or qemu)
            if [[ ${LXC[i]} == "YES" ]]; then
                TYPE="lxc"
            elif [[ ${VM[i]} == "YES" ]]; then
                TYPE="qemu"
            else
                echo "Neither LXC nor VM is set to YES for index $i"
                exit 1
            fi

    # Reboot the VM or LXC and send email
    curl -s -X POST -H "Authorization: PVEAPIToken=$API_TOKEN" -H "Content-Type: application/json" -d '{}' "${API_URL}/nodes/${NODE[i]}/${TYPE}/${VMID[i]}/status/reboot"
    # Send Email if machine had http error code
    echo "VM ${VMID[i]} on node ${NODE[i]} has been restarted due to HTTP error $HTTP_STATUS on website ${URL[i]}" | mail -r "$FROM_EMAIL" -s "VM Restarted" "$SENT_TO_EMAIL"  
       fi
    done
done
