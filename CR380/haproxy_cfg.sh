#!/bin/bash

# Configuration file path
CONFIG_FILE="/home/guillaume/haproxy.cfg"

# HAProxy container name
HAPROXY_CONTAINER_NAME="haproxy-router"

# Define services and paths
declare -A SERVICES=(
    ["student-registration"]="/student-registration"
    ["student-courses"]="/student-courses"
    ["student-paiement"]="/student-paiement"
    ["admin-dashboard"]="/admin-dashboard"
)

# Function to get the IP address of a container
get_container_ip() {
    local container_name=$1
    docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name" 2>/dev/null
}

# Generate HAProxy configuration
echo "Generating HAProxy configuration at $CONFIG_FILE..."
cat <<EOF > "$CONFIG_FILE"
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
    bind *:8090
    mode http
    option httpclose
    option forwardfor
EOF

# Add ACLs and backend rules dynamically
for service_name in "${!SERVICES[@]}"; do
    path="${SERVICES[$service_name]}"
    container_ip=$(get_container_ip "$service_name")

    if [[ -n "$container_ip" ]]; then
        echo "    acl is_${service_name} path_beg ${path}" >> "$CONFIG_FILE"
        echo "    use_backend ${service_name}_backend if is_${service_name}" >> "$CONFIG_FILE"
    else
        echo "Warning: Could not retrieve IP for container $service_name. Skipping backend configuration." >&2
    fi
done

# Add backend configurations dynamically
for service_name in "${!SERVICES[@]}"; do
    container_ip=$(get_container_ip "$service_name")

    if [[ -n "$container_ip" ]]; then
        cat <<EOF >> "$CONFIG_FILE"

backend ${service_name}_backend
    balance roundrobin
    http-request replace-path ${SERVICES[$service_name]}(/)?(.*) /\2
    server ${service_name} ${container_ip}:80 check
EOF
    fi
done

# Restart HAProxy container
echo "Starting or reloading HAProxy container..."
if docker ps --filter "name=$HAPROXY_CONTAINER_NAME" --format '{{.Names}}' | grep -q "$HAPROXY_CONTAINER_NAME"; then
    docker kill -s HUP "$HAPROXY_CONTAINER_NAME"
else
    docker stop "$HAPROXY_CONTAINER_NAME" 2>/dev/null || true
    docker rm "$HAPROXY_CONTAINER_NAME" 2>/dev/null || true
    docker run -d --name "$HAPROXY_CONTAINER_NAME" \
        --network host \
        -v "$CONFIG_FILE:/usr/local/etc/haproxy/haproxy.cfg:ro" \
        haproxy:latest
fi

# Test HAProxy configuration
echo "Testing HAProxy configuration..."
docker exec "$HAPROXY_CONTAINER_NAME" haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
if [[ $? -eq 0 ]]; then
    echo "HAProxy is now running and listening on port 8090."
    echo "Access your services at:"
    for service_name in "${!SERVICES[@]}"; do
        echo " - http://10.0.0.66:8090${SERVICES[$service_name]}"
    done
else
    echo "HAProxy setup failed. Check logs for details."
    docker logs "$HAPROXY_CONTAINER_NAME"
fi

