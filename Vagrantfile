# -*- mode: ruby -*-
# vi: set ft=ruby :

### Change here for more memory/cores ###
VM_MEMORY=16384
VM_CORES=8

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.disk :disk, size: "64GB", primary: true

  config.vm.provider "vmware_desktop" do |v|
    v.vmx["memsize"] = VM_MEMORY
    v.vmx["numvcpus"] = VM_CORES
  end

  config.vm.provider "virtualbox" do |v|
    v.memory = VM_MEMORY
    v.cpus = VM_CORES
  end

  config.vm.provision "shell", privileged: true, path: "vagrant_provision.sh"

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder ".", "/home/vagrant/arm32-jit", type: "rsync",
    rsync__args: ["--archive", "-z", "--copy-links", "--update"]

  # We start vagrant rsync-auto in the background
  # Make sure to stop it before changing the machine state
  config.trigger.after :up do |trigger|
    trigger.info = "rsync auto"
    trigger.run = {inline: "sh -c 'vagrant rsync-auto &'"}
  end

  # Stop rsync-auto when shutting down the machine
  config.trigger.after :halt do |trigger|
    trigger.info= "stop rsync auto"
    trigger.run= {inline: "pkill -f 'vagrant rsync-auto'"}
  end
end
