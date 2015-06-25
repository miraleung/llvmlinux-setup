# LLVM Linux Setup

Scripts to set up a fresh Linux OS for building LLVM Linux

### Steps to setup the VM and run magic build scripts
1. Set up a fresh Ubuntu 14.04 VM
2. In VirtualBox, increase the VM’s allocated memory to 2MB
3. Resize the existing virtual disk to 20 GB as per this [Gist](https://gist.github.com/miraleung/5fe18f7d68994024862a)
  1. Yes, the cloning and building will use up more than vagrant’s default 8 GB
4. Copy xen-slicing-pq.hg and build scripts into vagrant
  ```
  OPTIONS=`vagrant ssh-config | grep -v '^Host ' | awk -v ORS=' ' 'NF{print "-o " $1 "=" $2}'`
  scp -r ${OPTIONS} /path/to/xen-slicing-pq.hg vagrant:~/
  scp ${OPTIONS} /path/to/magic-build-script.sh vagrant:~/
  scp ${OPTIONS} /path/to/increase_swap.sh vagrant:~/
  ```
  1. Increases from 512 MB to 2 GB; otherwise LLVM build will fail at ~96% completion
5. vagrant ssh
6. sudo ./increase_swap.sh
7. sudo ./magic-build-script.sh
  1. Will prompt for “Build LLVM Linux? 1) Y 2) N” after dependencies are installed and sources are cloned.
8. Done
