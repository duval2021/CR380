#!/bin/bash

# Base directory for HTML files
HTML_DIR="/home/guillaume/CR380/CR320/Contenu_web2"
# Starting port for mapping
START_PORT=8081

# Volume paths per image
declare -A VOLUME_PATHS
VOLUME_PATHS["ubuntu_image_apache:v1.0"]="/var/www/html"
VOLUME_PATHS["ubuntu_image_nginx:v1.0"]="/usr/share/nginx/html"
VOLUME_PATHS["redhat_image_apache:v1.0"]="/var/www/html"
VOLUME_PATHS["redhat_image_nginx:v1.0"]="/usr/share/nginx/html"
VOLUME_PATHS["rocky_image_apache:v1.0"]="/var/www/html"
VOLUME_PATHS["rocky_image_nginx:v1.0"]="/usr/share/nginx/html"

# Image mapping: Match HTML files with the correct image
declare -A IMAGE_MAPPING
IMAGE_MAPPING["student_courses.html"]="ubuntu_image_apache:v1.0"
IMAGE_MAPPING["student_registration.html"]="redhat_image_apache:v1.0"
IMAGE_MAPPING["student_paiement.html"]="rocky_image_nginx:v1.0"
IMAGE_MAPPING["admin_dashboard.html"]="ubuntu_image_nginx:v1.0"

# Ensure the HTML directory exists
if [[ ! -d "$HTML_DIR" ]]; then
    echo "Error: HTML directory $HTML_DIR does not exist."
    exit 1
fi

# Counter for port assignment
current_port=$START_PORT

# Loop through HTML files and run containers
for html_file in "$HTML_DIR"/*.html; do
    if [[ -f "$html_file" ]]; then
        # Extract base name and assign image
        base_name=$(basename "$html_file")
        image_name=${IMAGE_MAPPING[$base_name]}

        # Check if an image is assigned for the file
        if [[ -z "$image_name" ]]; then
            echo "No matching image found for $base_name. Skipping."
            continue
        fi

        # Determine the correct volume path for the image
        container_volume_path=${VOLUME_PATHS[$image_name]}
        if [[ -z "$container_volume_path" ]]; then
            echo "No volume path defined for image: $image_name. Skipping $base_name."
            continue
        fi

        # Replace underscores with hyphens for container naming
        container_name=$(echo "$base_name" | sed 's/.html$//' | tr '_' '-')

        # Run the container with port mapping
        echo "Running container: $container_name using image: $image_name on external port $current_port"
        docker run -d \
            --name "$container_name" \
            --network app-network \
            -p "$current_port:80" \
            -v "$html_file":"$container_volume_path/index.html" \
            "$image_name"

        # Check if the container was successfully started
        if [[ $? -eq 0 ]]; then
            echo "Container $container_name is running on port $current_port."
        else
            echo "Failed to start container $container_name. Check Docker logs for details."
        fi

        # Increment the port number for the next container
        current_port=$((current_port + 1))
    else
        echo "Skipping invalid file: $html_file"
    fi
done

echo "All containers are started."

