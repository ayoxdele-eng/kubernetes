
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

    # Download the Google Cloud public signing key:
echo "[TASK 1] Disable and turn off SWAP"
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a

echo "[TASK 2] Stop and Disable firewall"
sudo systemctl disable --now ufw  

echo "[TASK 3] Enable and Load Kernel modules"
sudo cat >>/etc/modules-load.d/containerd.conf<<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

echo "[TASK 4] Add Kernel settings"
sudo cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system  

echo "[TASK 5] Install containerd runtime"
sudo apt update -qq  
sudo apt install -qq -y ca-certificates curl gnupg lsb-release  
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg  
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -qq  
sudo apt install -qq -y containerd.io  
sudo containerd config default > /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd  



sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# Add the Kubernetes apt repository:

sudo echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF



sudo systemctl enable --now kubelet

echo "[TASK 8] Enable ssh password authentication"
sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
sudo systemctl reload sshd

echo "[TASK 9] Set root password"
sudo echo -e "kubeadmin\nkubeadmin" | passwd root  
sudo echo "export TERM=xterm" >> /etc/bash.bashrc

cat >>/etc/hosts<<EOF
10.0.1.10   kmaster.example.com     kmaster
10.0.1.11   kworker1.example.com    kworker1
10.0.1.12   kworker2.example.com    kworker2
EOF




