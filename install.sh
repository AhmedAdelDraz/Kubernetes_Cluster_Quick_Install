##############################################################
# This Script is written to install lab kubernetes cluster 
# Written By Ahmed Draz
##############################################################
#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BIRED='\033[1;91m'
BIGREEN='\033[1;92m'
NC='\033[0m' # No Color

##Disable Swap Space
swapoff -a
if [[ -n `grep -i "swap" /etc/fstab` ]];then
 sed '/swap/d' /etc/fstab &> /dev/null
 #echo "file is deleted"
#else
# echo "${BIGREEN}No Swap Found${NC}" 
fi
/usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}NO Swap\n"

systemctl daemon-reload

##Disable SELinux
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
/usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}SELinux Disabled\n"

##Install Traffic Control Utility Package
dnf install -y iproute-tc &> /dev/null
if [[ -n `rpm -qa | grep -i iproute-tc` ]];then
  /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}Traffic Control Utility Package\n"
else
  /usr/bin/printf "${BIRED} \u274c ${NC}Traffic Control Utility Package\n"
fi



# Check in case of firewall service is active or not active
if [[ `systemctl is-active firewalld` == "active" ]]; then
  #echo -e "${BIRED}Firewall is Active${NC}"
  #------------------------------------------------------------------#

  # Ask the administrator is this node is master node or worker node
  echo -n -e  "${BIGREEN}Is it Master Node?${NC} [y/n]: "
  read -r ans 
  #-------------------------------------------------------------------#

  # Apply the changes in firewall service

  if [[ "$ans" == "y"  ]];then
    echo -e  "FireWall Rules:"
    firewall-cmd --permanent --add-port=6443/tcp &> /dev/null        #Kubernetes API server
    /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}Kubernetes API server\n"
    firewall-cmd --permanent --add-port=2379-2380/tcp &> /dev/null   #Etcd server client API
    /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}Etcd server client API\n"
    firewall-cmd --permanent --add-port=10250/tcp &> /dev/null       #kubelet API
    /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}kubelet API\n"
    firewall-cmd --permanent --add-port=10251/tcp &> /dev/null       #kube-scheduler
    /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}kube-scheduler\n"
    firewall-cmd --permanent --add-port=10252/tcp &> /dev/null       #kube-controller-manager
    /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}kube-controller-manager\n"
    firewall-cmd --reload &> /dev/null
    #echo -e "${BIRED}Master Node Firewall Setting Applied${NC}"

  else # then it is a worker machine
    firewall-cmd --permanent --add-port=10250/tcp &> /dev/null         #Kubelet API
    /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}Kubelet API\n"
    firewall-cmd --permanent --add-port=30000-32767/tcp &> /dev/null   #NodePort Services
    /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}NodePort Services\n\n"
    firewall-cmd --reload &> /dev/null
    #echo -e "${BIRED}Worker Node Firewall Setting Applied${NC}"

  fi
  #--------------------------------------------------------------------#
#else
#  echo -e "${BIRED}Firewall is Not Active${NC}"
fi


## Enable and Load Kernel Modules
#----------------------------------------------------------------------------------------------------#
echo -e  "Kernel Modules:"
if [[ ! -f "/etc/modules-load.d/k8s.conf" ]];then
  echo -e "overlay\nbr_netfilter" > /etc/modules-load.d/k8s.conf
  modprobe overlay
  modprobe br_netfilter
  /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}/etc/modules-load.d/k8s.conf\n"
else
  /usr/bin/printf "${BIRED} \u274c ${NC}/etc/modules-load.d/k8s.conf\n"
fi


if [[ ! -f "/etc/sysctl.d/k8s.conf" ]];then
  echo -e "net.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1\nnet.bridge.bridge-nf-call-ip6tables = 1" > /etc/sysctl.d/k8s.conf
  sysctl --system &> /dev/null 
  /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}/etc/sysctl.d/k8s.conf\n\n"
else
  /usr/bin/printf "${BIRED} \u274c ${NC}/etc/sysctl.d/k8s.conf\n\n"
fi
#-------------------------------------------------------------------------------------------------------#

## Select the CRI-O veresion you need to install
#-------------------------------------------------------------------------------------------------------#
export VERSION=1.25

## download crio repos so we can install it using yum
if [[ ! -e "/etc/yum.repos.d/devel:kubic:libcontainers:stable.repo" ]];then
  curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8/devel:kubic:libcontainers:stable.repo &> /dev/null 
#else
#  echo -e "${BIRED}/etc/yum.repos.d/devel:kubic:libcontainers:stable.repo is exist${NC}"
fi

if [[ ! -e "/etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo" ]];then
  curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/CentOS_8/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo &> /dev/null
#else
#  echo -e "${BIRED}/etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo is exist${NC}"
fi

dnf install cri-o -y &> /dev/null
if [[ -n `rpm -qa | grep -i cri-o ` ]];then
  systemctl enable --now crio &> /dev/null
  /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}CRI-O Installed\n\n"
else
  /usr/bin/printf "${BIRED} \u274c ${NC}CRI-O Installed\n"  
fi
#---------------------------------------------------------------------------------------------------#

## Install Kubernetes Packages
#---------------------------------------------------------------------------------------------------#
echo -e "Kubernetes Packages:"
if [[ ! -e "/etc/yum.repos.d/kubernetes.repo" ]];then
    cat << EOM > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOM
  /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}Kubernetes Repositry\n"
  #echo -e "${BIGREEN}Repo Has Been Created.${NC}"
#else
#   echo "Kubernetes Repo is Exists"
fi

## Install Kubernetes Packages ##
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes &> /dev/null 

if [[ -n `rpm -qa | grep -i kubelet` ]];then
  /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}Install kubelet\n"
else
  /usr/bin/printf "${BIRED} \u274c ${NC}Install kubelet\n"  
fi

if [[ -n `rpm -qa | grep -i kubeadm` ]];then
  /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}Install kubeadm\n"
else
  /usr/bin/printf "${BIRED} \u274c ${NC}Install kubeadm\n"  
fi

if [[ -n `rpm -qa | grep -i kubectl` ]];then
  /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}Install kubectl\n"
else
  /usr/bin/printf "${BIRED} \u274c ${NC}Install kubectl\n"  
fi

systemctl enable --now kubelet &> /dev/null    #Enable Kubelet in Node 

if [[ `systemctl is-active kubelet` == "active" ]];then
  /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}Enable Kubelet\n\n"
fi

#---------------------------------------------------------------------------------------------------#

## Only Master Nodes
#---------------------------------------------------------------------------------------------------#
if [[ "$ans" == "y"  ]];then
  kubeadm init --pod-network-cidr=10.244.0.0/16 &> /dev/null 
  /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}Kubernetes cluster Initialized\n"
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config 
  export KUBECONFIG=/etc/kubernetes/admin.conf

  kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml &> /dev/null
  /usr/bin/printf "${BIGREEN} \xE2\x9C\x94 ${NC}Kubernetes cluster Network Installed\n\n"

  TOKEN=`kubeadm token generate`
  echo -e "Save The Following command and run it in worker nodes to join them to the cluster"
  kubeadm token create $TOKEN --print-join-command

## Master Taints:
# kubectl taint nodes --all node-role.kubernetes.io/master-
else
  echo -n -e "Enter the joining command:"
  read -r JOIN
  $JOIN
fi