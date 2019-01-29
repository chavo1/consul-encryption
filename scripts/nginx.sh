#!/usr/bin/env bash

which nginx &>/dev/null || {
    sudo apt get update -y
    sudo apt install nginx -y
    }

service nginx stop

IPs=$(hostname -I | cut -f2 -d' ')
HOST=$(hostname)

sudo mkdir -p /vagrant/pkg

# If we need envconsul
if which envconsul >/dev/null; then

echo $nginx > /var/www/html/index.nginx-debian.html

# Another examples
# envconsul -pristine -prefix nginx env | sed 's/consul-client01=//g' > /var/www/html/index.nginx-debian.html
# export `envconsul -pristine -prefix nginx env`; env

# If we consul-template
elif  which consul-template >/dev/null; then

set -x
export HOST=$HOST
consul-template -config=/vagrant/templates/config.hcl > /vagrant/consul_logs/template_$HOST.log & 
set +x

else
  
  # Updating nginx start page with API
set -x
rm /var/www/html/index.nginx-debian.html
sudo curl -s --cacert /etc/consul.d/ssl/consul-agent-ca.pem https://127.0.0.1:8501/v1/kv/$HOST/nginx?raw > /var/www/html/index.nginx-debian.html

fi

service nginx start

sudo mkdir -p /etc/consul.d

#####################
# Register services #
#####################
sudo cat <<EOF > /etc/consul.d/ssl/web.json
{
  "service": {
    "name": "web",
    "tags": ["$HOST"],
    "port": 80,
  "check": {
    "args": ["curl", "127.0.0.1"],
    "interval": "3s"
    }
  }
}
EOF

sudo cat <<EOF > /etc/consul.d/ssl/http.json
{
  "check": {
    "id": "http",
    "name": "http TCP on port 80",
    "tcp": "127.0.0.1:80",
    "interval": "10s",
    "timeout": "1s"
  }
}
EOF

consul reload -ca-file=/etc/consul.d/ssl/consul-agent-ca.pem -client-cert=/etc/consul.d/ssl/dc1-cli-consul-0.pem \
  -client-key=/etc/consul.d/ssl/dc1-cli-consul-0-key.pem -http-addr="https://127.0.0.1:8501"

consul members -ca-file=/etc/consul.d/ssl/consul-agent-ca.pem -client-cert=/etc/consul.d/ssl/dc1-cli-consul-0.pem \
  -client-key=/etc/consul.d/ssl/dc1-cli-consul-0-key.pem -http-addr="https://127.0.0.1:8501"

  set +x