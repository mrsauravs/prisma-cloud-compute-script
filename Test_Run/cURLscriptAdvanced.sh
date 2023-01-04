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

# Users and Collections

## Users - Create a user

echo "How many users you want to create? For testing purposes, create at least four users."
read count_user

for i in $(seq $count_user); do
    echo "Enter a username"
    read user_name
    echo "Enter a password"
    read user_password
    echo "User role reference: admin (for administrator), ci (for CI User), auditor, user (for Access User), devOps (for DevOps User), devSecOps (for DevSecOps User), defenderManager (for Defender Manager), or vulnerabilityManager (for Vulnerability Manager). For more information, see https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin-compute/authentication/user_roles"
    echo "Enter the user role"
    read user_role
    echo "Enter the authentication type. Example: saml, ldap, basic, oauth, oidc. Use 'basic' in case you want to create a local user managed by Prisma Cloud Compute."
    read auth_type
    POST_users=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"username":"'"$user_name"'", "password":"'"$user_password"'", "role":"'"$user_role"'", "authType":"'"$auth_type"'"}' "${api_path}/users")
    if [[ $POST_users == 200 ]]; then
    echo "$POST_users: POST_users created users successfully at $(date) with permissions to all collections" >> success_response.txt
    else
    echo "$POST_users: POST_users failed at $(date)" >> failure_response.txt
    fi
done

## Users - Get a list of all users

echo "Getting details for all users. Refer to GET_users.json file."

GET_users=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_users.json -X GET "${api_path}/users")
if [[ $GET_users == 200 ]]; then
echo "$GET_users: GET_users is success at $(date)" >> success_response.txt
else
echo "$GET_users: GET_users failed at $(date)" >> failure_response.txt
fi

# Authenticate - Get access token for a user using username and password for authentication

echo "Enter a user name for which you want to download the access token"
read auth_user
echo "Enter the password for this user"
read auth_password

POST_authenticate=$(curl -k -H 'Content-Type: application/json' -w "%{http_code}\n" -o user_access_token.json -X POST -d '{"username": "'"$auth_user"'", "password": "'"$auth_password"'"}' "${api_path}/authenticate")
if [[ $POST_authenticate == 200 ]]; then
echo "$POST_authenticate: POST_authenticate is success at $(date)" >> success_response.txt
else
echo "$POST_authenticate: POST_authenticate failed at $(date)" >> failure_response.txt
fi

echo "Use the user_access_token.json file to view the access token."

echo "On the Prisma Cloud Compute user interface, go to Manage > Authentication > Credentials page, and copy the install command for the client certificate."
echo "On the Prisma Cloud Compute user interface, go to Manage > Authentication > User Certificates."
echo "Download the client certificate in PEM format and name it as 'cert.pem' or use the unsupported /api/v1/certs/client-certs.sh API to download the client certificate."

# Certs - Get Client certificate in PEM format

echo "Testing an unsupported v1 endpoint to download client certificate"
GET_client_certs_pem=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_client_certs.pem -X GET "${api_v1path}/certs/client-certs.sh" | sh)
if [[ $GET_client_certs_pem == 200 ]]; then
echo "$GET_client_certs_pem: GET_client_certs_pem is success at $(date)" >> success_response.txt
else
echo "$GET_client_certs_pem: GET_client_certs_pem failed at $(date)" >> failure_response.txt
fi

# Certs - Get CA certificate in PEM format

GET_certs_ca_pem=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_certs_ca_pem.json -X GET "${api_v1path}/certs/ca.pem")
if [[ $GET_certs_ca_pem == 200 ]]; then
echo "$GET_certs_ca_pem: GET_certs_ca_pem is success at $(date)" >> success_response.txt
else
echo "$GET_certs_ca_pem: GET_certs_ca_pem failed at $(date)" >> failure_response.txt
fi

# Certs - Get all server certificates

GET_certs_server_certs=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_certs_server_certs.json -X GET "${api_v1path}/certs/server-certs.sh")
if [[ $GET_certs_server_certs == 200 ]]; then
echo "$GET_certs_server_certs: GET_certs_server_certs is success at $(date)" >> success_response.txt
else
echo "$GET_certs_server_certs: GET_certs_server_certs failed at $(date)" >> failure_response.txt
fi

# Authenticate-Client - Get access token for a user using a client certificate for authentication

echo "Do you have a client certificate file in PEM format?"
read answer

while [$answer == yes]
do
    echo "Enter the path to the client certificate that you downloaded. Example: ~/Downloads/GET_client_certs.pem"
    read client_cert_path
    POST_authenticate_client=$(curl -k -H 'Content-Type: application/json' -w "%{http_code}\n" -o client_access_token.json -X POST --cert "$client_cert_path" "${api_path}/authenticate-client")
    if [[ $POST_authenticate_client == 200 ]]; then
    echo "$POST_authenticate_client: POST_authenticate_client is success at $(date)" >> success_response.txt
    else
    echo "$POST_authenticate_client: POST_authenticate_client failed at $(date)" >> failure_response.txt
    fi
    echo "Use the client_access_token.json file to view user role and an access token"
done

## Users - Update password for a user

echo "Enter a user name for which you want to update the password"
read user_update_password
echo "Enter the existing password for this user"
read user_update_oldpasphrase
echo "Enter the new password for this user"
read user_update_newpassphrase

users_password="$user_update_password:$user_update_oldpasphrase"

PUT_users_password=$(curl -k -H 'Content-Type: application/json' -u $users_password -w "%{http_code}\n" -X PUT -d '{"oldPassword": "'"$user_update_oldpasphrase"'", "newPassword": "'"$user_update_newpassphrase"'"}' "${api_path}/users/password")
if [[ $PUT_users_password == 200 ]]; then
echo "$PUT_users_password: PUT_users_password is success at $(date)" >> success_response.txt
else
echo "$PUT_users_password: PUT_users_password failed at $(date)" >> failure_response.txt
fi

## Users - Delete a user

echo "Enter a user name to delete"
read user_delete

DELETE_users_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X DELETE "${api_path}/users/$user_delete")
if [[ $DELETE_users_id == 200 ]]; then
echo "$DELETE_users_id: DELETE_users_id is success at $(date)" >> success_response.txt
else
echo "$DELETE_users_id: DELETE_users_id failed at $(date)" >> failure_response.txt
fi

# Coderepos - Add a code respository

POST_coderepos_ci=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/coderepos-ci")
if [[ $POST_coderepos_ci == 200 ]]; then
echo "POST_coderepos_ci is success at $(date)" >> success_response.txt
else
echo "$POST_coderepos_ci: POST_coderepos_ci failed at $(date)" >> failure_response.txt
fi

POST_coderepos_ci_evaluate=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/coderepos-ci/evaluate")
if [[ $POST_coderepos_ci_evaluate == 200 ]]; then
echo "POST_coderepos_ci_evaluate is success at $(date)" >> success_response.txt
else
echo "$POST_coderepos_ci_evaluate: POST_coderepos_ci_evaluate failed at $(date)" >> failure_response.txt
fi

## Collection - Create a collection

echo "How many collections you want to create?"
read count_collection

for i in $(seq $count_collection); do
    echo "Enter a collection name"
    read collection_name
    echo "Enter an image name. Example: ubuntu:18.04"
    read image_name
    POST_collections=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"name":"'"$collection_name"'", "images": ["'"$image_name"'"], "hosts": ["*"], "labels": ["*"], "containers": ["*"], "functions": ["*"], "namespaces": ["*"], "appIDs": ["*"], "accountIDs": ["*"], "codeRepos": ["*"], "clusters": ["*"], "color": "#AD3C21"}' "${api_path}/collections")
    if [[ $POST_collections == 200 ]]; then
    echo "$POST_collections: POST_collections is success at $(date)" >> success_response.txt
    else
    echo "$POST_collections: POST_collections failed at $(date)" >> failure_response.txt
    fi
done

## Collection - Get all collection details

GET_collections=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_collections.json -X GET "${api_path}/collections")
if [[ $GET_collections == 200 ]]; then
echo "$GET_collections: GET_collections is success at $(date)" >> success_response.txt
else
echo "$GET_collections: GET_collections failed at $(date)" >> failure_response.txt
fi

## Users - Update permissions for a user

echo "Enter a username for which you want to change permissions for project and collections"
read user_permissions
echo "Enter the project name to assign it to the user. Note: Make sure that you have enabled projects in the Prisma Cloud Compute."
read project_name
echo "Enter the collection name to assign it to the user. Use the file 'GET_collections.json' for reference."
read collection_name
PUT_users=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"username":"'"$user_permissions"'", "permissions":[{"project":"'"$project_name"'", "collections":["'"$collection_name"'"]}]}' "${api_path}/users")
if [[ $PUT_users == 200 ]]; then
echo "$PUT_users: PUT_users is success at $(date)" >> success_response.txt
else
echo "$PUT_users: PUT_users failed at $(date)" >> failure_response.txt
fi

# Current - Get a list of current collections assigned to a user

GET_current_collections=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_current_collections.json -X GET "${api_path}/current/collections")
if [[ $GET_current_collections == 200 ]]; then
echo "GET_current_collections is success at $(date)" >> success_response.txt
else
echo "$GET_current_collections: GET_current_collections failed at $(date)" >> failure_response.txt
fi

# Current - Get a list of current projects assigned to a user

GET_current_projects=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_current_projects.json -X GET "${api_path}/current/projects")
if [[ $GET_current_projects == 200 ]]; then
echo "GET_current_projects is success at $(date)" >> success_response.txt
else
echo "$GET_current_projects: GET_current_projects failed at $(date)" >> failure_response.txt
fi

# Credentials

GET_credentials=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_credentials.json -X GET "${api_path}/credentials")
if [[ $GET_credentials == 200 ]]; then
echo "$GET_credentials: GET_credentials is success at $(date)" >> success_response.txt
else
echo "$GET_credentials: GET_credentials failed at $(date)" >> failure_response.txt
fi

POST_credentials=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"serviceAccount":{ }, "apiToken":{"encrypted":"ENCRYPTED_TOKEN"}, "type":"TYPE", "_id":"{id}"}' "${api_path}/credentials")
if [[ $POST_credentials == 200 ]]; then
echo "$POST_credentials: POST_credentials is success at $(date)" >> success_response.txt
else
echo "$POST_credentials: POST_credentials failed at $(date)" >> failure_response.txt
fi

DELETE_credentials_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X DELETE "${api_path}/credentials/{id}")
if [[ $DELETE_credentials_id == 200 ]]; then
echo "$DELETE_credentials_id: DELETE_credentials_id is success at $(date)" >> success_response.txt
else
echo "$DELETE_credentials_id: DELETE_credentials_id failed at $(date)" >> failure_response.txt
fi

GET_credentials_id_usages=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_credentials_id_usages.json -X GET "${api_path}/credentials/{id}/usages")
if [[ $GET_credentials_id_usages == 200 ]]; then
echo "$GET_credentials_id_usages: GET_credentials_id_usages is success at $(date)" >> success_response.txt
else
echo "$GET_credentials_id_usages: GET_credentials_id_usages failed at $(date)" >> failure_response.txt
fi

# Settings

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

## Settings - Add serverless scan details

echo "Adding serverless scan details."
POST_settings_serverless_scan=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"provider": "aws", "credential":{}, "credentialID":"IAM Role"}' "${api_path}/settings/serverless-scan")
if [[ $POST_settings_serverless_scan == 200 ]]; then
echo "$POST_settings_serverless_scan: POST_settings_serverless_scan is success at $(date)" >> success_response.txt
else
echo "$POST_settings_serverless_scan: POST_settings_serverless_scan failed at $(date)" >> failure_response.txt
fi

## Settings - Get serverless scan details

echo "Getting serverless scan details."
GET_settings_serverless_scan=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_settings_serverless_scan.json -X GET "${api_path}/settings/serverless-scan")
if [[ $GET_settings_serverless_scan == 200 ]]; then
echo "$GET_settings_serverless_scan: GET_settings_serverless_scan is success at $(date)" >> success_response.txt
else
echo "$GET_settings_serverless_scan: GET_settings_serverless_scan failed at $(date)" >> failure_response.txt
fi

## Settings - Update serverless scan details

echo "Updating serverless scan details."
echo "Use details from the GET_settings_serverless_scan.json to add data to this API."
PUT_settings_serverless_scan=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"provider": "aws", "credential":{}, "credentialID":"IAM Role"}' "${api_path}/settings/serverless-scan")
if [[ $PUT_settings_serverless_scan == 200 ]]; then
echo "$PUT_settings_serverless_scan: PUT_settings_serverless_scan is success at $(date)" >> success_response.txt
else
echo "$PUT_settings_serverless_scan: PUT_settings_serverless_scan failed at $(date)" >> failure_response.txt
fi

## Settings - Add Tanzu Application Server details

echo "Adding Tanzu Application Server details."
POST_settings_tas=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"cap": 5, "cloudControllerAddress": "https://example.com", "hostname": "vm-host", "pattern": "droplet-name"}' "${api_path}/settings/tas")
if [[ $POST_settings_tas == 200 ]]; then
echo "$POST_settings_tas: POST_settings_tas is success at $(date)" >> success_response.txt
else
echo "$POST_settings_tas: POST_settings_tas failed at $(date)" >> failure_response.txt
fi

## Settings - Get Tanzu Application Server details

echo "Getting Tanzu Application Server details"
GET_settings_tas=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_settings_tas.json -X GET "${api_path}/settings/tas")
if [[ $GET_settings_tas == 200 ]]; then
echo "$GET_settings_tas: GET_settings_tas is success at $(date)" >> success_response.txt
else
echo "$GET_settings_tas: GET_settings_tas failed at $(date)" >> failure_response.txt
fi

## Settings - Get Code Repo details

echo "Getting details about code repositories."
GET_settings_coderepos=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_settings_coderepos.json -X GET "${api_path}/settings/coderepos")
if [[ $GET_settings_coderepos == 200 ]]; then
echo "$GET_settings_coderepos: GET_settings_coderepos is success at $(date)" >> success_response.txt
else
echo "$GET_settings_coderepos: GET_settings_coderepos failed at $(date)" >> failure_response.txt
fi

## Settings - Update Code Repo details

echo "Use details from the GET_settings_coderepos.json file to add data for this API."
echo "Updating details for the code repositry."
PUT_settings_coderepos=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"type":"github", "publicOnly":false, "credentialID":"<CREDENTIAL_ID>", "repositories":["*"}' "${api_path}/settings/coderepos")
if [[ $PUT_settings_coderepos == 200 ]]; then
echo "$PUT_settings_coderepos: PUT_settings_coderepos is success at $(date)" >> success_response.txt
else
echo "$PUT_settings_coderepos: PUT_settings_coderepos failed at $(date)" >> failure_response.txt
fi

## Settings - Get Virtual Machine settings

echo "Geting Virtual Machine details."
GET_settings_vm=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_settings_vm.json -X GET "${api_path}/settings/vm")
if [[ $GET_settings_vm == 200 ]]; then
echo "$GET_settings_vm: GET_settings_vm is success at $(date)" >> success_response.txt
else
echo "$GET_settings_vm: GET_settings_vm failed at $(date)" >> failure_response.txt
fi

## Settings - Update Virtual Machine details

echo "Use details from the GET_settings_vm.json file to add data for this API."
echo "Updating details for the virtual machines."
PUT_settings_vm=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"version":"aws", "region":"us-east-1", "credentialID":"IAM Role", "collections":[{"name":"All"}], "cap": 5, "scanners": 1, "consoleAddr":"127.0.0.1"}' "${api_path}/settings/vm")
if [[ $PUT_settings_vm == 200 ]]; then
echo "$PUT_settings_vm: PUT_settings_vm is success at $(date)" >> success_response.txt
else
echo "$PUT_settings_vm: PUT_settings_vm failed at $(date)" >> failure_response.txt
fi

## Settings - Get Custom Label details

echo "Getting custom label details."
GET_settings_custom_labels=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_settings_custom_labels.json -X GET "${api_path}/settings/custom-labels")
if [[ $GET_settings_custom_labels == 200 ]]; then
echo "$GET_settings_custom_labels: GET_settings_custom_labels is success at $(date)" >> success_response.txt
else
echo "$GET_settings_custom_labels: GET_settings_custom_labels failed at $(date)" >> failure_response.txt
fi

## Settings - Get Defender details

echo "Getting Defender details."
GET_settings_defender=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_settings_defender.json -X GET "${api_path}/settings/defender")
if [[ $GET_settings_defender == 200 ]]; then
echo "$GET_settings_defender: GET_settings_defender is success at $(date)" >> success_response.txt
else
echo "$GET_settings_defender: GET_settings_defender failed at $(date)" >> failure_response.txt
fi

## Settings - Get Wildfire details

echo "Getting Widfire details."
GET_settings_wildfire=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_settings_wildfire.json -X GET "${api_path}/settings/wildfire")
if [[ $GET_settings_wildfire == 200 ]]; then
echo "$GET_settings_wildfire: GET_settings_wildfire is success at $(date)" >> success_response.txt
else
echo "$GET_settings_wildfire: GET_settings_wildfire failed at $(date)" >> failure_response.txt
fi

# Agentless
GET_agentless_progress=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_agentless_progress.json -X GET "${api_path}/agentless/progress")
if [[ $GET_agentless_progress == 200 ]]; then 
echo "$GET_agentless_progress: GET_agentless_progress is success at $(date)" >> success_response.txt 
else 
echo "$GET_agentless_progress: GET_agentless_progress failed at $(date)" >> failure_response.txt 
fi

POST_agentless_scan=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/agentless/scan")
if [[ $POST_agentless_scan == 200 ]]; then 
echo "$POST_agentless_scan: POST_agentless_scan is success at $(date)" >> success_response.txt 
else 
echo "$POST_agentless_scan: POST_agentless_scan failed at $(date)" >> failure_response.txt 
fi

POST_agentless_stop=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/agentless/stop")
if [[ $POST_agentless_stop == 200 ]]; then 
echo "$POST_agentless_stop: POST_agentless_stop is success at $(date)" >> success_response.txt 
else 
echo "$POST_agentless_stop: POST_agentless_stop failed at $(date)" >> failure_response.txt 
fi

POST_agentless_templates=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -d '{"credentialID":"aws_docs"}' -X POST "${api_path}/agentless/templates")
if [[ $POST_agentless_templates == 200 ]]; then 
echo "POST_agentless_templates is success at $(date)" >> success_response.txt 
else 
echo "$POST_agentless_templates: POST_agentless_templates failed at $(date)" >> failure_response.txt 
fi

# Audits
GET_audits_access=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_access.json -X GET "${api_path}/audits/access")
if [[ $GET_audits_access == 200 ]]; then 
echo "GET_audits_access is success at $(date)" >> success_response.txt 
else 
echo "$GET_audits_access: GET_audits_access failed at $(date)" >> failure_response.txt 
fi

GET_audits_access_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_access_download.csv -X GET "${api_path}/audits/access/download")
if [[ $GET_audits_access_download == 200 ]]; then 
echo "GET_audits_access_download is success at $(date)" >> success_response.txt 
else 
echo "$GET_audits_access_download: GET_audits_access_download failed at $(date)" >> failure_response.txt 
fi

GET_audits_incidents=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_incidents.json -X GET "${api_path}/audits/incidents")
if [[ $GET_audits_incidents == 200 ]]; then 
echo "GET_audits_incidents is success at $(date)" >> success_response.txt 
else 
echo "$GET_audits_incidents: GET_audits_incidents failed  at $(date)" >> failure_response.txt 
fi

PATCH_audits_incidents_acknowledge_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -d '{"acknowledged":true}' -X PATCH "${api_path}/audits/incidents/acknowledge/{id}")
if [[ $PATCH_audits_incidents_acknowledge_id == 200 ]]; then 
echo "PATCH_audits_incidents_acknowledge_id is success at $(date)" >> success_response.txt 
else  
echo "$PATCH_audits_incidents_acknowledge_id: PATCH_audits_incidents_acknowledge_{id} failed at $(date)" >> failure_response.txt
fi

GET_audits_incidents_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_incidents_download.csv -X GET "${api_path}/audits/incidents/download")
if [[ $GET_audits_incidents_download == 200 ]]; then 
echo "GET_audits_incidents_download is success at $(date)" >> success_response.txt 
else 
echo " $GET_audits_incidents_download: GET_audits_incidents_download failed at $(date)" >> failure_response.txt 
fi

GET_audits_admission=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_admission.json -X GET "${api_path}/audits/admission")
if [[ $GET_audits_admission == 200 ]]; then 
echo "GET_audits_admission is success at $(date)" >> success_response.txt 
else 
echo " $GET_audits_admission + GET_audits_admission failed  at $(date)" >> failure_response.txt
fi

GET_audits_admission_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_admission_download -X GET "${api_path}/audits/admission/download")
if [[ $GET_audits_admission_download == 200 ]]; then 
echo "GET_audits_admission_download is success at $(date)" >> success_response.txt 
else 
echo "$GET_audits_admission_download + GET_audits_admission_download failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_agentless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_agentless.json -X GET "${api_path}/audits/firewall/app/agentless")
if [[ $GET_audits_firewall_app_agentless == 200 ]]; then 
echo "GET_audits_firewall_app_agentless is success at $(date)" >> success_response.txt 
else 
echo "$GET_audits_firewall_app_agentless + GET_audits_firewall_app_agentless failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_agentless_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_agentless_download.csv -X GET "${api_path}/audits/firewall/app/agentless/download")
if [[ $GET_audits_firewall_app_agentless_download == 200 ]]; then 
echo "GET_audits_firewall_app_agentless_download is success at $(date)" >> success_response.txt 
else 
echo "$GET_audits_firewall_app_agentless_download: GET_audits_firewall_app_agentless_download failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_agentless_timeslice=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_agentless_timeslice.json -X GET "${api_path}/audits/firewall/app/agentless/timeslice")
if [[ $GET_audits_firewall_app_agentless_timeslice == 200 ]]; then 
echo "GET_audits_firewall_app_agentless_timeslice is success at $(date)" >> success_response.txt 
else 
echo " $GET_audits_firewall_app_agentless_timeslice: GET_audits_firewall_app_agentless_timeslice failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_app_embedded=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_app_embedded.json -X GET "${api_path}/audits/firewall/app/app-embedded")
if [[ $GET_audits_firewall_app_app_embedded == 200 ]]; then 
echo "GET_audits_firewall_app_app_embedded is success at $(date)" >> success_response.txt 
else 
echo "$GET_audits_firewall_app_app_embedded: GET_audits_firewall_app_app_embedded failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_app_embedded_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_app-embedded_download.csv -X GET "${api_path}/audits/firewall/app/app-embedded/download")
if [[ $GET_audits_firewall_app_app_embedded_download == 200 ]]; then 
echo "GET_audits_firewall_app_app_embedded_download is success at $(date)" >> success_response.txt 
else 
echo "$GET_audits_firewall_app_app_embedded_download: GET_audits_firewall_app_app-embedded_download failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_app_embedded_timeslice=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_app-embedded_timeslice.json -X GET "${api_path}/audits/firewall/app/app-embedded/timeslice")
if [[ $GET_audits_firewall_app_app_embedded_timeslice == 200 ]]; then 
echo "GET_audits_firewall_app_app_embedded_timeslice is success at $(date)" >> success_response.txt 
else
echo "$GET_audits_firewall_app_app_embedded_timeslice: GET_audits_firewall_app_app-embedded_timeslice failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_container=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_container.json -X GET "${api_path}/audits/firewall/app/container")
if [[ $GET_audits_firewall_app_container == 200 ]]; then 
echo "GET_audits_firewall_app_container is success at $(date)" >> success_response.txt 
else 
echo "$GET_audits_firewall_app_container: GET_audits_firewall_app_container failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_container_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_container_download.csv -X GET "${api_path}/audits/firewall/app/container/download")
if [[ $GET_audits_firewall_app_container_download == 200 ]]; then 
echo "GET_audits_firewall_app_container_download is success at $(date)" >> success_response.txt 
else
echo "$GET_audits_firewall_app_container_download: GET_audits_firewall_app_container_download failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_container_timeslice=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_container_timeslice.json -X GET "${api_path}/audits/firewall/app/container/timeslice")
if [[ $GET_audits_firewall_app_container_timeslice == 200 ]]; then 
echo "GET_audits_firewall_app_container_timeslice is success at $(date)" >> success_response.txt 
else
echo "$GET_audits_firewall_app_container_timeslice: GET_audits_firewall_app_container_timeslice failed at $(date)" >> failure_response.txt
fi

GET_audits_kubernetes=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_kubernetes.json -X GET "${api_path}/audits/kubernetes")
if [[ $GET_audits_kubernetes == 200 ]]; then 
echo "GET_audits_kubernetes is success at $(date)" >> success_response.txt 
else
echo "$GET_audits_kubernetes: GET_audits_kubernetes failed at $(date)" >> failure_response.txt
fi

GET_audits_kubernetes_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_kubernetes_download.csv -X GET "${api_path}/audits/kubernetes/download")
if [[ $GET_audits_kubernetes_download == 200 ]]; then 
echo "GET_audits_kubernetes_download is success at $(date)" >> success_response.txt 
else
echo "$GET_audits_kubernetes_download: GET_audits_kubernetes_download failed at $(date)" >> failure_response.txt
fi

GET_audits_mgmt=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_mgmt.json -X GET "${api_path}/audits/mgmt")
if [[ $GET_audits_mgmt == 200 ]]; then 
echo "GET_audits_mgmt is success at $(date)" >> success_response.txt 
else
echo "$GET_audits_mgmt: GET_audits_mgmt failed at $(date)" >> failure_response.txt
fi

GET_audits_mgmt_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_mgmt_download.csv -X GET "${api_path}/audits/mgmt/download")
if [[ $GET_audits_mgmt_download == 200 ]]; then 
echo "GET_audits_mgmt_download is success at $(date)" >> success_response.txt 
else
echo "$GET_audits_mgmt_download: GET_audits_mgmt_download failed at $(date)" >> failure_response.txt
fi

GET_audits_mgmt_filters=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_mgmt_filters.json -X GET "${api_path}/audits/mgmt/filters")
if [[ $GET_audits_mgmt_filters == 200 ]]; then 
echo "GET_audits_mgmt_filters is success at $(date)" >> success_response.txt 
else
echo "$GET_audits_mgmt_filters: GET_audits_mgmt_filters failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_app_embedded=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_app-embedded.json -X GET "${api_path}/audits/runtime/app-embedded")
if [[ $GET_audits_runtime_app_embedded == 200 ]]; then 
echo "GET_audits_runtime_app_embedded is success at $(date)" >> success_response.txt 
else
echo "$GET_audits_runtime_app_embedded: GET_audits_runtime_app_embedded failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_app_embedded_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_app-embedded_download.csv -X GET "${api_path}/audits/runtime/app-embedded/download")
if [[ $GET_audits_runtime_app_embedded_download == 200 ]]; then 
echo "GET_audits_runtime_app_embedded_download is success at $(date)" >> success_response.txt 
else
echo "$GET_audits_runtime_app_embedded_download: GET_audits_runtime_app_embedded_download failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_container=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_container.json -X GET "${api_path}/audits/runtime/container")
if [[ $GET_audits_runtime_container == 200 ]]; then 
echo "GET_audits_runtime_container is success at $(date)" >> success_response.txt 
else
echo "$GET_audits_runtime_container: GET_audits_runtime_container failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_container_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_container_download.csv -X GET "${api_path}/audits/runtime/container/download")
if [[ $GET_audits_runtime_container_download == 200 ]]; then
echo "GET_audits_runtime_container_download is success at $(date)" >> success_response.txt 
else
echo "$GET_audits_runtime_container_download: GET_audits_runtime_container_download failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_container_timeslice=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_container_timeslice.json -X GET "${api_path}/audits/runtime/container/timeslice")
if [[ $GET_audits_runtime_container_timeslice == 200 ]]; then
echo "GET_audits_runtime_container_timeslice is success at $(date)" >> success_response.txt
else
echo "$GET_audits_runtime_container_timeslice: GET_audits_runtime_container_timeslice failed at $(date)" >> failure_response.txt
fi

GET_audits_trust=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_trust.json -X GET "${api_path}/audits/trust")
if [[ $GET_audits_trust == 200 ]]; then
echo "GET_audits_trust is success at $(date)" >> success_response.txt
else
echo "$GET_audits_trust: GET_audits_trust failed at $(date)" >> failure_response.txt
fi

GET_audits_trust_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_trust_download -X GET "${api_path}/audits/trust/download")
if [[ $GET_audits_trust_download == 200 ]]; then
echo "GET_audits_trust_download is success at $(date)" >> success_response.txt
else echo "$GET_audits_trust_download: GET_audits_trust_download failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_host=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_host.json -X GET "${api_path}/audits/firewall/app/host")
if [[ $GET_audits_firewall_app_host == 200 ]]; then
echo "GET_audits_firewall_app_host is success at $(date)" >> success_response.txt
else
echo "$GET_audits_firewall_app_host: GET_audits_firewall_app_host failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_host_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_host_download.csv -X GET "${api_path}/audits/firewall/app/host/download")
if [[ $GET_audits_firewall_app_host_download == 200 ]]; then
echo "GET_audits_firewall_app_host_download is success at $(date)" >> success_response.txt
else
echo "$GET_audits_firewall_app_host_download: GET_audits_firewall_app_host_download failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_host_timeslice=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_host_timeslice.json -X GET "${api_path}/audits/firewall/app/host/timeslice")
if [[ $GET_audits_firewall_app_host_timeslice == 200 ]]; then
echo "GET_audits_firewall_app_host_timeslice is success at $(date)" >> success_response.txt
else
echo "$GET_audits_firewall_app_host_timeslice: GET_audits_firewall_app_host_timeslice failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_file_integrity=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_file-integrity.json -X GET "${api_path}/audits/runtime/file-integrity")
if [[ $GET_audits_runtime_file_integrity == 200 ]]; then
echo "GET_audits_runtime_file_integrity is success at $(date)" >> success_response.txt 
else
echo "$GET_audits_runtime_file_integrity: GET_audits_runtime_file_integrity failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_file_integrity_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_file-integrity_download.csv -X GET "${api_path}/audits/runtime/file-integrity/download")
if [[ $GET_audits_runtime_file_integrity_download == 200 ]]; then
echo "GET_audits_runtime_file_integrity_download is success at $(date)" >> success_response.txt
else
echo "$GET_audits_runtime_file_integrity_download: GET_audits_runtime_file_integrity_download failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_host=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_host.json -X GET "${api_path}/audits/runtime/host")
if [[ $GET_audits_runtime_host == 200 ]]; then
echo "GET_audits_runtime_host is success at $(date)" >> success_response.txt
else
echo "$GET_audits_runtime_host: GET_audits_runtime_host failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_host_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_host_download.csv -X GET "${api_path}/audits/runtime/host/download")
if [[ $GET_audits_runtime_host_download == 200 ]]; then
echo "GET_audits_runtime_host_download is success at $(date)" >> success_response.txt
else
echo "$GET_audits_runtime_host_download: GET_audits_runtime_host_download failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_host_timeslice=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_host_timeslice.json -X GET "${api_path}/audits/runtime/host/timeslice")
if [[ $GET_audits_runtime_host_timeslice == 200 ]]; then
echo "GET_audits_runtime_host_timeslice is success at $(date)" >> success_response.txt
else
echo "$GET_audits_runtime_host_timeslice: GET_audits_runtime_host_timeslice failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_log_inspection=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_log-inspection.json -X GET "${api_path}/audits/runtime/log-inspection")
if [[ $GET_audits_runtime_log_inspection == 200 ]]; then
echo "GET_audits_runtime_log_inspection is success at $(date)" >> success_response.txt
else
echo " $GET_audits_runtime_log_inspection: GET_audits_runtime_log_inspection failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_log_inspection_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_log-inspection_download.csv -X GET "${api_path}/audits/runtime/log-inspection/download")
if [[ $GET_audits_runtime_log_inspection_download == 200 ]]; then
echo "GET_audits_runtime_log_inspection_download is success at $(date)" >> success_response.txt
else
echo "$GET_audits_runtime_log_inspection_download: GET_audits_runtime_log_inspection_download failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_serverless.json -X GET "${api_path}/audits/firewall/app/serverless")
if [[ $GET_audits_firewall_app_serverless == 200 ]]; then
echo "GET_audits_firewall_app_serverless is success at $(date)" >> success_response.txt
else
echo "$GET_audits_firewall_app_serverless: GET_audits_firewall_app_serverless failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_serverless_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_serverless_download.csv -X GET "${api_path}/audits/firewall/app/serverless/download")
if [[ $GET_audits_firewall_app_serverless_download == 200 ]]; then
echo "GET_audits_firewall_app_serverless_download is success at $(date)" >> success_response.txt
else
echo "$GET_audits_firewall_app_serverless_download: GET_audits_firewall_app_serverless_download failed at $(date)" >> failure_response.txt
fi

GET_audits_firewall_app_serverless_timeslice=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_firewall_app_serverless_timeslice.json -X GET "${api_path}/audits/firewall/app/serverless/timeslice")
if [[ $GET_audits_firewall_app_serverless_timeslice == 200 ]]; then
echo "GET_audits_firewall_app_serverless_timeslice is success at $(date)" >> success_response.txt
else
echo "$GET_audits_firewall_app_serverless_timeslice: GET_audits_firewall_app_serverless_timeslice failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_serverless.json -X GET "${api_path}/audits/runtime/serverless")
if [[ $GET_audits_runtime_serverless == 200 ]]; then
echo "GET_audits_runtime_serverless is success at $(date)" >> success_response.txt
else
echo "$GET_audits_runtime_serverless: GET_audits_runtime_serverless failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_serverless_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_serverless_download.csv -X GET "${api_path}/audits/runtime/serverless/download")
if [[ $GET_audits_runtime_serverless_download == 200 ]]; then
echo "GET_audits_runtime_serverless_download is success at $(date)" >> success_response.txt
else
echo "$GET_audits_runtime_serverless_download: GET_audits_runtime_serverless_download failed at $(date)" >> failure_response.txt
fi

GET_audits_runtime_serverless_timeslice=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_audits_runtime_serverless_timeslice.json -X GET "${api_path}/audits/runtime/serverless/timeslice")
if [[ $GET_audits_runtime_serverless_timeslice == 200 ]]; then
echo "GET_audits_runtime_serverless_timeslice is success at $(date)" >> success_response.txt
else
echo "$GET_audits_runtime_serverless_timeslice: GET_audits_runtime_serverless_timeslice failed at $(date)" >> failure_response.txt
fi


# Authenticate

GET_authenticate_identity_redirect_url=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_authenticate_identity-redirect-url.json -X GET "${api_path}/authenticate/identity-redirect-url")
if [[ $GET_authenticate_identity_redirect_url == 200 ]]; then
echo "GET_authenticate_identity_redirect_url is success at $(date)" >> success_response.txt
else
echo "$GET_authenticate_identity_redirect_url: GET_authenticate_identity_redirect_url failed at $(date)" >> failure_response.txt
fi

# Cloud
GET_cloud_discovery=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_cloud_discovery.json -X GET "${api_path}/cloud/discovery")
if [[ $GET_cloud_discovery == 200 ]]; then
echo "GET_cloud_discovery is success at $(date)" >> success_response.txt
else 
echo "$GET_cloud_discovery: GET_cloud_discovery failed at $(date)" >> failure_response.txt
fi

GET_cloud_discovery_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_cloud_discovery_download.csv -X GET "${api_path}/cloud/discovery/download")
if [[ $GET_cloud_discovery_download == 200 ]]; then
echo "GET_cloud_discovery_download is success at $(date)" >> success_response.txt
else
echo "$GET_cloud_discovery_download: GET_cloud_discovery_download failed at $(date)" >> failure_response.txt
fi

POST_cloud_discovery_scan=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/cloud/discovery/scan")
if [[ $POST_cloud_discovery_scan == 200 ]]; then
echo "POST_cloud_discovery_scan is success at $(date)" >> success_response.txt
else
echo "$POST_cloud_discovery_scan: POST_cloud_discovery_scan failed at $(date)" >> failure_response.txt
fi

POST_cloud_discovery_stop=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/cloud/discovery/stop")
if [[ $POST_cloud_discovery_stop == 200 ]]; then
echo "POST_cloud_discovery_stop is success at $(date)" >> success_response.txt
else 
echo "$POST_cloud_discovery_stop: POST_cloud_discovery_stop failed at $(date)" >> failure_response.txt
fi

GET_cloud_discovery_vms=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_cloud_discovery_vms.json -X GET "${api_path}/cloud/discovery/vms")
if [[ $GET_cloud_discovery_vms == 200 ]]; then
echo "GET_cloud_discovery_vms is success at $(date)" >> success_response.txt
else echo "$GET_cloud_discovery_vms: GET_cloud_discovery_vms failed at $(date)" >> failure_response.txt
fi

# Collections

PUT_collections_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"hosts": ["*"], "images": ["ubuntu:18.04"], "labels": ["*"], "containers": ["*"], "functions": ["*"], "namespaces": ["*"], "appIDs": ["*"], "accountIDs": ["*"], "codeRepos": ["*"], "clusters": ["*"], "name": "my-collection", "owner": "<OWNER_NAME>", "modified": "2021-0101T21:04:30.417Z", "color": "#AD3C21", "system": "false"}' "${api_path}/collections/{id}")
if [[ $PUT_collections_id == 200 ]]; then
echo "PUT_collections_id is success at $(date)" >> success_response.txt
else
echo "$PUT_collections_id: PUT_collections_id failed at $(date)" >> failure_response.txt
fi

DELETE_collections_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X DELETE "${api_path}/collections/{id}")
if [[ $DELETE_collections_id == 200 ]]; then
echo "DELETE_collections_id is success at $(date)" >> success_response.txt
else
echo "$DELETE_collections_id: DELETE_collections_id failed at $(date)" >> failure_response.txt
fi

GET_collections_id_usages=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_collections_id_usages.json -X GET "${api_path}/collections/{id}/usages")
if [[ $GET_collections_id_usages == 200 ]]; then
echo "GET_collections_id_usages is success at $(date)" >> success_response.txt
else echo "$GET_collections_id_usages: GET_collections_id_usages failed at $(date)" >> failure_response.txt
fi

# Containers
GET_containers=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_containers.json -X GET "${api_path}/containers")
if [[ $GET_containers == 200 ]]; then
echo "GET_containers is success at $(date)" >> success_response.txt
else
echo "$GET_containers: GET_containers failed at $(date)" >> failure_response.txt
fi

GET_containers_count=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_containers_count.json -X GET "${api_path}/containers/count")
if [[ $GET_containers_count == 200 ]]; then
echo "GET_containers_count is success at $(date)" >> success_response.txt
else
echo "$GET_containers_count: GET_containers_count failed at $(date)" >> failure_response.txt
fi

GET_containers_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_containers_download.csv -X GET "${api_path}/containers/download")
if [[ $GET_containers_download == 200 ]]; then
echo "GET_containers_download is success at $(date)" >> success_response.txt
else
echo "$GET_containers_download: GET_containers_download failed at $(date)" >> failure_response.txt
fi

GET_containers_names=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_containers_names.json -X GET "${api_path}/containers/names")
if [[ $GET_containers_names == 200 ]]; then
echo "GET_containers_names is success at $(date)" >> success_response.txt
else
echo "$GET_containers_names: GET_containers_names failed at $(date)" >> failure_response.txt
fi

POST_containers_scan=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/containers/scan")
if [[ $POST_containers_scan == 200 ]]; then
echo "POST_containers_scan is success at $(date)" >> success_response.txt
else
echo "$POST_containers_scan: POST_containers_scan failed at $(date)" >> failure_response.txt
fi

# Custom-Compliance
GET_custom_compliance=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_custom_compliance.json -X GET "${api_path}/custom-compliance")
if [[ $GET_custom_compliance == 200 ]]; then
echo "GET_custom_compliance is success at $(date)" >> success_response.txt
else
echo "$GET_custom_compliance: GET_custom_compliance failed at $(date)" >> failure_response.txt
fi

PUT_custom_compliance=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '@custom_check.json' "${api_path}/custom-compliance")
if [[ $PUT_custom_compliance == 200 ]]; then
echo "PUT_custom_compliance is success at $(date)" >> success_response.txt
else
echo "$PUT_custom_compliance: PUT_custom_compliance failed at $(date)" >> failure_response.txt
fi

DELETE_custom_compliance_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X DELETE  "${api_path}/custom-compliance/{id}")
if [[ $DELETE_custom_compliance_id == 200 ]]; then
echo "DELETE_custom-compliance_id is success at $(date)" >> success_response.txt
else
echo "$DELETE_custom_compliance_id: DELETE_custom-compliance_id failed at $(date)" >> failure_response.txt
fi

# Custom-Rules
GET_custom_rules=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_custom-rules.json -X GET "${api_path}/custom-rules")
if [[ $GET_custom_rules == 200 ]]; then
echo "GET_custom_rules is success at $(date)" >> success_response.txt
else
echo "$GET_custom_rules: GET_custom-rules failed at $(date)" >> failure_response.txt
fi

DELETE_custom_rules_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X DELETE  "${api_path}/custom-rules/{id}")
if [[ $DELETE_custom_rules_id == 200 ]]; then
echo "DELETE_custom_rules_id is success at $(date)" >> success_response.txt
else
echo "$DELETE_custom_rules_id: DELETE_custom_rules_id failed at $(date)" >> failure_response.txt
fi

PUT_custom_rules_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"_id":{id}, "type": "processes", "message": "unexpected %proc.name was spawned", "name": "<CUSTOM_RULE_NAME>", "script": "proc.interactive"}' "${api_path}/custom-rules/{id}")
if [[ $PUT_custom_rules_id == 200 ]]; then
echo "PUT_custom_rules_id is success at $(date)" >> success_response.txt
else
echo "$PUT_custom_rules_id: PUT_custom_rules_id failed at $(date)" >> failure_response.txt
fi

# Defenders
GET_defenders=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_defenders.json -X GET "${api_path}/defenders")
if [[ $GET_defenders == 200 ]]; then
echo "GET_defenders is success at $(date)" >> success_response.txt
else
echo "$GET_defenders: GET_defenders failed at $(date)" >> failure_response.txt
fi

POST_defenders_app_embedded=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o POST_defenders_app-embedded.zip -X POST -d '{"appID": "my-app", "consoleAddr": "https://localhost:8083", "dataFolder": "/var/lib/docker/containers/twistlock/tmp", "dockerfile": "/var/lib/docker/overlay2/183e9e3ec933ba2363bcf6066b7605d99bfcf4dce84f72eeeba0f616c679cf48"}' "${api_path}/defenders/app-embedded")
if [[ $POST_defenders_app_embedded == 200 ]]; then
echo "POST_defenders_app_embedded is success at $(date)" >> success_response.txt
else
echo "$POST_defenders_app_embedded: POST_defenders_app_embedded failed at $(date)" >> failure_response.txt
fi

POST_defenders_daemonset=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o POST_defenders_daemonset.yaml -X POST -d '{"orchestration": "container", "consoleAddr": "servo-vmware71", "namespace": "twistlock"}' "${api_path}/defenders/daemonset.yaml")
if [[ $POST_defenders_daemonset == 200 ]]; then
echo "POST_defenders_daemonset is success at $(date)" >> success_response.txt
else
echo "$POST_defenders_daemonset: POST_defenders_daemonset failed at $(date)" >> failure_response.txt
fi

GET_defenders_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_defenders_download.csv -X GET "${api_path}/defenders/download")
if [[ $GET_defenders_download == 200 ]]; then
echo "GET_defenders_download is success at $(date)" >> success_response.txt
else
echo "$GET_defenders_download: GET_defenders_download failed at $(date)" >> failure_response.txt
fi

POST_defenders_fargate_json=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o POST_defenders_fargate_protected.json -X POST -d '@POST_defenders_fargate_protected_unprotected.json' "${api_path}/defenders/fargate.json")
if [[ $POST_defenders_fargate_json == 200 ]]; then
echo "POST_defenders_fargate_json is success at $(date)" >> success_response.txt
else
echo "$POST_defenders_fargate_json: POST_defenders_fargate_json failed at $(date)" >> failure_response.txt
fi

POST_defenders_fargate_yaml=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o POST_defenders_fargate_protected.yaml -X POST -d '@POST_defenders_fargate_unprotected.yaml' "${api_path}/defenders/fargate.yaml")
if [[ $POST_defenders_fargate_yaml == 200 ]]; then
echo "POST_defenders_fargate_yaml is success at $(date)" >> success_response.txt
else
echo "$POST_defenders_fargate_yaml: POST_defenders_fargate_yaml failed at $(date)" >> failure_response.txt
fi

POST_defenders_helm_twistlock_defender_helm=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o POST_defenders_helm_twistlock_defender_helm.tar.gz -X POST -d '{"orchestration": "container", "consoleAddr": "servo-vmware71", "namespace": "twistlock"}' "${api_path}/defenders/helm/twistlock-defender-helm.tar.gz")
if [[ $POST_defenders_helm_twistlock_defender_helm == 200 ]]; then
echo "POST_defenders_helm_twistlock_defender_helm is success at $(date)" >> success_response.txt
else
echo "$POST_defenders_helm_twistlock_defender_helm: POST_defenders_helm_twistlock_defender_helm failed at $(date)" >> failure_response.txt
fi

GET_defenders_image_name=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_defenders_image_name.json -X GET "${api_path}/defenders/image-name")
if [[ $GET_defenders_image_name == 200 ]]; then
echo "GET_defenders_image_name is success at $(date)" >> success_response.txt
else
echo "$GET_defenders_image_name: GET_defenders_image_name failed at $(date)" >> failure_response.txt
fi

GET_defenders_install_bundle=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_defenders_install_bundle.json -X GET "${api_path}/defenders/install-bundle")
if [[ $GET_defenders_install_bundle == 200 ]]; then
echo "GET_defenders_install_bundle is success at $(date)" >> success_response.txt
else
echo "$GET_defenders_install_bundle: GET_defenders_install_bundle failed at $(date)" >> failure_response.txt
fi

GET_defenders_names=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_defenders_names.json -X GET "${api_path}/defenders/names")
if [[ $GET_defenders_names == 200 ]]; then
echo "GET_defenders_names is success at $(date)" >> success_response.txt
else
echo "$GET_defenders_names: GET_defenders_names failed at $(date)" >> failure_response.txt
fi

POST_defenders_serverless_bundle=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o POST_defenders_serverless_bundle.zip -X POST -d '{"provider": ["aws"], "runtime": ["nodejs14.x"]}' "${api_path}/defenders/serverless/bundle")
if [[ $POST_defenders_serverless_bundle == 200 ]]; then
echo "POST_defenders_serverless_bundle is success at $(date)" >> success_response.txt
else
echo "$POST_defenders_serverless_bundle: POST_defenders_serverless_bundle failed at $(date)" >> failure_response.txt
fi

GET_defenders_summary=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_defenders_summary.json -X GET  "${api_path}/defenders/summary")
if [[ $GET_defenders_summary == 200 ]]; then
echo "GET_defenders_summary is success at $(date)" >> success_response.txt
else
echo "$GET_defenders_summary: GET_defenders_summary failed at $(date)" >> failure_response.txt
fi

POST_defenders_upgrade=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/defenders/upgrade")
if [[ $POST_defenders_upgrade == 200 ]]; then
echo "POST_defenders_upgrade is success at $(date)" >> success_response.txt
else
echo "$POST_defenders_upgrade: POST_defenders_upgrade failed at $(date)" >> failure_response.txt
fi

DELETE_defenders_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X DELETE "${api_path}/defenders/{id}")
if [[ $DELETE_defenders_id == 200 ]]; then
echo "DELETE_defenders_id is success at $(date)" >> success_response.txt
else
echo "$DELETE_defenders_id: DELETE_defenders_id failed at $(date)" >> failure_response.txt
fi

POST_defenders_id_features=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"proxyListenerType": "tcp", "registryScanner":"<true|false>", "serverlessScanner":"<true|false>"}' "${api_path}/defenders/{id}/features")
if [[ $POST_defenders_id_features == 200 ]]; then
echo "POST_defenders_id_features is success at $(date)" >> success_response.txt
else
echo "$POST_defenders_id_features: POST_defenders_id_features failed at $(date)" >> failure_response.txt
fi

POST_defenders_id_restart=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/defenders/{id}/restart")
if [[ $POST_defenders_id_restart == 200 ]]; then
echo "POST_defenders_id_restart is success at $(date)" >> success_response.txt
else
echo "$POST_defenders_id_restart: POST_defenders_id_restart failed at $(date)" >> failure_response.txt
fi

POST_defenders_id_upgrade=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/defenders/{id}/upgrade")
if [[ $POST_defenders_id_upgrade == 200 ]]; then
echo "POST_defenders_id_upgrade is success at $(date)" >> success_response.txt
else
echo "$POST_defenders_id_upgrade: POST_defenders_id_upgrade failed at $(date)" >> failure_response.txt
fi

# Groups
GET_groups=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_groups.json -X GET "${api_path}/groups")
if [[ $GET_groups == 200 ]]; then
echo "GET_groups is success at $(date)" >> success_response.txt
else
echo "$GET_groups: GET_groups failed at $(date)" >> failure_response.txt
fi

POST_groups=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"groupName": "my-group", "user": [{"username": "john"}, {"username": "jane"}]}' "${api_path}/groups")
if [[ $POST_groups == 200 ]]; then
echo "POST_groups is success at $(date)" >> success_response.txt
else
echo "$POST_groups: POST_groups failed at $(date)" >> failure_response.txt
fi

GET_groups_names=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_groups_names.json -X GET "${api_path}/groups/names")
if [[ $GET_groups_names == 200 ]]; then
echo "GET_groups_names is success at $(date)" >> success_response.txt
else
echo "$GET_groups_names: GET_groups_names failed at $(date)" >> failure_response.txt
fi

DELETE_groups_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X DELETE "${api_path}/groups/{id}")
if [[  $DELETE_groups_id == 200 ]]; then
echo "DELETE_groups_id is success at $(date)" >> success_response.txt
else
echo "$DELETE_groups_id: DELETE_groups_id failed at $(date)" >> failure_response.txt
fi

PUT_groups_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"groupName": "my-group", "user": [{"username": "john"}, {"username": "jane"}], "lastModified":"2021-03-11T23:32:51.336Z"}' "${api_path}/groups/{id}")
if [[ $PUT_groups_id == 200 ]]; then
echo "PUT_groups_id is success at $(date)" >> success_response.txt
else
echo "$PUT_groups_id: PUT_groups_id failed at $(date)" >> failure_response.txt
fi

# Hosts
GET_hosts=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_hosts.json -X GET "${api_path}/hosts")
if [[ $GET_hosts == 200 ]]; then
echo "GET_hosts is success at $(date)" >> success_response.txt
else
echo "$GET_hosts: GET_hosts failed at $(date)" >> failure_response.txt
fi

GET_hosts_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_hosts_download.csv -X GET "${api_path}/hosts/download")
if [[ $GET_hosts_download == 200 ]]; then
echo "GET_hosts_download is success at $(date)" >> success_response.txt
else
echo "$GET_hosts_download: GET_hosts_download failed at $(date)" >> failure_response.txt
fi

POST_hosts_evaluate=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/hosts/evaluate")
if [[ $POST_hosts_evaluate == 200 ]]; then
echo "POST_hosts_evaluate is success at $(date)" >> success_response.txt
else
echo "$POST_hosts_evaluate: POST_hosts_evaluate failed at $(date)" >> failure_response.txt
fi

GET_hosts_info=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_hosts_info.json -X GET "${api_path}/hosts/info")
if [[ $GET_hosts_info == 200 ]]; then
echo "GET_hosts_info is success at $(date)" >> success_response.txt
else
echo "$GET_hosts_info: GET_hosts_info failed at $(date)" >> failure_response.txt
fi

POST_hosts_scan=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/hosts/scan")
if [[ $POST_hosts_scan == 200 ]]; then
echo "POST_hosts_scan is success at $(date)" >> success_response.txt
else
echo "$POST_hosts_scan: POST_hosts_scan failed at $(date)" >> failure_response.txt
fi

# Images
GET_images=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_images.json -X GET "${api_path}/images")
if [[ $GET_images == 200 ]]; then
echo "GET_images is success at $(date)" >> success_response.txt
else
echo "$GET_images: GET_images failed at $(date)" >> failure_response.txt
fi

GET_images_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_images_download.csv -X GET "${api_path}/images/download")
if [[ $GET_images_download == 200 ]]; then
echo "GET_images_download is success at $(date)" >> success_response.txt
else
echo "$GET_images_download: GET_images_download failed at $(date)" >> failure_response.txt
fi

POST_images_evaluate=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/images/evaluate")
if [[ $POST_images_evaluate == 200 ]]; then
echo "POST_images_evaluate is success at $(date)" >> success_response.txt
else
echo "$POST_images_evaluate: POST_images_evaluate failed at $(date)" >> failure_response.txt
fi

GET_images_names=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_images_names.json -X GET "${api_path}/images/names")
if [[ $GET_images_names == 200 ]]; then
echo "GET_images_names is success at $(date)" >> success_response.txt
else
echo "$GET_images_names: GET_images_names failed at $(date)" >> failure_response.txt
fi

POST_images_scan=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/images/scan")
if [[ $POST_images_scan == 200 ]]; then
echo "POST_images_scan is success at $(date)" >> success_response.txt
else
echo "$POST_images_scan: POST_images_scan failed at $(date)" >> failure_response.txt
fi

GET_images_twistlock_defender_app_embedded=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_images_twistlock_defender_app_embedded.tar.gz -X GET "${api_path}/images/twistlock_defender_app_embedded.tar.gz")
if [[ $GET_images_twistlock_defender_app_embedded == 200 ]]; then
echo "GET_images_twistlock_defender_app_embedded is success at $(date)" >> success_response.txt
else
echo "$GET_images_twistlock_defender_app_embedded: GET_images_twistlock_defender_app_embedded failed at $(date)" >> failure_response.txt
fi

POST_images_twistlock_defender_layer=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" POST_images_twistlock_defender_layer.zip -X POST "${api_path}/images/twistlock_defender_layer.zip")
if [[ $POST_images_twistlock_defender_layer == 200 ]]; then
echo "POST_images_twistlock_defender_layer is success at $(date)" >> success_response.txt
else
echo "$POST_images_twistlock_defender_layer: POST_images_twistlock_defender_layer failed at $(date)" >> failure_response.txt
fi

# Policies
GET_policies_cloud_platforms=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_cloud-platforms.json -X GET "${api_path}/policies/cloud-platforms")
if [[ $GET_policies_cloud_platforms == 200 ]]; then
echo "GET_policies_cloud_platforms is success at $(date)" >> success_response.txt
else
echo "$GET_policies_cloud_platforms: GET_policies_cloud_platforms failed at $(date)" >> failure_response.txt
fi

PUT_policies_compliance_ci_images=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules": [{"name": "my-rule", "effect": "alert", "collections":[{"name":"All"}],"condition": {"vulnerabilities":{"id": 41, "block": false, "minSeverity": 1}]}}], "policyType": "ciImagesCompliance"}' "${api_path}/policies/compliance/ci/images")
if [[ $PUT_policies_compliance_ci_images == 200 ]]; then
echo "PUT_policies_compliance_ci_images is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_compliance_ci_images: PUT_policies_compliance_ci_images failed at $(date)" >> failure_response.txt
fi

GET_policies_compliance_ci_images=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X GET  "${api_path}/policies/compliance/ci/images > GET_policies_compliance_ci_images.json")
if [[ $GET_policies_compliance_ci_images == 200 ]]; then
echo "GET_policies_compliance_ci_images is success at $(date)" >> success_response.txt
else
echo "$GET_policies_compliance_ci_images: GET_policies_compliance_ci_images failed at $(date)" >> failure_response.txt
fi

PUT_policies_compliance_ci_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules": [{"name": "my-rule", "effect": "alert", "collections":[{"name":"All"}],"condition": {"vulnerabilities": [{"id": 436, "block": false, "minSeverity": 1}]}}], "policyType": "ciServerlessCompliance"}' "${api_path}/policies/compliance/ci/serverless")
if [[ $PUT_policies_compliance_ci_serverless == 200 ]]; then
echo "PUT_policies_compliance_ci_serverless is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_compliance_ci_serverless: PUT_policies_compliance_ci_serverless failed at $(date)" >> failure_response.txt
fi

GET_policies_compliance_ci_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_compliance_ci_serverless.json -X GET "${api_path}/policies/compliance/ci/serverless")
if [[ $GET_policies_compliance_ci_serverless == 200 ]]; then
echo "GET_policies_compliance_ci_serverless is success at $(date)" >> success_response.txt
else
echo "$GET_policies_compliance_ci_serverless: GET_policies_compliance_ci_serverless failed at $(date)" >> failure_response.txt
fi

GET_policies_compliance_container=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_compliance_container.json -X GET "${api_path}/policies/compliance/container")
if [[ $GET_policies_compliance_container == 200 ]]; then
echo "GET_policies_compliance_container is success at $(date)" >> success_response.txt
else
echo "$GET_policies_compliance_container: GET_policies_compliance_container failed at $(date)" >> failure_response.txt
fi

PUT_policies_compliance_container=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules":[{"name": "my-rule", "effect": "alert", "collections":[{"name":"All"}],"condition": {"vulnerabilities": [{"id": 531, "block": false, "minSeverity": 1}]}}], "policyType":"containerCompliance"}' "${api_path}/policies/compliance/container")
if [[ $PUT_policies_compliance_container == 200 ]]; then
echo "PUT_policies_compliance_container is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_compliance_container: PUT_policies_compliance_container failed at $(date)" >> failure_response.txt
fi

GET_policies_compliance_container_impacted=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_compliance_container_impacted.json -X GET "${api_path}/policies/compliance/container/impacted")
if [[ $GET_policies_compliance_container_impacted == 200 ]]; then
echo "GET_policies_compliance_container_impacted is success at $(date)" >> success_response.txt
else
echo "$GET_policies_compliance_container_impacted: GET_policies_compliance_container_impacted failed at $(date)" >> failure_response.txt
fi

GET_policies_compliance_host=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_compliance_host.json -X GET "${api_path}/policies/compliance/host")
if [[ $GET_policies_compliance_host == 200 ]]; then
echo "GET_policies_compliance_host is success at $(date)" >> success_response.txt
else
echo "$GET_policies_compliance_host: GET_policies_compliance_host failed at $(date)" >> failure_response.txt
fi

PUT_policies_compliance_host=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules":[{"name":"my-rule", "effect":"alert", "collections":[{"name":"All"}],"condition":{"vulnerabilities":[{"id":6151, "block":false}]}}], "policyType":"hostCompliance"}' "${api_path}/policies/compliance/host")
if [[ $PUT_policies_compliance_host == 200 ]]; then
echo "PUT_policies_compliance_host is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_compliance_host: PUT_policies_compliance_host failed at $(date)" >> failure_response.txt
fi

GET_policies_compliance_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_compliance_serverless.json -X GET "${api_path}/policies/compliance/serverless")
if [[ $GET_policies_compliance_serverless == 200 ]]; then
echo "GET_policies_compliance_serverless is success at $(date)" >> success_response.txt
else
echo "$GET_policies_compliance_serverless: GET_policies_compliance_serverless failed at $(date)" >> failure_response.txt
fi

PUT_policies_compliance_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules":[{"name":"my-rule","effect":"alert","collections":[{"name":"All"}],"condition":{"vulnerabilities":["id":434, "block":false}]}}], "policyType":"serverlessCompliance"}' "${api_path}/policies/compliance/serverless")
if [[ $PUT_policies_compliance_serverless == 200 ]]; then
echo "PUT_policies_compliance_serverless is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_compliance_serverless: PUT_policies_compliance_serverless failed at $(date)" >> failure_response.txt
fi

GET_policies_compliance_vms_impacted=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_compliance_vms_impacted.json -X GET "${api_path}/policies/compliance/vms/impacted")
if [[ $GET_policies_compliance_vms_impacted == 200 ]]; then
echo "GET_policies_compliance_vms_impacted is success at $(date)" >> success_response.txt
else
echo "$GET_policies_compliance_vms_impacted: GET_policies_compliance_vms_impacted failed at $(date)" >> failure_response.txt
fi

GET_policies_firewall_app_agentless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_firewall_app_agentless.json -X GET "${api_path}/policies/firewall/app/agentless")
if [[ $GET_policies_firewall_app_agentless == 200 ]]; then
echo "GET_policies_firewall_app_agentless is success at $(date)" >> success_response.txt
else
echo "$GET_policies_firewall_app_agentless: GET_policies_firewall_app_agentless failed at $(date)" >> failure_response.txt
fi

PUT_policies_firewall_app_agentless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT "${api_path}/policies/firewall/app/agentless.json")
if [[ $PUT_policies_firewall_app_agentless == 200 ]]; then
echo "PUT_policies_firewall_app_agentless is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_firewall_app_agentless: PUT_policies_firewall_app_agentless failed at $(date)" >> failure_response.txt
fi

GET_policies_firewall_app_agentless_impacted=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_firewall_app_agentless_impacted.json -X GET "${api_path}/policies/firewall/app/agentless/impacted")
if [[ $GET_policies_firewall_app_agentless_impacted == 200 ]]; then
echo "GET_policies_firewall_app_agentless_impacted is success at $(date)" >> success_response.txt
else
echo "$GET_policies_firewall_app_agentless_impacted: GET_policies_firewall_app_agentless_impacted failed at $(date)" >> failure_response.txt
fi

GET_policies_firewall_app_agentless_resources=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_firewall_app_agentless_resources.json -X GET "${api_path}/policies/firewall/app/agentless/resources")
if [[ $GET_policies_firewall_app_agentless_resources == 200 ]]; then
echo "GET_policies_firewall_app_agentless_resources is success at $(date)" >> success_response.txt
else
echo "$GET_policies_firewall_app_agentless_resources: GET_policies_firewall_app_agentless_resources failed at $(date)" >> failure_response.txt
fi

GET_policies_firewall_app_agentless_state=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_firewall_app_agentless_state.json -X GET "${api_path}/policies/firewall/app/agentless/state")
if [[ $GET_policies_firewall_app_agentless_state == 200 ]]; then
echo "GET_policies_firewall_app_agentless_state is success at $(date)" >> success_response.txt
else
echo "$GET_policies_firewall_app_agentless_state: GET_policies_firewall_app_agentless_state failed at $(date)" >> failure_response.txt
fi

GET_policies_firewall_app_app_embedded=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_firewall_app_app_embedded.json -X GET "${api_path}/policies/firewall/app/app-embedded")
if [[ $GET_policies_firewall_app_app_embedded == 200 ]]; then
echo "GET_policies_firewall_app_app_embedded is success at $(date)" >> success_response.txt
else
echo "$GET_policies_firewall_app_app_embedded: GET_policies_firewall_app_app_embedded failed at $(date)" >> failure_response.txt
fi

GET_policies_firewall_app_container=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_firewall_app_container.json -X GET "${api_path}/policies/firewall/app/container")
if [[ $GET_policies_firewall_app_container == 200 ]]; then
echo "GET_policies_firewall_app_container is success at $(date)" >> success_response.txt
else
echo "$GET_policies_firewall_app_container: GET_policies_firewall_app_container failed at $(date)" >> failure_response.txt
fi

GET_policies_firewall_app_container_impacted=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_firewall_app_container_impacted.json -X GET "${api_path}/policies/firewall/app/container/impacted")
if [[ $GET_policies_firewall_app_container_impacted == 200 ]]; then
echo "GET_policies_firewall_app_container_impacted is success at $(date)" >> success_response.txt
else
echo "$GET_policies_firewall_app_container_impacted: GET_policies_firewall_app_container_impacted failed at $(date)" >> failure_response.txt
fi

GET_policies_firewall_app_host=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_firewall_app_host.json -X GET "${api_path}/policies/firewall/app/host")
if [[ $GET_policies_firewall_app_host == 200 ]]; then
echo "GET_policies_firewall_app_host is success at $(date)" >> success_response.txt
else
echo "$GET_policies_firewall_app_host: GET_policies_firewall_app_host failed at $(date)" >> failure_response.txt
fi

GET_policies_firewall_app_host_impacted=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_firewall_app_host_impacted.json -X GET "${api_path}/policies/firewall/app/host/impacted")
if [[ $GET_policies_firewall_app_host_impacted == 200 ]]; then
echo "GET_policies_firewall_app_host_impacted is success at $(date)" >> success_response.txt
else
echo "$GET_policies_firewall_app_host_impacted: GET_policies_firewall_app_host_impacted failed at $(date)" >> failure_response.txt
fi

GET_policies_firewall_app_network_list=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_firewall_app_network-list.json -X GET "${api_path}/policies/firewall/app/network-list")
if [[ $GET_policies_firewall_app_network_list == 200 ]]; then
echo "GET_policies_firewall_app_network_list is success at $(date)" >> success_response.txt
else
echo "$GET_policies_firewall_app_network_list: GET_policies_firewall_app_network_list failed at $(date)" >> failure_response.txt
fi

POST_policies_firewall_app_network_list=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"_id":"{id}", "subnets":["192.145.2.3", "192.167.2.2"]}' "${api_path}/policies/firewall/app/network-list")
if [[ $POST_policies_firewall_app_network_list == 200 ]]; then
echo "POST_policies_firewall_app_network_list is success at $(date)" >> success_response.txt
else
echo "$POST_policies_firewall_app_network_list: POST_policies_firewall_app_network_list failed at $(date)" >> failure_response.txt
fi

PUT_policies_firewall_app_network_list=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"_id":"{id}", "subnets":["192.145.3.3", "192.167.3.2"]}' "${api_path}/policies/firewall/app/network-list")
if [[ $PUT_policies_firewall_app_network_list == 200 ]]; then
echo "PUT_policies_firewall_app_network_list is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_firewall_app_network_list: PUT_policies_firewall_app_network_list failed at $(date)" >> failure_response.txt
fi

DELETE_policies_firewall_app_network_list_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X DELETE "${api_path}/policies/firewall/app/network-list/{id}")
if [[ $DELETE_policies_firewall_app_network_list_id == 200 ]]; then
echo "DELETE_policies_firewall_app_network_list_id is success at $(date)" >> success_response.txt
else
echo "$DELETE_policies_firewall_app_network_list_id: DELETE_policies_firewall_app_network_list_id failed at $(date)" >> failure_response.txt
fi

GET_policies_firewall_app_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_firewall_app_serverless.json -X GET "${api_path}/policies/firewall/app/serverless")
if [[ $GET_policies_firewall_app_serverless == 200 ]]; then
echo "GET_policies_firewall_app_serverless is success at $(date)" >> success_response.txt
else
echo "$GET_policies_firewall_app_serverless: GET_policies_firewall_app_serverless failed at $(date)" >> failure_response.txt
fi

GET_policies_firewall_network=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_firewall_network.json -X GET "${api_path}/policies/firewall/network")
if [[ $GET_policies_firewall_network == 200 ]]; then
echo "GET_policies_firewall_network is success at $(date)" >> success_response.txt
else
echo "$GET_policies_firewall_network: GET_policies_firewall_network failed at $(date)" >> failure_response.txt
fi

PUT_policies_firewall_network=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o PUT_policies_firewall_network.json -X PUT "${api_path}/policies/firewall/network")
if [[ $PUT_policies_firewall_network == 200 ]]; then
echo "PUT_policies_firewall_network is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_firewall_network: PUT_policies_firewall_network failed at $(date)" >> failure_response.txt
fi

GET_policies_firewall_app_out_of_band=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_firewall_app_out-of-band.json -X GET "${api_path}/policies/firewall/app/out-of-band")
if [[ $GET_policies_firewall_app_out_of_band == 200 ]]; then
echo "GET_policies_firewall_app_out_of_band is success at $(date)" >> success_response.txt
else
echo "$GET_policies_firewall_app_out_of_band: GET_policies_firewall_app_out_of_band failed at $(date)" >> failure_response.txt
fi

PUT_policies_firewall_app_out_of_band=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules":[{"name":"my-rule", "effect":"disable", "collections":[{"name":"All"}],}]}' "${api_path}/policies/firewall/app/out-of-band")
if [[ $PUT_policies_firewall_app_out_of_band == 200 ]]; then
echo "PUT_policies_firewall_app_out_of_band is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_firewall_app_out_of_band: PUT_policies_firewall_app_out_of_band failed at $(date)" >> failure_response.txt
fi

GET_policies_firewall_app_out_of_band_impacted=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_firewall_app_out_of_band_impacted.json -X GET "${api_path}/policies/firewall/app/out-of-band/impacted")
if [[ $GET_policies_firewall_app_out_of_band_impacted == 200 ]]; then
echo "GET_policies_firewall_app_out_of_band_impacted is success at $(date)" >> success_response.txt
else
echo "$GET_policies_firewall_app_out_of_band_impacted: GET_policies_firewall_app_out_of_band_impacted failed at $(date)" >> failure_response.txt
fi

GET_policies_runtime_app_embedded=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_runtime_app_embedded.json -X GET "${api_path}/policies/runtime/app-embedded")
if [[ $GET_policies_runtime_app_embedded == 200 ]]; then
echo "GET_policies_runtime_app_embedded is success at $(date)" >> success_response.txt
else
echo "$GET_policies_runtime_app_embedded: GET_policies_runtime_app_embedded failed at $(date)" >> failure_response.txt
fi

PUT_policies_runtime_app_embedded=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules":[{"name":"my-rule", "collections":[{"name":"All"}], "processes":{"effect":"alert"}, "network":{"effect":"alert"}, "dns":{"effect":"alert"}}]}' "${api_path}/policies/runtime/app-embedded")
if [[ $PUT_policies_runtime_app_embedded == 200 ]]; then 
echo "PUT_policies_runtime_app-embedded is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_runtime_app_embedded: PUT_policies_runtime_app_embedded failed at $(date)" >> failure_response.txt
fi

GET_policies_runtime_container=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_runtime_container.json -X GET  "${api_path}/policies/runtime/container")
if [[ $GET_policies_runtime_container == 200 ]]; then
echo "GET_policies_runtime_container is success at $(date)" >> success_response.txt
else
echo "$GET_policies_runtime_container: GET_policies_runtime_container failed at $(date)" >> failure_response.txt
fi

POST_policies_runtime_container=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"rules":[{"name":"my-rule", "collections":[{"name":"All"}], "processes":{"effect":"alert"}, "network":{"effect":"alert"}, "dns":{"effect":"alert"}, "filesystem":{"effect":"alert"}}]}' "${api_path}/policies/runtime/container")
if [[ $POST_policies_runtime_container == 200 ]]; then
echo "POST_policies_runtime_container is success at $(date)" >> success_response.txt
else
echo "$POST_policies_runtime_container: POST_policies_runtime_container failed at $(date)" >> failure_response.txt
fi

PUT_policies_runtime_container=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules":[{"name":"my-rule", "collections":[{"name":"All"}], "processes":{"effect":"alert"}, "network":{"effect":"alert"}, "dns":{"effect":"alert"}, "filesystem":{"effect":"alert"}}]}' "${api_path}/policies/runtime/container")
if [[ $PUT_policies_runtime_container == 200 ]]; then
echo "PUT_policies_runtime_container is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_runtime_container: PUT_policies_runtime_container failed at $(date)" >> failure_response.txt
fi

GET_policies_runtime_container_impacted=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_runtime_container_impacted.json -X GET "${api_path}/policies/runtime/container/impacted")
if [[ $GET_policies_runtime_container_impacted == 200 ]]; then
echo "GET_policies_runtime_container_impacted is success at $(date)" >> success_response.txt
else
echo "$GET_policies_runtime_container_impacted: GET_policies_runtime_container_impacted failed at $(date)" >> failure_response.txt
fi

GET_policies_runtime_host=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_runtime_host.json -X GET "${api_path}/policies/runtime/host")
if [[ $GET_policies_runtime_host == 200 ]]; then
echo "GET_policies_runtime_host is success at $(date)" >> success_response.txt
else
echo "$GET_policies_runtime_host: GET_policies_runtime_host failed at $(date)" >> failure_response.txt
fi

POST_policies_runtime_host=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"rules":[{"name":"my-rule", "collections":[{"name":"All"}], "advancedProtection":"alert", "processes":{"effect":"alert"}, "network":{"effect":"disable"}, "dns":{"effect":"disable"}}]}' "${api_path}/policies/runtime/host")
if [[ $POST_policies_runtime_host == 200 ]]; then
echo "POST_policies_runtime_host is success at $(date)" >> success_response.txt
else
echo "$POST_policies_runtime_host: POST_policies_runtime_host failed at $(date)" >> failure_response.txt
fi

PUT_policies_runtime_host=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules":[{"name":"my-rule", "collections":[{"name":"All"}], "advancedProtection":"alert", "processes":{"effect":"alert"}, "network":{"effect":"disable"}, "dns":{"effect":"disable"}}]}' "${api_path}/policies/runtime/host")
if [[ $PUT_policies_runtime_host == 200 ]]; then
echo "PUT_policies_runtime_host is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_runtime_host: PUT_policies_runtime_host failed at $(date)" >> failure_response.txt
fi

GET_policies_runtime_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_runtime_serverless.json -X GET "${api_path}/policies/runtime/serverless")
if [[ $GET_policies_runtime_serverless == 200 ]]; then
echo "GET_policies_runtime_serverless is success at $(date)" >> success_response.txt
else
echo "$GET_policies_runtime_serverless: GET_policies_runtime_serverless failed at $(date)" >> failure_response.txt
fi

POST_policies_runtime_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"rules":[{"name":"my-rule", "collections":[{"name":"All"}]"processes":{"effect":"alert"}, "network":{"effect":"disable"}, "dns":{"effect":"disable"}, "filesystem":{"effect":"disable"}}]}' "${api_path}/policies/runtime/serverless")
if [[ $POST_policies_runtime_serverless == 200 ]]; then
echo "POST_policies_runtime_serverless is success at $(date)" >> success_response.txt
else
echo "$POST_policies_runtime_serverless: POST_policies_runtime_serverless failed at $(date)" >> failure_response.txt
fi

PUT_policies_runtime_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules":[{"name":"my-rule", "collections":[{"name":"All"}], "processes":{"effect":"alert"}, "network":{"effect":"disable"}, "dns":{"effect":"disable"}, "filesystem":{"effect":"disable"}}]}' "${api_path}/policies/runtime/serverless")
if [[ $PUT_policies_runtime_serverless == 200 ]]; then
echo "PUT_policies_runtime_serverless is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_runtime_serverless: PUT_policies_runtime_serverless failed at $(date)" >> failure_response.txt
fi

GET_policies_vulnerability_base_images=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_vulnerability_base_images.json -X GET "${api_path}/policies/vulnerability/base-images")
if [[ $GET_policies_vulnerability_base_images == 200 ]]; then
echo "GET_policies_vulnerability_base_images is success at $(date)" >> success_response.txt
else
echo "$GET_policies_vulnerability_base_images: GET_policies_vulnerability_base_images failed at $(date)" >> failure_response.txt
fi

POST_policies_vulnerability_base_images=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST  "${api_path}/policies/vulnerability/base-images")
if [[ $POST_policies_vulnerability_base_images == 200 ]]; then
echo "POST_policies_vulnerability_base_images is success at $(date)" >> success_response.txt
else
echo "$POST_policies_vulnerability_base_images: POST_policies_vulnerability_base_images failed at $(date)" >> failure_response.txt
fi

GET_policies_vulnerability_base_images_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_vulnerability_base_images_download.csv -X GET "${api_path}/policies/vulnerability/base-images/download")
if [[ $GET_policies_vulnerability_base_images_download == 200 ]]; then
echo "GET_policies_vulnerability_base_images_download is success at $(date)" >> success_response.txt
else
echo "$GET_policies_vulnerability_base_images_download: GET_policies_vulnerability_base_images_download failed at $(date)" >> failure_response.txt
fi

DELETE_policies_vulnerability_base_images_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X DELETE "${api_path}/policies/vulnerability/base-images/{id}")
if [[ $DELETE_policies_vulnerability_base_images_id == 200 ]]; then
echo "DELETE_policies_vulnerability_base_images_id is success at $(date)" >> success_response.txt
else
echo "$DELETE_policies_vulnerability_base_images_id: DELETE_policies_vulnerability_base_images_id failed at $(date)" >> failure_response.txt
fi

GET_policies_vulnerability_ci_images=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_vulnerability_ci_images.json -X GET "${api_path}/policies/vulnerability/ci/images")
if [[ $GET_policies_vulnerability_ci_images == 200 ]]; then
echo "GET_policies_vulnerability_ci_images is success at $(date)" >> success_response.txt
else
echo "$GET_policies_vulnerability_ci_images: GET_policies_vulnerability_ci_images failed at $(date)" >> failure_response.txt
fi

PUT_policies_vulnerability_ci_images=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules": [{"name": "<RULE_NAME>", "collections":[{"name":"<COLLECTION_NAME>",}], "alertThreshold":{"disabled":false, "value":4}, "blockThreshold":{"enabled":false, "value":0}}], "policyType": "ciImagesVulnerability"}' "${api_path}/policies/vulnerability/ci/images")
if [[ $PUT_policies_vulnerability_ci_images == 200 ]]; then
echo "PUT_policies_vulnerability_ci_images is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_vulnerability_ci_images: PUT_policies_vulnerability_ci_images failed at $(date)" >> failure_response.txt
fi

GET_policies_vulnerability_ci_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_vulnerability_ci_serverless.json -X GET "${api_path}/policies/vulnerability/ci/serverless")
if [[ $GET_policies_vulnerability_ci_serverless == 200 ]]; then
echo "GET_policies_vulnerability_ci_serverless is success at $(date)" >> success_response.txt
else
echo "$GET_policies_vulnerability_ci_serverless: GET_policies_vulnerability_ci_serverless failed at $(date)" >> failure_response.txt
fi

PUT_policies_vulnerability_ci_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules": [{"name": "<RULE_NAME>", "collections": [{"name":"<COLLECTION_NAME>",}], "alertThreshold": {"value": 1, "disabled": false}, "blockThreshold": {"value": 0, "enabled": false}], "policyType": "ciServerlessVulnerability"}' "${api_path}/policies/vulnerability/ci/serverless")
if [[ $PUT_policies_vulnerability_ci_serverless == 200 ]]; then
echo "PUT_policies_vulnerability_ci_serverless is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_vulnerability_ci_serverless: PUT_policies_vulnerability_ci_serverless failed at $(date)" >> failure_response.txt
fi

GET_policies_vulnerability_coderepos=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_vulnerability_coderepos.json -X GET "${api_path}/policies/vulnerability/coderepos")
if [[ $GET_policies_vulnerability_coderepos == 200 ]]; then
echo "GET_policies_vulnerability_coderepos is success at $(date)" >> success_response.txt
else
echo "$GET_policies_vulnerability_coderepos: GET_policies_vulnerability_coderepos failed at $(date)" >> failure_response.txt
fi

PUT_policies_vulnerability_coderepos=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules":[{"name":"<RULE_NAME>", "collection":[{"name":"<COLLECTION_NAME>",}], "alertThreshold":{"disabled":false, "value":0}, "blockThreshold":{"enabled":false, "value":0},}], "policyType": "codeRepoVulnerability"}' "${api_path}/policies/vulnerability/coderepos")
if [[ $PUT_policies_vulnerability_coderepos == 200 ]]; then
echo "PUT_policies_vulnerability_coderepos is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_vulnerability_coderepos: PUT_policies_vulnerability_coderepos failed at $(date)" >> failure_response.txt
fi

GET_policies_vulnerability_coderepos_impacted=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_vulnerability_coderepos_impacted.json -X GET "${api_path}/policies/vulnerability/coderepos/impacted")
if [[ $GET_policies_vulnerability_coderepos_impacted == 200 ]]; then
echo "GET_policies_vulnerability_coderepos_impacted is success at $(date)" >> success_response.txt
else
echo "$GET_policies_vulnerability_coderepos_impacted: GET_policies_vulnerability_coderepos_impacted failed at $(date)" >> failure_response.txt
fi

GET_policies_vulnerability_host=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_vulnerability_host.json -X GET "${api_path}/policies/vulnerability/host")
if [[ $GET_policies_vulnerability_host == 200 ]]; then
echo "GET_policies_vulnerability_host is success at $(date)" >> success_response.txt
else
echo "$GET_policies_vulnerability_host: GET_policies_vulnerability_host failed at $(date)" >> failure_response.txt
fi

PUT_policies_vulnerability_host=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules":[{"name":"<RULE_NAME>", "collections":[{"name":"<COLLECTION_NAME>"}], "alertThreshold":{"disabled":false, "value":1}}], "policyType":"hostVulnerability", "_id":"hostVulnerability"}' "${api_path}/policies/vulnerability/host")
if [[ $PUT_policies_vulnerability_host == 200 ]]; then
echo "PUT_policies_vulnerability_host is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_vulnerability_host: PUT_policies_vulnerability_host failed at $(date)" >> failure_response.txt
fi

GET_policies_vulnerability_host_impacted=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_vulnerability_host_impacted.json -X GET "${api_path}/policies/vulnerability/host/impacted")
if [[ $GET_policies_vulnerability_host_impacted == 200 ]]; then
echo "GET_policies_vulnerability_host_impacted is success at $(date)" >> success_response.txt
else
echo "$GET_policies_vulnerability_host_impacted: GET_policies_vulnerability_host_impacted failed at $(date)" >> failure_response.txt
fi

GET_policies_vulnerability_images=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_vulnerability_images.json -X GET "${api_path}/policies/vulnerability/images")
if [[ $GET_policies_vulnerability_images == 200 ]]; then
echo "GET_policies_vulnerability_images is success at $(date)" >> success_response.txt
else
echo "$GET_policies_vulnerability_images: GET_policies_vulnerability_images failed at $(date)" >> failure_response.txt
fi

PUT_policies_vulnerability_images=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules":[{"name":"<RULE_NAME>", "collections":[{"name":"<COLLECTION_NAME>",}], "alertThreshold":{"disabled":false, "value":4}, "blockThreshold":{"enabled":false, "value":0},}], "policyType": "containerVulnerability"}' "${api_path}/policies/vulnerability/images")
if [[ $PUT_policies_vulnerability_images == 200 ]]; then
echo "PUT_policies_vulnerability_images is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_vulnerability_images: PUT_policies_vulnerability_images failed at $(date)" >> failure_response.txt
fi

GET_policies_vulnerability_images_impacted=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_vulnerability_images_impacted.json -X GET "${api_path}/policies/vulnerability/images/impacted")
if [[ $GET_policies_vulnerability_images_impacted == 200 ]]; then
echo "GET_policies_vulnerability_images_impacted is success at $(date)" >> success_response.txt
else
echo "$GET_policies_vulnerability_images_impacted: GET_policies_vulnerability_images_impacted failed at $(date)" >> failure_response.txt
fi

GET_policies_vulnerability_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_policies_vulnerability_serverless.json -X GET "${api_path}/policies/vulnerability/serverless")
if [[ $GET_policies_vulnerability_serverless == 200 ]]; then
echo "GET_policies_vulnerability_serverless is success at $(date)" >> success_response.txt
else
echo "$GET_policies_vulnerability_serverless: GET_policies_vulnerability_serverless failed at $(date)" >> failure_response.txt
fi

PUT_policies_vulnerability_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"rules": [{"name": "<RULE_NAME>", "collections": [{"name":"<COLLECTION_NAME>"}], "alertThreshold": {"value": 1, "disabled": false}}], "policyType": "serverlessVulnerability"}' "${api_path}/policies/vulnerability/serverless")
if [[ $PUT_policies_vulnerability_serverless == 200 ]]; then
echo "PUT_policies_vulnerability_serverless is success at $(date)" >> success_response.txt
else
echo "$PUT_policies_vulnerability_serverless: PUT_policies_vulnerability_serverless failed at $(date)" >> failure_response.txt
fi

# Profiles
GET_profiles_container=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_profiles_container.json -X GET "${api_path}/profiles/container")
if [[ $GET_profiles_container == 200 ]]; then
echo "GET_profiles_container is success at $(date)" >> success_response.txt
else
echo "$GET_profiles_container: GET_profiles_container failed at $(date)" >> failure_response.txt
fi

GET_profiles_app_embedded=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_profiles_app-embedded.json -X GET "${api_path}/profiles/app-embedded")
if [[ $GET_profiles_app_embedded == 200 ]]; then
echo "GET_profiles_app_embedded is success at $(date)" >> success_response.txt
else
echo "$GET_profiles_app_embedded: GET_profiles_app-embedded failed at $(date)" >> failure_response.txt
fi

GET_profiles_app_embedded_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_profiles_app-embedded_download.csv -X GET "${api_path}/profiles/app-embedded/download")
if [[ $GET_profiles_app_embedded_download == 200 ]]; then
echo "GET_profiles_app_embedded_download is success at $(date)" >> success_response.txt
else
echo "$GET_profiles_app_embedded_download: GET_profiles_app-embedded_download failed at $(date)" >> failure_response.txt
fi

GET_profiles_container_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_profiles_container_download.csv -X GET "${api_path}/profiles/container/download")
if [[ $GET_profiles_container_download == 200 ]]; then
echo "GET_profiles_container_download is success at $(date)" >> success_response.txt
else
echo "$GET_profiles_container_download: GET_profiles_container_download failed at $(date)" >> failure_response.txt
fi

POST_profiles_container_learn=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST  "${api_path}/profiles/container/learn")
if [[ $POST_profiles_container_learn == 200 ]]; then
echo "POST_profiles_container_learn is success at $(date)" >> success_response.txt
else
echo "$POST_profiles_container_learn: POST_profiles_container_learn failed at $(date)" >> failure_response.txt
fi

GET_profiles_host=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_profiles_host.json -X GET "${api_path}/profiles/host")
if [[ $GET_profiles_host == 200 ]]; then
echo "GET_profiles_host is success at $(date)" >> success_response.txt
else
echo "$GET_profiles_host: GET_profiles_host failed at $(date)" >> failure_response.txt
fi

GET_profiles_host_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_profiles_host_download.csv -X GET "${api_path}/profiles/host/download")
if [[ $GET_profiles_host_download == 200 ]]; then
echo "GET_profiles_host_download is success at $(date)" >> success_response.txt
else
echo "$GET_profiles_host_download: GET_profiles_host_download failed at $(date)" >> failure_response.txt
fi

# Registry
DELETE_registry_webhook_webhook=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X DELETE "${api_v1path}/registry/webhook/webhook")
if [[ $DELETE_registry_webhook_webhook == 200 ]]; then
echo "DELETE_registry_webhook_webhook is success at $(date)" >> success_response.txt
else
echo "$DELETE_registry_webhook_webhook: DELETE_registry_webhook_webhook failed at $(date)" >> failure_response.txt
fi

POST_registry_webhook_webhook=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_v1path}/registry/webhook/webhook")
if [[ $POST_registry_webhook_webhook == 200 ]]; then
echo "POST_registry_webhook_webhook is success at $(date)" >> success_response.txt
else
echo "$POST_registry_webhook_webhook: POST_registry_webhook_webhook failed at $(date)" >> failure_response.txt
fi

GET_registry=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_registry.json -X GET "${api_path}/registry")
if [[ $GET_registry == 200 ]]; then
echo "GET_registry is success at $(date)" >> success_response.txt
else
echo "$GET_registry: GET_registry failed at $(date)" >> failure_response.txt
fi

GET_registry_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_registry_download.csv -X GET "${api_path}/registry/download")
if [[ $GET_registry_download == 200 ]]; then
echo "GET_registry_download is success at $(date)" >> success_response.txt
else
echo "$GET_registry_download: GET_registry_download failed at $(date)" >> failure_response.txt
fi

GET_registry_names=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_registry_names.json -X GET "${api_path}/registry/names")
if [[ $GET_registry_names == 200 ]]; then
echo "GET_registry_names is success at $(date)" >> success_response.txt
else
echo "$GET_registry_names: GET_registry_names failed at $(date)" >> failure_response.txt
fi

POST_registry_scan=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/registry/scan")
if [[ $POST_registry_scan == 200 ]]; then
echo "POST_registry_scan is success at $(date)" >> success_response.txt
else
echo "$POST_registry_scan: POST_registry_scan failed at $(date)" >> failure_response.txt
fi

POST_registry_stop=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/registry/stop")
if [[ $POST_registry_stop == 200 ]]; then
echo "POST_registry_stop is success at $(date)" >> success_response.txt
else
echo "$POST_registry_stop: POST_registry_stop failed at $(date)" >> failure_response.txt
fi

# Scans

GET_scans=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_scans.json -X GET "${api_path}/scans")
if [[ $GET_scans == 200 ]]; then
echo "GET_scans is success at $(date)" >> success_response.txt
else
echo "$GET_scans: GET_scans failed at $(date)" >> failure_response.txt
fi

POST_scans=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/scans")
if [[ $POST_scans == 200 ]]; then
echo "POST_scans is success at $(date)" >> success_response.txt
else
echo "$POST_scans: POST_scans failed at $(date)" >> failure_response.txt
fi

GET_scans_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_scans_download.csv -X GET "${api_path}/scans/download")
if [[ $GET_scans_download == 200 ]]; then
echo "GET_scans_download is success at $(date)" >> success_response.txt
else
echo "$GET_scans_download: GET_scans_download failed at $(date)" >> failure_response.txt
fi

POST_scans_sonatype=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/scans/sonatype")
if [[ $POST_scans_sonatype == 200 ]]; then
echo "POST_scans_sonatype is success at $(date)" >> success_response.txt
else
echo "$POST_scans_sonatype: POST_scans_sonatype failed at $(date)" >> failure_response.txt
fi

GET_scans_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_scans_id.json -X GET "${api_path}/scans/{id}")
if [[ $GET_scans_id == 200 ]]; then
echo "GET_scans_id is success at $(date)" >> success_response.txt
else
echo "$GET_scans_id: GET_scans_id failed at $(date)" >> failure_response.txt
fi

# Serverless

GET_serverless=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_serverless.json -X GET "${api_path}/serverless")
if [[ $GET_serverless == 200 ]]; then
echo "GET_serverless is success at $(date)" >> success_response.txt
else
echo "$GET_serverless: GET_serverless failed at $(date)" >> failure_response.txt
fi

GET_serverless_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_serverless_download.csv -X GET "${api_path}/serverless/download")
if [[ $GET_serverless_download == 200 ]]; then
echo "GET_serverless_download is success at $(date)" >> success_response.txt
else
echo "$GET_serverless_download: GET_serverless_download failed at $(date)" >> failure_response.txt
fi

POST_serverless_evaluate=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/serverless/evaluate")
if [[ $POST_serverless_evaluate == 200 ]]; then
echo "POST_serverless_evaluate is success at $(date)" >> success_response.txt
else
echo "$POST_serverless_evaluate: POST_serverless_evaluate failed at $(date)" >> failure_response.txt
fi

GET_serverless_names=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_serverless_names.json -X GET "${api_path}/serverless/names")
if [[ $GET_serverless_names == 200 ]]; then
echo "GET_serverless_names is success at $(date)" >> success_response.txt
else
echo "$GET_serverless_names: GET_serverless_names failed at $(date)" >> failure_response.txt
fi

POST_serverless_scan=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/serverless/scan")
if [[ $POST_serverless_scan == 200 ]]; then
echo "POST_serverless_scan is success at $(date)" >> success_response.txt
else
echo "$POST_serverless_scan: POST_serverless_scan failed at $(date)" >> failure_response.txt
fi

POST_serverless_stop=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/serverless/stop")
if [[ $POST_serverless_stop == 200 ]]; then
echo "POST_serverless_stop is success at $(date)" >> success_response.txt
else
echo "$POST_serverless_stop: POST_serverless_stop failed at $(date)" >> failure_response.txt
fi

# Stats

GET_stats_app_firewall_count=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_stats_app_firewall_count.json -X GET "${api_path}/stats/app-firewall/count")
if [[ $GET_stats_app_firewall_count == 200 ]]; then
echo "GET_stats_app_firewall_count is success at $(date)" >> success_response.txt
else
echo "$GET_stats_app_firewall_count: GET_stats_app_firewall_count failed at $(date)" >> failure_response.txt
fi

GET_stats_compliance=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_stats_compliance.json -X GET "${api_path}/stats/compliance")
if [[ $GET_stats_compliance == 200 ]]; then
echo "GET_stats_compliance is success at $(date)" >> success_response.txt
else
echo "$GET_stats_compliance: GET_stats_compliance failed at $(date)" >> failure_response.txt
fi

GET_stats_compliance_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_stats_compliance_download.csv -X GET "${api_path}/stats/compliance/download")
if [[ $GET_stats_compliance_download == 200 ]]; then
echo "GET_stats_compliance_download is success at $(date)" >> success_response.txt
else
echo "$GET_stats_compliance_download: GET_stats_compliance_download failed at $(date)" >> failure_response.txt
fi

POST_stats_compliance_refresh=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/stats/compliance/refresh")
if [[ $POST_stats_compliance_refresh == 200 ]]; then
echo "POST_stats_compliance_refresh is success at $(date)" >> success_response.txt
else
echo "$POST_stats_compliance_refresh: POST_stats_compliance_refresh failed at $(date)" >> failure_response.txt
fi

GET_stats_daily=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_stats_daily.json -X GET "${api_path}/stats/daily")
if [[ $GET_stats_daily == 200 ]]; then
echo "GET_stats_daily is success at $(date)" >> success_response.txt
else
echo "$GET_stats_daily: GET_stats_daily failed at $(date)" >> failure_response.txt
fi

GET_stats_dashboard=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_stats_dashboard.json -X GET "${api_path}/stats/dashboard")
if [[ $GET_stats_dashboard == 200 ]]; then
echo "GET_stats_dashboard is success at $(date)" >> success_response.txt
else
echo "$GET_stats_dashboard: GET_stats_dashboard failed at $(date)" >> failure_response.txt
fi

GET_stats_events=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_stats_events.json -X GET "${api_path}/stats/events")
if [[ $GET_stats_events == 200 ]]; then
echo "GET_stats_events is success at $(date)" >> success_response.txt
else
echo "$GET_stats_events: GET_stats_events failed at $(date)" >> failure_response.txt
fi

GET_stats_license=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_stats_license.json -X GET "${api_path}/stats/license")
if [[ $GET_stats_license == 200 ]]; then
echo "GET_stats_license is success at $(date)" >> success_response.txt
else
echo "$GET_stats_license: GET_stats_license failed at $(date)" >> failure_response.txt
fi

GET_stats_vulnerabilities=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_stats_vulnerabilities.json -X GET "${api_path}/stats/vulnerabilities")
if [[ $GET_stats_vulnerabilities == 200 ]]; then
echo "GET_stats_vulnerabilities is success at $(date)" >> success_response.txt
else
echo "$GET_stats_vulnerabilities: GET_stats_vulnerabilities failed at $(date)" >> failure_response.txt
fi

GET_stats_vulnerabilities_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_stats_vulnerabilities_download.csv -X GET "${api_path}/stats/vulnerabilities/download")
if [[ $GET_stats_vulnerabilities_download == 200 ]]; then
echo "GET_stats_vulnerabilities_download is success at $(date)" >> success_response.txt
else
echo "$GET_stats_vulnerabilities_download: GET_stats_vulnerabilities_download failed at $(date)" >> failure_response.txt
fi

GET_stats_vulnerabilities_impacted_resources=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_stats_vulnerabilities_impacted_resources.json -X GET "${api_path}/stats/vulnerabilities/impacted-resources")
if [[ $GET_stats_vulnerabilities_impacted_resources == 200 ]]; then
echo "GET_stats_vulnerabilities_impacted_resources is success at $(date)" >> success_response.txt
else
echo "$GET_stats_vulnerabilities_impacted_resources: GET_stats_vulnerabilities_impacted_resources failed at $(date)" >> failure_response.txt
fi

GET_stats_vulnerabilities_impacted_resources_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_stats_vulnerabilities_impacted_resources_download.csv -X GET "${api_path}/stats/vulnerabilities/impacted-resources/download")
if [[ $GET_stats_vulnerabilities_impacted_resources_download == 200 ]]; then
echo "GET_stats_vulnerabilities_impacted_resources_download is success at $(date)" >> success_response.txt
else
echo "$GET_stats_vulnerabilities_impacted_resources_download: GET_stats_vulnerabilities_impacted_resources_download failed at $(date)" >> failure_response.txt
fi

POST_stats_vulnerabilities_refresh=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/stats/vulnerabilities/refresh")
if [[ $POST_stats_vulnerabilities_refresh == 200 ]]; then
echo "POST_stats_vulnerabilities_refresh is success at $(date)" >> success_response.txt
else
echo "$POST_stats_vulnerabilities_refresh: POST_stats_vulnerabilities_refresh failed at $(date)" >> failure_response.txt
fi

# Statuses

GET_statuses_registry=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_statuses_registry.json -X GET "${api_path}/statuses/registry")
if [[ $GET_statuses_registry == 200 ]]; then
echo "GET_statuses_registry is success at $(date)" >> success_response.txt
else
echo "$GET_statuses_registry: GET_statuses_registry failed at $(date)" >> failure_response.txt
fi


# Util

GET_util_arm64_twistcli=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X GET "${api_path}/util/arm64/twistcli")
if [[ $GET_util_arm64_twistcli == 200 ]]; then
echo "GET_util_arm64_twistcli is success at $(date)" >> success_response.txt
else
echo "$GET_util_arm64_twistcli: GET_util_arm64_twistcli failed at $(date)" >> failure_response.txt
fi

GET_util_prisma_cloud_jenkins_plugin=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X GET "${api_v1path}/util/prisma-cloud-jenkins-plugin.hpi")
if [[ $GET_util_prisma_cloud_jenkins_plugin == 200 ]]; then
echo "GET_util_prisma_cloud_jenkins_plugin is success at $(date)" >> success_response.txt
else
echo "$GET_util_prisma_cloud_jenkins_plugin: GET_util_prisma_cloud_jenkins_plugin failed at $(date)" >> failure_response.txt
fi

GET_util_tas_tile=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X GET "${api_v1path}/util/tas-tile")
if [[ $GET_util_tas_tile == 200 ]]; then
echo "GET_util_tas_tile is success at $(date)" >> success_response.txt
else
echo "$GET_util_tas_tile: GET_util_tas_tile failed at $(date)" >> failure_response.txt
fi

GET_util_osx_twistcli=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X GET "${api_path}/util/osx/twistcli")
if [[ $GET_util_osx_twistcli == 200 ]]; then
echo "GET_util_osx_twistcli is success at $(date)" >> success_response.txt
else
echo "$GET_util_osx_twistcli: GET_util_osx_twistcli failed at $(date)" >> failure_response.txt
fi

GET_util_windows_twistcli=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X GET "${api_path}/util/windows/twistcli.exe")
if [[ $GET_util_windows_twistcli == 200 ]]; then
echo "GET_util_windows_twistcli is success at $(date)" >> success_response.txt
else
echo "$GET_util_windows_twistcli: GET_util_windows_twistcli failed at $(date)" >> failure_response.txt
fi

GET_util_twistcli=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X GET "${api_path}/util/twistcli")
if [[ $GET_util_twistcli == 200 ]]; then
echo "GET_util_twistcli is success at $(date)" >> success_response.txt
else
echo "$GET_util_twistcli: GET_util_twistcli failed at $(date)" >> failure_response.txt
fi

# Version

GET_version=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_version.json -X GET "${api_path}/version")
if [[ $GET_version == 200 ]]; then
echo "GET_version is success at $(date)" >> success_response.txt
else
echo "$GET_version: GET_version failed at $(date)" >> failure_response.txt
fi


# Vms

GET_vms=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_vms.json -X GET "${api_path}/vms")
if [[ $GET_vms == 200 ]]; then
echo "GET_vms is success at $(date)" >> success_response.txt
else
echo "$GET_vms: GET_vms failed at $(date)" >> failure_response.txt
fi

GET_vms_download=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_vms_download.csv -X GET "${api_path}/vms/download")
if [[ $GET_vms_download == 200 ]]; then
echo "GET_vms_download is success at $(date)" >> success_response.txt
else
echo "$GET_vms_download: GET_vms_download failed at $(date)" >> failure_response.txt
fi

GET_vms_labels=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_vms_labels.json -X GET "${api_path}/vms/labels")
if [[ $GET_vms_labels == 200 ]]; then
echo "GET_vms_labels is success at $(date)" >> success_response.txt
else
echo "$GET_vms_labels: GET_vms_labels failed at $(date)" >> failure_response.txt
fi

GET_vms_names=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_vms_names.json -X GET "${api_path}/vms/names")
if [[ $GET_vms_names == 200 ]]; then
echo "GET_vms_names is success at $(date)" >> success_response.txt
else
echo "$GET_vms_names: GET_vms_names failed at $(date)" >> failure_response.txt
fi

POST_vms_scan=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/vms/scan")
if [[ $POST_vms_scan == 200 ]]; then
echo "POST_vms_scan is success at $(date)" >> success_response.txt
else
echo "$POST_vms_scan: POST_vms_scan failed at $(date)" >> failure_response.txt
fi

POST_vms_stop=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST "${api_path}/vms/stop")
if [[ $POST_vms_stop == 200 ]]; then
echo "POST_vms_stop is success at $(date)" >> success_response.txt
else
echo "$POST_vms_stop: POST_vms_stop failed at $(date)" >> failure_response.txt
fi



# Tags

GET_Tags=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_Tags.json -X GET "${api_path}/Tags")
if [[ $GET_Tags == 200 ]]; then
echo "GET_Tags is success at $(date)" >> success_response.txt
else
echo "$GET_Tags: GET_Tags failed at $(date)" >> failure_response.txt
fi

POST_Tags=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"name": "my-tag", "color": "#ff0000", "description": "A test collection"}' "${api_path}/Tags")
if [[ $POST_Tags == 200 ]]; then
echo "POST_Tags is success at $(date)" >> success_response.txt
else
echo "$POST_Tags: POST_Tags failed at $(date)" >> failure_response.txt
fi

DELETE_Tags_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X DELETE "${api_path}/Tags/{id}")
if [[ $DELETE_Tags_id == 200 ]]; then
echo "DELETE_Tags_id is success at $(date)" >> success_response.txt
else
echo "$DELETE_Tags_id: DELETE_Tags_id failed at $(date)" >> failure_response.txt
fi

PUT_Tags_id=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X PUT -d '{"name": "my_tag2", "color": "#ff0000", "description": "A super cool tag"}' "${api_path}/Tags/{id}")
if [[ $PUT_Tags_id == 200 ]]; then
echo "PUT_Tags_id is success at $(date)" >> success_response.txt
else
echo "$PUT_Tags_id: PUT_Tags_id failed at $(date)" >> failure_response.txt
fi

DELETE_Tags_id_vuln=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X DELETE -d {"id": "CVE-2017-15088", "packageName": "krb5"} "${api_path}/Tags/{id}/vuln")
if [[ $DELETE_Tags_id_vuln == 200 ]]; then
echo "DELETE_Tags_id_vuln is success at $(date)" >> success_response.txt
else
echo "$DELETE_Tags_id_vuln: DELETE_Tags_id_vuln failed at $(date)" >> failure_response.txt
fi

POST_Tags_id_vuln=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -X POST -d '{"id": "CVE-2020-16156", "packageName": "perl"}' "${api_path}/Tags/{id}/vuln")
if [[ $POST_Tags_id_vuln == 200 ]]; then
echo "POST_Tags_id_vuln is success at $(date)" >> success_response.txt
else
echo "$POST_Tags_id_vuln: POST_Tags_id_vuln failed at $(date)" >> failure_response.txt
fi

# WAAS

POST_waas_openapi_scans=$(curl -k -H 'Content-Type: multipart/form-data' -u $api_user -w "%{http_code}\n" -X POST -v -F ‘spec=@<FILE NAME>.json;type=application/json’ -F ‘data={“source”:“manual”};type=application/json’ "${api_path}/waas/openapi-scans")
if [[ $POST_waas_openapi_scans == 200 ]]; then
echo "POST_waas_openapi_scans is success at $(date)" >> success_response.txt
else
echo "$POST_waas_openapi_scans: POST_waas_openapi_scans failed at $(date)" >> failure_response.txt
fi