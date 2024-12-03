#!/bin/bash

# Répertoire contenant les Dockerfiles
DOCKERFILES_DIR="/home/guillaume/CR380/CR320/Dockerfiles"

# Construire les images Docker
echo "Construction des images Docker avec Contenu_web2..."

docker build -t centos_apache:v1.0 -f "$DOCKERFILES_DIR/Containerfile_centos_apache" "$DOCKERFILES_DIR"
docker build -t centos_nginx:v1.0 -f "$DOCKERFILES_DIR/Containerfile_centos_nginx" "$DOCKERFILES_DIR"
docker build -t rocky_apache:v1.0 -f "$DOCKERFILES_DIR/Containerfile_rocky_apache" "$DOCKERFILES_DIR"
docker build -t rocky_nginx:v1.0 -f "$DOCKERFILES_DIR/Containerfile_rocky_nginx" "$DOCKERFILES_DIR"
docker build -t ubuntu_apache:v1.0 -f "$DOCKERFILES_DIR/Containerfile_ubuntu_apache" "$DOCKERFILES_DIR"
docker build -t ubuntu_nginx:v1.0 -f "$DOCKERFILES_DIR/Containerfile_ubuntu_nginx" "$DOCKERFILES_DIR"

echo "Toutes les images Docker ont été construites avec succès."
