#!/bin/bash -e

echo "-----------------Uploading docker image---------------------------"

echo "$travis_currency_service_id_api_key_dev" | docker login -u "iamapikey" --password-stdin icr.io
if [ $? -ne 0 ]; then
    echo "Docker login failed. Exiting script."
    exit 1
fi
echo "----------------Lowering package name--------------------------"
package_name=$(echo $PACKAGE_NAME | tr '[:upper:]' '[:lower:]')
echo "-----------------Tagging image---------------------------"

docker tag $IMAGE_NAME icr.io/ose4power-packages/$package_name-ppc64le:$VERSION
echo "-----------------Pushing image---------------------------"
docker push "icr.io/ose4power-packages/$package_name-ppc64le:$VERSION"
if [ $? -ne 0 ]; then
    echo "Docker push failed. Exiting script."
    exit 1
fi

