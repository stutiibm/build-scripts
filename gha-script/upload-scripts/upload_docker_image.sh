#!/bin/bash -e

echo "-----------------Uploading docker image---------------------------"
echo "Checking DNS resolution for icr.io"
dig icr.io || nslookup icr.io
echo "-----------------logging in docker---------------------------"
echo "$travis_currency_service_id_api_key_dev" | docker login -u "iamapikey" --password-stdin icr.io
if [ $? -ne 0 ]; then
    echo "Docker login failed. Exiting script."
    exit 1
fi
echo "----------------Lowering package name--------------------------"
package_name=$(echo $PACKAGE_NAME | tr '[:upper:]' '[:lower:]')
echo "-----------------Tagging image---------------------------"

echo "----------------Validating required environment variables---------------------------"

missing_vars=0

if [[ -z "$PACKAGE_NAME" ]]; then
    echo "❌ PACKAGE_NAME is not set"
    missing_vars=1
fi

if [[ -z "$IMAGE_NAME" ]]; then
    echo "❌ IMAGE_NAME is not set"
    missing_vars=1
fi

if [[ -z "$VERSION" ]]; then
    echo "❌ VERSION is not set"
    missing_vars=1
fi

if [[ $missing_vars -eq 1 ]]; then
    echo "❌ One or more required environment variables are missing. Exiting script."
    exit 1
fi


docker tag $IMAGE_NAME icr.io/ose4power-packages/$package_name-ppc64le:$VERSION
echo "-----------------Pushing image---------------------------"
docker push "icr.io/ose4power-packages/$package_name-ppc64le:$VERSION"
if [ $? -ne 0 ]; then
    echo "Docker push failed. Exiting script."
    exit 1
fi

