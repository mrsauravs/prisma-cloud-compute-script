import json
import requests

# JIRA URL
jira_url = 'https://yourdomain.atlassian.net/rest/api/2/issue/'

# JIRA credentials
username = input("Enter your JIRA username: ")
password = input("Enter your JIRA password: ")

# Get issue keys from user input
issue_keys = input("Enter JIRA issue keys separated by comma: ").split(',')

for issue_key in issue_keys:
    # Send a GET request to the JIRA REST API
    response = requests.get(jira_url + issue_key.strip(), auth=(username, password))
    # Parse the JSON response
    issue_data = json.loads(response.text)
    # Extract the description field
    description = issue_data['fields']['description']
    # Write the description to an ASCII file
    with open(f'{issue_key.strip()}_description.txt', 'w', encoding='ascii') as f:
        f.write(description)
    print(f"Issue {issue_key} description written to {issue_key.strip()}_description.txt")
