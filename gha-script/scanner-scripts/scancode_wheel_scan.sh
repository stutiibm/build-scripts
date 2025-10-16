#!/bin/bash -e

# validate_build_script=$VALIDATE_BUILD_SCRIPT
# cloned_package=$CLONED_PACKAGE

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
sudo apt update -y && sudo apt-get install file git python3.12 python3.12-pip python3.12-devel gcc gcc-c++ make unzip patch wget tar which findutils libffi-devel zlib-devel openssl-devel libxml2 libxml2-devel libxslt libxslt-devel libicu-devel pkgconfig libicu-devel pkgconf-pkg-config -y
echo "----------Installed dependencies-----------------"
git checkout v32.4.0
echo "-------------- Create venv ------------------"
which icu-config
echo "========================================="
icu-config --version
python3.12 -m venv venv
source venv/bin/activate
python3.12 -m pip install --upgrade pip setuptools wheel typecode pyahocorasick

echo "--------------- Apply changes ----------------"
sed -i '/typecode\[full\] >= 30\.0\.1/s/^/    # /' setup.cfg
sed -i '/extractcode\[full\] >= 31\.0\.0/s/^/    # /' setup.cfg
sed -i '/typecode\[full\] >= 30\.0\.0/s/^/    # /' setup.cfg

echo "------------- Install scancode-toolkit ---------------"
python3.12 -m pip install -e .

  # python -m pip install -e .
  # export PYTHONWARNINGS="ignore"
  # export PATH=$HOME/scancode-toolkit/venv/bin:$PATH
  # scancode --version
#fi
