#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
cloned_package=$CLONED_PACKAGE

# Use pre-installed scancode from the cached artifact
# $SCANCODE_BIN is set by the workflow (points to scan-tools-venv/bin/scancode)
if [ -z "$SCANCODE_BIN" ]; then
  echo "Error: SCANCODE_BIN environment variable not set"
  exit 1
fi

echo "------------- Using cached scancode ---------------"
$SCANCODE_BIN --version

echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
ls 
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
cd package-cache/wheels

for wheel in *.whl; do
  echo "Processing: $wheel"
  
  base_name="${wheel%.whl}"  # Strip .whl extension
  extract_dir="${base_name}_extract"
  output_json="${base_name}_output.json"

  echo "base name : $base_name"
  echo "extract_dir : $extract_dir"
  echo "output_json : $output_json"
 
  # Unzip the wheel
  unzip -q "$wheel" -d "$extract_dir"
  echo "------------- unzipped wheel ------------------------------"
  ls
  
  # Run scancode using the cached binary
  echo "------------------------------------------------------------"
  $SCANCODE_BIN --license --package --json-pp "$output_json" "$extract_dir"

  # Cleanup extract dir to save space
  rm -rf "$extract_dir"
  
  echo "------------------------- output files ---------------------"
  ls
  echo "------------------------------------------------------------"
  echo "Finished: $wheel"
done
