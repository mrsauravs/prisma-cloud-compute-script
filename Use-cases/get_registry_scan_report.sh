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

api_user="$admin:$password"

## Settings - Add a registry

echo "Adding registry details."
POST_settings_registry=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"version": "2", "registry": "", "repository": "library/ubuntu", "tag": "16.04", "os": "linux", "cap": 5, "hostname": "", "scanners": 2, "collections": ["All"]}' "${api_path}/settings/registry")
if [[ $POST_settings_registry == 200 ]]; then
echo "$POST_settings_registry: POST_settings_registry is success at $(date)" >> success_response.txt
else
echo "$POST_settings_registry: POST_settings_registry failed at $(date)" >> failure_response.txt
fi

## Settings - Get Registry details

echo "Getting details about registries."
GET_settings_registry=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_settings_registry.json -X GET "${api_path}/settings/registry")
if [[ $GET_settings_registry == 200 ]]; then
echo "$GET_settings_registry: GET_settings_registry is success at $(date)" >> success_response.txt
else
echo "$GET_settings_registry: GET_settings_registry failed at $(date)" >> failure_response.txt
fi

## Settings - Update Registry details

echo "Updating details about registries."
echo "Use details from the GET_settings_registry.json file to add data for this API."
PUT_settings_registry=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"specifications": [{"version": "2", "registry": "", "repository": "library/ubuntu", "tag": "18.04", "os": "linux", "cap": 5, "credentialID": "<CREDENTIAL_ID1>", "scanners": 2, "collections": ["All"]}, {"version": "aws", "registry": "<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com", "os": "linux", "credentialID": "<CREDENTIAL_ID2>", "scanners": 2, "cap": 5, "collections": ["All"]}]}' "${api_path}/settings/registry")
if [[ $PUT_settings_registry == 200 ]]; then
echo "$PUT_settings_registry: PUT_settings_registry is success at $(date)" >> success_response.txt
else
echo "$PUT_settings_registry: PUT_settings_registry failed at $(date)" >> failure_response.txt
fi

## Start a Registry Scan

echo "Initiating an On-demand Registry Scan"
POST_registry_scan=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{“onDemandScan”:true,“tag”:{“repo”:“library/alpine”,“tag” :“3.16”}}' "${api_path}/registry/scan")
if [[ $POST_registry_scan == 200 ]]; then
echo "POST_registry_scan is success at $(date)" >> success_response.txt
else
echo "$POST_registry_scan: POST_registry_scan failed at $(date)" >> failure_response.txt
fi

echo "Initiating a Regular Registry Scan"
POST_registry_scan=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/registry/scan")
if [[ $POST_registry_scan == 200 ]]; then
echo "POST_registry_scan is success at $(date)" >> success_response.txt
else
echo "$POST_registry_scan: POST_registry_scan failed at $(date)" >> failure_response.txt
fi

## View Registry Scan Progress

echo "Viewing a Registry Scan Progress"
GET_registry_scan=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X GET "${api_path}/registry/progress?onDemand=true&repo=library/alpine&tag=3.16")
if [[ $GET_registry_scan == 200 ]]; then
echo "GET_registry_scan is success at $(date)" >> success_response.txt
else
echo "$GET_registry_scan: GET_registry_scan failed at $(date)" >> failure_response.txt
fi

## Get Registry Scan Report
echo "Download Registry Scan Report"
GET_registry_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_registry_download.csv -X GET "${api_path}/registry/download")
if [[ $GET_registry_download == 200 ]]; then
echo "GET_registry_download is success at $(date)" >> success_response.txt
else
echo "$GET_registry_download: GET_registry_download failed at $(date)" >> failure_response.txt
fi