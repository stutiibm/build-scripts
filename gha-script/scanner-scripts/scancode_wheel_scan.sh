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

# Wheels are built into the workspace root by build_wheels.sh
WHEEL_DIR=$(pwd)

echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
echo "Looking for wheels in: $WHEEL_DIR"
ls "$WHEEL_DIR"/*.whl 2>/dev/null || { echo "No .whl files found in $WHEEL_DIR"; exit 1; }
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

for wheel in "$WHEEL_DIR"/*.whl; do
  echo "Processing: $wheel"

  base_name=$(basename "${wheel%.whl}")
  extract_dir="${WHEEL_DIR}/${base_name}_extract"
  output_json="${WHEEL_DIR}/${base_name}_output.json"

  echo "base name : $base_name"
  echo "extract_dir : $extract_dir"
  echo "output_json : $output_json"

  # Unzip the wheel
  unzip -q "$wheel" -d "$extract_dir"
  echo "------------- unzipped wheel ------------------------------"
  ls "$WHEEL_DIR"

  # Run scancode using the cached binary
  echo "------------------------------------------------------------"
  $SCANCODE_BIN --license --package --json-pp "$output_json" "$extract_dir"

  # Cleanup extract dir to save space
  rm -rf "$extract_dir"

  echo "------------------------- output files ---------------------"
  ls "$WHEEL_DIR"
  echo "------------------------------------------------------------"
  echo "Finished: $wheel"
done
