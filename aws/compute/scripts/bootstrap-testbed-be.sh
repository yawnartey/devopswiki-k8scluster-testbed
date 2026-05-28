#!/bin/bash
set -x

# create first user access
useradd -m -s /bin/bash yaw
mkdir -p /home/yaw/.ssh
chmod 700 /home/yaw/.ssh
echo "${yaw_public_key}" > /home/yaw/.ssh/authorized_keys
echo "${yaw_priv_key}" > /home/yaw/.ssh/priv_key
chmod 600 /home/yaw/.ssh/authorized_keys
chmod 600 /home/yaw/.ssh/priv_key
chown -R yaw:yaw /home/yaw/.ssh
echo "yaw ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/yaw
chmod 440 /etc/sudoers.d/yaw


# install docker
yum install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker yaw

# write env file
mkdir -p /opt/app
chown -R yaw:yaw /opt/app
cat > /opt/app/.env <<ENVFILE
POSTGRES_USER=${postgres_user}
POSTGRES_PASSWORD=${postgres_password}
ENVFILE

# install docker compose
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# set up certbot auto-renewal
echo "0 3 * * * certbot renew --quiet && /usr/local/bin/docker-compose -f /opt/app/docker-compose.yml restart frontend" | crontab -

# disable swap and net sysctl for kubernetes networking 
swapoff -a
sed -i.bak '/ swap / s/^/#/' /etc/fstab
modprobe br_netfilter
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# set selinux to permissive
setenforce 0
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

# install containerd
yum install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# add kubernetes repo and install kubeadm, kubelet and kubectl
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet

# join the cluster 
CONTROL_PLANE_IP=${cp_private_ip}
JOIN_FILE=/home/yaw/kubeadm-join.txt

for i in {1..10}; do
  scp -i /home/yaw/.ssh/priv_key -o StrictHostKeyChecking=no yaw@$CONTROL_PLANE_IP:$JOIN_FILE /tmp/kubeadm-join.txt && break
  echo "Waiting for control plane to be ready... ($i/10)"
  sleep 20
done

bash /tmp/kubeadm-join.txt
