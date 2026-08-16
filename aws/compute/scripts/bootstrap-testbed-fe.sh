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

# install and setup the frontend worker node
ansible-playbook /opt/devopswiki-ansible/k8s-workers/frontend-worker-components.yml -e "cp_private_ip=${cp_private_ip} env=${env} region=${aws_region}"

# create first user access (this will be handled by ansible)
# useradd -m -s /bin/bash yaw
# mkdir -p /home/yaw/.ssh
# chmod 700 /home/yaw/.ssh
# echo "${yaw_public_key}" > /home/yaw/.ssh/authorized_keys
# echo "${yaw_priv_key}" > /home/yaw/.ssh/priv_key
# chmod 600 /home/yaw/.ssh/authorized_keys
# chmod 600 /home/yaw/.ssh/priv_key
# chown -R yaw:yaw /home/yaw/.ssh
# echo "yaw ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/yaw
# chmod 440 /etc/sudoers.d/yaw


# install docker (this is being handled by ansible)
# yum install -y docker
# systemctl enable docker
# systemctl start docker
# usermod -aG docker yaw

# install certbot (now being handled by ansible)
# yum install -y certbot

# try copy certbot from bucket first (now being handled by ansible)
# aws s3 cp s3://devops-wiki-letsencrypt-c9123c3a736c3547/k8scluster-testbed/letsencrypt /etc/letsencrypt --recursive 2>/dev/null

#run certbot if the file does not exist (now being handled by ansible)
# if [ ! -f /etc/letsencrypt/live/test.devopswiki.info/fullchain.pem ]; then
#   certbot certonly --standalone -d test.devopswiki.info \
#     --non-interactive --agree-tos --email yawenochnartey@gmail.com
#   aws s3 cp /etc/letsencrypt s3://devops-wiki-letsencrypt-c9123c3a736c3547/k8scluster-testbed/letsencrypt --recursive
# fi

# write env file for nginx (now being handled by ansible)
# mkdir -p /opt/app
# chown -R yaw:yaw /opt/app
# cat > /opt/app/.env <<ENVFILE
# BE_PRIVATE_IP=${be_private_ip}
# SERVER_NAME=test.devopswiki.info
# CERT_DOMAIN=test.devopswiki.info
# ENVFILE

# install docker compose (now being handled by ansible)
# curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose

# set up certbot auto-renewal (now being handled by ansible)
# echo "0 3 * * * certbot renew --quiet && /usr/local/bin/docker-compose -f /opt/app/docker-compose.yml restart frontend" | crontab -

# disable swap and net sysctl for kubernetes networking (ansible handling this)
# swapoff -a
# sed -i.bak '/ swap / s/^/#/' /etc/fstab
# modprobe br_netfilter
# cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
# net.bridge.bridge-nf-call-ip6tables = 1
# net.bridge.bridge-nf-call-iptables  = 1
# net.ipv4.ip_forward                 = 1
# EOF
# sysctl --system

# # set selinux to permissive
# setenforce 0
# sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

# # install containerd
# yum install -y containerd
# mkdir -p /etc/containerd
# containerd config default > /etc/containerd/config.toml
# sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
# systemctl restart containerd
# systemctl enable containerd

# # add kubernetes repo and install kubeadm, kubelet and kubectl
# cat <<EOF > /etc/yum.repos.d/kubernetes.repo
# [kubernetes]
# name=Kubernetes
# baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
# enabled=1
# gpgcheck=1
# gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
# EOF

# yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
# systemctl enable --now kubelet

# # set node labels at kubelet startup
# echo 'KUBELET_EXTRA_ARGS=--node-labels=role=frontend' > /etc/sysconfig/kubelet

# # join the cluster
# CONTROL_PLANE_IP=${cp_private_ip}
# JOIN_FILE=/home/yaw/kubeadm-join.txt

# for i in {1..10}; do
#   scp -i /home/yaw/.ssh/priv_key -o StrictHostKeyChecking=no yaw@$CONTROL_PLANE_IP:$JOIN_FILE /tmp/kubeadm-join.txt && break
#   echo "Waiting for control plane to be ready... ($i/10)"
#   sleep 20
# done

# bash /tmp/kubeadm-join.txt

# # add node-role label for kubectl get nodes ROLES column display
# scp -i /home/yaw/.ssh/priv_key -o StrictHostKeyChecking=no yaw@$CONTROL_PLANE_IP:/home/yaw/.kube/config /tmp/admin.conf
# KUBECONFIG=/tmp/admin.conf kubectl label node $(hostname -f) node-role.kubernetes.io/frontend=
