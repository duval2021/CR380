#!/bin/bash

# Define directory for Dockerfiles
dockerfiles_dir="Dockerfiles"

# Array of Dockerfiles to build images from
dockerfiles=(
  "Containerfile_centos_apache"
  "Containerfile_centos_nginx"
  "Containerfile_rocky_apache"
  "Containerfile_rocky_nginx"
  "Containerfile_ubuntu_apache"
  "Containerfile_ubuntu_nginx"
)

# Change to Dockerfiles directory
cd "$dockerfiles_dir" || { echo "Error: Could not change to Dockerfiles directory."; exit 1; }

# Correct system time to fix repository release file errors
echo "Updating system time to avoid repository release file errors..."
date -s "$(curl -s --head http://google.com | grep ^Date: | sed 's/Date: //g')"

# Loop over each Dockerfile and build the corresponding Docker image
for dockerfile in "${dockerfiles[@]}"
do
  # Extract image name from Dockerfile name (using the last two parts of the name)
  image_name=$(basename "$dockerfile" | cut -d'_' -f2-3)

  # Build Podman image and log the output to a separate log file for debugging
  podman build -f "$dockerfile" -t "$image_name" . > build_$image_name.log 2>&1

  # Check if the build was successful
  if [ $? -eq 0 ]; then
    echo "Successfully built image: $image_name"
  else
    echo "Failed to build image: $image_name. Check build_$image_name.log for details."
  fi

done

