#!/bin/bash

CONFIG_FILE="/path/to/haproxy-config/haproxy.cfg"

echo "
global
    log stdout format raw local0
    maxconn 4096

defaults
    log global
    mode http
    option httplog
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend http_front
    bind *:80
    default_backend web_servers

backend web_servers
    balance roundrobin" > $CONFIG_FILE

# Boucler sur tous les conteneurs qui sont dans le réseau `web_network`
for container in $(docker network inspect web_network --format '{{range .Containers}}{{.Name}} {{end}}')
do
    IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container)
    echo "    server ${container} ${IP}:80 check" >> $CONFIG_FILE
done

# Redémarrer HAProxy pour appliquer la nouvelle configuration
docker kill -s HUP my-haproxy

