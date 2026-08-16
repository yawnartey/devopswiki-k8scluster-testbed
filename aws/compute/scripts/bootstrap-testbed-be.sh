#!/bin/bash
set -x

yum install -y ansible-core git

# checkout the playbooks
git clone -b dev https://github.com/yawnartey/devopswiki-ansible.git /opt/devopswiki-ansible

# install requirements
ansible-galaxy collection install -r /opt/devopswiki-ansible/base-components/requirements.yml

# install base components
ansible-playbook /opt/devopswiki-ansible/base-components/main.yml -e "env=${env} region=${aws_region}"

# setup the backend
ansible-playbook /opt/devopswiki-ansible/backend/main.yml -e "env=${env} region=${aws_region}"

# install and setup the backend worker node
ansible-playbook /opt/devopswiki-ansible/k8s-workers/backend-worker-components.yml -e "cp_private_ip=${cp_private_ip} env=${env} region=${aws_region}"
