#!/bin/bash
set -x

# create first user access
useradd -m -s /bin/bash yaw
mkdir -p /home/yaw/.ssh
chmod 700 /home/yaw/.ssh
echo "${yaw_public_key}" > /home/yaw/.ssh/authorized_keys
chmod 600 /home/yaw/.ssh/authorized_keys
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

# initialise the control plane
PRIVATE_IP=$(ip route get 1.2.3.4 | awk '{print $7}')
kubeadm init --apiserver-advertise-address=$PRIVATE_IP --pod-network-cidr=192.168.0.0/16 | tee /root/kubeadm-init.log
grep -A2 "kubeadm join" /root/kubeadm-init.log > /root/kubeadm-join.txt
cp /root/kubeadm-join.txt /home/yaw/kubeadm-join.txt && chown yaw:yaw /home/yaw/kubeadm-join.txt

# configure kubectl for yaw/root user
mkdir -p /home/yaw/.kube
cp -i /etc/kubernetes/admin.conf /home/yaw/.kube/config
chown yaw:yaw /home/yaw/.kube/config

mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config

# install a CNI plugin (Calico)
su - yaw -c "kubectl apply -f https://projectcalico.docs.tigera.io/manifests/calico.yaml"