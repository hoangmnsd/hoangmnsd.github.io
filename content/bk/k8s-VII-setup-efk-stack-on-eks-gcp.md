---
title: "K8S 7: Setup EFK Stack on EKS/GCP cluster (ElasticSearch, Fluentd, Kibana)"
date: 2019-11-23T15:47:46+09:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [EKS,GCP,Kibana,Fluentd,ElasticSearch,Kubernetes,EFK]
comments: false
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Xây dựng hệ thống logging EFK stack"
---

# Yêu cầu
Đã cài đặt `eksctl, kubectl`

# Cách làm
```sh
git clone https://github.com/hoangmnsd/kubernetes-series
cd kubernetes-series/efk-stack
```

## 1. Tạo cluster

### 1.1. eks
trên eks phải tạo cluster bằng file này `cluster-efk.yaml`

có thể đổi tên cluster, tạo thêm node, đổi type của node trong file đó, nhưng nên chọn 1 node có 4vCPU, >8GB (t2.xlarge), đã test trường hợp sử dụng t2.large (2 vCPU, 8 GB Mem) cũng ok
```sh
eksctl create cluster -f cluster-efk.yaml
```
### 1.2. gcp
trên gcp thì tạo cluster bằng console, mình đã chọn loại N1 standard 4 (4vCPU,15GB memory), chưa test loại khác

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gcp-cluster-node.jpg)

## 2. Tạo namespace
```sh
kubectl create -f kube-logging.yaml
```

## 3. Tạo service ElasticSearch
```sh
kubectl create -f elasticsearch_svc.yaml
```

## 4. Tạo statefulset ElasticSearch 

có vài chỗ nên sửa trước khi tạo

cụ thể là xem file này `elasticsearch_statefulset.yaml`
```sh
nano elasticsearch_statefulset.yaml
```

■ sửa tên của cluster đang dùng, nếu bạn đang dùng cluster name khác thì nên sửa giá trị `efk-stack`
```
env:
          - name: cluster.name
            value: efk-stack
```

■ sửa namespace của volume mà mình sẽ sử dụng, ở đây mình dùng namespace "default"  
■ sửa storageClass của volume mình sẽ sử dụng, ở đây mình dùng "gp2":  
 - nếu đang dùng cluster trên eks thì volume ở namespace "default" là "gp2"   
 - nếu đang dùng cluster trên gcp thì volume ở namespace "default" là "standard"  
 - nếu đang dùng cluster trên DigitalOcean thì volume ở namespace "default" là "do-block-storage"  

■ sửa dung lượng của storage nếu đang muốn test thì dùng 5-10GB thôi cho tiết kiệm, ở đây mình dùng "10Gi"  

```
volumeClaimTemplates:
  - metadata:
      name: data
      namespace: default
      labels:
        app: elasticsearch
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: gp2
      resources:
        requests:
          storage: 10Gi
```
Ngoài ra còn các thông số khác, xem kỹ để nếu muốn thay đổi  
sửa xong hết thì mới tạo statefulset bằng command sau:  
```sh
kubectl create -f elasticsearch_statefulset.yaml  
```

dùng command sau để kiểm tra pod đã tạo hết chưa
```sh
kubectl describe pod <POD_NAME>
```

Nếu bị lỗi `pod has unbound immediate PersistentVolumeClaims`
thì cần phải fix, thử những command sau:
```sh
kubectl get storageclass --all-namespaces
kubectl get pvc --all-namespaces
```
Nếu có cái nào cứ ở trạng thái `pending` mãi thì nên xóa nó đi,
```sh
kubectl delete pvc <PVC_NAME> -n <NAME_SPACE>
```

rồi chạy lại các command
```sh
kubectl delete -f elasticsearch_statefulset.yaml
kubectl create -f elasticsearch_statefulset.yaml
```
Nếu tất cả pod elasticsearch đều lên `Running` nghĩa là ok
```
[ec2-user@ip-172-31-84-250 efk-stack]$ kubectl get pods -A
NAMESPACE      NAME                       READY   STATUS    RESTARTS   AGE
kube-logging   es-cluster-0               1/1     Running   0          2m6s
kube-logging   es-cluster-1               1/1     Running   0          85s
kube-logging   es-cluster-2               1/1     Running   0          43s
kube-system    aws-node-j28lc             1/1     Running   0          14m
kube-system    aws-node-n87zk             1/1     Running   0          14m
kube-system    coredns-8455f84f99-2cjf8   1/1     Running   0          20m
kube-system    coredns-8455f84f99-p7fv9   1/1     Running   0          20m
kube-system    kube-proxy-dm77l           1/1     Running   0          14m
kube-system    kube-proxy-nfqgn           1/1     Running   0          14m
```

### 4.1. (Optional) kiểm tra ElasticSearch bằng port-forward
#### 4.1.a. Trên eks
```sh
kubectl port-forward es-cluster-0 9200:9200 --namespace=kube-logging --address 0.0.0.0
```
rồi trên trình duyệt vào `http://<EC2-PUBLIC-IP>:9200`  để check  
**Chú ý** Mở Security Group cho port 9200  
Nếu  trả về 1 chuỗi JSON có chứa "You know, For Search" nghĩa là ok

#### 4.1.b. Trên gcp
muốn check phải edit service thành `NodePort` rồi mới port-forward được
```sh
kubectl edit service <ELASTIC_SVC> -n kube-logging
```
muốn check `NodePort` đang sử dụng là port bao nhiêu thì:
```sh
kubectl describe svc <ELASTIC_SVC> -n kube-logging
```
edit xong thì port-forward:  
```sh
kubectl port-forward -n kube-logging service/<ELASTICSEARCH_SVC> <NODEPORT>:9200 --address 0.0.0.0
```
Lấy external IP của Node
```sh
kubectl get nodes --output wide
```
rồi trên trình duyệt vào `http://<EXTERNAL-IP>:<NODOE_PORT>` để check  
**Chú ý** Mở Firewall cho <NODE_PORT>:
```sh
gcloud compute firewall-rules create elasticsearch-node-port --allow tcp:<NODE_PORT>
# If rules exist you need to using `update` instead of `create`
```
Nếu  trả về 1 chuỗi JSON có chứa "You know, For Search" nghĩa là ok

## 5. Tạo kibana
```sh
kubectl create -f kibana.yaml
```

### 5.1. kiểm tra Kibana bằng port-forward

#### 5.1.a. Trên eks
```sh
kubectl port-forward <KIBANA_POD_NAME> 5601:5601 --namespace=kube-logging --address 0.0.0.0
```
rồi trên trình duyệt vào `http://<EC2-PUBLIC-IP>:5601` để check  
**Chú ý** Mở Security Group cho port 5601  

#### 5.1.b. Trên gcp
muốn check phải edit service thành `NodePort` rồi mới port-forward được
```sh
kubectl edit service <KIBANA_SVC> -n kube-logging
```
muốn check `NodePort` đang sử dụng là port bao nhiêu thì:
```sh
kubectl describe svc <KIBANA_SVC> -n kube-logging
```
edit xong thì port-forward:  
```sh
kubectl port-forward -n kube-logging service/<KIBANA_SVC> <NODEPORT>:5601 --address 0.0.0.0
```
Lấy external IP của Node
```sh
kubectl get nodes --output wide
```
rồi trên trình duyệt vào `http://<EXTERNAL-IP>:<NODOE_PORT>` để check  
**Chú ý** Mở Firewall cho port `NodePort` của Kibana service:
```sh
gcloud compute firewall-rules create kibana-node-port --allow tcp:<NODE_PORT>
# If rules exist you need to using `update` instead of `create`
```

## 6. Tạo DaemonSet fluentd
```sh
kubectl create -f fluentd.yaml
```

Check xem trạng thái các pods:
```sh
kubectl get pods -A
```
Nếu tất cả pod đều lên `Running` nghĩa là ok

## 7. Check hệ thống EFK hoạt động ra sao

Giờ có thể port-forward để vào lại link kibana xem log `http://<EC2-PUBLIC-IP>:5601`
```sh
kubectl port-forward <KIBANA_POD_NAME> 5601:5601 --namespace=kube-logging --address 0.0.0.0
```
select Discover
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/efk-kibana-discover.jpg)

Enter `logstash-*` in the text box and click on Next step.
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/efk-kibana-index-patt.jpg)

select `@timestamp`
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/efk-kibana-index-patt2.jpg)

back to Discover
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/efk-kibana-index-log-1.jpg)

tạo app `Counter` để test việc xuất logs
```sh
kubectl create -f counter.yaml
```

Nếu muốn filter log theo pod name tên là "counter", thì trong tab Discover, điền vào khung search `kubernetes.pod_name:counter`

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/efk-kibana-index-log-of-pod.jpg)


# CREDIT

https://www.digitalocean.com/community/tutorials/how-to-set-up-an-elasticsearch-fluentd-and-kibana-efk-logging-stack-on-kubernetes
https://jmartinezxp.gitlab.io/post/config-kubernetes-efk/
https://chris-vermeulen.com/how-to-monitor-distributed-logs-in-kubernetes-with-the-efk-stack-/
https://github.com/GoogleCloudPlatform/click-to-deploy/tree/master/k8s/elastic-gke-logging
https://github.com/mjhea0/efk-kubernetes/blob/master/kubernetes/elastic.yaml
https://mherman.org/blog/logging-in-kubernetes-with-elasticsearch-Kibana-fluentd/
https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/fluentd-elasticsearch#storage

