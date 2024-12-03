# -*- mode: ruby -*-
# vi: set ft=ruby :

### Change here for more memory/cores ###
VM_MEMORY=16384
VM_CORES=8

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.disk :disk, size: "64GB", primary: true
  
  config.vm.provider "vmware_destop" do |v, override|
    v.vmx['memsize'] = VM_MEMORY
    v.vmx['numvcpus'] = VM_CORES
  end

  config.vm.provision "shell", privileged: true, inline:
    "apt-get -q update
     apt-get -q -y install \
        autoconf gcc make qemu qemu-user \
        pkg-config \
        gcc-arm-linux-gnueabihf \
        g++-arm-linux-gnueabihf \
        binutils-arm-linux-gnueabihf \
        gdb-multiarch \
        ncurses-dev \
        clang
     apt-get -q -y autoremove
     apt-get -q -y clean
     wget https://ftp.gnu.org/gnu/autoconf/autoconf-2.72.tar.xz
     tar -xf autoconf-2.72.tar.xz
     cd autoconf-2.72/
     ./configure
     make 
     make install
     cd ..
     mkdir -p bin
     cd bin
     curl -O https://raw.githubusercontent.com/kerl/kerl/master/kerl
     chmod a+x kerl
     cd ..
     export PATH=/home/vagrant/bin:$PATH
     kerl cleanup all
     kerl build-install 27.0 27.0 /usr/local/lib/erlang/27.0
     echo . /usr/local/lib/erlang/27.0/activate >> .bashrc"
  
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder ".", "/home/vagrant/arm32-jit", type: "rsync",
    rsync__args: ["--archive", "-z", "--copy-links", "--update"]

  # We start vagrant rsync-auto in the background
  # Make sure to stop it before changing the machine state
  config.trigger.after :up do |trigger|
    trigger.info = "rsync auto"
    trigger.run = {inline: "zsh -c 'vagrant rsync-auto &'"}
  end

  # Stop rsync-auto when shutting down the machine
  config.trigger.after :halt do |trigger|
    trigger.info= "stop rsync auto"
    trigger.run= {inline: "pkill -f 'vagrant rsync-auto'"}
  end
end
