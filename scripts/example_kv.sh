#!/usr/bin/env bash

# Consul CMD - add value

consul kv put my-key-cmd 'Hello Consul from cmd!!!'
consul kv get my-key-cmd
consul kv get -detailed my-key-cmd
consul kv delete my-key-cmd

# API add value
curl -s \
    --request PUT \
    --data 'Hello Consul API!!!' \
    http://127.0.0.1:8500/v1/kv/my-key

# Get encrypted value
curl -s \
    http://127.0.0.1:8500/v1/kv/my-key | jq '.'

# Reading value raw
echo $(curl -s 127.0.0.1:8500/v1/kv/my-key?raw)

# Hard way
curl -s 127.0.0.1:8500/v1/kv/my-key | jq -r '.[0].Value' | base64 --decode

# Deleting value
curl -s \
    --request DELETE \
    http://127.0.0.1:8500/v1/kv/my-key





   