SERVER_COUNT = 3
CLIENT_COUNT = 2
CONSUL_VERSION = '1.4.1'

Vagrant.configure(2) do |config|
    config.vm.box = "chavo1/xenial64base"
    config.vm.provider "virtualbox" do |v|
      v.memory = 512
      v.cpus = 2
    
    end

    1.upto(SERVER_COUNT) do |n|
      config.vm.define "consul-server0#{n}" do |server|
        server.vm.hostname = "consul-server0#{n}"
        server.vm.network "private_network", ip: "192.168.56.#{50+n}"
        server.vm.provision "shell",inline: "cd /vagrant ; bash scripts/consul.sh", env: {"CONSUL_VERSION" => CONSUL_VERSION, "SERVER_COUNT" => SERVER_COUNT}

      end
    end

    1.upto(CLIENT_COUNT) do |n|
      config.vm.define "consul-client0#{n}" do |client|
        client.vm.hostname = "consul-client0#{n}"
        client.vm.network "private_network", ip: "192.168.56.#{60+n}"
        client.vm.provision "shell",inline: "cd /vagrant ; bash scripts/consul.sh", env: {"CONSUL_VERSION" => CONSUL_VERSION}
        client.vm.provision "shell",inline: "cd /vagrant ; bash scripts/kv.sh"
        client.vm.provision "shell",inline: "cd /vagrant ; bash scripts/nginx.sh"
        
      end
    end
  end
