#!/bin/bash -e

# Log in to IBM Cloud Container Registry
echo "$GHA_CURRENCY_SERVICE_ID_API_KEY" | docker login -u iamapikey --password-stdin icr.io

if [ $? -ne 0 ]; then
    echo "Docker login failed. Exiting script."
    exit 1
fi

# Normalize package name to lowercase
package_name=$(echo $PACKAGE_NAME | tr '[:upper:]' '[:lower:]')

# Define full image path
image_path="icr.io/ose4power-packages-stag/$package_name-ppc64le:$VERSION"

echo "Pulling image: $image_path"
docker pull "$image_path"

if [ $? -ne 0 ]; then
    echo "Docker pull failed. Exiting script."
    exit 1
fi

# Save image as tar file
if [ "$SAVE_AS_TAR" = "true" ]; then
    tar_name="${package_name}_${VERSION}_ppc64le.tar"
    echo "Saving image as tar file: $tar_name"
    docker save -o "$tar_name" "$image_path"
    echo "Image saved successfully: $tar_name"
fi

echo "Verifying if image exists locally..."
docker images
echo "---------------------------------------------------------"
    docker images | grep "${image_path}" || {
      echo "Image not found locally. Download failed or image not loaded."
      exit 1
    }

    echo "Image verified locally: ${image_path}"
    docker inspect "${image_path}" >/dev/null 2>&1 || {
      echo "Docker inspect failed. Image may be corrupted."
      exit 1
    }


# --- Inspect the image ---
echo "Inspecting image metadata..."
if docker inspect "${image_path}" >/dev/null 2>&1; then
    echo "Docker inspect successful. Image integrity verified."
else
    echo "Docker inspect failed for ${image_path}."
    docker images
    exit 1
fi

echo "Image download completed successfully!"
