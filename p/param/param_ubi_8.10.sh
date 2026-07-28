#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : param
# Version          : v2.2.0
# Source repo      : https://github.com/holoviz/param.git
# Tested on        : UBI:8.10
# Language         : Python
# Ci-Check     : True
# Script License   : GNU General Public License v3.0
# Maintainer       : Anumala Rajesh <Anumala.Rajesh@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=param
PACKAGE_VERSION=${1:-v2.2.0}
PACKAGE_URL=https://github.com/holoviz/param.git

yum install -y git python3.12 python3.12-devel python3.12-pip gcc make wget sudo
python3.12 -m pip install ez_setup nose pytest --ignore-installed
python3.12 -m pip install pytest tox pytest-asyncio

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! pytest ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
