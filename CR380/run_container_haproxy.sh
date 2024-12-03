#!/bin/bash

# Configuration file path
CONFIG_FILE="/home/guillaume/haproxy.cfg"

# Ensure the HAProxy configuration directory exists
if [[ ! -d "/home/guillaume" ]]; then
    echo "Error: Configuration directory does not exist."
    exit 1
fi

echo "Generating HAProxy configuration at ${CONFIG_FILE}..."

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
    bind *:8095
    # ACLs to match specific paths
    acl is_enregistrement path_beg /enregistrement
    acl is_paiement path_beg /paiement
    acl is_admin path_beg /admin
    acl is_cours path_beg /cours

    # Use specific backends based on ACLs
    use_backend enregistrement_backend if is_enregistrement
    use_backend paiement_backend if is_paiement
    use_backend admin_backend if is_admin
    use_backend cours_backend if is_cours

    # Default backend if no ACL matches
    default_backend default_backend

EOF

# Backend definitions with container IPs
declare -A SERVICES
SERVICES["enregistrement"]="enregistrement"
SERVICES["paiement"]="paiement"
SERVICES["admin"]="admin"
SERVICES["cours"]="cours"

for service in "${!SERVICES[@]}"; do
    echo "Adding backend configuration for ${service}..."
    cat <<EOF >> $CONFIG_FILE
backend ${service}_backend
    balance roundrobin
EOF

    # Get containers for the service and fetch their IPs
    for container in $(docker ps --filter "name=${service}" --format "{{.Names}}"); do
        IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container)
        if [[ -n $IP ]]; then
            echo "    server ${container} ${IP}:80 check" >> $CONFIG_FILE
        else
            echo "Warning: No IP found for container ${container}."
        fi
    done
done

# Add a default backend configuration
echo "Adding default backend configuration..."
cat <<EOF >> $CONFIG_FILE
backend default_backend
    balance roundrobin
EOF

for container in $(docker ps --filter "name=default" --format "{{.Names}}"); do
    IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container)
    if [[ -n $IP ]]; then
        echo "    server ${container} ${IP}:80 check" >> $CONFIG_FILE
    fi
done

# Restart or start the HAProxy container
echo "Restarting HAProxy container..."
docker stop haproxy_service >/dev/null 2>&1 || true
docker rm haproxy_service >/dev/null 2>&1 || true
docker run -d \
    --name haproxy_service \
    -p 8095:8095 \
    -v ${CONFIG_FILE}:/usr/local/etc/haproxy/haproxy.cfg:ro \
    --network bridge \
    haproxy:latest

if [[ $? -ne 0 ]]; then
    echo "Failed to start HAProxy container. Check Docker logs for more details."
    exit 1
fi

echo "HAProxy is now running and listening on port 8095."

