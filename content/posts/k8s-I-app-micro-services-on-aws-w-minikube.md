---
title: "K8S 1: App Micro Services on AWS with Minikube"
date: 2019-10-11T15:14:01+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Docker,Kubernetes]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "cách 3 là tạo 1 EC2 Ubuntu 18.04 LTS (t2.medium trở lên), cài `minikube` lên nó, dựng 1 cluster"
---

# Giới thiệu

Để vọc Kubernetes trên AWS, có nhiều cách:

cách 1 là dùng Service EKS của AWS, làm việc trên Console luôn, rất trực quan

cách 2 là dùng `eksctl` là CLI của AWS phát triển, nhiệm vụ tương tự như Service EKS, nhưng ta làm việc với nó trên CLI/terminal

cách 3 là tạo 1 EC2 Ubuntu 18.04 LTS (t2.medium trở lên), cài `minikube` lên nó, dựng 1 cluster

=> cách 1 và 2 khá tốn kém, nhưng bạn có thể dùng full service, gần với môi trường production nhất,  
cách 3 thì rẻ hơn nhiều, các bạn chỉ tốn phí duy trì con EC2 Ubuntu thôi, tuy nhiên cách này chỉ nên dùng để vọc vạch, dùng "cho biết" thế nào là k8s thôi 😆

Bài này mình đang ở cách 3, sẽ hướng dẫn cách để dựng 1 app k8s micro-service trên Amazon EC2 Ubuntu

Trước tiên hãy dựa vào mục lục, nếu bạn muốn làm 1 app micro-services bằng Kubernetes thì hãy làm lần lượt các mục `1.b.`→`2.b.`→`3.` nhé (tránh 1 phát vào làm bước `3.` luôn rồi sẽ rơi vào cảnh **ko hiểu mình thiếu cái gì mà bị lỗi**),  
nên làm lần lượt như vậy để hiểu vấn đề, khi đã quen rồi thì có thể bỏ những bước ko cần thiết.

# 1. Deploy 1 Micro-service app trên AWS EC2 

## 1.a. Linux

Launch 1 EC2 Amazon Linux
```sh
cd ~
git clone https://github.com/hoangmnsd/k8s-mastery
```
**Phần frontend**

install nodejs:  

```sh
sudo yum install -y gcc-c++ make
curl -sL https://rpm.nodesource.com/setup_13.x | sudo -E bash -
sudo yum install -y nodejs
node -v
npm -v
```

sửa cái `localhost` bằng `Public IP` của EC2 (giả sử là ip `52.90.234.33`)
```sh
nano ~/k8s-mastery/sa-frontend/src/App.js
```
```
analyzeSentence() {
        fetch('http://52.90.234.33:8080/sentiment', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({sentence: this.textField.getValue()})
        })
            .then(response => response.json())
            .then(data => this.setState(data));
    }
```
Rồi verify nếu muốn
```sh
cd ~/k8s-mastery/sa-frontend
npm install
npm start
```

Verify xong, giờ thì build
```sh
npm run build
```

Install nginx
```sh
sudo yum install nginx
```
Sửa file config nginx, cụ thể là sửa cái path đến folder chứa html của app và add thêm cái phần location đến path /sentiment
```sh
sudo nano /etc/nginx/nginx.conf
```
```
server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  localhost;
        #root         /usr/share/nginx/html;
        root         /home/ec2-user/k8s-mastery/sa-frontend/build;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        
        }

        location /sentiment {
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header Host $http_host;
            proxy_set_header X-NginX-Proxy true;
            proxy_pass http://localhost:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
```
Start nginx để apply thay đổi
```sh
chmod 755 /home/ec2-user/
sudo /etc/init.d/nginx restart
```
Xong phần frontend, dùng browser để vào Public IP của EC2 để check frontend:  
`http://52.90.234.33`

**Sang phần backend Java webapp**

install `maven` và `java 8` theo link https://docs.aws.amazon.com/neptune/latest/userguide/iam-auth-connect-prerq.html

Install dependencies
```sh
cd ~/k8s-mastery/sa-webapp
mvn install
```

Build phần webapp
```sh
cd ~/k8s-mastery/sa-webapp/target
java -jar sentiment-analysis-web-0.0.1-SNAPSHOT.jar --sa.logic.api.url=http://localhost:5000
```

**Sang phần backend Python logic**

Install dependencies
```sh
cd ~/k8s-mastery/sa-logic/sa
sudo python -m pip install -r requirements.txt
python -m textblob.download_corpora
```

Build phần backend logic
```sh
cd ~/k8s-mastery/sa-logic/sa
python sentiment_analysis.py
```

Giờ vào browser test app chạy ok là đc

Xong phần này

## 1.b. Ubuntu

Launch EC2 Ubuntu 18.04
```sh
cd ~
git clone https://github.com/rinormaloku/k8s-mastery
```
**Phần frontend**

sửa cái ip localhost bằng public ip của EC2
```sh
nano ~/k8s-mastery/sa-frontend/src/App.js
```
```
analyzeSentence() {
        fetch('http://52.90.234.33:8080/sentiment', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({sentence: this.textField.getValue()})
        })
            .then(response => response.json())
            .then(data => this.setState(data));
    }
```

Install nodejs, nhớ là bạn đang ở user `ubuntu`, ko phải `root`  
```sh
curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
sudo apt-get install -y nodejs
```

Rồi verify nếu muốn
```sh
cd ~/k8s-mastery/sa-frontend
npm install
npm start
```

Verify xong, giờ thì build
```sh
npm run build
```

Install nginx
```sh
sudo apt install nginx
```

Sửa config của nginx
```sh
sudo nano /etc/nginx/sites-available/default
```
```
# Default server configuration
#
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        # SSL configuration
        #
        # listen 443 ssl default_server;
        # listen [::]:443 ssl default_server;
        #
        # Note: You should disable gzip for SSL traffic.
        # See: https://bugs.debian.org/773332
        #
        # Read up on ssl_ciphers to ensure a secure configuration.
        # See: https://bugs.debian.org/765782
        #
        # Self signed certs generated by the ssl-cert package
        # Don't use them in a production server!
        #
        # include snippets/snakeoil.conf;

        #root /var/www/html;
        root /home/ubuntu/k8s-mastery/sa-frontend/build;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }
        location /sentiment {
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header Host $http_host;
            proxy_set_header X-NginX-Proxy true;
            proxy_pass http://localhost:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
```

Giờ restart nginx
```sh
chmod 755 /home/ubuntu/
sudo /etc/init.d/nginx restart
```
Xong phần frontend, dùng browser để vào Public IP của EC2 để check frontend:  
`http://52.90.234.33`

**Sang phần backend Java webapp**

Cần install maven  https://www.hostinger.com/tutorials/how-to-install-maven-on-ubuntu-18-04/
```sh
sudo apt-get -y install maven
```

install dependencies
```sh
cd ~/k8s-mastery/sa-webapp
mvn install
```

build phần webapp
```sh
cd ~/k8s-mastery/sa-webapp/target
java -jar sentiment-analysis-web-0.0.1-SNAPSHOT.jar --sa.logic.api.url=http://localhost:5000
```
Cứ để cửa sổ terminal đó, bật thêm cái nữa để chạy phần backend Python logic

**Sang phần backend Python logic**

Cần install pip nếu chưa có
```sh
sudo apt install python3-pip
```

Install dependencies
```sh
cd ~/k8s-mastery/sa-logic/sa
sudo python3 -m pip install -r requirements.txt
python3 -m textblob.download_corpora
```

Build phần backend
```sh
cd ~/k8s-mastery/sa-logic/sa
python3 sentiment_analysis.py
```

Cứ để cửa sổ terminal đó, giờ vào browser (`http://52.90.234.33`) test app chạy ok từ frontend đến backend là đc

Xong phần này

# 2. Deploy 1 Micro-service app trên AWS EC2 bằng Docker

Trước tiên cần install docker, cái này khá dễ nên sẽ viết sau

Sau đó đăng ký 1 account Docker Hub

Set các biến môi trường để dùng về sau
```sh
export DOCKER_USERNAME=AAAABBBB
export DOCKER_PASSWORD=CCCCDDDD
export DOCKER_USER_ID=AAAABBBB
```

## 2.a. Linux

Install docker (bonus cả `docker compose`)
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
#Sau đó log out and log in trở lại EC2 để EC2 apply docker user group
```

Login vào Docker Hub với account và password đã đăng ký
```sh
docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
```

**Dockerize phần frontend**

Add các line sau vào để khi build docker sẽ ignore những cái này
```sh
cd ~/k8s-mastery/sa-frontend
nano .dockerignore
```
```
node_modules
src
public
```

Build Docker image
```sh
docker build -f Dockerfile -t $DOCKER_USER_ID/sentiment-analysis-frontend .
```

Push docker image đó lên Docker Hub
```sh
docker push $DOCKER_USER_ID/sentiment-analysis-frontend
```
lúc này docker image mình build ra đã dc push lên Docker Hub, ai cũng có thể dùng dc

Run container
```sh
docker pull $DOCKER_USER_ID/sentiment-analysis-frontend
docker run -d -p 80:80 $DOCKER_USER_ID/sentiment-analysis-frontend
```

nếu bị lỗi `tcp 0.0.0.0:80: bind: address already in use`  
thì kill process root nginx theo bài này: https://github.com/hadim/docker-omero/issues/9

```sh
sudo netstat -tulpn | grep :80
ps aux | grep nginx
sudo kill 1027
```

Test vào Frontend bình thường là ok

**Dockerize phần backend Python logic**

Build và push docker image
```sh
cd  ~/k8s-mastery/sa-logic
docker build -f Dockerfile -t $DOCKER_USER_ID/sentiment-analysis-logic .
docker push $DOCKER_USER_ID/sentiment-analysis-logic
```

Run container
```sh
docker pull $DOCKER_USER_ID/sentiment-analysis-logic
docker run -d -p 5050:5000 $DOCKER_USER_ID/sentiment-analysis-logic
```

**Dockerize phần backend Java webapp**

Build và push docker image
```sh
cd ~/k8s-mastery/sa-webapp
docker build -f Dockerfile -t $DOCKER_USER_ID/sentiment-analysis-webapp .
docker push $DOCKER_USER_ID/sentiment-analysis-webapp
```

Run container
```sh
docker pull $DOCKER_USER_ID/sentiment-analysis-webapp
```

Lấy container ip của sa-logic để dùng bên dưới (sẽ thêm hình ảnh minh họa sau)

```sh
docker container list
docker inspect <container_id của sa-logic> #chỗ này cần thay bằng container_id của sa-logic nhìn thấy ở command "docker container list"
```

Copy cái Containers IP address ở `NetworkSettings.IPAddress`  
Giả sử là `172.17.0.3`

```sh
docker run -d -p 8080:8080 -e SA_LOGIC_API_URL='http://172.17.0.3:5000' $DOCKER_USER_ID/sentiment-analysis-webapp
```

Test app bình thường trên port 8080

Xong phần Dockerize cho app


## 2.b. Ubuntu

*Trước khi làm phần này thì hãy chắc chắn là bạn đã làm phần `1.b. Ubuntu` (để hiểu 1 app để build chạy được cần làm những gì)

Install docker
```sh
sudo apt-get update && \
sudo apt-get install docker.io -y
```

Login vào Docker Hub với account và password đã đăng ký
```sh
sudo docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
```
Hiện như này là đã login thành công:
```
ubuntu@ip-172-31-28-137:~$ sudo docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
WARNING! Your password will be stored unencrypted in /home/ubuntu/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

**Dockerize phần frontend**

Add các line sau vào để khi build docker sẽ ignore những cái này
```sh
cd ~/k8s-mastery/sa-frontend
nano .dockerignore
```
```
node_modules
src
public
```

Build Docker image
```sh
sudo docker build -f Dockerfile -t $DOCKER_USER_ID/sentiment-analysis-frontend .
```

Push docker image đó lên Docker Hub
```sh
sudo docker push $DOCKER_USER_ID/sentiment-analysis-frontend
```
Lúc này docker image mình build ra đã dc push lên Docker Hub, ai cũng có thể dùng dc

Run container
```sh
sudo docker pull $DOCKER_USER_ID/sentiment-analysis-frontend
sudo docker run -d -p 80:80 $DOCKER_USER_ID/sentiment-analysis-frontend
```

Nếu bị lỗi `tcp 0.0.0.0:80: bind: address already in use`  
thì kill process root nginx theo bài này: https://github.com/hadim/docker-omero/issues/9

```sh
sudo netstat -tulpn | grep :80
ps aux | grep nginx
sudo kill 1027
```

Test vào Frontend bình thường là ok

**Dockerize phần backend Python logic**

Build và push docker image
```sh
cd  ~/k8s-mastery/sa-logic
sudo docker build -f Dockerfile -t $DOCKER_USER_ID/sentiment-analysis-logic .
sudo docker push $DOCKER_USER_ID/sentiment-analysis-logic
```

Run container
```sh
sudo docker pull $DOCKER_USER_ID/sentiment-analysis-logic
sudo docker run -d -p 5050:5000 $DOCKER_USER_ID/sentiment-analysis-logic
```

**Dockerize phần backend Java webapp**

Build và push docker image
```sh
cd ~/k8s-mastery/sa-webapp
sudo docker build -f Dockerfile -t $DOCKER_USER_ID/sentiment-analysis-webapp .
sudo docker push $DOCKER_USER_ID/sentiment-analysis-webapp
```

Run container
```sh
sudo docker pull $DOCKER_USER_ID/sentiment-analysis-webapp
```

lấy container ip của sa-logic để dùng bên dưới (sẽ thêm hình ảnh minh họa sau)

```sh
sudo docker container list
sudo docker inspect <container_id của sa-logic> #chỗ này cần thay bằng container_id của sa-logic nhìn thấy ở command "docker container list"
```

copy cái Containers IP address ở `NetworkSettings.IPAddress`  
Giả sử là `172.17.0.3`

```sh
sudo docker run -d -p 8080:8080 -e SA_LOGIC_API_URL='http://172.17.0.3:5000' $DOCKER_USER_ID/sentiment-analysis-webapp
```

Test app bình thường trên port 8080

xong phần Dockerize cho app

# 3. Deploy 1 Micro-service app trên AWS EC2 bằng Kubernetes (Ubuntu)

Không thể chạy **minikube** trên Amazon EC2 Linux được 

(Có 1 cách để dựng app k8s trên Amazon EC2 Linux đó là dùng `eksctl`, tuy nhiên cách này bắt buộc phải để eksctl dựng network, tốn khá nhiều tiền - sẽ có 1 bài về dùng cách `eksctl` này)  

Nên nếu muốn dùng minikube trên Amazon EC2 thì phải chọn Ubuntu - 18.04 LTS - t2.medium  

*Trước khi làm phần này thì hãy chắc chắn là bạn đã có những docker images riêng trên Docker Hub (có thể làm phần `2.b. Ubuntu` ở phía trên để tạo Docker images riêng)  

Install kubectl 
```sh
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

Install docker
```sh
sudo apt-get update && \
sudo apt-get install docker.io -y
```

Install minikube 
```sh
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```

check minikube version:  
```
ubuntu@ip-172-31-17-59:~$ minikube version
minikube version: v1.5.2
commit: 792dbf92a1de583fcee76f8791cff12e0c9440ad-dirty
```

Start minikube lên, từ đây trở xuống sẽ switch sang user `root`
```sh
sudo -i
minikube start --vm-driver=none
```

Check status của minikube
```sh
minikube status
```
Hiện như này là ok:  
```
root@ip-172-31-16-165:~# minikube status
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

Check các node của kubectl
```sh
kubectl get nodes
```
Direct vào thư mục project:  
```sh
cd /home/ubuntu/k8s-mastery/resource-manifests
```

Giờ sẽ tạo 2 pods và 1 Service để loadbalancing 2 pods đó

Best practice thì cần dùng deployment template để tạo các pods  

```sh
nano sa-frontend-deployment.yaml
```
Sửa phần "images" bằng Username trên Docker Hub của bạn:  
```
apiVersion: apps/v1
kind: Deployment                                          # 1
metadata:
  name: sa-frontend
spec:
  replicas: 2                                             # 2: đây là số lượng pods 
  selector:                                               # 3: Pods matching the selector will be taken under the management of this deployment.
    matchLabels:
      app: sa-frontend
  minReadySeconds: 15
  strategy:
    type: RollingUpdate                                   # 4
    rollingUpdate:
      maxUnavailable: 1                                   # 5
      maxSurge: 1                                         # 6
  template:                                               # 7
    metadata:
      labels:
        app: sa-frontend                                  # 8 the label to use for the pods created by this template.
    spec:
      containers:
        - image: hoangmnsd/sentiment-analysis-frontend
          imagePullPolicy: Always                         # 9
          name: sa-frontend
          ports:
            - containerPort: 80
```

Apply cái deployment template mà mình vừa tạo
```sh
kubectl apply -f sa-frontend-deployment.yaml
```

Get các pods hiện đang chạy
```sh
kubectl get pods
```

Nếu muốn xóa pods
```sh
kubectl delete pod <pod-name>
```

Tạo file service load balancer config
```sh
nano service-sa-frontend-lb.yaml
```
```
apiVersion: v1
kind: Service              # 1
metadata:
  name: sa-frontend-lb
spec:
  type: LoadBalancer       # 2 Specification type, we choose LoadBalancer because we want to balance the load between the pods.
  ports:
  - port: 80               # 3 Specifies the port in which the service gets requests.
    protocol: TCP          # 4
    targetPort: 80         # 5 The port at which incomming requests are forwarded.
  selector:                # 6
    app: sa-frontend       # 7 app Defines which pods to target, only pods that are labeled with “app: sa-frontend”
```

Tạo service từ file config đã tạo
```sh
kubectl create -f service-sa-frontend-lb.yaml
```

Check các service kubectl đang chạy
```sh
kubectl get svc
```
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/kube-get-svc.jpg)

Vào browser gõ `http://<public-ip-ec2>:32613`  
thì sẽ ra dc app frontend  
Trước đó thì SG của EC2 nên mở port `TCP 32613` với source là `0.0.0.0/0` để có thể access vào dc từ everywhere  

Nếu muốn delete services thì
```sh
kubectl delete services sa-frontend-lb
```

Giờ giả sử bạn muốn update Dòng chữ "Sentiment Analyser" thành "Sentiment Analyser Update"  
thì bạn sẽ sửa code file `/home/ubuntu/k8s-mastery/sa-frontend/src/App.js`

sau đó build lại frontend  
```sh
cd /home/ubuntu/k8s-mastery/sa-frontend
npm run build
```

sau đó build thành image mới gắn luôn tag là 19 chẳng hạn
```sh
sudo docker build -f Dockerfile -t $DOCKER_USER_ID/sentiment-analysis-frontend:19 .
```

list các images ra
```sh
docker images
```

Nếu muốn đánh lại tag cho image mà mình vừa tạo từ :19 thành :20 chẳng hạn
```sh
docker  tag  hoangmnsd/sentiment-analysis-frontend:19  hoangmnsd/sentiment-analysis-frontend:20
```

push image vừa build xong lên Docker Hub
```sh
sudo docker push $DOCKER_USER_ID/sentiment-analysis-frontend:19
```

tạo deployment config file mới, sửa cái image mình sẽ dùng là cái có tag:19  
```sh
nano sa-frontend-deployment-update.yaml
```
```
apiVersion: apps/v1
kind: Deployment                                          # 1
metadata:
  name: sa-frontend
spec:
  replicas: 2                                             # 2
  selector:
    matchLabels:
      app: sa-frontend
  minReadySeconds: 15
  strategy:
    type: RollingUpdate                                   # 3
    rollingUpdate:
      maxUnavailable: 1                                   # 4
      maxSurge: 1                                         # 5
  template:                                               # 6
    metadata:
      labels:
        app: sa-frontend                                  # 7
    spec:
      containers:
        - image: hoangmnsd/sentiment-analysis-frontend:19
          imagePullPolicy: Always                         # 8
          name: sa-frontend
          ports:
            - containerPort: 80
```

sau đó dùng kubectl để apply lại file deployment yaml với tên mới
```sh
kubectl apply -f sa-frontend-deployment-update.yaml  --record
```

lần lượt 2 pods cũ sẽ bị terminate:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/kube-pods-status-update.jpg)

check status của quá trình rollout images
```sh
kubectl rollout status deployment sa-frontend
```

Vào link `http://<public-ip-ec2>:32613` để confirm sự thay đổi của frontend: "Sentiment Analyser Update"

check lại lịch sử các revision đã dc deploy 
```sh
kubectl rollout history deployment sa-frontend
```

rollback lại bản deploy trước , ví dụ bản 14
```sh
kubectl rollout undo deployment sa-frontend --to-revision=14
```

**Giờ sẽ tạo backend SA-Logic pods**

Deployment SA-Logic

bởi vì trong folder `resource-manifests` đã có sẵn file config k8s để tạo backend SA-logic rồi    
nhưng cũng nên sửa lại để dùng image của mình tạo ra:  
```
image: hoangmnsd/sentiment-analysis-logic 
```

```sh
cd /home/ubuntu/k8s-mastery/resource-manifests
kubectl apply -f sa-logic-deployment.yaml --record
```

**Rồi tạo backend SA-Logic service để load balance traffic giữa các pods của nó**  

deploy Service SA-Logic

```sh
cd /home/ubuntu/k8s-mastery/resource-manifests
kubectl apply -f service-sa-logic.yaml
```

check các pods và services đã được tạo ra bằng command `kubectl get pods` và `kubectl get svc`

**Giờ sẽ tạo backend SA-WebApp pods**  

Deployment SA-WebApp

bởi vì trong folder `resource-manifests` đã có sẵn file config k8s để tạo backend SA-WebApp rồi    
nhưng cũng nên sửa lại để dùng image của mình tạo ra:  
```
image: hoangmnsd/sentiment-analysis-webapp 
```

```sh
cd /home/ubuntu/k8s-mastery/resource-manifests
kubectl apply -f sa-web-app-deployment.yaml --record
```

**Rồi tạo backend SA-WebApp service để load balance traffic giữa các pods của nó** 

Service SA-WebApp
```sh
cd /home/ubuntu/k8s-mastery/resource-manifests
kubectl apply -f service-sa-web-app-lb.yaml
```

list các services của minikube
```sh
minikube service list
```

thấy là sa-web-app-lb đang mở port 30079 (của mình là vậy, của các bạn có thể port khác), nên frontend khi fetch request cần sửa sang port đó

```sh
nano /home/ubuntu/k8s-mastery/sa-frontend/src/App.js
```
```
    analyzeSentence() {
//        fetch('http://54.236.201.29:8080/sentiment', {
        fetch('http://54.236.201.29:30079/sentiment', {
            method: 'POST',
```

Build lại source code, images với tag tùy bạn (ở đây mình chọn 20) và push lên Docker Hub
```sh
cd /home/ubuntu/k8s-mastery/sa-frontend
npm run build
sudo docker build -f Dockerfile -t $DOCKER_USER_ID/sentiment-analysis-frontend:20 .
sudo docker push $DOCKER_USER_ID/sentiment-analysis-frontend:20
```

Sửa lại file config `sa-frontend-deployment-update.yaml` bằng image có tag:20, rồi apply nó

```
image: hoangmnsd/sentiment-analysis-frontend:20
```

```sh
kubectl apply -f sa-frontend-deployment-update.yaml  --record
```
Bằng `kubectl get pods` bạn sẽ thấy 2 pods cũ sẽ dần dần bị terminate, thay bằng 2 pods mới chạy từ cái docker image:20

Nhớ sửa Security Group mở port cho port 30079

Vào lại frontend với port của frontend test app hoàn chỉnh  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/kube-sa-app-done.jpg)


**Bài sau sẽ nói về Kubernetes Dashboard**

**References**:  
https://www.freecodecamp.org/news/learn-kubernetes-in-under-3-hours-a-detailed-guide-to-orchestrating-containers-114ff420e882/  
https://www.radishlogic.com/kubernetes/running-minikube-in-aws-ec2-ubuntu/  
https://blog.kornelondigital.com/2019/04/28/setting-up-a-kubernetes-sandbox-in-aws-ec2/  
https://stackoverflow.com/questions/51912879/is-it-possible-to-setup-a-local-kubernetes-development-environment-minikube-et  
https://docs.aws.amazon.com/neptune/latest/userguide/iam-auth-connect-prerq.html
https://github.com/kubernetes/dashboard/blob/master/docs/user/accessing-dashboard/1.7.x-and-above.md
