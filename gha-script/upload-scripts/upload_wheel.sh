#!/bin/bash -e

token_request=$(curl -X POST https://iam.cloud.ibm.com/identity/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -H "accept: application/json" \
  -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=$GHA_CURRENCY_SERVICE_ID_API_KEY")

#token=$(echo "$token_request" | jq -r '.access_token')
#curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: application/gzip" -T $1 "https://s3.au-syd.cloud-object-storage.appdomain.cloud/currency-automation-toolci-bucket/$PACKAGE_NAME/$VERSION/$1"

# Check if the token request was successful based on the presence of 'errorCode'
if [[ $(echo "$token_request" | jq -r '.errorCode') == "null" ]]; then
    token=$(echo "$token_request" | jq -r '.access_token')
    
    # curl command for uploading the file
    #response=$(curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: application/octet-stream" -T $1 "https://s3.us.cloud-object-storage.appdomain.cloud/ose-power-artifacts-prod/$PACKAGE_NAME/$VERSION/$1")
    response=$(curl -i -X PUT -H "Authorization: bearer $token" -H "Content-Type: application/octet-stream" -T $1 "https://s3.us.cloud-object-storage.appdomain.cloud/ose-power-artifacts-production/$PACKAGE_NAME/$VERSION/$1")

    echo "*****************************************************"
    echo "--------- token : $token ----------------------------"
    echo "-----------length of token : ${token:0:10} ------------"
    echo "-----------response : $response --------------------"
    echo "*****************************************************"
    
    # Check if the PUT request was successful based on the absence of an <Error> block
    if ! echo "$response" | grep -q "<Error>"; then
        echo "File successfully uploaded."
    else
        # Handle PUT request failure
        echo "Error: PUT request failed. Response: $response"
        exit 1
    fi    
else
    # Handle token request failure
    echo "Error: Token request failed. Response: $token_request"
    exit 1
fi



# token_request=$(curl -X POST https://iam.cloud.ibm.com/identity/token \
#   -H "content-type: application/x-www-form-urlencoded" \
#   -H "accept: application/json" \
#   -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=$GHA_CURRENCY_SERVICE_ID_API_KEY")

# # Check if the token request was successful based on the presence of 'errorCode'
# if [[ $(echo "$token_request" | jq -r '.errorCode') == "null" ]]; then
#     token=$(echo "$token_request" | jq -r '.access_token')
#     echo "bearer token length: ${#token}"
#     echo "bearer token chars: ${token:0:10}"
    
#     # Upload the file and capture response + HTTP status code
#     full_response=$(curl -i -s -w "%{http_code}" -X PUT \
#       -H "Authorization: bearer $token" \
#       -H "Content-Type: application/octet-stream" \
#       -T "$1" \
#       "https://s3.us.cloud-object-storage.appdomain.cloud/ose-power-artifacts-production/$PACKAGE_NAME/$VERSION/$1")

#     http_code="${full_response: -3}"
#     response="${full_response:0:-3}"

#     echo "------------------------------------------------------ Full Resoponse : $full_response"

#     # Check if the PUT request was successful based on the absence of an <Error> block
#     if ! echo "$response" | grep -q "<Error>"; then
#         echo "File successfully uploaded."
#         echo "Response: $response"
#         echo "HTTP status code: $http_code"
#     else
#         echo "Error: PUT request failed."
#         echo "HTTP status code: $http_code"
#         echo "Response: $response"
#         exit 1
#     fi    
# else
#     echo "Error: Token request failed. Response: $token_request"
#     exit 1
# fi
