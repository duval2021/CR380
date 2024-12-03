#!/bin/bash

# Define the base directory containing the Dockerfiles
BASE_DIR="/home/guillaume/CR380/CR320/Dockerfiles"

# Tag version for the images
IMAGE_TAG="v1.0"

# Loop through all files in the Dockerfiles directory
for DOCKERFILE in "$BASE_DIR"/*; do
    if [[ -f "$DOCKERFILE" ]]; then
        # Extract the base name of the Dockerfile
        FILE_NAME=$(basename "$DOCKERFILE")
        
        # Parse the image name components from the file name
        COMPONENTS=$(echo "$FILE_NAME" | sed 's/Containerfile_//g' | sed 's/_/\ /g')
        IMAGE_NAME=$(echo "$COMPONENTS" | awk '{print $1 "_image_" $2}')
        
        # Full image tag
        FULL_IMAGE_NAME="$IMAGE_NAME:$IMAGE_TAG"

        # Build the Docker image
        echo "Building image: $FULL_IMAGE_NAME using $DOCKERFILE"
        docker build -t "$FULL_IMAGE_NAME" -f "$DOCKERFILE" .

        # Check if the build was successful
        if [[ $? -eq 0 ]]; then
            echo "Successfully built $FULL_IMAGE_NAME"
        else
            echo "Failed to build $FULL_IMAGE_NAME"
            exit 1
        fi
    fi
done

echo "All images built successfully."

