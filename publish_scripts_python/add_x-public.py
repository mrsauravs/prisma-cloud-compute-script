import json
with open('input.json', 'r') as json_file:
    json_data = json.load(json_file)
    for path, methods in json_data["paths"].items():
        for method in ["put", "get", "delete", "post", "patch"]:
            if method in methods and "Supported API" in methods[method].get("tags", []):
                methods[method]["x-public"] = True
                methods[method]["tags"].remove("Supported API")

with open('output.json', 'w') as json_file:
    json.dump(json_data, json_file, indent=4)