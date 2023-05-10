echo "[TASK 10] Pull required containers"
kubeadm config images pull >/dev/null 2>&1

echo "[TASK 11] Initialize Kubernetes Cluster"
kubeadm init --apiserver-advertise-address=10.0.1.10 --pod-network-cidr=192.168.0.0/16 

sleep 50

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Alternatively, if you are the root user, you can run:

#   export KUBECONFIG=/etc/kubernetes/admin.conf

echo "[TASK 4] Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh 2>/dev/null
