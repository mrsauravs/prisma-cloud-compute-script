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

# Get a list of vulnerabilities by package name

GET_stats_vulnerabilities_in_package=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_stats_vulnerabilities_in_package.csv -X GET "${api_path}/stats/vulnerabilities/download?package")
if [[ $GET_stats_vulnerabilities_in_package == 200 ]]; then
echo "$GET_stats_vulnerabilities_in_package: Successfully retrieved list of vulnerabilities in a package at $(date). Refer to the file GET_stats_vulnerabilities_in_package.csv."
else
echo "$GET_stats_vulnerabilities_in_package: Failed to retrieve the list of vulnerabilities in a package at $(date)"
fi
