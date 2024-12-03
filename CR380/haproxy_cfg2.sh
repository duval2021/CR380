#!/bin/bash

CONFIG_FILE="/home/guillaume/haproxy.cfg"
DOCKER_NETWORK="web_network"

# Generate the HAProxy configuration file
cat <<EOF > $CONFIG_FILE
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
    # ACLs to match specific paths
EOF

# Function to add ACLs and backends dynamically
add_backend() {
    local service_name=$1
    local path=$2
    local backend_name="${service_name}_backend"

    # Add ACL and backend directive to frontend
    echo "    acl is_${service_name} path_beg ${path}" >> $CONFIG_FILE
    echo "    use_backend ${backend_name} if is_${service_name}" >> $CONFIG_FILE

    # Add backend configuration
    echo "
backend ${backend_name}
    balance roundrobin
" >> $CONFIG_FILE

    # Add servers for the backend
    for container in $(docker ps --filter "name=${service_name}" --format "{{.Names}}"); do
        IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container)
        echo "    server ${container} ${IP}:80 check" >> $CONFIG_FILE
    done
}

# Add specific service backends
add_backend "service1" "/service1"
add_backend "service2" "/service2"

# Add a default backend
cat <<EOF >> $CONFIG_FILE

    # Default backend
    default_backend default_backend

backend default_backend
    balance roundrobin
EOF

for container in $(docker ps --filter "name=default" --format "{{.Names}}"); do
    IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container)
    echo "    server ${container} ${IP}:80 check" >> $CONFIG_FILE
done

# Reload or run HAProxy container
if docker ps --filter "name=my-haproxy" --format '{{.Names}}' | grep -q '^my-haproxy$'; then
    echo "Reloading HAProxy configuration..."
    docker kill -s HUP my-haproxy
else
    echo "Starting HAProxy container..."
    docker run -d --name my-haproxy --network ${DOCKER_NETWORK} -v $(dirname $CONFIG_FILE):/usr/local/etc/haproxy:ro -p 80:80 haproxy:latest
fi

