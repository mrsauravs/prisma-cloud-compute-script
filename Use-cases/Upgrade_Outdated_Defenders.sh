#!/bin/bash

echo "Enter the URL to access Prisma Cloud Compute in the format: https://<IP_address>:<port_number>"
read path

echo "Enter the build version number for the Prisma Cloud Compute. Example: v22.12, v22.06, and so on ..."
read version

echo "Setting path variable to access and test APIs"
api_path="$path/api/$version"
api_v1path="$path/api/v1"

echo "Enter user name for an administrative account"
read admin
echo "Enter password for the administrative account"
read password

api_user="$admin:$password"

# Get a list of outdated deployed Defenders

echo "Getting a list of outdated Defenders"

GET_outdated_defenders=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_outdated_Defenders.json -X GET "${api_path}/defenders/names?latest=false")
if [[ $GET_outdated_defenders == 200 ]]; then
echo "$GET_outdated_defenders: Successfully retrieved a list of outdated Defenders at $(date).\n Please see the file GET_outdated_Defenders.json to see the list of Defenders." >> Results.txt
else
echo "$GET_ooutdated_defenders: Failed to retrieve a list of outdated Defenders at $(date)" >> Results.txt
fi

# Upgrading the outdated Defenders

echo "Do you wish to upgrade an outdated Defender?"
read answer

while [[ $answer == "Yes" ]] | [[ $answer == "yes"]]
do
    echo "Which Defender you wish to upgrade? Refer to file GET_outdated_Defenders.json for Defender names."
    read defender_name
    POST_defenders_id_upgrade=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/defenders/${defender_name}/upgrade")
    if [[ $POST_defenders_id_upgrade == 200 ]]; 
    then
        echo "$POST_defenders_id_upgrade: Successfully upgraded a Defender at $(date)" >> Results.txt
        continue
    else
    echo "$POST_defenders_id_upgrade: Failed to upgrade a Defender at $(date)" >> Results.txt
    fi
done
exit
echo "Skipped Defender upgradation."