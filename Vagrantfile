# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure(2) do |config|

  config.vm.provision "shell", inline: $install_common_tools

  # Kubernetes Master Server
  config.vm.define "master" do |master|
    master.vm.box = "bento/ubuntu-18.04"
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "10.0.0.10"
    master.vm.provider "virtualbox" do |v|
      v.name = "master"
      v.memory = 1024
      v.cpus = 2
    end
    master.vm.provision "shell", inline: $provision_master_node
  end

  NodeCount = 2

  # Kubernetes Worker Nodes
  (1..NodeCount).each do |i|
    config.vm.define "worker#{i}" do |workernode|
      workernode.vm.box = "bento/ubuntu-18.04"
      workernode.vm.hostname = "worker#{i}.pahamify.com"
      workernode.vm.network "private_network", ip: "10.0.0.1#{i}"
      workernode.vm.provider "virtualbox" do |v|
        v.name = "worker#{i}"
        v.memory = 1024
        v.cpus = 1
      end
      workernode.vm.provision "shell", inline: $provision_worker_node
    end
  end
end

$install_common_tools = <<-'SCRIPT'
echo "[TASK 1] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
10.0.0.10 master.pahamify.com master
10.0.0.11 worker1.pahamify.com worker1
10.0.0.12 worker2.pahamify.com worker2
EOF

echo "[TASK 2] Install docker container engine"
export DEBIAN_FRONTEND=noninteractive
apt-get install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install docker-ce -y

# add ccount to the docker group
usermod -aG docker vagrant

# Enable docker service
echo "[TASK 3] Enable and start docker service"
systemctl enable docker
systemctl start docker

# Add sysctl settings
echo "[TASK 6] Add sysctl settings"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# Disable swap
echo "[TASK 7] Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

# Install apt-transport-https pkg
echo "[TASK 8] Installing apt-transport-https pkg"
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# Add he kubernetes sources list into the sources.list directory
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

ls -ltr /etc/apt/sources.list.d/kubernetes.list

apt-get update -y

# Install Kubernetes
echo "[TASK 9] Install Kubernetes kubeadm, kubelet and kubectl"
apt-get install -y kubeadm=1.18.0-00 kubelet=1.18.0-00 kubectl=1.18.0-00

# Start and Enable kubelet service
echo "[TASK 10] Enable and start kubelet service"
systemctl enable kubelet
systemctl start kubelet

# Enable ssh password authentication
echo "[TASK 11] Enable ssh password authentication"
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Set Root password
echo "[TASK 12] Set root password"
echo -e "kubeadmin\nkubeadmin" | passwd root

# Update vagrant user's bashrc file
echo "export TERM=xterm" >> /etc/bashrc
SCRIPT

$provision_master_node = <<-'SCRIPT'
# Initialize Kubernetes
echo "[TASK 1] Initialize Kubernetes Cluster"
kubeadm init --apiserver-advertise-address=10.0.0.10 --pod-network-cidr=10.244.0.0/16 >> /root/kubeinit.log

# Copy Kube admin config
echo "[TASK 2] Copy kube admin config to Vagrant user .kube directory"
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube/config

# Deploy calico network
echo "[TASK 3] Deploy Pod network"
kubectl --kubeconfig=/home/vagrant/.kube/config apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml

# Generate Cluster join command
echo "[TASK 4] Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh
SCRIPT

$provision_worker_node = <<-'SCRIPT'
# Join worker nodes to the Kubernetes cluster
echo "[TASK 1] Join node to Kubernetes Cluster"
apt-get  install -y sshpass
sshpass -p "kubeadmin" scp -o StrictHostKeyChecking=no master.pahamify.com:/joincluster.sh /joincluster.sh
bash /joincluster.sh
SCRIPT
