#!/usr/bin/env bash

SERVER_COUNT=${SERVER_COUNT}
CONSUL_VERSION=${CONSUL_VERSION}

# Install packages

which unzip socat jq dig route vim curl sshpass &>/dev/null || {
    apt-get update -y
    apt-get install unzip socat net-tools jq dnsutils vim curl sshpass -y 
}

#####################
# Installing consul #
#####################
sudo mkdir -p /vagrant/pkg

which consul || {
    # consul file exist.
    CHECKFILE="/vagrant/pkg/consul_${CONSUL_VERSION}_linux_amd64.zip"
    if [ ! -f "$CHECKFILE" ]; then
        pushd /vagrant/pkg
        wget https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
        popd
 
    fi
    
    pushd /usr/local/bin/
    unzip /vagrant/pkg/consul_${CONSUL_VERSION}_linux_amd64.zip 
    sudo chmod +x consul
    popd
}

killall consul

sudo mkdir -p /etc/consul.d /vagrant/consul_logs

###########################
# Starting consul servers #
###########################
IPs=$(hostname -I | cut -f2 -d' ')
HOST=$(hostname)

set +x

if [[ $HOST =~ consul-server01 ]]; then

sudo mkdir -p /etc/consul.d/ssl/

    pushd /etc/consul.d/ssl/
        consul tls ca create
        consul tls cert create -server
        consul tls cert create -cli
    popd

sudo cat <<EOF > /etc/consul.d/ssl/config.json
{
  "verify_incoming": false,
  "verify_outgoing": true,
  "verify_server_hostname": true,
  "ca_file": "/etc/consul.d/ssl/consul-agent-ca.pem",
  "cert_file": "/etc/consul.d/ssl/dc1-server-consul-0.pem",
  "key_file": "/etc/consul.d/ssl/dc1-server-consul-0-key.pem",
  "ports": {
    "http": -1,
    "https": 8501
  }
}
EOF

    consul agent -server -ui -bind 0.0.0.0 -advertise $IPs -client 0.0.0.0 -data-dir=/tmp/consul \
-bootstrap-expect=$SERVER_COUNT -config-dir=/etc/consul.d/ssl/ -retry-join=192.168.56.52 \
-retry-join=192.168.56.51 > /vagrant/consul_logs/$HOST.log & 

elif [[ $HOST =~ consul-server* ]]; then

sudo mkdir -p /etc/consul.d/ssl/

pushd /etc/consul.d/ssl/
    sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no vagrant@192.168.56.51:"/etc/consul.d/ssl/consul-agent-ca*" /etc/consul.d/ssl/
    consul tls cert create -server
    consul tls cert create -cli
popd


sudo cat <<EOF > /etc/consul.d/ssl/config.json
{
  "verify_incoming": false,
  "verify_outgoing": true,
  "verify_server_hostname": true,
  "ca_file": "/etc/consul.d/ssl/consul-agent-ca.pem",
  "cert_file": "/etc/consul.d/ssl/dc1-server-consul-0.pem",
  "key_file": "/etc/consul.d/ssl/dc1-server-consul-0-key.pem",
  "ports": {
    "http": -1,
    "https": 8501
  }
}
EOF

    consul agent -server -ui -bind 0.0.0.0 -advertise $IPs -client 0.0.0.0 -data-dir=/tmp/consul \
-bootstrap-expect=$SERVER_COUNT -config-dir=/etc/consul.d/ssl/ -retry-join=192.168.56.52 \
-retry-join=192.168.56.51 > /vagrant/consul_logs/$HOST.log & 

else

sudo mkdir -p /etc/consul.d/ssl/

pushd /etc/consul.d/ssl/
    sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no vagrant@192.168.56.51:"/etc/consul.d/ssl/consul-agent-ca*" /etc/consul.d/ssl/
    consul tls cert create -client
    consul tls cert create -cli
popd


sudo cat <<EOF > /etc/consul.d/ssl/config.json
{
  "verify_incoming": false,
  "verify_outgoing": true,
  "verify_server_hostname": true,
  "ca_file": "/etc/consul.d/ssl/consul-agent-ca.pem",
  "cert_file": "/etc/consul.d/ssl/dc1-client-consul-0.pem",
  "key_file": "/etc/consul.d/ssl/dc1-client-consul-0-key.pem",
  "ports": {
    "http": -1,
    "https": 8501
  }
}
EOF

    consul agent -ui -bind 0.0.0.0 -advertise $IPs -client 0.0.0.0 -data-dir=/tmp/consul \
 -enable-script-checks=true -config-dir=/etc/consul.d/ssl/ -retry-join=192.168.56.52 \
 -retry-join=192.168.56.51 > /vagrant/consul_logs/$HOST.log & 

fi
set -x
sleep 5

	consul members -ca-file=/etc/consul.d/ssl/consul-agent-ca.pem -client-cert=/etc/consul.d/ssl/dc1-cli-consul-0.pem \
-client-key=/etc/consul.d/ssl/dc1-cli-consul-0-key.pem -http-addr="https://127.0.0.1:8501"
