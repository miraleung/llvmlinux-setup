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

declare -a INSTALL_RA=("git" "cmake" "subversion" "mercurial" "gparted"
"build-essential" "git-svn" "kpartx" "libglib2.0-dev" "patch" "quilt"
"rsync" "zlib1g-dev" "flex" "libfdt1" "libfdt-dev" "libpixman-1-0"
"libpixman-1-dev" "libc6:i386" "libncurses5:i386" "linaro-image-tools")

print_info "Installing git and dependencies"
for p in "${INSTALL_RA[@]}"; do
  install-pkg "$p"
done

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


print_info "Getting LLVM Linux"
cd ${SCRIPT_ROOT}
if [ ! -d "llvmlinux" ]; then
  print_clone_to "LLVM Linux" "llvmlinux"
  git clone http://git.linuxfoundation.org/llvmlinux.git
else
  print_src_found "LLVM Linux" "llvmlinux"
fi


# Do builds
cd ${SCRIPT_ROOT}/llvmlinux/x86_64
echo "Build LLVM Linux, Clang, and LLVM? Enter 1 or 2"
BUILD_OPTS=("Yes" "No")
select yn in "${BUILD_OPTS[@]}"; do
  case $yn in
    "Yes" )
      print_info "Building llvmlinux in $(pwd); target is x86_64"
      sudo make
      break;;
    "No" )
      echo "Build of LLVM Linux skipped."
      break;;
  esac
done


cho "Run 'make test' on LLVM Linux? Enter 1 or 2"
BUILD_OPTS=("Yes" "No")
select yn in "${BUILD_OPTS[@]}"; do
  case $yn in
    "Yes" )
      print_info "Running LLVM Linux tests in $(pwd)"
      sudo make test
      break;;
    "No" )
      echo "LLVM Linux tests not run."
      break;;
  esac
done


print_info "All done!"
echo -e "To update and rebuild the sources for the target and its dependencies, run:\n\t\tmake sync-all\n\t\tmake\n"
