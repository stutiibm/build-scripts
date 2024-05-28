#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : nbconvert
# Version       : v7.16.4
# Source repo   : https://github.com/jupyter/nbconvert
# Tested on     : UBI: 9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=nbconvert
PACKAGE_VERSION=${1:-v7.16.4}
PACKAGE_URL=https://github.com/jupyter/nbconvert
HOME_DIR=${PWD}

yum install -y wget git python3 python3-devel gcc gcc-c++

# miniconda installation 
wget https://repo.anaconda.com/miniconda/Miniconda3-py39_23.10.0-1-Linux-ppc64le.sh -O miniconda.sh 
bash miniconda.sh -b -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"
conda create -n $PACKAGE_NAME python=3.9 -y
eval "$(conda shell.bash hook)"
conda activate $PACKAGE_NAME
python3 -m pip install -U pip
conda install --yes -c conda-forge hatch

# Clone package repository
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3 -m pip install --upgrade pip
pip install jupyter
export JUPYTER_PLATFORM_DIRS=1
jupyter notebook --generate-config
find / -name jupyter*config.py
jupyter --paths

# Install
if ! python3 -m pip install -e .; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

pip install -e ".[test]"
export JUPYTER_PATH=/root/.config/jupyter

# Test
if ! hatch run test:nowarn; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 2
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	exit 0
fi