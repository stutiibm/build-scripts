#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
cloned_package=$CLONED_PACKAGE

# Use pre-installed grype from the cached artifact
# $GRYPE_BIN is set by the workflow (points to scan-tools-bin/grype)
if [ -z "$GRYPE_BIN" ]; then
  echo "Error: GRYPE_BIN environment variable not set"
  exit 1
fi

sudo apt update -y && sudo apt install -y jq

echo "------------- Using cached grype ---------------"
$GRYPE_BIN version

echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
ls 
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
cd package-cache/wheels

for wheel in *.whl; do
  echo "Processing: $wheel"
  
  base_name="${wheel%.whl}"  # Strip .whl extension
  extract_dir="${base_name}_extract"
  output_json="${base_name}_grype_output.json"

  echo "base name : $base_name"
  echo "extract_dir : $extract_dir"
  echo "output_json : $output_json"
 
  # Unzip the wheel
  unzip -q "$wheel" -d "$extract_dir"
  echo "------------- unzipped wheel ------------------------------"
  ls
  
  # Run grype scanner using the cached binary
  echo "------------------------------------------------------------"
  $GRYPE_BIN "$extract_dir" -o json | jq . > "$output_json"

  # Cleanup extract dir to save space
  rm -rf "$extract_dir"

  echo "------------------------- output files ---------------------"
  ls
  echo "------------------------------------------------------------"
  echo "Finished: $wheel"
done
