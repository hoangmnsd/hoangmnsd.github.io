---
title: "K8S 4: App Micro Services on AWS with eksctl"
date: 2019-11-15T17:09:22+09:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Kubernetes,Docker-compose,eksctl]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bài này mình đang ở cách 2, sẽ hướng dẫn cách để dựng 1 app micro-service (SpringBoot + PostgreSQL) trên AWS bằng 2 phương pháp là `Docker Compose` và `Kubernetes`"
---

# Run Spring Boot + Postgresql App by Docker Compose/Kubernetes

Để vọc Kubernetes trên AWS, có nhiều cách:

cách 1 là dùng Service EKS của AWS, làm việc trên Console luôn, rất trực quan

cách 2 là dùng `eksctl` là CLI của AWS phát triển, nhiệm vụ tương tự như Service EKS, nhưng ta làm việc với nó trên CLI/terminal

cách 3 là tạo 1 EC2 Ubuntu 18.04 LTS (t2.medium trở lên), cài `minikube` lên nó, dựng 1 cluster

=> cách 1 và 2 khá tốn kém, nhưng bạn có thể dùng full service, gần với môi trường production nhất,  
cách 3 thì rẻ hơn nhiều, các bạn chỉ tốn phí duy trì con EC2 Ubuntu thôi, tuy nhiên cách này chỉ nên dùng để vọc vạch, dùng "cho biết" thế nào là k8s thôi 😆

Bài này mình đang ở cách 2, sẽ hướng dẫn cách để dựng 1 app micro-service (SpringBoot + PostgreSQL) trên AWS
bằng 2 phương pháp là `Docker Compose` và `Kubernetes`

## 1. Prepare

Launch 1 EC2 Amazon Linux, t2.micro là đủ, ssh vào rồi làm việc

Để vào bài này thì các bạn cần chuẩn bị môi trường với `eksctl, kubectl`, mình đã hướng dẫn ở link này:  
[K8S 3: Using eksctl on Amazon Linux EC2](../../posts/k8s-iii-using-eksctl-on-amazon-linux/)  

vào link trên các bạn làm đến hết bước **Cách tạo 1 cluster bằng eksctl** là được, rồi quay lại đây làm tiếp  

Make sure you installed `maven`, `java`, `docker`, `docker compose`:  

maven, java: `https://docs.aws.amazon.com/neptune/latest/userguide/iam-auth-connect-prerq.html`

docker, docker compose:  

```sh
sudo yum install git -y
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo -i
curl -L https://github.com/docker/compose/releases/download/1.23.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
exit
#Logout and Login
```
clone project sau:  
```sh
cd ~
git clone https://github.com/hoangmnsd/kubernetes-series
cd kubernetes-series/spring-maven-postgres-docker-k8s
```

## 2. How to run on Kubernetes

### 2.1. Setup

set env of Docker Hub account  
```sh
export AWS_DEFAULT_REGION=us-east-1
export DOCKER_USERNAME=XXXXX
export DOCKER_PASSWORD=YYYYY
docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
```

Edit file này để config db `spring-maven-postgres-docker-k8s/src/main/resources`, nội dùng edit như sau:  
```
#below is config for running in Docker compose
#ENV_DATASOURCE_URL: jdbc:postgresql://postgres/store
#below is config for running in  postgresql in local windows
#ENV_DATASOURCE_URL: jdbc:postgresql://localhost:5432/store
#below is config for running in  K8s, using service_name:5432 to connect db
ENV_DATASOURCE_URL: jdbc:postgresql://docker-postgres:5432/store
```

build jar file
```sh
cd spring-maven-postgres-docker-k8s
mvn clean package
```

build Docker image of `Spring App` and push image to Docker Hub

```sh
cd spring-maven-postgres-docker-k8s
docker build -f Dockerfile -t $DOCKER_USERNAME/docker_spring-boot-containers .
docker push $DOCKER_USERNAME/docker_spring-boot-containers
```

build Docker image of `Postgresql` and push image to Docker Hub

```sh
cd spring-maven-postgres-docker-k8s/docker/postgres
docker build -f Dockerfile -t $DOCKER_USERNAME/docker_postgres .
docker push $DOCKER_USERNAME/docker_postgres
```
### 2.2. Run app 

run app by kubectl:  

trước khi run thì các file trong folder `spring-maven-postgres-docker-k8s/resource-manifests` cần được edit để sử dụng images của riêng các bạn (hiện tại nó đang lấy từ Docker Hub repository của mình), các bạn edit các file yaml chỗ `image` này:  
```
spec:
      containers:
        - image: hoangmnsd/docker_spring-boot-containers
```  
thay bằng Docker Hub account của bạn:  
```
spec:
      containers:
        - image: XXXXX/docker_spring-boot-containers
```

sau đó apply các file config:  
```sh
cd spring-maven-postgres-docker-k8s/resource-manifests
kubectl apply -f docker_postgres-deployment.yaml
kubectl apply -f docker_postgres-service.yaml
kubectl apply -f docker_spring-boot-containers-deployment.yaml
kubectl apply -f docker_spring-boot-containers-service.yaml

kubectl get pods,svc -A
```
output:  
```
NAMESPACE     NAME                                                 READY   STATUS    RESTARTS   AGE
default       pod/docker-postgres-dd794d8bd-wjhhc                  1/1     Running   0          74s
default       pod/docker-postgres-dd794d8bd-xncpf                  1/1     Running   0          74s
default       pod/docker-spring-boot-containers-5cb7c5d684-jc6nq   1/1     Running   0          38s
default       pod/docker-spring-boot-containers-5cb7c5d684-xv2dt   1/1     Running   0          38s
kube-system   pod/aws-node-ntc7n                                   1/1     Running   0          12m
kube-system   pod/coredns-8455f84f99-2b46q                         1/1     Running   0          17m
kube-system   pod/coredns-8455f84f99-zndgw                         1/1     Running   0          17m
kube-system   pod/kube-proxy-h2rw6                                 1/1     Running   0          12m

NAMESPACE     NAME                                    TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)         AGE
default       service/docker-postgres                 ClusterIP      10.100.143.50    <none>                                                                    5432/TCP        52s
default       service/docker-spring-boot-containers   LoadBalancer   10.100.197.147   aff5c4d4f086e11eab08c128b5593723-1463578799.us-east-1.elb.amazonaws.com   80:32700/TCP    17s
default       service/kubernetes                      ClusterIP      10.100.0.1       <none>                                                                    443/TCP         17m
kube-system   service/kube-dns                        ClusterIP      10.100.0.10      <none>                                                                    53/UDP,53/TCP   17m
```
Có thể thấy là kubectl đã tạo ra 4 pod, và 2 service mới

### 2.3. How to test

Using Postman, send POST request to `http://aff5c4d4f086e11eab08c128b5593723-1463578799.us-east-1.elb.amazonaws.com/v1/product` with body:  
```
{"name":"product001"}
```
Chú ý là body của request cần set là `raw` và `JSON`: (ảnh)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/postman-setting-request-body.jpg)

if `success`, Postman sẽ trả về response dạng này:  
```
{
    "product": {
        "id": 1,
        "name": "product001",
        "new": false
    },
    "result": {
        "success": true,
        "message": "Success"
    }
}
```

In Browser, check this link `http://aff5c4d4f086e11eab08c128b5593723-1463578799.us-east-1.elb.amazonaws.com/v1/product/product001`

if `success` browser sẽ trả về chuỗi này (quá trình chờ ELB available tốn khá nhiều thời gian, chắc khoảng 3 phút):  
`{"product":{"id":1,"name":"product001","new":false},"result":{"success":true,"message":"Success"}}`  

(ảnh)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/k8s-spring-postgres-get-req.jpg)

Vậy là xong, giờ các bạn chỉ cần lục lọi cái project đó để xem k8s nó hoạt động như nào thôi😆  

### 2.4. Using NodePort instead of LoadBalancer

Ở trên `service/docker-spring-boot-containers` đang dùng type `LoadBalancer` kiểu này tất nhiên sẽ tốn tiền `LoadBalancer` (0.025$ per hour, 0.008$ per GB) nên nếu bạn muốn tiết kiệm thì nên dùng `NodePort`

```sh
kubectedit svc docker-spring-boot-containers
```

sửa thành như sau(chủ yếu sửa `type` và `ports`):  
```
  externalTrafficPolicy: Cluster
  ports:
  - nodePort: 31138 #chỗ này chỉ có thể chọn từ 30000 đến 32267
    port: 12345
    protocol: TCP
    targetPort: 12345
  selector:
    app: docker-spring-boot-containers
  sessionAffinity: None
  type: NodePort
```
`nodePort`: port mà sẽ outside có thể access được vào  
`port`: giữa các service sẽ nói chuyện với nhau qua port này  
`targetPort`: port mà pod thực sự đang running  

sau khi sửa xong thì từ bên ngoài có thể access vào bằng cách port-forward  
```sh
kubectl port-forward -n default service/docker-spring-boot-containers 31138:12345 --address 0.0.0.0
```

### 2.5. Test on NodePort

Using Postman, send POST request to `http://<EC2-PUBLIC-IP>:31138/v1/product` with body:  
```
{"name":"product001"}
```

if `success`, Postman sẽ trả về response dạng này:  
```
{
    "product": {
        "id": 1,
        "name": "product001",
        "new": false
    },
    "result": {
        "success": true,
        "message": "Success"
    }
}
```

In Browser, check this link `http://<EC2-PUBLIC-IP>:31138/v1/product/product001`

if `success` browser sẽ trả về chuỗi này:  
`{"product":{"id":1,"name":"product001","new":false},"result":{"success":true,"message":"Success"}}`  

## 3. How to run by Docker Compose

### 3.1. Setup

Make sure below config in `spring-maven-postgres-docker-k8s/src/main/resources` :  
```
#below is config for running in Docker compose
ENV_DATASOURCE_URL: jdbc:postgresql://postgres/store
#below is config for running in  postgresql in local windows
#ENV_DATASOURCE_URL: jdbc:postgresql://localhost:5432/store
#below is config for running in  K8s, using service_name:5432 to connect db
#ENV_DATASOURCE_URL: jdbc:postgresql://docker-postgres:5432/store
```

### 3.2. Run app

```sh
cd spring-maven-postgres-docker-k8s
sh cleanRun.sh
```

### 3.3. How to test

Using Postman, send POST request to `http://<EC2-PUBLIC-IP>:12345/v1/product` with body:  
```
{"name":"product001"}
```

if `success`:  
```
{
    "product": {
        "id": 1,
        "name": "product001",
        "new": false
    },
    "result": {
        "success": true,
        "message": "Success"
    }
}
```
In Browser, check this link `http://<EC2-PUBLIC-IP>:12345/v1/product/product001`

if `success`:  
`{"product":{"id":1,"name":"product001","new":false},"result":{"success":true,"message":"Success"}}`

## 4. How to run in local windows machine

### 4.1. Setup

Make sure you install maven, java8, Intelij IDEA, Postgresql.  

Config postgresql open port 5432, create database `store`, and user `dbuser`/password `password`

execute below query on PgAdmin4:  

```
GRANT ALL PRIVILEGES ON DATABASE "store" TO "dbuser";
    create table if not exists product
    (
      id  bigint not null constraint product_pkey primary key,
      name  varchar(255) UNIQUE
    );
    CREATE SEQUENCE IF NOT EXISTS hibernate_sequence START 1;
```

Edit `src/main/resources/application.yml`, uncomment set config like this

```
#below is config for Docker compose
#ENV_DATASOURCE_URL: jdbc:postgresql://postgres/store
#below is config for postgresql in local windows
ENV_DATASOURCE_URL: jdbc:postgresql://localhost:5432/store
#below is config for k8s, using service_name:5432 to connect db
#ENV_DATASOURCE_URL: jdbc:postgresql://docker-postgres:5432/store
```

### 4.2. Run app

```sh
cd spring-maven-postgres-docker-k8s
mvn spring-boot:run
```

### 4.3. How to test

Using Postman, send POST request to `http://localhost:12345/v1/product` with body:  
```
{"name":"product001"}
```

if `success`:  
```
{
    "product": {
        "id": 1,
        "name": "product001",
        "new": false
    },
    "result": {
        "success": true,
        "message": "Success"
    }
}
```

In Browser, check this link `http://localhost:12345/v1/product/product001`

if `success`:  
`{"product":{"id":1,"name":"product001","new":false},"result":{"success":true,"message":"Success"}}`

# Bonus

Dưới đây là hướng dẫn cách xây dựng 1 base project chạy app Spring Boot + PostgreSQL bằng Docker Compose

Nếu muốn 1 project chạy bằng Maven, thì hãy vào folder này rồi đọc file `README.md`:  
https://github.com/hoangmnsd/kubernetes-series/tree/master/spring-maven-postgres-docker

Nếu muốn 1 project chạy bằng Gradle, thì hãy vào folder này rồi đọc file `README.md`:  
https://github.com/hoangmnsd/kubernetes-series/tree/master/spring-gradle-postgres-docker

**Reference**:  
Special thank to `muzir` because this   
https://muzir.github.io/spring/docker/docker-compose/postgres/2019/03/24/Spring-Boot-Docker.html

