VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.box = "centos/7"

  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--ostype", "RedHat_64"]
  end

end
