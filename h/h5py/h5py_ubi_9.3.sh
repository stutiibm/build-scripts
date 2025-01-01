#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : h5py
# Version       : 3.7.0
# Source repo   : https://github.com/h5py/h5py.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=h5py
PACKAGE_VERSION=${1:-3.7.0}
PACKAGE_URL=https://github.com/h5py/h5py.git

# Install dependencies and tools.
yum install -y wget gcc gcc-c++ gcc-gfortran git make  python-devel  openssl-devel unzip libzip-devel.ppc64le gzip.ppc64le
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
yum install -y gcc-c++ cmake make pkgconfig gcc-gfortran hdf5 hdf5-devel

#clone repository 
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip install Cython==0.29.36 numpy==1.21.0 pkgconfig pytest-mpi

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
cd h5py/tests
export PY_IGNORE_IMPORTMISMATCH=1

if ! ( pytest --ignore=test_dataset.py  --ignore=test_h5d_direct_chunk.py --ignore=test_h5t.py --ignore=test_vds/test_highlevel_vds.py --ignore=test_file.py); then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi	