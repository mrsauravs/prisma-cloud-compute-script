
# Introduction

The script files cURLscriptBasic.sh and cURLscriptAdvanced.sh are both executable and ready for use.
Both scripts are written to match a specific workflow but more advanced workflow could be designed to achieve better testing and results.

## What to do for a fresh one-box installation?

It is recommended that you set up a one-box installation, see [Install one-box](https://docs.paloaltonetworks.com/prisma/prisma-cloud/21-08/prisma-cloud-compute-edition-admin/install/install_onebox).

- For a fresh on-prem installation, always run both scripts cURLscriptBasic.sh and cURLscriptAdvanced.sh
    - Run the scripts under a blank folder to see and use output files easily.
    - Follow the on-screen instructions in the script.

## What to do for a second or subsequent testing?
- For a second run (or when you have set up the admin account and added the license key), run only the cURLscriptAdvanced.sh
    - Run the scripts under a blank folder to see and use output files easily.
    - Follow the on-screen instructions in the script.

## Result
- Success messages are stored in a single file success_response.txt
- Failure messages are stored in a single file failure_response.txt
- JSON responses are stored in individual API files <api_name_details>.json at the same location.
- Individual downloaded files are also stored at the same location.

**Note:** A Test_Run folder is available to see results from the initial run.

## Pending: Improvements and additions
- More refined workflow for other APIs.
- Collate all results in Results.txt
    - $ cat success_response.txt failure_response.txt >> Results.txt
- Print total successful endpoints using:
    - $ total_success=`wc -l < success_response.txt`
    - $ echo “Number of API endpoints passed: $total_success” >> Results.txt 
- Print total successful endpoints using:
    - $ total_failure=`wc -l < failure_response.txt`
    - $ echo “Number of API endpoints failed: $total_failure” >> Results.txt
