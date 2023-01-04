#!/bin/bash

echo "Enter the URL to access Prisma Cloud Compute in the format: https://<IP_address>:<port_number>"
read path

echo "Enter the build version number for the Prisma Cloud Compute. Example: v22.12, v22.06, and so on ..."
read version

echo "Setting path variable to access and test APIs"
api_path="$path/api/$version"
api_v1path="$path/api/v1"

echo "Creating an administrative account to access other APIs"
echo "Enter a username for an administrative account"
read admin
echo "Enter a password for the administrative account"
read password

# Signup - Administrator

POST_signup=$(curl -k -H 'Content-Type: application/json' -w "%{http_code}\n" -X POST -d '{"username": "'"$admin"'", "password": "'"$password"'"}' "${api_v1path}/signup")
if [[ $POST_signup == 200 ]]; then
echo "$POST_signup: POST_signup is success at $(date)" >> success_response.txt
else
echo "$POST_signup: POST_signup failed at $(date)" >> failure_response.txt
fi

echo "Setting up the admin user"
api_user="$admin:$password"

# Settings - Add license key for activation

echo "Enter the license key to activate the Prisma Cloud Compute"
read license_key

POST_settings_license=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"key": "'"$license_key"'"}' "${api_v1path}/settings/license")
if [[ $POST_settings_license == 200 ]]; then
echo "$POST_settings_license: POST_settings_license is success at $(date)" >> success_response.txt
else
echo "$POST_settings_license: POST_settings_license failed at $(date)" >> failure_response.txt
fi