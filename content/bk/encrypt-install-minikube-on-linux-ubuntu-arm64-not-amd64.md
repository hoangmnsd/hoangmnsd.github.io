---
title: "Install Minikube on Linux Ubuntu arm64 (not amd64)"
date: 2022-12-13T20:42:58+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Kubernetes]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Mình có cơ hội sử dụng cả 2 loại amd64 và arm64, gặp nhiều lỗi khi làm theo các tut trên mạng nên phải viết bài này."
---

# 1. Story

Vì sự khác biệt CPU arhchitecture có thể dẫn đến lỗi nếu bạn cài đặt phần mềm ko tương thích.  

Mình có cơ hội sử dụng cả 2 loại amd64 và arm64, gặp nhiều lỗi khi làm theo các tut trên mạng nên phải viết bài này.  

Check CPU architecture của máy bạn đang sử dụng:  
```sh
dpkg --print-architecture
```
kết quả có thể ra `arm64` hoặc `amd64`, tùy theo đó mà chọn các package phù hợp để install

https://computingforgeeks.com/install-kvm-centos-rhel-ubuntu-debian-sles-arch/  
https://computingforgeeks.com/how-to-run-minikube-on-kvm/  

# 2. Steps to install Minikube (on arm64)

Bài này hướng dẫn Install Minikube on **Ubuntu18.04 Oracle cloud VM**

## 2.1. Install Docker

```sh
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt update
sudo apt upgrade -y
sudo apt install docker.io -y
sudo systemctl enable docker
sudo curl -L "https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-aarch64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

## 2.2. Install 1 số package cần thiết 

```sh
sudo apt update
sudo apt install apt-transport-https
sudo apt upgrade
# install KVM
sudo apt update
sudo apt -y install qemu-kvm libvirt-dev bridge-utils libvirt-daemon-system libvirt-daemon virtinst bridge-utils libosinfo-bin libguestfs-tools virt-top

sudo modprobe vhost_net
sudo lsmod | grep vhost
echo "vhost_net" | sudo tee -a /etc/modules
```

## 2.3. Download minikube 

(Chỗ này vì mình dùng Oracle VM có kiến trúc CPU là arm64 nên phải downlink `arm64`, chứ download cái `amd64` sẽ ko dùng dc)

```sh
wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-arm64
chmod +x minikube-linux-arm64
sudo mv minikube-linux-arm64 /usr/local/bin/minikube
```
Check version:  
```
$ minikube version
minikube version: v1.28.0
commit: 986b1ebd987211ed16f8cc10aed7d2c42fc8392f
```

## 2.4. Install kubectl

```sh
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/arm64/kubectl
chmod +x kubectl
sudo mv kubectl  /usr/local/bin/
kubectl version -o json 
```

## 2.5. Install Docker Machine KVM drive (đang bị lỗi vì ko tìm dc bản cho arm64)

```sh
curl -LO https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-kvm2
chmod +x docker-machine-driver-kvm2
sudo mv docker-machine-driver-kvm2 /usr/local/bin/
docker-machine-driver-kvm2 version => đang bị lỗi vì ko tìm dc bản cho arm64
```
refer:  
https://github.com/kubernetes/minikube/issues/9418  
https://github.com/kubernetes/minikube/issues/9593    
https://github.com/kubernetes/minikube/issues/9228  

## 2.6. Add user

```sh
sudo usermod -aG libvirt $USER
newgrp libvirt
```

## 2.7. Fix trước 1 số lỗi rồi start minikube

```sh
sudo apt-get install -y conntrack
```

```sh
# Download:
wget https://go.dev/dl/go1.19.4.linux-arm64.tar.gz

# unzip: 
tar -zxvf go1.19.4.linux-arm64.tar.gz

sudo mv go /usr/local/
cd /usr/local/go/bin
sudo cp * /usr/bin/
go version
# -> thấy đúng version download về là OK
```

```sh
git clone https://github.com/Mirantis/cri-dockerd.git

cd cri-dockerd
mkdir bin
go build -o bin/cri-dockerd
mkdir -p /usr/local/bin
install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
cp -a packaging/systemd/* /etc/systemd/system
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
systemctl daemon-reload
systemctl enable cri-docker.service
systemctl enable --now cri-docker.socket
```

check version `cri-dockerd`:   
```
$ cri-dockerd --version
cri-dockerd 0.2.6 (HEAD)
```

```sh
VERSION="v1.25.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/critest-$VERSION-linux-arm64.tar.gz
sudo tar zxvf critest-$VERSION-linux-arm64.tar.gz -C /usr/local/bin
rm -f critest-$VERSION-linux-arm64.tar.gz
```

Test version `crictl`:  
```
$ crictl --version
crictl version v1.25.0
```

```sh
sudo chown $USER $HOME/.kube/config && chmod 600 $HOME/.kube/config
```

```sh
sudo chown -R $USER $HOME/.minikube; chmod -R u+wrx $HOME/.minikube
```

```
$ minikube start --driver=docker
* minikube v1.28.0 on Ubuntu 18.04 (arm64)
* Using the docker driver based on user configuration
* Using Docker driver with root privileges
* Starting control plane node minikube in cluster minikube
* Pulling base image ...
* Downloading Kubernetes v1.25.3 preload ...
    > preloaded-images-k8s-v18-v1...:  320.81 MiB / 320.81 MiB  100.00% 133.13
* Creating docker container (CPUs=2, Memory=5900MB) ...
* Preparing Kubernetes v1.25.3 on Docker 20.10.20 ...
  - Generating certificates and keys ...
  - Booting up control plane ...
  - Configuring RBAC rules ...
* Verifying Kubernetes components...
  - Using image gcr.io/k8s-minikube/storage-provisioner:v5
* Enabled addons: storage-provisioner, default-storageclass
* Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

# 3. Troubleshooting (arm64)

## 3.1. Lỗi PROVIDER_KVM2_ERROR

```
$ minikube config set vm-driver kvm2
! These changes will take effect upon a minikube delete and then a minikube start

$ minikube start
* minikube v1.28.0 on Ubuntu 18.04 (arm64)
* Using the kvm2 driver based on user configuration

X Exiting due to PROVIDER_KVM2_ERROR: /usr/bin/virsh domcapabilities --virttype kvm failed:
error: failed to get emulator capabilities
error: invalid argument: KVM is not supported by '/usr/bin/kvm' on this host
exit status 1
* Suggestion: Follow your Linux distribution instructions for configuring KVM
* Documentation: https://minikube.sigs.k8s.io/docs/reference/drivers/kvm2/
```

-> Do kvm2 ko khả dụng, nên phải dùng `minikube start --driver=none`, hoặc `minikube start --driver=docker`

reference: https://github.com/kubernetes/minikube/issues/5667

## 3.2. Lỗi GUEST_MISSING_CONNTRACK

```
$ minikube config set vm-driver none
! These changes will take effect upon a minikube delete and then a minikube start
$ minikube start
* minikube v1.28.0 on Ubuntu 18.04 (arm64)
* Using the none driver based on user configuration

X Exiting due to GUEST_MISSING_CONNTRACK: Sorry, Kubernetes 1.25.3 requires conntrack to be installed in root's path
```

-> Fix bằng cách:  
```sh
sudo apt-get install -y conntrack
```

## 3.3. Lỗi NOT_FOUND_CRI_DOCKERD

```
$ minikube start --driver=none
* minikube v1.28.0 on Ubuntu 18.04 (arm64)
! Both driver=none and vm-driver=none have been set.

    Since vm-driver is deprecated, minikube will default to driver=none.

    If vm-driver is set in the global config, please run "minikube config unset vm-driver" to resolve this warning.

* Using the none driver based on user configuration
* Starting control plane node minikube in cluster minikube
* Running on localhost (CPUs=4, Memory=23997MB, Disk=148662MB) ...

* Exiting due to NOT_FOUND_CRI_DOCKERD:

* Suggestion:

    The none driver with Kubernetes v1.24+ and the docker container-runtime requires cri-dockerd.

    Please install cri-dockerd using these instructions:

    https://github.com/Mirantis/cri-dockerd#build-and-install
```

https://github.com/kubernetes/minikube/issues/9593
https://github.com/kubernetes/minikube/issues/5667

Fix bằng cách cài `cri-dockerd`, tuy nhiên để cài đc nó thì lại cần cài `golang` trước

Vào đây lấy link go latest file gz: https://go.dev/dl/

Tương ứng với arm64 linux sẽ tìm được link: https://go.dev/dl/go1.19.4.linux-arm64.tar.gz  

```sh
# Download:
wget https://go.dev/dl/go1.19.4.linux-arm64.tar.gz

# unzip: 
tar -zxvf go1.19.4.linux-arm64.tar.gz

sudo mv go /usr/local/
cd /usr/local/go/bin
sudo cp * /usr/bin/
go version
# -> thấy đúng version download về là OK
```

Cài cri-dockerd:   
https://github.com/Mirantis/cri-dockerd#build-and-install

```sh
git clone https://github.com/Mirantis/cri-dockerd.git

cd cri-dockerd
mkdir bin
go build -o bin/cri-dockerd
mkdir -p /usr/local/bin
install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
cp -a packaging/systemd/* /etc/systemd/system
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
systemctl daemon-reload
systemctl enable cri-docker.service
systemctl enable --now cri-docker.socket
```

check version `cri-dockerd`:   
```
$ cri-dockerd --version
cri-dockerd 0.2.6 (HEAD)
```

## 3.4. Lỗi Exiting due to RUNTIME_ENABLE

`Exiting due to RUNTIME_ENABLE Temporary Error: sudo crictl version: exit status 1`

Do chưa cài crictl

Cài như sau (chú ý mình đang dùng arm64): https://github.com/kubernetes-sigs/cri-tools#install-crictl

```sh
VERSION="v1.25.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/critest-$VERSION-linux-arm64.tar.gz
sudo tar zxvf critest-$VERSION-linux-arm64.tar.gz -C /usr/local/bin
rm -f critest-$VERSION-linux-arm64.tar.gz
```

Test version `crictl`:  
```
$ crictl --version
crictl version v1.25.0
```

## 3.5. Lỗi HOST_KUBECONFIG_PERMISSION

```
X Exiting due to HOST_KUBECONFIG_PERMISSION: Failed kubeconfig update: Error reading file "/home/ubuntu/.kube/config": open /home/ubuntu/.kube/config: permission denied
* Suggestion: Run: 'sudo chown $USER $HOME/.kube/config && chmod 600 $HOME/.kube/config'
* Related issue: https://github.com/kubernetes/minikube/issues/5714
```

-> fix bằng cách:  
```sh
sudo chown $USER $HOME/.kube/config && chmod 600 $HOME/.kube/config
```

## 3.6. Lỗi HOST_HOME_PERMISSION

```
X Exiting due to HOST_HOME_PERMISSION: Unable to load config: open /home/ubuntu/.minikube/profiles/minikube/config.json: permission denied
* Suggestion: Your user lacks permissions to the minikube profile directory. Run: 'sudo chown -R $USER $HOME/.minikube; chmod -R u+wrx $HOME/.minikube' to fix
* Related issue: https://github.com/kubernetes/minikube/issues/9165
```

-> fix bằng cách: 
```sh
sudo chown -R $USER $HOME/.minikube; chmod -R u+wrx $HOME/.minikube
```

## 3.7. Lỗi pending các pod coredns và storage-provisioner

```
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                     READY   STATUS    RESTARTS        AGE
kube-system   coredns-565d847f94-lh9tw                 0/1     Pending   0               9m41s
kube-system   etcd-ubuntu-oc-gp02                      1/1     Running   2 (4m30s ago)   9m54s
kube-system   kube-apiserver-ubuntu-oc-gp02            1/1     Running   2 (4m29s ago)   9m53s
kube-system   kube-controller-manager-ubuntu-oc-gp02   1/1     Running   2 (4m30s ago)   9m53s
kube-system   kube-proxy-mjpc6                         1/1     Running   2 (4m38s ago)   9m41s
kube-system   kube-scheduler-ubuntu-oc-gp02            1/1     Running   2 (4m37s ago)   9m53s
kube-system   storage-provisioner                      0/1     Pending   0               4m20s
```

=> Do bị lỗi node NotReady nên mới có 2 pod pending

```
$ k get nodes
NAME             STATUS     ROLES           AGE   VERSION
ubuntu-oc-gp02   NotReady   control-plane   21h   v1.25.3

$ k describe node ubuntu-oc-gp02

 container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized
```

=> lỗi chưa fix dc hoàn toàn, dùng `driver=docker` để workaround: `minikube start --driver=docker`

-> https://github.com/kubernetes/minikube/issues/14924#issuecomment-1241675839

```sh
# xóa minikube đi:  
minikube delete

# run lại driver=docker
minikube start --driver=docker
```

Test get nodes status `Ready` như này là OK:  
```
$ k get nodes
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   24s   v1.25.3

$ k get pods -A
NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
kube-system   coredns-565d847f94-9pw2q           1/1     Running   0          38s
kube-system   etcd-minikube                      1/1     Running   0          52s
kube-system   kube-apiserver-minikube            1/1     Running   0          51s
kube-system   kube-controller-manager-minikube   1/1     Running   0          51s
kube-system   kube-proxy-45kcb                   1/1     Running   0          39s
kube-system   kube-scheduler-minikube            1/1     Running   0          51s
kube-system   storage-provisioner                1/1     Running   0          49s
```

```
$ kubectl cluster-info
Kubernetes control plane is running at https://10.0.0.228:8443
CoreDNS is running at https://10.0.0.228:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.


$ kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /home/ubuntu/.minikube/ca.crt
    extensions:
    - extension:
        last-update: Tue, 13 Dec 2022 10:06:52 UTC
        provider: minikube.sigs.k8s.io
        version: v1.28.0
      name: cluster_info
    server: https://10.0.0.228:8443
  name: minikube
contexts:
- context:
    cluster: minikube
    extensions:
    - extension:
        last-update: Tue, 13 Dec 2022 10:06:52 UTC
        provider: minikube.sigs.k8s.io
        version: v1.28.0
      name: context_info
    namespace: default
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
#NAME?
  user:
    client-certificate: /home/ubuntu/.minikube/profiles/minikube/client.crt
    client-key: /home/ubuntu/.minikube/profiles/minikube/client.key
```

## 3.8. Lỗi ko minikube ssh được 

Do driver mình chọn là `none` nên ko thể ssh dc:  

```
$ minikube ssh

X Exiting due to MK_USAGE: 'none' driver does not support 'minikube ssh' command
```

## 3.9. Một số command thường dùng

List các addon mà minikube đang enable:  
```
$ minikube addons list
|-----------------------------|----------|--------------|--------------------------------|
|         ADDON NAME          | PROFILE  |    STATUS    |           MAINTAINER           |
|-----------------------------|----------|--------------|--------------------------------|
| ambassador                  | minikube | disabled     | 3rd party (Ambassador)         |
| auto-pause                  | minikube | disabled     | Google                         |
| cloud-spanner               | minikube | disabled     | Google                         |
| csi-hostpath-driver         | minikube | disabled     | Kubernetes                     |
| dashboard                   | minikube | disabled     | Kubernetes                     |
| default-storageclass        | minikube | enabled ✅   | Kubernetes                     |
| efk                         | minikube | disabled     | 3rd party (Elastic)            |
| freshpod                    | minikube | disabled     | Google                         |
| gcp-auth                    | minikube | disabled     | Google                         |
| gvisor                      | minikube | disabled     | Google                         |
| headlamp                    | minikube | disabled     | 3rd party (kinvolk.io)         |
| helm-tiller                 | minikube | disabled     | 3rd party (Helm)               |
| inaccel                     | minikube | disabled     | 3rd party (InAccel             |
|                             |          |              | [info@inaccel.com])            |
| ingress                     | minikube | disabled     | Kubernetes                     |
| ingress-dns                 | minikube | disabled     | Google                         |
| istio                       | minikube | disabled     | 3rd party (Istio)              |
| istio-provisioner           | minikube | disabled     | 3rd party (Istio)              |
| kong                        | minikube | disabled     | 3rd party (Kong HQ)            |
| kubevirt                    | minikube | disabled     | 3rd party (KubeVirt)           |
| logviewer                   | minikube | disabled     | 3rd party (unknown)            |
| metallb                     | minikube | disabled     | 3rd party (MetalLB)            |
| metrics-server              | minikube | disabled     | Kubernetes                     |
| nvidia-driver-installer     | minikube | disabled     | Google                         |
| nvidia-gpu-device-plugin    | minikube | disabled     | 3rd party (Nvidia)             |
| olm                         | minikube | disabled     | 3rd party (Operator Framework) |
| pod-security-policy         | minikube | disabled     | 3rd party (unknown)            |
| portainer                   | minikube | disabled     | 3rd party (Portainer.io)       |
| registry                    | minikube | disabled     | Google                         |
| registry-aliases            | minikube | disabled     | 3rd party (unknown)            |
| registry-creds              | minikube | disabled     | 3rd party (UPMC Enterprises)   |
| storage-provisioner         | minikube | enabled ✅   | Google                         |
| storage-provisioner-gluster | minikube | disabled     | 3rd party (Gluster)            |
| volumesnapshots             | minikube | disabled     | Kubernetes                     |
|-----------------------------|----------|--------------|--------------------------------|
```

Các service của `kube-system` namespace:  
```
$ kubectl get svc --all-namespaces
NAMESPACE     NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
default       kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP                  10m
kube-system   kube-dns     ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   10m
```

Open dashboard:  
```
minikube dashboard
$ minikube dashboard --url
http://192.168.39.117:30000
```

Xem địa chỉ Ip của minikube:
```
minikube ip
# 192.168.49.2
```

Clean up:  
```
$ minikube delete
* Deleting "minikube" in docker ...
* Deleting container "minikube" ...
* Removing /home/ubuntu/.minikube/machines/minikube ...
* Removed all traces of the "minikube" cluster.

$ minikube delete --all --purge
```

# 4. Setup vsftpd FTP server trên Minikube (arm64)

Yêu cầu là:  
- Setup vsftpd FTP server.  
- Viết trong 1 file yaml.  
- Data phải dc persistence.  
- Access đc từ FileZilla.  

Tuy nhiên do mạng nhà mình setup minikube thì quá chậm và yếu, nên mình phải run minikube trên máy ảo Cloud (oracle).  

Khi đó, mình ko thể dùng FileZilla từ laptop để access được, (đã thử cài Wireguard VPN, Tinyproxy)

đành test bằng command line `ftp`.  

Bên ngoài host mình sẽ tạo 1 folder `/opt/devops/ftp-lab/minikube-data-mnt`

Để mount được folder từ bên ngoài host vào trong Minikube VM thì cần mount ngay từ khi start như sau:   
`minikube start --driver=docker --mount --mount-string /opt/devops/ftp-lab/minikube-data-mnt:/mnt/data`

(`/mnt/data` sẽ được tạo ra ở bên trong Minikube VM)

```
$ minikube start --driver=docker --mount --mount-string /opt/devops/ftp-lab/minikube-data-mnt:/mnt/data
* minikube v1.28.0 on Ubuntu 18.04 (arm64)
* Using the docker driver based on user configuration
* Using Docker driver with root privileges
* Starting control plane node minikube in cluster minikube
* Pulling base image ...
* Downloading Kubernetes v1.25.3 preload ...
    > preloaded-images-k8s-v18-v1...:  320.81 MiB / 320.81 MiB  100.00% 133.13
* Creating docker container (CPUs=2, Memory=5900MB) ...
* Preparing Kubernetes v1.25.3 on Docker 20.10.20 ...
  - Generating certificates and keys ...
  - Booting up control plane ...
  - Configuring RBAC rules ...
* Verifying Kubernetes components...
  - Using image gcr.io/k8s-minikube/storage-provisioner:v5
* Enabled addons: storage-provisioner, default-storageclass
* Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default


$ minikube ip
192.168.49.2
```

Vì `docker-vsftpd` ko có image cho arm64 nên phải tự build ở local,  
Các command sau sẽ tạo ra docker image bên trong minikube VM (not host VM nhé)

```sh
eval $(minikube docker-env)
git clone https://github.com/fauria/docker-vsftpd
cd docker-vsftpd
docker build -t terabithians/vsftpd:1.0.0 .
```

Image được tạo ra trong minikube VM (Nếu xóa `minikube delete` thì image này cũng sẽ mất theo):  
```
$ docker images
REPOSITORY                                TAG       IMAGE ID       CREATED          SIZE
terabithians/vsftpd                       1.0.0     46f9af7d0ac2   12 seconds ago   1.09GB
```

File `ftp-k8s-all.yaml`:  

Để ý phần `PersistentVolume`: sẽ thấy `/mnt/data` được define ở đây, chính là đường dẫn được mount từ ngoài vào trong Minikube

```yml
kind: PersistentVolume
apiVersion: v1
metadata:
  name: task-pv-volume
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 3Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"

---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: task-pv-claim
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-ftp-deployment
  labels:
    app: my-ftp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-ftp
  template:
    metadata:
      labels:
        app: my-ftp
    spec:
      volumes:
      - name: task-pv-storage
        persistentVolumeClaim:
          claimName: task-pv-claim
      containers:
      - name: my-ftp-container
        # image: fauria/vsftpd
        image: terabithians/vsftpd:1.0.0
        # imagePullPolicy: Never
        ports:
        - containerPort: 21
        - containerPort: 20
        - containerPort: 30020
        - containerPort: 30021
        volumeMounts:
        - mountPath: "/home/vsftpd"
          name: task-pv-storage
        env:
        - name: FTP_USER
          value: "sftpuser"
        - name: FTP_PASS
          value: "sftp1234"
        - name: PASV_ADDRESS
          value: "192.168.49.2" # minikube: 192.168.49.2
        - name: PASV_MIN_PORT
          value: "30020"
        - name: PASV_MAX_PORT
          value: "30021"

---
apiVersion: v1
kind: Service
metadata:
  name: my-ftp-service
  labels:
    app: my-ftp
spec:
  type: NodePort # LoadBalancer
  ports:
  - port: 21
    targetPort: 21
    nodePort: 30025
    protocol: TCP
    name: ftp21
  - port: 20
    targetPort: 20
    protocol: TCP
    nodePort: 30026
    name: ftp20
  - port: 30020
    targetPort: 30020
    nodePort: 30020
    protocol: TCP
    name: ftp30020
  - port: 30021
    targetPort: 30021
    nodePort: 30021
    protocol: TCP
    name: ftp30021
  selector:
    app: my-ftp
```

```sh
kubectl create ns sftp
kubectl create -f ftp-k8s-all.yaml -n sftp
```

check:  
```
$ k get pods,svc,pvc -n sftp
NAME                                    READY   STATUS    RESTARTS   AGE
pod/my-ftp-deployment-d458df5d8-vlwf5   1/1     Running   0          8m37s

NAME                     TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                                                     AGE
service/my-ftp-service   NodePort   10.99.37.214   <none>        21:30025/TCP,20:30026/TCP,30020:30020/TCP,30021:30021/TCP   8m37s

NAME                                  STATUS   VOLUME           CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/task-pv-claim   Bound    task-pv-volume   3Gi        RWO            manual         8m37s

$ k logs my-ftp-deployment-d458df5d8-b7gd4 -n sftp
        *************************************************
        *                                               *
        *    Docker image: fauria/vsftpd                *
        *    https://github.com/fauria/docker-vsftpd    *
        *                                               *
        *************************************************

        SERVER SETTINGS
        ---------------
        · FTP User: sftpuser
        · FTP Password: sftp1234
        · Log file: /var/log/vsftpd/vsftpd.log
        · Redirect vsftpd log to STDOUT: No.

$ k describe pv task-pv-volume
Name:            task-pv-volume
Labels:          type=local
Annotations:     pv.kubernetes.io/bound-by-controller: yes
Finalizers:      [kubernetes.io/pv-protection]
StorageClass:    manual
Status:          Bound
Claim:           sftp/task-pv-claim
Reclaim Policy:  Retain
Access Modes:    RWO
VolumeMode:      Filesystem
Capacity:        3Gi
Node Affinity:   <none>
Message:
Source:
    Type:          HostPath (bare host directory volume)
    Path:          /mnt/data
    HostPathType:
Events:            <none>


```

test ftp: 
```
$ ftp 192.168.49.2 30025
Connected to 192.168.49.2.
220 (vsFTPd 3.0.2)
Name (192.168.49.2:ubuntu): sftpuser
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.

ftp> pass
Passive mode on.

ftp> ls
227 Entering Passive Mode (192,168,49,2,117,69).
150 Here comes the directory listing.
226 Directory send OK.
```

test thử mkdir để tạo folder `test-1`, `test-2`. 

```
ftp> ls
227 Entering Passive Mode (192,168,49,2,117,69).
150 Here comes the directory listing.
226 Directory send OK.
ftp> mkdir test-1
257 "/test-1" created
ftp> mkdir test-2
257 "/test-2" created
ftp> ls
227 Entering Passive Mode (192,168,49,2,117,68).
150 Here comes the directory listing.
drwx------    2 ftp      ftp          4096 Dec 17 13:30 test-1
drwx------    2 ftp      ftp          4096 Dec 17 13:31 test-2

```

giờ nếu `exit` ra để xem folder `/opt/devops/ftp-lab/minikube-data-mnt`:  
```
ubuntu@ubuntu-oc-gp02:/opt/devops/ftp-lab/minikube-data-mnt/sftpuser$ ll
total 20
drwxr-xr-x 5   14 staff 4096 Dec 17 13:34 ./
drwxrwxr-x 3   14 staff 4096 Dec 17 13:30 ../
drwx------ 2   14 staff 4096 Dec 17 13:36 test-1/
drwx------ 2   14 staff 4096 Dec 17 13:31 test-2/
```
-> chứng tỏ data trong FTP server đã được mount ra ngoài host. 

Giờ thử chiều ngược lại, tạo folder ngoài host xem trong FTP server có hiển thị ko?.  
```
ubuntu@ubuntu-oc-gp02:/opt/devops/ftp-lab/minikube-data-mnt/sftpuser$ ll
total 20
drwxr-xr-x 5   14 staff 4096 Dec 17 13:34 ./
drwxrwxr-x 3   14 staff 4096 Dec 17 13:30 ../
drwx------ 2   14 staff 4096 Dec 17 13:36 test-1/
drwx------ 2   14 staff 4096 Dec 17 13:31 test-2/

ubuntu@ubuntu-oc-gp02:/opt/devops/ftp-lab/minikube-data-mnt/sftpuser$ mkdir oh-dir
ubuntu@ubuntu-oc-gp02:/opt/devops/ftp-lab/minikube-data-mnt/sftpuser$ ll
total 20
drwxr-xr-x 5   14 staff 4096 Dec 17 13:34 ./
drwxrwxr-x 3   14 staff 4096 Dec 17 13:30 ../
drwxr-xr-x 2 root root  4096 Dec 17 13:35 oh-dir/
drwx------ 2   14 staff 4096 Dec 17 13:36 test-1/
drwx------ 2   14 staff 4096 Dec 17 13:31 test-2/
```

Vào FTP server xem:  
```
$ ftp 192.168.49.2 30025
Connected to 192.168.49.2.
220 (vsFTPd 3.0.2)
Name (192.168.49.2:ubuntu): sftpuser
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.

ftp> pass
Passive mode on.

ftp> ls
227 Entering Passive Mode (192,168,49,2,117,69).
150 Here comes the directory listing.
drwxr-xr-x    2 ftp      ftp          4096 Dec 17 13:35 oh-dir -------------> nghĩa là đã OK 
drwx------    2 ftp      ftp          4096 Dec 17 13:36 test-1
drwx------    2 ftp      ftp          4096 Dec 17 13:31 test-2
226 Directory send OK.
```
-> Vậy nghĩa là data trong FTP server đã được mount ra ngoài host OK. 

Giờ sẽ test Trường hợp xóa minikube đi, tạo lại. Thì data vẫn phải được perssistence.

```
# Xóa minikube

ubuntu@ubuntu-oc-gp02:/opt/devops/ftp-lab$ minikube delete
* Deleting "minikube" in docker ...
* Deleting container "minikube" ...
* Removing /home/ubuntu/.minikube/machines/minikube ...
* Removed all traces of the "minikube" cluster.

# Tạo lại minikube với mount vào folder có sẵn data

ubuntu@ubuntu-oc-gp02:/opt/devops/ftp-lab$ minikube start --driver=docker --mount --mount-string /opt/devops/ftp-lab/minikube-data-mnt:/mnt/data
* minikube v1.28.0 on Ubuntu 18.04 (arm64)
* Using the docker driver based on user configuration
* Using Docker driver with root privileges
* Starting control plane node minikube in cluster minikube
* Pulling base image ...
* Creating docker container (CPUs=2, Memory=5900MB) ...
* Preparing Kubernetes v1.25.3 on Docker 20.10.20 ...
  - Generating certificates and keys ...
  - Booting up control plane ...
  - Configuring RBAC rules ...
* Verifying Kubernetes components...
  - Using image gcr.io/k8s-minikube/storage-provisioner:v5
* Enabled addons: default-storageclass, storage-provisioner
* Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

# Tạo lại namespace, resource ftp-k8s-all.yaml

ubuntu@ubuntu-oc-gp02:/opt/devops/ftp-lab$ k get pods -A
NAMESPACE     NAME                               READY   STATUS    RESTARTS      AGE
kube-system   coredns-565d847f94-dxncx           1/1     Running   0             25s
kube-system   etcd-minikube                      1/1     Running   0             38s
kube-system   kube-apiserver-minikube            1/1     Running   0             38s
kube-system   kube-controller-manager-minikube   1/1     Running   0             38s
kube-system   kube-proxy-r74tj                   1/1     Running   0             25s
kube-system   kube-scheduler-minikube            1/1     Running   0             37s
kube-system   storage-provisioner                1/1     Running   1 (24s ago)   36s
ubuntu@ubuntu-oc-gp02:/opt/devops/ftp-lab$ k create ns sftp
namespace/sftp created
ubuntu@ubuntu-oc-gp02:/opt/devops/ftp-lab$ k create -f ftp-k8s-all.yaml -n sftp
persistentvolume/task-pv-volume created
persistentvolumeclaim/task-pv-claim created
deployment.apps/my-ftp-deployment created
service/my-ftp-service created
ubuntu@ubuntu-oc-gp02:/opt/devops/ftp-lab$ k get pods -A
NAMESPACE     NAME                                READY   STATUS    RESTARTS      AGE
kube-system   coredns-565d847f94-dxncx            1/1     Running   0             99s
kube-system   etcd-minikube                       1/1     Running   0             112s
kube-system   kube-apiserver-minikube             1/1     Running   0             112s
kube-system   kube-controller-manager-minikube    1/1     Running   0             112s
kube-system   kube-proxy-r74tj                    1/1     Running   0             99s
kube-system   kube-scheduler-minikube             1/1     Running   0             111s
kube-system   storage-provisioner                 1/1     Running   1 (98s ago)   110s
sftp          my-ftp-deployment-d458df5d8-clstr   1/1     Running   0             49s

# access vào FTP server xem có còn data ko?

ubuntu@ubuntu-oc-gp02:/opt/devops/ftp-lab$ ftp 192.168.49.2 30025
Connected to 192.168.49.2.
220 (vsFTPd 3.0.2)
Name (192.168.49.2:ubuntu): sftpuser
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> ls
500 Illegal PORT command.
ftp: bind: Address already in use
ftp> pas
Passive mode on.
ftp> ls
227 Entering Passive Mode (192,168,49,2,117,69).
150 Here comes the directory listing.
drwxr-xr-x    2 ftp      ftp          4096 Dec 17 13:35 oh-dir
drwx------    2 ftp      ftp          4096 Dec 17 13:36 test-1
drwx------    2 ftp      ftp          4096 Dec 17 13:31 test-2
226 Directory send OK.
```
-> Thấy có sẵn 3 folder trước khi delete minikube, nghĩa là đã Thành Công 😁😁

=> Như vậy là đã hoàn thành được 3/4 yêu cầu, chỉ còn cái access qua FileZilla ko test được.  

CREDIT:  
https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/

# 5. Một số chú ý sau khi làm phần FTP Server

## 5.1. Khác nhau giữa các Access Mode của PV

Câu này có thể bị hỏi khi phỏng vấn:  

`ReadWriteOnce` - The volume can be mounted as read-write by a single node.

`ReadOnlyMany` - The volume can be mounted as read-only by many nodes.

`ReadWriteMany` - The volume can be mounted as read-write by many nodes.

## 5.2. What if request storage của PVC nhỏ hơn PV

Để ý ở phần tạo PV và PVC:  
Mình đang setup PV 3Gi, PVC request 1Gi. Tuy nhiên khi describe pv,pvc ra thì tất cả đều là 3Gi. Ko thấy 1Gi ở đâu cả. 
Như vậy set request 1Gi ở PVC hầu như vô nghĩa. PVC sẽ lấy toàn bộ capacity của PV.   
refer: https://discuss.kubernetes.io/t/when-capacity-of-pvc-is-smaller-than-capacity-of-pc/8572

## 5.3. Check Usage storage của PV, PVC

Hầu như ko có cách chính thức nào để xem usage storage của PV,PVC:  
refer: https://stackoverflow.com/questions/59299503/is-there-an-efficient-way-to-check-the-usage-for-pv-pvc-in-kubernetes
cái plugin được recommend là [kubectl-df-pv](https://github.com/yashbhutwala/kubectl-df-pv) thì lại chỉ support GKE. Không support EKS, AKS, minikube.  
1 cách workaround là dùng 1 busybox: https://stackoverflow.com/a/64627103/9922066   
ngắn gọn là trong deployment sẽ có thêm 1 container run command: `du -sh /home/vsftpd` liên tục sau 10s.  
Rồi khi muốn biết hiện tại usage storage của PV,PVC là bao nhiêu thì get log của busybox ra:  

```yml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-ftp-deployment
  labels:
    app: my-ftp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-ftp
  template:
    metadata:
      labels:
        app: my-ftp
    spec:
      volumes:
      - name: task-pv-storage
        persistentVolumeClaim:
          claimName: task-pv-claim
      containers:
      - name: my-ftp-container
        # image: fauria/vsftpd
        image: terabithians/vsftpd:1.0.0
        # imagePullPolicy: Never
        ports:
        - containerPort: 21
        - containerPort: 20
        - containerPort: 30020
        - containerPort: 30021
        volumeMounts:
        - mountPath: "/home/vsftpd"
          name: task-pv-storage
        env:
        - name: FTP_USER
          value: "sftpuser"
        - name: FTP_PASS
          value: "sftp1234"
        - name: PASV_ADDRESS
          value: "192.168.49.2" # minikube: 192.168.49.2
        - name: PASV_MIN_PORT
          value: "30020"
        - name: PASV_MAX_PORT
          value: "30021"
      - name: busybox
        image: busybox
        command: ["/bin/sh"]
        args: ["-c", "while true; do du -sh /home/vsftpd; sleep 10;done"]
        volumeMounts:
        - mountPath: "/home/vsftpd"
          name: task-pv-storage
```

```
k logs my-ftp-deployment-58565df89d-4b7x9 busybox -n sftp
7.2M    /home/vsftpd
7.2M    /home/vsftpd
7.2M    /home/vsftpd
7.2M    /home/vsftpd
7.2M    /home/vsftpd
7.2M    /home/vsftpd
```
-> mình đang có 7.2M trong PV, PVC

check lại ngoài host:  
```
ubuntu@ubuntu-oc-gp02:/opt/devops/ftp-lab/minikube-data-mnt$ sudo du -sh .
7.2M    .
```

# 6. Troubleshooting (amd64)

Mình dùng Azure VM, OS: Ubuntu 18.04 

Cái amd64 thì có nhiều bài hướng dẫn khá đầy đủ và dễ rồi, mình ko ghi lại nữa

Sau đây là lỗi mình gặp:  

```
$ minikube delete
* Uninstalling Kubernetes v1.25.3 using kubeadm ...
E1215 08:36:54.985219    7380 delete.go:516] unpause failed: kubelet start: sudo systemctl start kubelet: exit status 5
stdout:

stderr:
Failed to start kubelet.service: Unit kubelet.service not found.
X error deleting profile "minikube": failed to delete cluster: /bin/bash -c "sudo env PATH="/var/lib/minikube/binaries/v1.25.3:$PATH" kubeadm reset --cri-socket /var/run/cri-dockerd.sock --force": exit status 127
stdout:

stderr:
env: ‘kubeadm’: No such file or directory
```

-> Cần cài kubeadm: https://cuongquach.com/cai-dat-kubernetes-cluster-voi-kubeadm.html

```sh
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
> deb https://apt.kubernetes.io/ kubernetes-xenial main
> EOF

sudo apt-get update  

sudo apt-get install -y kubelet kubeadm kubectl  
```
Sau đó mới `minikube delete` được.  

# 7. CREDIT

https://cuongquach.com/cai-dat-kubernetes-cluster-voi-kubeadm.html   
https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/   
https://github.com/fauria/docker-vsftpd  
https://github.com/kubernetes/minikube/issues/14924#issuecomment-1241675839  
https://computingforgeeks.com/install-kvm-centos-rhel-ubuntu-debian-sles-arch/   
https://computingforgeeks.com/how-to-run-minikube-on-kvm/   
https://github.com/aledv/kubernetes-ftp  