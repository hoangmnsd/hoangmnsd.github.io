---
title: "K8S 6: Using Postgresql Run Outside Cluster (in Another Host Ec2)"
date: 2019-11-21T10:39:03+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Postgresql,Kubernetes]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "If you delete the database pod all data is lost. We'll fix this by using a database that lives externally to our cluster."
---

> If you delete the database pod all data is lost. We'll fix this by using a database that lives externally to our cluster.

# Yêu cầu

Workplace: Amazon EC2 Linux

Đã tạo môi trường, cluster của riêng bạn, có thể dùng `eksctl` tạo từ file `cluster.yaml` sau
```
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: base-project
  region: us-east-1

availabilityZones: ["us-east-1a", "us-east-1d"]

nodeGroups:
  - name: nodegrp-1
    instanceType: t2.medium
    desiredCapacity: 1
    ssh: # import public key from file
      publicKeyPath: /home/ec2-user/.ssh/id_rsa.pub
```
**Chú ý**:  
Sử dụng `ssh-keygen` để generate ra bộ key (id_rsa.pub, id_rsa) dùng để SSH vào Node

## Tạo cluster
```sh
eksctl create cluster -f cluster.yaml
```

## Clone project
```sh
cd ~
git clone https://github.com/hoangmnsd/kubernetes-series
cd kubernetes-series
ll
```

Bài này sẽ dựa trên 2 folder `spring-maven-postgres-docker-k8s-helm` và `spring-maven-postgres-docker-k8s`

Cuối cùng sẽ lưu lại sản phẩm trong folder `spring-maven-postgres-docker-k8s-helm-externaldb`

# Cách làm

## Khái quát

>trước tiên mục tiêu mình sẽ để PostgreSQL DB chạy trên con workplace EC2 bằng docker. Rồi trên cluster sẽ chỉ chạy app Spring boot thôi, và app đó sẽ chọc vào PostgreSQL DB mình đã tạo  

## Cụ thể

Chuẩn bị biến môi trường
```sh
export AWS_DEFAULT_REGION=us-east-1
export DOCKER_USERNAME=AAAAAA
export DOCKER_PASSWORD=BBBBBB
export DOCKER_USER_ID=CCCCCC
docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
```

Giờ sẽ chạy con postgreSQL DB  
Trong trường hợp chưa có image thì cần build docker image trước:  
```sh
cd spring-maven-postgres-docker-k8s/docker/postgres
docker build -f Dockerfile -t $DOCKER_USERNAME/docker_postgres .
```

Vì cái image Postgres cần truyền vào các biến môi trường env nên mình chạy lệnh sau:  
```sh
docker run --env POSTGRES_USER=dbuser --env POSTGRES_PASSWORD=password --env POSTGRES_DB=store  -d -p 5432:5432 hoangmnsd/docker_postgres
```

Sau khi chạy xong muốn check việc tạo db đã ok chưa thì ssh vào container đó
```sh
docker ps
docker exec -it <CONTAINER_NAME> bash
su postgres
psql -p 5432 store -U dbuser
# show all database
\list
# show all table
\d
```
Nếu thấy database "store" và table "product" có nghĩa là đã run db thành công

```
root@7b00518cc6c3:/# su postgres
postgres@7b00518cc6c3:/$ psql -p 5432 store -U dbuser
psql (12.0 (Debian 12.0-2.pgdg100+1))
Type "help" for help.

store=# \l
                              List of databases
   Name    | Owner  | Encoding |  Collate   |   Ctype    | Access privileges
-----------+--------+----------+------------+------------+-------------------
 postgres  | dbuser | UTF8     | en_US.utf8 | en_US.utf8 |
 store     | dbuser | UTF8     | en_US.utf8 | en_US.utf8 | =Tc/dbuser       +
           |        |          |            |            | dbuser=CTc/dbuser
 template0 | dbuser | UTF8     | en_US.utf8 | en_US.utf8 | =c/dbuser        +
           |        |          |            |            | dbuser=CTc/dbuser
 template1 | dbuser | UTF8     | en_US.utf8 | en_US.utf8 | =c/dbuser        +
           |        |          |            |            | dbuser=CTc/dbuser
(4 rows)

store=# \d
                List of relations
 Schema |        Name        |   Type   | Owner
--------+--------------------+----------+--------
 public | hibernate_sequence | sequence | dbuser
 public | product            | table    | dbuser
(2 rows)
```

Giờ nên test connection giữa Node và Host (Workplace EC2) xem đã connect dc tới DB hay chưa

SSH vào Node
```sh
ssh -i ~/.ssh/id_rsa ec2-user@<EC2-NODE-PUBLIC-IP>
```

Bởi vì Node là Amazon linux 2, nên cần install psql client bằng command sau:
```sh
sudo amazon-linux-extras install postgresql10 -y
```

Sau đó dùng `psql` để connect vào DB đang chạy trên Workplace xem được ko
```sh
# psql -h <EC2-PUBLIC-IP> -p 5432 <DB_NAME>  <DB_USER>
psql -h 34.238.123.20 -p 5432 store dbuser
```
nhập password la` "password" (cái này mình define trong biến môi trường khi truyền vào và run docker image postgres)

Nếu connect thành công thử list db và list table xem
```sh
\list
\d
```
Nếu thấy database "store" và table "product" có nghĩa là đã connect db thành công

Nếu ko thấy nghĩa là connect ko thành công thì nên check Security Group xem Workplace đã mở port 5432 cho con Node connect vào chưa

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/run-postgres-outside-cluster.jpg)

Giờ cần sửa project Spring và Helm chart để khi deploy lên cluster nó có thể connect vào DB đang ở 1 máy EC2 khác (chính là máy workplace của mình)
```sh
nano spring-maven-postgres-docker-k8s/src/main/resources/application.yml
```
sửa URL của PostgreSQL DB như sau:  
```
#below is config for Docker compose
#ENV_DATASOURCE_URL: jdbc:postgresql://postgres/store
#below is config for postgresql in local windows
#ENV_DATASOURCE_URL: jdbc:postgresql://localhost:5432/store
#below is config for k8s, using service_name:5432 to connect db
#ENV_DATASOURCE_URL: jdbc:postgresql://docker-postgres:5432/store
#below is config for k8s, using a external db running in another machine
ENV_DATASOURCE_URL: jdbc:postgresql://34.238.123.20:5432/store #đây là EC2-PUBLIC-IP của con máy mà mình đang run Postgres DB
```

sau đó build là file jar và đóng docker image mới
```sh
cd spring-maven-postgres-docker-k8s
mvn clean package
docker build -f Dockerfile -t $DOCKER_USERNAME/docker_spring-boot-containers .
```

cần push lên Docker Hub để sau này helm chart pull về
```sh
docker push $DOCKER_USERNAME/docker_spring-boot-containers
```

Tiếp là sửa helm chart, đầu tiên sửa file Service của Postgres
```sh
nano spring-maven-postgres-docker-k8s-helm/templates/docker_postgres-service-external.yaml
```

```
apiVersion: v1
kind: Service
metadata:
  name: docker-postgres
  labels:
    app: docker-postgres
spec:
  type: ExternalName
  externalName: {{ .Values.postgresService.externalName }}
  selector:
    app: docker-postgres
```

bởi vì ko tạo pod cho Postgresql mà sẽ dùng bên ngoài nên cần xóa file `docker_postgres-deployment.yaml`, bạn sẽ thấy file đó ko còn trong folder `spring-maven-postgres-docker-k8s-helm-externaldb` nữa 

cần sửa file `values.yaml` nữa

```
postgresService:
  type: ClusterIP
  port: 5432
  targetPort: 5432
  externalName: 34.238.123.20 #đây là IP của con máy mà mình đang run Postgres DB
```

vậy là chuẩn bị xong giờ có thể install helm chart
```sh
cd spring-maven-postgres-docker-k8s-helm
helm install -n spring-postgres .
```

```
$ kubectl get pods,svc -A
NAMESPACE     NAME                                                 READY   STATUS    RESTARTS   AGE
default       pod/docker-spring-boot-containers-54566ddbc8-8dpkf   1/1     Running   0          39s
kube-system   pod/aws-node-jpx87                                   1/1     Running   0          27m
kube-system   pod/coredns-8455f84f99-7wzm8                         1/1     Running   0          32m
kube-system   pod/coredns-8455f84f99-dpxld                         1/1     Running   0          32m
kube-system   pod/kube-proxy-r9tsx                                 1/1     Running   0          27m
kube-system   pod/tiller-deploy-586965d498-58gn9                   1/1     Running   0          50s

NAMESPACE     NAME                                    TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)           AGE
default       service/docker-postgres                 ExternalName   <none>          34.238.123.20   <none>            39s
default       service/docker-spring-boot-containers   NodePort       10.100.248.57   <none>          12345:32594/TCP   39s
default       service/kubernetes                      ClusterIP      10.100.0.1      <none>          443/TCP           32m
kube-system   service/kube-dns                        ClusterIP      10.100.0.10     <none>          53/UDP,53/TCP     32m
kube-system   service/tiller-deploy                   ClusterIP      10.100.5.254    <none>          44134/TCP         50s
```

Check logs của pod nếu ko có lỗi kết nối DB là thành công
```sh
kubectl logs pod/docker-spring-boot-containers-54566ddbc8-8dpkf
```

vì ở trên Spring pod đang dùng kiểu NodePort nên cần forward port để mọi nơi có thể dùng:
```sh
kubectl port-forward -n default service/docker-spring-boot-containers 32594:12345 --address 0.0.0.0
```

Sau đó có thể insert DB bằng cách dùng POSTMAN send POST request đến `http://<EC2-PUBLIC-IP>:32594/v1/product` với body:
```
{"name":"product001"}
```

Bây giờ khi xóa cluster tạo lại thì DB vẫn còn đó, bởi vì nó đc giữ ở 1 con EC2 khác

Tuy nhiên trên workplace nếu mình stop docker thì DB sẽ mất, nên cần mount volume dể lưu DB ra bên ngoài docker

việc này thuộc về kĩ thuật dùng docker

tất cả những thay đổi vừa xong được lưu trong folder `spring-maven-postgres-docker-k8s-helm-externaldb`

https://github.com/hoangmnsd/kubernetes-series/tree/master/spring-maven-postgres-docker-k8s-helm-externaldb


**REFERENCES**:  
https://github.com/red-gate/ks/blob/master/ks8-2/ks8-2.md
https://stackoverflow.com/questions/49573258/installing-postgresql-client-v10-on-aws-amazon-linux-ec2-ami
https://stackoverflow.com/questions/37694987/connecting-to-postgresql-in-a-docker-container-from-outside
https://severalnines.com/database-blog/using-kubernetes-deploy-postgresql
https://stackoverflow.com/questions/26040493/how-to-show-data-in-a-table-by-using-psql-command-line-interface
