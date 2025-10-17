#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
cloned_package=$CLONED_PACKAGE

#cd package-cache

#if [ "$validate_build_script" == true ]; then  
  
  # echo "------------------Installing ScanCode Toolkit..."
  # SCANCODE_VERSION=v32.4.0
  # echo "===============wgetting=================="
  # wget https://github.com/nexB/scancode-toolkit/archive/refs/tags/${SCANCODE_VERSION}.tar.gz
  # echo "===============tarring=================="
  # tar -xzf ${SCANCODE_VERSION}.tar.gz
  # SCANCODE_DIR="scancode-toolkit-${SCANCODE_VERSION#v}"
  # cd $SCANCODE_DIR
  # echo "===============Python version=================="
  # python --version
  # echo "===============Python version=================="


echo "----------Installing-----------------"
#sudo apt update -y && sudo apt-get install file git python3.12 python3.12-pip python3.12-devel gcc gcc-c++ make unzip patch wget tar which findutils libffi-devel zlib-devel openssl-devel libxml2 libxml2-devel libxslt libxslt-devel libicu-devel pkgconfig libicu-devel pkgconf-pkg-config -y
sudo apt update -y && sudo apt install -y file git python3.12 python3.12-venv python3-pip python3.12-dev build-essential unzip patch wget tar libffi-dev zlib1g-dev libssl-dev libxml2-dev libxslt1-dev libicu-dev pkg-config

echo "----------Installed dependencies-----------------"
git clone https://github.com/nexB/scancode-toolkit.git
cd scancode-toolkit
git checkout v32.4.0
echo "-------------- Create venv ------------------"
python --version
echo "========================================="
python3.12 -m venv venv
source venv/bin/activate
python3.12 -m pip install --upgrade pip setuptools wheel typecode pyahocorasick 

echo "--------------- Apply changes ----------------"
sed -i '/typecode\[full\] >= 30\.0\.1/s/^/    # /' setup.cfg
sed -i '/extractcode\[full\] >= 31\.0\.0/s/^/    # /' setup.cfg
sed -i '/typecode\[full\] >= 30\.0\.0/s/^/    # /' setup.cfg

echo "------------- Install scancode-toolkit ---------------"
python3.12 -m pip install -e .
python3.12 -m pip install click==8.0.4
echo "------------- scancode version ---------------"
scancode --version

echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
cd ..
ls 
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
cd package-cache/wheels

#find package-cache/wheels -type f -name "*.whl" | while IFS= read -r wheel; do
for wheel in *.whl; do
  echo "Processing: $wheel"
  
  base_name="${wheel%.whl}"  # Strip .whl extension
  extract_dir="${base_name}_extract"
  output_json="${base_name}_output.json"
  #output_zip="${base_name}_output.zip"

  echo "base name : $base_name"
  echo "extract_dir : $extract_dir"
  echo "output_json : $output_json"
  #echo "output_zip : $output_zip"
  

  # Unzip the wheel
  echo "------------- unzipping wheel ------------------------------"
  cd package-cache/wheels
  ls 
  echo "------------- unzippied wheel ------------------------------"
  unzip -q "$wheel" -d "$extract_dir"
  echo "??????????????????????????????????"
  ls
  
  
  # Run scancode
 
  echo "****************************************************************"
 
  ../../scancode-toolkit/venv/bin/scancode --license --package --json-pp "$output_json" "$extract_dir"

  # Zip the result
  echo "------------------------- output files ---------------------"
  ls
  echo "------------------------------------------------------------"
  cat $output_json
  echo "------------------------------------------------------------"
  #zip -q "$output_zip" "$output_json"

  echo "Finished: $wheel"
  #echo "Output: $output_zip"
  echo "==========================================="
done




  # python -m pip install -e .
  # export PYTHONWARNINGS="ignore"
  # export PATH=$HOME/scancode-toolkit/venv/bin:$PATH
  # scancode --version
#fi
