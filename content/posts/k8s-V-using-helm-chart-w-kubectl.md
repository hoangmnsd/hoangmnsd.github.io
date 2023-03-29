---
title: "K8S 5: Using Helm Chart With Kubectl"
date: 2019-11-19T17:25:05+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Kubernetes,Helm,kubectl]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Mô tả việc sử dụng Helm Chart"
---

# Giới thiệu

Trước khi dùng helm, mình đã dùng `kubectl` để run app này ok:  
https://github.com/hoangmnsd/kubernetes-series/tree/master/spring-maven-postgres-docker-k8s

tuy nhiên việc chạy riêng từng command `kubectl apply -f …` và việc quản lý version tập trung của `kubectl` bất tiện đã dẫn đến việc cần dùng Helm để quản lý kubernetes cluster  

Vậy nên giờ mình sẽ cấu trúc lại folder `https://github.com/hoangmnsd/kubernetes-series/tree/master/spring-maven-postgres-docker-k8s`
để sử dụng được Helm, 

Sau khi cấu trúc lại thì kết quả cuối cùng là project này `https://github.com/hoangmnsd/kubernetes-series/tree/master/spring-maven-postgres-docker-k8s-helm`

Giờ mình sẽ mô tả lại các bước đã làm để cấu trúc lại project đó

# Chuẩn bị 

Workplace: `Amazon EC2 Linux`

Đầu tiên cần đảm bảo đã tạo ra cluster, có thể tạo bằng `eksctl` chẳng hạn

sau đó là install helm + tiller  
(https://eksworkshop.com/helm_root/helm_intro/install/)
```sh
cd ~/environment
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod +x get_helm.sh
./get_helm.sh
```

Tạo `rbac.yaml`
```sh
cat <<EoF > ~/environment/rbac.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
EoF
```

Sau mỗi lần xóa đi tạo lại cluster, bạn đều cần làm bước này để install Tiller (còn gọi là helm server-side) lên cluster
```sh
kubectl apply -f ~/environment/rbac.yaml
helm init --service-account tiller
```

```
$ helm version
Client: &version.Version{SemVer:"v2.16.1", GitCommit:"bbdfe5e7803a12bbdf97e94cd847859890cf4050", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.16.1", GitCommit:"bbdfe5e7803a12bbdf97e94cd847859890cf4050", GitTreeState:"clean"}
[ec2-user@ip-172-31-84-250 environment]$ kubectl get pods,svc -A
NAMESPACE     NAME                                 READY   STATUS    RESTARTS   AGE
kube-system   pod/aws-node-rjgp7                   1/1     Running   0          12m
kube-system   pod/coredns-8455f84f99-kjxvs         1/1     Running   0          17m
kube-system   pod/coredns-8455f84f99-tlmql         1/1     Running   0          17m
kube-system   pod/kube-proxy-5hpd7                 1/1     Running   0          12m
kube-system   pod/tiller-deploy-586965d498-q9pc4   1/1     Running   0          8m52s

NAMESPACE     NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)         AGE
default       service/kubernetes      ClusterIP   10.100.0.1       <none>        443/TCP         17m
kube-system   service/kube-dns        ClusterIP   10.100.0.10      <none>        53/UDP,53/TCP   17m
kube-system   service/tiller-deploy   ClusterIP   10.100.162.227   <none>        44134/TCP       8m52s
```

# Bắt đầu dùng Helm

```sh
helm repo update
```

create 1 chart tên tự define như sau:
```sh
helm create spring-maven-postgres-docker-k8s-helm
```

chart mới tạo có cấu trúc thư mục như sau
```sh
cd spring-maven-postgres-docker-k8s-helm
```

```
tree
├── charts
├── Chart.yaml
├── templates
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── ingress.yaml
│   ├── NOTES.txt
│   ├── serviceaccount.yaml
│   ├── service.yaml
│   └── tests
│       └── test-connection.yaml
└── values.yaml
```

trong folder `/templates`, Helm đã tạo cho chúng ta những default resource, 
nhưng mình cần dùng những resource mình đã tạo từ trước cơ, nên hãy xóa hết các file trong `/templates` đi
chỉ cần giữ lại cái `serviceaccount.yaml` thôi

Copy những file template yaml cũ (có sẵn) vào thư mục templates

cấu trúc mới như sau:
```
├── charts
├── Chart.yaml
├── templates
│   ├── docker_postgres-deployment.yaml
│   ├── docker_postgres-service.yaml
│   ├── docker_spring-boot-containers-deployment.yaml
│   ├── docker_spring-boot-containers-service.yaml
│   ├── _helpers.tpl
│   ├── serviceaccount.yaml
│   └── tests
│       └── test-connection.yaml
└── values.yaml
```

Cần chỉnh sửa file `values.yaml` để sử dụng nó  
các file yaml cũ cũng cần được chỉnh sửa lại, ví dụ như file `docker_postgres-deployment.yaml`

cụ thể thì các bạn xem file đã sửa ở đây  
https://github.com/hoangmnsd/kubernetes-series/tree/master/spring-maven-postgres-docker-k8s-helm/templates

Giờ có thể deploy helm chart
```sh
helm install --name spring-maven-postgres-docker-k8s-helm .
```

```
$ helm install --name spring-maven-postgres-docker-k8s-helm .
NAME:   spring-maven-postgres-docker-k8s-helm
LAST DEPLOYED: Mon Nov 18 14:17:37 2019
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Deployment
NAME                           AGE
docker-postgres                0s
docker-spring-boot-containers  0s

==> v1/Pod(related)
NAME                                            AGE
docker-postgres-748bcf79db-tcgp8                0s
docker-spring-boot-containers-6f8c4fbbbb-pnkng  0s

==> v1/Service
NAME                           AGE
docker-postgres                0s
docker-spring-boot-containers  0s

==> v1/ServiceAccount
NAME                                   AGE
spring-maven-postgres-docker-k8s-helm  0s
```

```
$ kubectl get pods,svc,serviceaccount -A
NAMESPACE     NAME                                                 READY   STATUS    RESTARTS   AGE
default       pod/docker-postgres-748bcf79db-tcgp8                 1/1     Running   0          19s
default       pod/docker-spring-boot-containers-6f8c4fbbbb-pnkng   1/1     Running   0          19s
kube-system   pod/aws-node-wg64q                                   1/1     Running   0          78m
kube-system   pod/coredns-8455f84f99-r78gk                         1/1     Running   0          85m
kube-system   pod/coredns-8455f84f99-szqsl                         1/1     Running   0          85m
kube-system   pod/kube-proxy-ddjhk                                 1/1     Running   0          78m
kube-system   pod/tiller-deploy-586965d498-64pt8                   1/1     Running   0          69m

NAMESPACE     NAME                                    TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)         AGE
default       service/docker-postgres                 ClusterIP      10.100.193.192   <none>                                                                   5432/TCP        19s
default       service/docker-spring-boot-containers   LoadBalancer   10.100.24.212    a2c8bb9720a0e11eaaeb412190640976-542595414.us-east-1.elb.amazonaws.com   80:30911/TCP    19s
default       service/kubernetes                      ClusterIP      10.100.0.1       <none>                                                                   443/TCP         85m
kube-system   service/kube-dns                        ClusterIP      10.100.0.10      <none>                                                                   53/UDP,53/TCP   85m
kube-system   service/tiller-deploy                   ClusterIP      10.100.14.180    <none>                                                                   44134/TCP       69m

NAMESPACE         NAME                                                   SECRETS   AGE
default           serviceaccount/default                                 1         85m
default           serviceaccount/spring-maven-postgres-docker-k8s-helm   1         19s
```

muốn get logs trong 1 pod nào đó
```sh
kubectl  logs  <POD_NAME>
```

sau mỗi lần edit file yaml, cần phải upgrade helm chart
```sh
helm upgrade spring-maven-postgres-docker-k8s-helm .
```

muốn xóa helm chart thì 
`helm ls` để lấy tên
```sh
helm delete <CHART_NAME>
```

command trên chưa phải xóa triệt để, vẫn có thể thấy bằng cách "helm list --all"

Nếu muốn rollback lại cái helm chart vừa xóa thì
```sh
helm rollback <CHART_NAME> <REVISON>
```

Nếu muốn thực sự xóa thì 
```sh
helm delete --purge <CHART_NAME>
```

đóng cả cái chart thành package
```sh
helm package .
```
nó sẽ tạo thành 1 file package .tgz

tạo repo index
```sh
helm repo index .
```
Nó sẽ tạo file `index.html`

Git push lên 1 repo nào đấy trên github  
Lấy link raw `https://raw.githubusercontent.com/<ACCOUNT_NAME>/<REPO>/<BRANCH>`

add repo lấy raw từ github
```sh
helm  repo  add  spring-postgres  https://raw.githubusercontent.com/hoangmnsd/spring-maven-postgres-docker-k8s-helm/master
```

list all repo
```sh
helm repo list
```

sau này có thể install bằng command
```sh
helm  install  --name  spring-maven-postgres-docker-k8s-helm  spring-postgres/spring-maven-postgres-docker-k8s-helm
```

**REFERENCES**:   
https://github.com/red-gate/ks/blob/master/ks5/ks5.md  
https://medium.com/ingeniouslysimple/deploying-kubernetes-applications-with-helm-81c9c931f9d3