#!/bin/bash

# Initialiser et Appliquer Terraform
cd terraform
terraform init
terraform apply -auto-approve

# Extraire l'IP Publique
export INSTANCE_IP=$(terraform output -raw instance_ip)

# Mettre à jour le fichier d'inventaire Ansible
echo "[devsecops]" > ../ansible/hosts.ini
echo "$INSTANCE_IP ansible_user=ubuntu ansible_ssh_private_key_file=/home/jalel/terraformdev.pem" >> ../ansible/hosts.ini

# Exécuter le Playbook Ansible
cd ../ansible
ansible-playbook -i hosts.ini setup.yml

