---
title: "K8S 11: Using Keel on GKE Cluster for Continuous Deployment (CD)"
date: 2020-05-09T17:36:12+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Keel,GKE,CI/CD,Kubernetes] 
comments: false
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Keel được đánh giá là 1 tool dễ cài đặt, dễ sử dụng, và rất **nhẹ**. Bài này chỉ đơn giản là mình muốn demo về cách sử dụng 1 tool `lightweight` được nhiều người giới thiệu (Keel) thôi. Ngoài ra còn 1 số tool khác cũng được suggest nhiều, đó là Weave Flux. Tool này nhiều chức năng hơn Keel, mình cũng muốn thử dùng trong tương lai."
---

# Giới thiệu
> Keel is a tool for automating Kubernetes deployment updates. Keel is stateless, robust and lightweight.

Keel được đánh giá là 1 tool dễ cài đặt, dễ sử dụng, và rất **nhẹ**.  
Bài này chỉ đơn giản là mình muốn demo về cách sử dụng 1 tool `lightweight` được nhiều người giới thiệu (Keel) thôi. Ngoài ra còn 1 số tool khác cũng được suggest nhiều, đó là Weave Flux. Tool này nhiều chức năng hơn Keel, mình cũng muốn thử dùng trong tương lai.

quay lại với Keel:

# Yêu cầu
Không gì khác ngoài 1 Cluster trên GKE.  
Ngoài ra bài này mình sẽ dùng Docker Hub để làm Registry (chỗ lưu Docker images) nên bạn cũng cần có account Docker Hub.

# Cách làm

1- Trong Cloudshell của GCP Console, tạo folder để làm workspace của bạn
```sh
mkdir keel-demo-golang-app && cd keel-demo-golang-app
```

2- Chuẩn bị các biến môi trường, và login và Docker account của bạn
```sh
export DOCKER_USERNAME=AAAAAA
export DOCKER_PASSWORD=BBBBBB
docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
```

3- Viết 1 app đơn giản chạy bằng Go (command sau sẽ tạo ra file `main.go`)
```sh
cat > ./main.go <<EOF
package main

import (
 "fmt"
 "log"
 "net/http"
)

var version = 1

func handler(w http.ResponseWriter, r *http.Request) {
 fmt.Fprintln(w, "Hello 世界... from v %s", version)
}
func main() {
 http.HandleFunc("/", handler)
 log.Fatal(http.ListenAndServe(":8888", nil))
}
EOF
```

4- Tạo Dockerfile và build images riêng của bạn
```sh
cat > ./Dockerfile <<EOF
FROM golang:1.11-alpine AS build
WORKDIR /
COPY main.go go.* /
RUN CGO_ENABLED=0 go build -o /bin/demo
FROM scratch 
COPY --from=build /bin/demo /bin/demo
ENTRYPOINT ["/bin/demo"] 
EOF
```

5- Build image từ Dockerfile trên
```sh
docker image build -t keeldemo:latest .
```

Confirm rằng images đã được tạo ra
```
docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
keeldemo            latest              83dc90c47721        18 seconds ago      6.51MB
<none>              <none>              37109af028d4        19 seconds ago      325MB
golang              1.11-alpine         e116d2efa2ab        8 months ago        312MB
```

Đánh tag cho images đó
```sh
docker image tag keeldemo:latest $DOCKER_USERNAME/keeldemo:latest
```

Push images có tag `latest` đó lên Docker Hub của bạn
```sh
docker push $DOCKER_USERNAME/keeldemo:latest
```

6- Login to your GKE cluster
```
gcloud container clusters get-credentials <YOUR_CLUSTER> --zone asia-northeast1-a --project <YOUR_PROJECT>
Fetching cluster endpoint and auth data.
kubeconfig entry generated for <YOUR_CLUSTER>.
```

7- Install Keel to your cluster, this will create new `keel` namespace for Keel
```sh
kubectl apply -f https://sunstone.dev/keel?namespace=keel&username=admin&password=admin&tag=latest
```

Check your Keel pods and service
```
kubectl get pods,svc -A
NAMESPACE     NAME                                                      READY   STATUS    RESTARTS   AGE
keel          pod/keel-7c75bc645c-tpbzw                                 1/1     Running   0          99s
kube-system   pod/kube-dns-5f7d7d8796-5kz4s                             3/3     Running   0          14m
kube-system   pod/kube-dns-autoscaler-6b7f784798-xtm6s                  1/1     Running   0          14m
kube-system   pod/kube-proxy-gke-hoang1105-default-pool-4cc65383-5zqf   1/1     Running   0          14m
kube-system   pod/l7-default-backend-84c9fcfbb-rv8fs                    1/1     Running   0          14m
kube-system   pod/metrics-server-v0.3.3-7599dd85cd-vmzqb                2/2     Running   0          14m

NAMESPACE     NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)          AGE
default       service/kubernetes             ClusterIP      10.68.0.1       <none>         443/TCP          14m
keel          service/keel                   LoadBalancer   10.68.170.35    35.221.94.65   9300:32712/TCP   101s
kube-system   service/default-http-backend   NodePort       10.68.178.170   <none>         80:32137/TCP     14m
kube-system   service/kube-dns               ClusterIP      10.68.0.10      <none>         53/UDP,53/TCP    14m
kube-system   service/metrics-server         ClusterIP      10.68.177.176   <none>         443/TCP          14m
```

8- Tạo file `keel-demo-deployment.yaml` để deploy simple app
```sh
cat > ./keel-demo-deployment.yaml <<EOF
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: wd
  namespace: default
  labels:
    name: "wd"
  annotations:
    keel.sh/policy: major
    keel.sh/trigger: poll
    keel.sh/pollSchedule: "@every 30s"
spec:
  replicas: 1
  template:
    metadata:
      name: wd
      labels:
        app: wd
    spec:
      containers:
        - image: $DOCKER_USERNAME/keeldemo:latest
          imagePullPolicy: Always
          name: wd
          ports:
            - containerPort: 8888
EOF
```
Giải thích file trên:  
Giống như những file Deployment bình thường,  
nhưng được add thêm annotations để dùng `keel`,  
cứ 30s nó sẽ poll từ Docker Hub của bạn về xem có images mới ko,  
nếu có thì nó sẽ tạo pod mới từ images mới 1 cách tự động (Đây chính là CD (Continuos Deployment))

Deploy your simple application
```sh
kubectl apply -f keel-demo-deployment.yaml
```

Check your simple app pod:
```
kubectl get pods,svc -A
k get pods,svc -A
NAMESPACE     NAME                                                      READY   STATUS    RESTARTS   AGE
default       pod/wd-75c65cbf5b-fg2r2                                   1/1     Running   0          8s
keel          pod/keel-7c75bc645c-tpbzw                                 1/1     Running   0          3m33s
kube-system   pod/kube-dns-5f7d7d8796-5kz4s                             3/3     Running   0          16m
kube-system   pod/kube-dns-autoscaler-6b7f784798-xtm6s                  1/1     Running   0          16m
kube-system   pod/kube-proxy-gke-hoang1105-default-pool-4cc65383-5zqf   1/1     Running   0          16m
kube-system   pod/l7-default-backend-84c9fcfbb-rv8fs                    1/1     Running   0          16m
kube-system   pod/metrics-server-v0.3.3-7599dd85cd-vmzqb                2/2     Running   0          16m

NAMESPACE     NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)          AGE
default       service/kubernetes             ClusterIP      10.68.0.1       <none>         443/TCP          16m
keel          service/keel                   LoadBalancer   10.68.170.35    35.221.94.65   9300:32712/TCP   3m34s
kube-system   service/default-http-backend   NodePort       10.68.178.170   <none>         80:32137/TCP     16m
kube-system   service/kube-dns               ClusterIP      10.68.0.10      <none>         53/UDP,53/TCP    16m
kube-system   service/metrics-server         ClusterIP      10.68.177.176   <none>         443/TCP          16m
```

9- View app của bạn bằng chức năng Web Preview của Cloudshell
```sh
kubectl port-forward pod/wd-75c65cbf5b-fg2r2 8888:8888 
```
(ảnh)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/using-keel-k8s-v1.jpg)

# Test
Giờ bạn muốn deploy 1 version mới của app thì chỉ cần tạo dc images mới thôi. Công việc còn lại do keel xử lý

1- Sửa app thành version `2`
```
package main

import (
 "fmt"
 "log"
 "net/http"
)

var version = 2

func handler(w http.ResponseWriter, r *http.Request) {
 fmt.Fprintln(w, "Hello 世界... from v", version)
}
func main() {
 http.HandleFunc("/", handler)
 log.Fatal(http.ListenAndServe(":8888", nil))
}
```

2- Build, tag, và push lại image mới lên Docker Hub
```sh
docker image build -t keeldemo:latest .
docker image tag keeldemo:latest $DOCKER_USERNAME/keeldemo:latest
docker push $DOCKER_USERNAME/keeldemo:latest
``` 

Chờ 30s và check pod mới của app đã được tạo ra
```
kubectl get pods,svc -A
NAMESPACE     NAME                                                      READY   STATUS    RESTARTS   AGE
default       pod/wd-69c5c4fd89-xwxhn                                   1/1     Running   0          12s
keel          pod/keel-7c75bc645c-tpbzw                                 1/1     Running   0          19m
kube-system   pod/kube-dns-5f7d7d8796-5kz4s                             3/3     Running   0          32m
kube-system   pod/kube-dns-autoscaler-6b7f784798-xtm6s                  1/1     Running   0          32m
kube-system   pod/kube-proxy-gke-hoang1105-default-pool-4cc65383-5zqf   1/1     Running   0          32m
kube-system   pod/l7-default-backend-84c9fcfbb-rv8fs                    1/1     Running   0          32m
kube-system   pod/metrics-server-v0.3.3-7599dd85cd-vmzqb                2/2     Running   0          32m

NAMESPACE     NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)          AGE
default       service/kubernetes             ClusterIP      10.68.0.1       <none>         443/TCP          32m
keel          service/keel                   LoadBalancer   10.68.170.35    35.221.94.65   9300:32712/TCP   19m
kube-system   service/default-http-backend   NodePort       10.68.178.170   <none>         80:32137/TCP     32m
kube-system   service/kube-dns               ClusterIP      10.68.0.10      <none>         53/UDP,53/TCP    32m
kube-system   service/metrics-server         ClusterIP      10.68.177.176   <none>         443/TCP          32m
```

3- View app của bạn bằng chức năng Web Preview của Cloudshell
```sh
kubectl port-forward pods/wd-69c5c4fd89-xwxhn 8888:8888 
```
(ảnh)  
Version đã được thay đổi  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/using-keel-k8s-v2.jpg)

Done! Như vậy là về cơ bản ta đã hiểu được cách thức hoạt động của keel, ngoài ra keel còn 1 vài tính năng hay ho nữa (notify qua Slack, UI Dashboard, integrate với AWS ECR, GCR, Gitlab...) mà bạn có thể tìm hiểu trên trang chủ của keel tại đây (https://keel.sh)



# CREDIT 

https://github.com/keel-hq/keel  
https://keel.sh  
https://github.com/Chams91/Golang_keelDemo  
