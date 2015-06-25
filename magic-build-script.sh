#!/bin/bash

# Setup/install LLVM Linux
# Steps (high-level) from http://llvm.linuxfoundation.org/index.php/Main_Page

# Variables
SCRIPT_ROOT=/vagrant
FETCH_ROOT=/home/vagrant

print_info() {
  if [[ $1 != "" ]]; then
    DIV="++++++++++++"
    echo -e "\n$DIV $(echo "$1" | tr [a-z] [A-Z]) $DIV\n"
  fi
}

print_clone_to() {
  if [[ $1 != "" && $2 != "" ]]; then
    echo "Cloning $1 to $(pwd)/$2"
  fi
}

print_src_found() {
  if [[ $1 != "" && $2 != "" ]]; then
    echo "$1 found at $(pwd)/$2"
  fi
}

install-pkg() {
if [[ $1 != "" ]]; then
  PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $1 | grep "$1 already installed")
  print_info "Checking for $1 ... $PKG_OK"
  if [ "" == "$PKG_OK" ]; then
    echo "$1 not found; setting up $1."
    sudo apt-get --force-yes --yes install $1
  else
    echo "$1 is installed"
  fi
fi
}

add_ppa() {
  grep -h "$1" /etc/apt/sources.list > /dev/null 2>&1
  if [ $? -ne 0 ]
  then
    echo "Adding $1"
    sudo add-apt-repository "$1"
    return 0
  fi

  echo "Repo $1 already exists"
  return 1
}

declare -a LLVM_REPO_RA=("deb http://llvm.org/apt/trusty llvm-toolchain-trusty main"
  "deb http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.6 main")
# Clang 3.5:
# "deb http://llvm.org/apt/trusty llvm-toolchain-trusty-3.5 main"

declare -a INSTALL_RA=("git" "cmake" "subversion" "mercurial")

print_info "Adding repos"
# LLVM nighly package - 3.6
for r in "${LLVM_REPO_RA[@]}"; do
  add_ppa "$r"
done


print_info "Installing git and dependencies"
for p in "${INSTALL_RA[@]}"; do
  install-pkg "$p"
done

print_info "Installing clang and LLVM from source to $(pwd)"
print_info "Getting LLVM"
cd ${SCRIPT_ROOT}
if [ ! -d "llvm" ]; then
  print_clone_to "LLVM" "llvm" 
  svn co http://llvm.org/svn/llvm-project/llvm/trunk llvm
fi
  print_src_found "LLVM" "llvm"

print_info "Getting Clang"
cd ${SCRIPT_ROOT}/llvm/tools
if [ ! -d "clang" ]; then
  print_clone_to "Clang""clang"
  svn co http://llvm.org/svn/llvm-project/cfe/trunk clang
else
  print_src_found "Clang" "clang"
fi

print_info "Getting Clang extra tools"
cd ${SCRIPT_ROOT}/llvm/tools/clang/tools
# Check out extra Clang tools
if [ ! -d "extra" ]; then
  print_clone_to "Clang extra tools" "extra"
  svn co http://llvm.org/svn/llvm-project/clang-tools-extra/trunk extra
else
  print_src_found "Clang extra tools" "extra"
fi

print_info "Getting compiler-rt"
cd ${SCRIPT_ROOT}/llvm/projects
if [ ! -d "compiler-rt" ]; then
  print_clone_to "compiler-rt" "compiler-rt"
  svn co http://llvm.org/svn/llvm-project/compiler-rt/trunk compiler-rt
else
  print_src_found "compiler-rt" "compiler-rt"
fi

##
# Copy SSH key.
##

cd ${HOME}
print_info "Copying SSH key to $(pwd)/.ssh"
if [ ! -d ".ssh" ]; then
  cp ${SCRIPT_ROOT}/ssh/* ~/.ssh/ 2>/dev/null || :
  chmod -f 0600 ${HOME}/.ssh/id_rsa*
  chmod -f 0600 ${HOME}/.ssh/known_hosts
  echo "Done copying SSH key"
else
  echo "Already copied"
fi

cd ${FETCH_ROOT}
print_info "Getting Slice"
if [ ! -d "xen-slicing-pq.hg" ]; then
  echo "If you are not using Windows, you may need to VPN into UBC"
  read -p "Hit <Enter> once connected, or to skip this step" key
  echo "Cloning from xen-slicing-pq.hg nss.cs.ubc.ca to $(pwd)/xen-slicing-pq.hg"
  hg clone ssh://hg@hg.nss.cs.ubc.ca/disaggregation/xen-slicing-pq.hg
else
  echo "Already exists"
fi
print_info "Copying Slice to LLVM - $SCRIPT_ROOT/llvm/lib/Transforms/Slice"
cp -r ${FETCH_ROOT}/xen-slicing-pq.hg/Slice ${SCRIPT_ROOT}/llvm/lib/Transforms/
 

# LLVMLinux kernel tree - recent mainline with latest LLVMLinux patches applied
cd ${SCRIPT_ROOT}
if [ ! -d "kernel" ]; then
  NOW=$(date)
  LATER=$(date -d "$NOW +20 min" +"%H:%M")
  print_info "git clone LLVMLinux into $(pwd)/kernel; please check back at about $LATER"
  git clone git://git.linuxfoundation.org/llvmlinux/kernel.git
  print_info "LLVMLinux repo cloned. Getting makefile"
  cd ${SCRIPT_ROOT}/kernel
  wget http://buildbot.llvm.linuxfoundation.org/makefile
  echo "$SCRIPT_ROOT/kernel/makefile default is to use clang; edit further for other options if needed."
else
  echo "LLVMLinux has been cloned in $SCRIPT_ROOT/kernel/"
fi

# Do buidls
cd ${SCRIPT_ROOT}
if [ ! -d "build" ]; then
  mkdir ${SCRIPT_ROOT}/build
fi
echo "Build LLVM? Enter 1 or 2"
BUILD_OPTS=("Yes" "No")
select yn in "${BUILD_OPTS[@]}"; do
  case $yn in
    "Yes" )
      cd ${SCRIPT_ROOT}/build
      print_info "Building llvm in $(pwd)"
      cmake -G "Unix Makefiles" ../llvm
      make
      break;;
    "No" )
      echo "Build of LLVM skipped."
      break;;
  esac
done


cd ${SCRIPT_ROOT}/build/tools/clang
echo "It is a good idea to run the Clang tests to make sure your build works correctly."
echo "Run 'make test' to run the Clang tests? Enter 1 or 2"
BUILD_OPTS=("Yes" "No")
select yn in "${BUILD_OPTS[@]}"; do
  case $yn in
    "Yes" )
      print_info "Running Clang  tests in $(pwd)"
      sudo make test
      break;;
    "No" )
      echo "Clang tests not run."
      break;;
  esac
done


echo "make install clang? Enter 1 or 2"
BUILD_OPTS=("Yes" "No")
select yn in "${BUILD_OPTS[@]}"; do
  case $yn in
    "Yes" )
      print_info "make install on clang in $(pwd)"
      sudo make install
      break;;
    "No" )
      echo "Clang not installed."
      break;;
  esac
done


print_info "All done!"
