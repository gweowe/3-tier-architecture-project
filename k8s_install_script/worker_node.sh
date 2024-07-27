# 사전 OS 구성
sudo systemctl disable --now firewalld
sudo swapoff -a
sudo modprobe br_netfilter
sudo modprobe overlay
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system

# git 설치
sudo yum install git -y

# k8s 설치
sudo yum update -y
sudo yum install nfs-utils -y
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
EOF
sudo yum install kubelet kubeadm kubectl -y
sudo systemctl enable --now kubelet

# CRI(containerd) 설치
sudo yum install yum-utils -y
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install containerd.io -y
sudo rm -rf /etc/containerd/config.toml
sudo systemctl enable --now containerd

# master node init 후 join 작업 수행 필요
