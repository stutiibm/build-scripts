#!/bin/bash -e
#
# Usage:
#   ./download_wheel.sh <filename>
#
# Environment Variables Required:
#   GHA_CURRENCY_SERVICE_ID_API_KEY  - IAM API key for COS access
#   PACKAGE_NAME                     - Name of the package
#   VERSION                          - Version of the package
#
# Downloads the specified wheel file from IBM COS (ose-power-artifacts-stag).

FILE_NAME=$1

if [ -z "$FILE_NAME" ]; then
    echo "Error: No filename provided."
    echo "Usage: ./download_wheel.sh <filename>"
    exit 1
fi

if [ -z "$GHA_CURRENCY_SERVICE_ID_API_KEY" ]; then
    echo "Error: Environment variable GHA_CURRENCY_SERVICE_ID_API_KEY not set."
    exit 1
fi

if [ -z "$PACKAGE_NAME" ] || [ -z "$VERSION" ]; then
    echo "Error: PACKAGE_NAME or VERSION environment variable missing."
    exit 1
fi

# Request IAM token
echo "Requesting IAM token..."
token_request=$(curl -s -X POST "https://iam.cloud.ibm.com/identity/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/json" \
  -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$GHA_CURRENCY_SERVICE_ID_API_KEY")

# Verify token retrieval
if [[ $(echo "$token_request" | jq -r '.errorCode') != "null" ]]; then
    echo "Error: Failed to obtain IAM token. Response:"
    echo "$token_request"
    exit 1
fi

# Extract access token
token=$(echo "$token_request" | jq -r '.access_token')

# Construct COS download URL
COS_URL="https://s3.us.cloud-object-storage.appdomain.cloud/ose-power-artifacts-stag/${PACKAGE_NAME}/${VERSION}/${FILE_NAME}"
echo "Downloading from: $COS_URL"

# Perform the GET request
response_code=$(curl -w "%{http_code}" -s -o "$FILE_NAME" \
  -H "Authorization: bearer $token" \
  -X GET "$COS_URL")

# Handle response
if [[ "$response_code" == "200" ]]; then
    echo "Successfully downloaded '$FILE_NAME'"
elif [[ "$response_code" == "404" ]]; then
    echo "Error: File not found at $COS_URL"
    rm -f "$FILE_NAME"
    exit 1
else
    echo "Error: Download failed (HTTP $response_code)"
    rm -f "$FILE_NAME"
    exit 1
fi
