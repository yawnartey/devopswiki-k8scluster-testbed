#!/bin/bash
set -x

yum install -y ansible-core git

# checkout the playbooks
git clone -b dev https://github.com/yawnartey/devopswiki-ansible.git /opt/devopswiki-ansible

# install requirements
ansible-galaxy collection install -r /opt/devopswiki-ansible/base-components/requirements.yml

# install base-components
ansible-playbook /opt/devopswiki-ansible/base-components/main.yml -e "env=${env} region=${aws_region}"

# install and setup certbot and nginx
ansible-playbook /opt/devopswiki-ansible/frontend/main.yml -e "env=${env} domain=${domain} region=${aws_region}"

# install and setup the control plane
ansible-playbook /opt/devopswiki-ansible/k8s-control-plane/main.yml -e "env=${env} region=${aws_region}"
