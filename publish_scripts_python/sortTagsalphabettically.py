import json

# Read in JSON file
with open('openapi_22_12_631_pp.json', 'r') as f:
    data = json.load(f)

# Sort name-value pairs in each tags array
for tag in data['tags']:
    data['tags'].sort(key=lambda x: x['name'])

# Write sorted data back to file
with open('output_openapi_22_12_631.json', 'w') as f:
    json.dump(data, f, indent=4)