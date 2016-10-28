# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "private_network", ip: "10.2.2.2"
  config.vm.hostname = "vmlemp"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = "2"
    vb.memory = "1024"
  end

  config.vm.provision :shell, path: "bootstrap.sh"
end
