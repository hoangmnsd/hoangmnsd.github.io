---
title: "K8S 9: Setup External DNS + Cert Manager + Nginx Ingress Controller Wilcard"
date: 2019-12-23T14:02:41+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Kubernetes,GKE,Nginx,CertManager,ExternalDNS]
comments: false
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Yêu cầu đã tạo GKE Cluster, đã mua 1 domain riêng, kiểu `your-domain.net`, đã setup service CloudDNS trong GCP console, để sử dụng dc `your-domain.net`"
---

# Yêu Cầu

- Đã tạo GKE Cluster  
- Đã mua 1 domain riêng, kiểu `your-domain.net`  
- Đã setup service CloudDNS trong GCP console, để sử dụng dc `your-domain.net`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/clouddns-setup-on-gcp.jpg)

# Cách Làm

## 0. Setup environment variables
Các biến này sẽ dùng xuyên suốt trong bài:  
```sh
export PROJECT_ID="your-project-id"
export DOMAIN="your-domain.net"
export SUBDOMAIN="your-subdomain.your-domain.net"
export YOUR_EMAIL_ADDRESS="your-mail-address"
# Cloud DNS service account nên là unique để tránh lỗi khi issue Certificate, nên mình cho thêm hậu tố `date` vào như sau:   
export CLOUD_DNS_SA="certmng-cdns-$(date +%d%m%Y-%H)"
```

## 1. Install Helm 2
```sh
mkdir ~/environment
cd ~/environment
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod +x get_helm.sh
./get_helm.sh

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

Sau mỗi lần xóa đi tạo lại cluster, bạn đều cần làm bước sau để install Tiller (còn gọi là helm server-side) lên cluster
```sh
kubectl apply -f ~/environment/rbac.yaml
helm init --service-account tiller
```

check version:  
```
helm version
Client: &version.Version{SemVer:"v2.16.1", GitCommit:"bbdfe5e7803a12bbdf97e94cd847859890cf4050", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.16.1", GitCommit:"bbdfe5e7803a12bbdf97e94cd847859890cf4050", GitTreeState:"clean"}
```

## 2. Install Nginx Ingress Controller

```sh
helm install -n nginx-ingress stable/nginx-ingress --namespace nginx-ingress
```

```
k get pods -A
NAMESPACE     NAME                                                       READY   STATUS    RESTARTS   AGE
nginx-ingress   nginx-ingress-controller-5cbd846c5f-nmhwz                     1/1     Running   0          20s
nginx-ingress   nginx-ingress-default-backend-576b86996d-5c4dh                1/1     Running   0          20s
```

## 3. Install External DNS

```sh
cat > ./externaldns-values.yaml <<EOF
rbac:
  create: true
provider: google
interval: "1m"
policy: sync # or upsert-only
domainFilters: [ '${DOMAIN}' ]
source: ingress
registry: txt
txt-owner-id: my-identifier
EOF
```

install by helm:
```sh
helm install -n external-dns stable/external-dns -f externaldns-values.yaml --namespace nginx-ingress
```

check:
```
k get pods -A
NAMESPACE      NAME                                                        READY   STATUS    RESTARTS   AGE
nginx-ingress        external-dns-6df4c8c96d-cwvl2                               1/1     Running   0          47s
```
Nếu bạn dự định dùng link "your-subdomain.your-domain.net" và wildcard cho "*.your-subdomain.your-domain.net" thì cần annotate nó vào service ingress-controller như sau:  
```sh
kubectl annotate service nginx-ingress-controller "external-dns.alpha.kubernetes.io/hostname=${SUBDOMAIN}.,*.${SUBDOMAIN}." -n nginx-ingress --overwrite
```

Sau khi annotate thì bạn sẽ thấy trên CloudDNS tự động xuất hiện các A record và TXT record của domain (ảnh):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/externaldns-annotate.jpg)

## 4. Setup sample app (Echo App)

Tạo 1 web app đơn giản để test việc access vào domain:  
```sh
cat > ./echo-app.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: echo
spec:
  ports:
  - port: 80
    targetPort: 5678
  selector:
    app: echo

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo
spec:
  selector:
    matchLabels:
      app: echo
  replicas: 1
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
      - name: echo
        image: hashicorp/http-echo
        args:
        - "-text=Echo!"
        ports:
        - containerPort: 5678
EOF
```

apply để install app:
```sh
k apply -f echo-app.yaml
```

check:  
```
k get pods,svc -A
NAMESPACE     NAME                                                       READY   STATUS    RESTARTS   AGE
default       echo-84bb76dddf-pgtdl                                      1/1     Running   0          11s

NAMESPACE       NAME                                    TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
default         service/echo                            ClusterIP      10.68.64.124    <none>           80/TCP                       24s
```

## 5. Create Ingress

Ingress sẽ route traffic từ 1 domain cụ thể vào service của Echo App

```sh
cat > ./echo-ingress.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: echo-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: ${SUBDOMAIN}
    http:
      paths:
      - path: /
        backend:
          serviceName: echo
          servicePort: 80
  - host: "*.${SUBDOMAIN}"
    http:
      paths:
      - path: /
        backend:
          serviceName: echo
          servicePort: 80
EOF
```

apply ingress:  
```sh
k apply -f echo-ingress.yaml
```

check trên browser (vào link sau `your-subdomain.your-domain.net`), hiển thị như sau là ok (ảnh):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/domain-not-secure-http.jpg)

🎉 Như vậy web đã có HTTP, để có HTTPS thì cần dùng Cert Manager, các bước tiếp theo sẽ setup HTTPS

## 6. Install Cert Manager

```sh
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.12/deploy/manifests/00-crds.yaml
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  -n cert-manager \
  --namespace cert-manager \
  --version v0.12.0 \
  jetstack/cert-manager
```

check:  
```
kubectl get pods --namespace cert-manager
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-5fd56d487b-j862g              1/1     Running   0          2m5s
cert-manager-cainjector-6bdbb96457-9scgc   1/1     Running   0          2m5s
cert-manager-webhook-6f78788cd-x2rrs       1/1     Running   0          2m5s
```

Tạo key của Service Account với quyền "DNS Admin":   
```sh
gcloud config set project ${PROJECT_ID}
gcloud config set compute/region asia-northeast1
gcloud config set compute/zone asia-northeast1-a
```

Tạo service account:  
```sh
gcloud iam service-accounts create ${CLOUD_DNS_SA} \
  --display-name "Service Account to support ACME DNS-01 challenge."
```

Tạo service account Key:  
```sh
gcloud iam service-accounts keys create --iam-account \
  ${CLOUD_DNS_SA}@${PROJECT_ID}.iam.gserviceaccount.com /tmp/cloud-dns-key.json
```

Binding cái role DNS Admin vào Service account đó:  
```sh
gcloud projects add-iam-policy-binding --role roles/dns.admin ${PROJECT_ID} \
  --member=serviceAccount:${CLOUD_DNS_SA}@${PROJECT_ID}.iam.gserviceaccount.com
```

Tạo secret dùng để issue Certificate:  
```sh
kubectl create secret generic clouddns-service-account --from-file=service-account-key.json=/tmp/cloud-dns-key.json --namespace=cert-manager
```

check:  
```
kubectl describe secret clouddns-service-account -n cert-manager
Name:         clouddns-service-account
Namespace:    cert-manager
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
service-account-key.json:  2335 bytes
```

tạo ClusterIssuer staging
```sh
cat > ./staging-issuer.yaml <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: ${YOUR_EMAIL_ADDRESS}
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-staging

    # ACME DNS-01 provider configurations
    solvers:
    - dns01:
        clouddns:
          # The Google Cloud project in which to update the DNS zone
          project: ${PROJECT_ID}
          # A secretKeyRef to a google cloud json service account
          serviceAccountSecretRef:
            name: clouddns-service-account
            key: service-account-key.json
EOF
```
apply issuer:  
```sh
kubectl apply -f staging-issuer.yaml
```

tạo ClusterIssuer production:  
```sh
cat > ./production-issuer.yaml <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: ${YOUR_EMAIL_ADDRESS}
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-prod

    # ACME DNS-01 provider configurations
    solvers:
    - dns01:
        clouddns:
          # The Google Cloud project in which to update the DNS zone
          project: ${PROJECT_ID}
          # A secretKeyRef to a google cloud json service account
          serviceAccountSecretRef:
            name: clouddns-service-account
            key: service-account-key.json
EOF
```
apply issuer:  
```sh
kubectl apply -f production-issuer.yaml
```

check:
```
k get clusterissuer -A
NAME                  READY   AGE
letsencrypt-prod      True    20s
letsencrypt-staging   True    99s
```

Issue staging Certificate cho domain:  
```sh
cat > ./echo-certificate-staging.yaml <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: echo-tls-cert-staging
  namespace: default
spec:
  secretName: echo-tls-secret-staging
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  commonName: ${SUBDOMAIN}
  dnsNames:
    - ${SUBDOMAIN}
    - "*.${SUBDOMAIN}"
EOF
```

apply để issue certificate:  
```sh
k apply -f echo-certificate-staging.yaml
```

Quá trình issue certificate phải chờ khoảng 5 phút thì mới Issued thành công được, vì Issue cho wildcard mất thời gian

Nếu thành công sẽ hiện như sau:

```
k describe cert echo-tls-cert-staging
Status:
  Conditions:
    Last Transition Time:  2019-12-14T14:54:05Z
    Message:               Certificate is up to date and has not expired
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Not After:               2020-03-13T13:54:05Z
Events:
  Type    Reason     Age    From          Message
  ----    ------     ----   ----          -------
  Normal  GeneratedKey  5m25s  cert-manager  Generated a new private key
  Normal  Requested     5m25s  cert-manager  Created new CertificateRequest resource "echo-tls-cert-staging-2906129357"
  Normal  Issued        61s    cert-manager  Certificate issued successfully
```

Khi đã confirm thành công thì có thể làm bước sau (Chú ý là phải confirm chắc chắn là staging Certificate `echo-tls-cert-staging` đã đc issue thành công thì mới làm tiếp production Certificate, bởi vì letsencrypt production Certificate rất hạn chế số lần issue, làm đi làm lại với 1 subdomain có thể bị lỗi ko thể làm lại)

Issue production Certificate cho domain: 

```sh
cat > ./echo-certificate-prod.yaml <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: echo-tls-cert-prod
  namespace: default
spec:
  secretName: echo-tls-secret-prod
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: ${SUBDOMAIN}
  dnsNames:
    - ${SUBDOMAIN}
    - "*.${SUBDOMAIN}"
EOF
```

apply để issue certificate: 
```sh
k apply -f echo-certificate-prod.yaml
```

check :

```
k describe cert echo-tls-cert-prod	
Status:	
  Conditions:	
    Last Transition Time:  2019-12-14T14:54:05Z	
    Message:               Certificate is up to date and has not expired	
    Reason:                Ready	
    Status:                True	
    Type:                  Ready	
  Not After:               2020-03-13T13:54:05Z	
Events:	
  Type    Reason     Age    From          Message	
  ----    ------     ----   ----          -------	
  Normal  GeneratedKey  4m18s  cert-manager  Generated a new private key
  Normal  Requested     4m18s  cert-manager  Created new CertificateRequest resource "echo-tls-cert-prod-2591535419"
  Normal  Issued        5s     cert-manager  Certificate issued successfully	

```

## 7. Create Ingress with TLS

TLS ở đây sẽ sử dụng Certificate mà chúng ta đã issue thành công ở bước trước, để secure cho app của mình:
```sh
cat > ./echo-ingress-prod.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: echo-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  tls:
  - hosts:
    - ${SUBDOMAIN}
    - "*.${SUBDOMAIN}"
    secretName: echo-tls-secret-prod
  rules:
  - host: ${SUBDOMAIN}
    http:
      paths:
      - path: /
        backend:
          serviceName: echo
          servicePort: 80
  - host: "*.${SUBDOMAIN}"
    http:
      paths:
      - path: /
        backend:
          serviceName: echo
          servicePort: 80
EOF
```

apply ingress:
```sh
k apply -f echo-ingress-prod.yaml
```

Check trên browser (vào link `your-subdomain.your-domain.net`), confirm có HTTPS và **Certificate Valid** như hình sau là OK:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/echo-ingress-tls.jpg)

Check wildcard hoạt động OK bằng cách thêm 1 prefix bất kỳ (ví dụ như `test`) vào link trên để thành như sau: `test.your-subdomain.your-domain.net`, nếu vẫn có HTTPS và **Certificate Valid** thì có nghĩa là wildcard đã hoạt động thành công:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/echo-ingress-tls-wildcard.jpg)

## 8. Clean up  
- Chắc chắn rằng bạn đã xóa Cluster, VPC  
- Vào Service Cloud DNS, xóa các record được sinh ra bởi ExternalDNS  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/cleanup-cloud-dns-k8s-ix.jpg)  
- Vào IAM - IAM xóa member `certmng-cdns-*` mà bạn đã tạo  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/cleanup-iam-k8s-ix.jpg)  
- Vào IAM - Service Account xóa service account `certmng-cdns-*` mà bạn đã tạo  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/cleanup-iam-sa-k8s-ix.jpg)


Done!