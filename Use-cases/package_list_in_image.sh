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

# Images

echo "Enter the image ID to view the packages inside it"
read image_name
GET_images=$(curl -k -H 'Content-Type: application/json' -u $api_user -w "%{http_code}\n" -o GET_images_new.json -X GET "${api_path}/images?id=${image_name}")
if [[ $GET_images == 200 ]]; then
echo "$GET_images: GET_images is success at $(date)" >> success_response.txt
else
echo "$GET_images: GET_images failed at $(date)" >> failure_response.txt
fi

cat GET_images_new.json | jq . > GET_images_new_pp.json

package_list=$(cat GET_images_new_pp.json | jq '.[].packages')

echo $package_list >> package_list.json

cat package_list.json | jq . > package_list_image.json

echo "View the list of packages in a image here: package_list_image.json"
