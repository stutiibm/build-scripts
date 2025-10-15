#!/bin/bash -e

# validate_build_script=$VALIDATE_BUILD_SCRIPT
# cloned_package=$CLONED_PACKAGE

#cd package-cache

#if [ "$validate_build_script" == true ]; then  
  
  echo "------------------Installing ScanCode Toolkit..."
  SCANCODE_VERSION=v32.4.0
  echo "===============wgetting=================="
  wget https://github.com/nexB/scancode-toolkit/archive/refs/tags/${SCANCODE_VERSION}.tar.gz
  echo "===============tarring=================="
  tar -xzf ${SCANCODE_VERSION}.tar.gz
  SCANCODE_DIR="scancode-toolkit-${SCANCODE_VERSION#v}"
  cd $SCANCODE_DIR
  echo "===============Python version=================="
  python --version
  echo "===============Python version=================="
  # python -m pip install -e .
  # export PYTHONWARNINGS="ignore"
  # export PATH=$HOME/scancode-toolkit/venv/bin:$PATH
  # scancode --version
#fi
