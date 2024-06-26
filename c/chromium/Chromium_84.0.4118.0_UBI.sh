  
# ----------------------------------------------------------------------------
#
# Package	: chromium
# Version	: 84.0.4118.0
# Source repo	: https://chromium.googlesource.com/chromium/src.git
# Tested on	: UBI 8.4
# Script License: Apache License Version 2.0
# Maintainer	: Amit Sadaphule <amits2@us.ibm.com> / Maniraj Deivendran <maniraj.deivendran@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -ex

# Install dependencies
dnf -y --disableplugin=subscription-manager install \
    http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-2.el8.noarch.rpm \
    http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-2.el8.noarch.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

yum install -y git vim make cmake3 python2 cups-devel pkgconfig nss-devel openssl-devel glib2-devel pango-devel dbus-devel atk-devel at-spi2-atk-devel gtk3-devel krb5-devel pulseaudio-libs-devel libXScrnSaver-devel epel-release subversion curl alsa-lib-devel pciutils-devel mesa-libGLw bison patch bzip2 libuuid-devel mesa-libgbm libsecret-devel python38 python2-psutil python38-psutil java-1.*.0-openjdk-devel libXtst-devel libatomic gcc-c++ expat-devel zlib-devel perl-ExtUtils-MakeMaker wget diffutils libdrm-devel

dnf install -y http://mirror.centos.org/centos/8/PowerTools/ppc64le/os/Packages/gperf-3.1-5.el8.ppc64le.rpm
dnf install -y http://mirror.centos.org/centos/8/PowerTools/ppc64le/os/Packages/mesa-libgbm-devel-20.3.3-2.el8.ppc64le.rpm
dnf install -y http://mirror.centos.org/centos/8/PowerTools/ppc64le/os/Packages/re2c-0.14.3-2.el8.ppc64le.rpm
dnf install -y http://mirror.centos.org/centos/8/PowerTools/ppc64le/os/Packages/ninja-build-1.8.2-1.el8.ppc64le.rpm

alternatives --set python /usr/bin/python2

# Must install nodejs to include already built modules.
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install v12.13.1
ln -s $HOME/.nvm/versions/node/v12.13.1/bin/node /usr/bin/node

cd $HOME
mkdir chromium_build
export CHROMIUM_DIR=$HOME/chromium_build
cd $CHROMIUM_DIR

git clone https://gn.googlesource.com/gn
export CC=gcc
export CXX=g++
export AR=ar
cd gn/
git checkout 5ed3c9cc67b090d5e311e4bd2aba072173e82db9
python build/gen.py --no-static-libstdc++
ninja -C out

unset CXX
unset CC
unset AR 

cd $CHROMIUM_DIR
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export DEPOT_TOOLS_UPDATE=0
export PATH=${CHROMIUM_DIR}/gn/out:$PATH:${CHROMIUM_DIR}/depot_tools
export VPYTHON_BYPASS="manually managed python not supported by chrome operations"
export GYP_DEFINES="disable_nacl=1"

# Downloading the source code
cd $CHROMIUM_DIR
mkdir chromium && cd chromium
gclient config --name "src" --unmanaged https://chromium.googlesource.com/chromium/src.git --custom-var="checkout_nacl=False"

# Remove sync option '--no-history' to resolve gclient sync failure with wayland/src third_party module
gclient sync --nohooks

cd src
git fetch https://chromium.googlesource.com/chromium/src.git +refs/tags/84.0.4118.0:chromium_84.0.4118.0 --depth 1
git checkout chromium_84.0.4118.0

curl -k "https://wiki.raptorcs.com/w/images/1/10/Binutils-download.py-PPC.patch" | patch -p1 third_party/binutils/download.py
rm -rf buildtools/linux64/gn
cp -f $CHROMIUM_DIR/gn/out/gn buildtools/linux64/gn
# Disable gn_version_check since that overwrites power gn with amd64 gn
sed -i '/'\''src\/buildtools\/linux64'\''/,+9d' DEPS
gclient sync --with_branch_heads --with_tags

# check out LLVM and Clang
REVISION=$(grep 'CLANG_REVISION = ' tools/clang/scripts/update.py | awk -F " = " '/CLANG_REVISION = / {print $2}' | tr -d \')
cd $CHROMIUM_DIR
if [ -d "llvm-project" ]; then
    cd llvm-project
    git add -A
    git status
    git reset --hard HEAD
    git fetch
    git status
    cd ../
else
    git clone https://github.com/llvm/llvm-project.git
fi

git -C llvm-project checkout "${REVISION}"

# Build the compiler
mkdir -p llvm_build
cd llvm_build

LLVM_BUILD_DIR=$(pwd)

cmake3 -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="PowerPC" -DLLVM_ENABLE_PROJECTS="clang;lld" -G "Ninja" ../llvm-project/llvm
ninja -j$(nproc)

export PATH=$LLVM_BUILD_DIR/bin/:$PATH

# Patching Chromium
cd $CHROMIUM_DIR
git clone https://github.com/shawnanastasio/chromium_power
cd chromium_power
git checkout 146c60db1ac158ccb6397e3e74f7381b21a638c4

sed -i '/0001-Implement-support-for-PPC64-on-Linux.patch/d' patches.json
sed -i '/prompt_fail_action(e.reason, dest_dir, patch_path, e.output)/d' cpf.py
sed -i '/if not DRY and e.reason != PatchFailReason.ALREADY:/d' cpf.py

python3 cpf.py $CHROMIUM_DIR/chromium/src

cd $CHROMIUM_DIR/chromium/src/third_party/crashpad/crashpad/
cat ../../../../../chromium_power/crashpad/0001-Implement-support-for-PPC64-on-Linux.patch | patch -p1

cd $CHROMIUM_DIR/chromium/src/third_party/ffmpeg
./chromium/scripts/build_ffmpeg.py linux ppc64
./chromium/scripts/generate_gn.py
./chromium/scripts/copy_config.sh

cd $CHROMIUM_DIR/chromium/src/third_party/libvpx
mkdir source/config/linux/ppc64
./generate_gni.sh

cd $CHROMIUM_DIR/chromium/src
curl -k "https://wiki.raptorcs.com/w/images/b/bb/0001-sandbox-linux-seccomp-bpf-helpers-Fix-TCGETS-declara.patch" | patch -p1

# Additional patches for ppc for gn gen failures (20/04/2020)
sed -i '414i  } else if (current_cpu == "ppc64") { \n    sources = libvpx_srcs_ppc64'  third_party/libvpx/BUILD.gn

# Adding power changes to Syscall set files
sed -i -e '/#include <asm\/unistd.h>/a\
#if !defined(__NR_shmdt)\n#define __NR_shmdt 197\n#endif\n\n \
#if !defined(__NR_shmget)\n#define __NR_shmget 194\n#endif\n\n \
#if !defined(__NR_shmctl)\n#define __NR_shmctl 195\n#endif\n\n \
#if !defined(__NR_shmat)\n#define __NR_shmat 196\n#endif\n\n' sandbox/linux/system_headers/ppc64_linux_syscalls.h

perl -i -0pe 's/\(defined\(ARCH_CPU_MIPS_FAMILY\) \&\& defined\(ARCH_CPU_64_BITS\)\)\n\/\/ These give a lot of ambient authority and bypass the setuid sandbox.\nbool SyscallSets::IsSystemVSharedMemory\(int sysno\) \{/\(defined\(ARCH_CPU_MIPS_FAMILY\) \&\& defined\(ARCH_CPU_64_BITS\)\) || \\\n defined\(__powerpc64__\)\n\/\/ These give a lot of ambient authority and bypass the setuid sandbox.\nbool SyscallSets::IsSystemVSharedMemory\(int sysno\) \{/' sandbox/linux/seccomp-bpf-helpers/syscall_sets.cc

perl -i -0pe 's/\(defined\(ARCH_CPU_MIPS_FAMILY\) \&\& defined\(ARCH_CPU_64_BITS\)\)\n\/\/ These give a lot of ambient authority and bypass the setuid sandbox.\n  static bool IsSystemVSharedMemory\(int sysno\);/\(defined\(ARCH_CPU_MIPS_FAMILY\) \&\& defined\(ARCH_CPU_64_BITS\)\) || \\\n defined\(__powerpc64__\)\n\/\/ These give a lot of ambient authority and bypass the setuid sandbox.\n  static bool IsSystemVSharedMemory\(int sysno\);/' sandbox/linux/seccomp-bpf-helpers/syscall_sets.h

# Generate files
gn gen out/Default --args="is_component_build = false is_debug = false enable_nacl = false treat_warnings_as_errors = false enable_dav1d_decoder = false is_clang = true clang_base_path = \"$LLVM_BUILD_DIR\" clang_use_chrome_plugins = false use_lld = false use_glib=true use_gnome_keyring=false"

# Build chromium and chromedriver
ninja -C out/Default chrome
ninja -C out/Default chromedriver

# To verify chrome binary
cd out/Default/
./chrome --version
./chromedriver --version

