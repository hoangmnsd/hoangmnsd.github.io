---
title: "K8S 10: Setup Gitlab Self Hosted on GKE Cluster"
date: 2020-02-20T12:28:58+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Gitlab,GKE,Kubernetes]
comments: false
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Tạo Gitlab với yêu cầu là: disable MinIO, dùng GCS. Disable cert-manager, dùng cert-manager mình tự tạo riêng. Các config về resource của gitlab ở mức minimal. Gitlab sẽ vào qua link `gitlab.your-subdomain.your-domain.net` và có HTTPS"
---

Tạo Gitlab với yêu cầu là:  
- disable MinIO, dùng GCS,   
- disable cert-manager, dùng cert-manager mình tự tạo riêng,   
- các config về resource của gitlab ở mức minimal,  
- gitlab sẽ vào qua link `gitlab.your-subdomain.your-domain.net` và có HTTPS

# Yêu Cầu

- Đã tạo GKE Cluster có ít nhất là 3 vCPU  
- Đã install Helm 2  
- Đã làm theo bài này để setup cert-manager:  
[K8S 9: Setup External DNS + Cert Manager + Nginx Ingress Controller Wilcard](../../posts/k8s-ix-setup-extdns-certmanager-nginxingress-wilcard/) 

# Cách Làm

## 1. Setup environment variables
```sh
export PROJECT_ID="YOUR_PROJECT_ID"
export CLUSTER_NAME="YOUR_CLUSTER_NAME"
export SUBDOMAIN="your-subdomain.your-domain.net"
gcloud config set project ${PROJECT_ID}
gcloud config set compute/region asia-northeast1
gcloud config set compute/zone asia-northeast1-a
```

## 2. Tạo namespace `gitlab` và add helm repo
```sh
kubectl create namespace gitlab
helm repo add gitlab https://charts.gitlab.io/
helm repo update
```

## 3. Dùng Kubed để synchronize TLS secret giữa các namespaces

```sh
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
helm install -n kubed appscode/kubed --version 0.12.0 --namespace kube-system --wait --set config.clusterName=${CLUSTER_NAME}
```

Giả sử nhờ bài trước mà mình đã issue được 1 TLS Secret thành công tên là `echo-tls-secret-prod` ở namespace `default`,  
```
k get secret -A
default           default-token-7hsrc                              kubernetes.io/service-account-token   3      3h11m
default           echo-tls-secret-prod                             kubernetes.io/tls                     3      157m
default           echo-tls-secret-staging                          kubernetes.io/tls                     3      164m
gitlab            default-token-t728z                              kubernetes.io/service-account-token   3      99s
```
giờ mình cần sync secret đó sang namespace `gitlab` khác thì cần làm như sau:  
annotate secret mà mình muốn sync giữa các namespaces
```sh
# Đánh label `app=kubed` cho namespace gitlab
kubectl label namespace gitlab app=kubed
# Annotate để secret mình muốn sẽ sync sang các namespace có label `app=kubed` 
kubectl annotate secret echo-tls-secret-prod -n default kubed.appscode.com/sync="app=kubed"
```

check: (Bạn sẽ thấy namespace `gitlab` cũng có secret `echo-tls-secret-prod`)  
```
k get secret -A
default           default-token-7hsrc                              kubernetes.io/service-account-token   3      3h15m
default           echo-tls-secret-prod                             kubernetes.io/tls                     3      161m
default           echo-tls-secret-staging                          kubernetes.io/tls                     3      168m
gitlab            default-token-t728z                              kubernetes.io/service-account-token   3      5m43s
gitlab            echo-tls-secret-prod                             kubernetes.io/tls                     3      6s
```

## 4. GCP - Tạo Service Account
```sh
gcloud iam service-accounts create gitlab-gcs \
  --display-name "Gitlab Cloud Storage"
```
## 5. GCP - Tạo Service Account Key
```sh
gcloud iam service-accounts keys create --iam-account \
  gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com /tmp/gitlab-gcs-key.json
```

## 6. GCP - Binding role Storage Admin vào Service Account
```sh
gcloud projects add-iam-policy-binding --role roles/storage.admin ${PROJECT_ID} \
  --member=serviceAccount:gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com
```

## 7. GCP - Create GCS Buckets
```sh
gsutil mb -c standard gs://${PROJECT_ID}-gitlab-uploads
gsutil mb -c standard gs://${PROJECT_ID}-gitlab-artifacts
gsutil mb -c standard gs://${PROJECT_ID}-gitlab-lfs
gsutil mb -c standard gs://${PROJECT_ID}-gitlab-packages
gsutil mb -c standard gs://${PROJECT_ID}-gitlab-registry
gsutil mb -c standard gs://${PROJECT_ID}-gitlab-runner-cache
gsutil mb -c nearline gs://${PROJECT_ID}-gitlab-backups
```

## 8. Create a Secret to hold your Cloud Storage credentials
```sh
kubectl create secret generic google-application-credentials \
  --from-file=gcs-application-credentials-file=/tmp/gitlab-gcs-key.json \
  --namespace gitlab
```

## 9. Tạo file `rails.yaml`
```sh
cat > /tmp/rails.yaml <<EOF
provider: Google
google_project: ${PROJECT_ID}
google_client_email: gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com
google_json_key_string: '$(cat /tmp/gitlab-gcs-key.json)'
EOF
```

## 10. Tạo secret từ file `rails.yaml`
```sh
kubectl create secret generic gitlab-rails-storage --from-file=connection=/tmp/rails.yaml --namespace gitlab
```

## 11. (Optional) Xóa key đi cho secure
```sh
rm -rf /tmp/gitlab-gcs-key.json
rm -rf /tmp/rails.yaml
```

## 12. Tạo Gitlab helm values file
```sh
cat > ./gitlab-values.yaml <<EOF
# Values for gitlab/gitlab chart on GKE
global:
  edition: ce

  ## doc/charts/globals.md#configure-ingress-settings
  ingress:
    configureCertmanager: false
    tls:
      enabled: true
      secretName: echo-tls-secret-prod

  hosts:
    domain: ${SUBDOMAIN}
    https: false
    gitlab:
      https: false
    registry:
      https: false
    minio:
      https: false

  ## doc/charts/globals.md#configure-minio-settings
  minio:
    enabled: false

  registry:
    bucket: ${PROJECT_ID}-gitlab-registry

  ## doc/charts/globals.md#configure-appconfig-settings
  ## Rails based portions of this chart share many settings
  appConfig:
    ## doc/charts/globals.md#general-application-settings
    enableUsagePing: false

    defaultTheme: 2

    defaultProjectsFeatures:
      issues: true
      mergeRequests: true
      wiki: true
      snippets: true
      builds: true
      containerRegistry: true

    ## doc/charts/globals.md#lfs-artifacts-uploads-packages
    backups:
      bucket: ${PROJECT_ID}-gitlab-backups
    lfs:
      bucket: ${PROJECT_ID}-gitlab-lfs
      connection:
        secret: gitlab-rails-storage
        key: connection
    artifacts:
      bucket: ${PROJECT_ID}-gitlab-artifacts
      connection:
        secret: gitlab-rails-storage
        key: connection
    uploads:
      bucket: ${PROJECT_ID}-gitlab-uploads
      connection:
        secret: gitlab-rails-storage
        key: connection
    packages:
      bucket: ${PROJECT_ID}-gitlab-packages
      connection:
        secret: gitlab-rails-storage
        key: connection

gitlab:  
  webservice:
    minReplicas: 1
    resources:
      limits:
       memory: 1.5G
      requests:
        cpu: 100m
        memory: 900M
    workhorse:
      resources:
        limits:
          memory: 100M
        requests:
          cpu: 10m
          memory: 10M
  task-runner:
    backups:
      objectStorage:
        backend: gcs
        config:
          secret: "google-application-credentials"
          key: gcs-application-credentials-file
          gcpProject: ${PROJECT_ID}
  sidekiq:
    minReplicas: 1
    resources:
      limits:
        memory: 1.5G
      requests:
        cpu: 50m
        memory: 625M
  gitlab-shell:
    minReplicas: 1

nginx-ingress:
  controller:
    replicaCount: 1
    minAvailable: 0
    resources:
      requests:
        cpu: 50m
        memory: 100Mi
  defaultBackend:
    replicaCount: 1
    minAvailable: 0
    resources:
      requests:
        cpu: 5m
        memory: 5Mi

redis:
  resources:
    requests:
      cpu: 10m
      memory: 64Mi

certmanager:
  install: false

prometheus:
  install: false

registry:
  enabled: true
  certificate:
    secret: gitlab-rails-storage
    key: connection
  ingress:
    tls:
      enabled: true
      secretName: echo-tls-secret-prod

gitlab-runner:
  install: false
  rbac:
    create: true
  runners:
    locked: false
    cache:
      cacheType: gcs
      gcsBucketname: ${PROJECT_ID}-gitlab-runner-cache
      secretName: gitlab-rails-storage
      cacheShared: true
EOF
```

## 13. Install Gitlab helm chart
```sh
helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --values gitlab-values.yaml
```

Check gitlab trên link `gitlab.your-subdomain.your-domain.net` được như sau là OK:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gitlab-tls-secure.jpg)

Đăng  nhập vào gitlab bằng user "root", pass lấy từ command sau:  
```sh
kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath={.data.password} -n gitlab | base64 --decode ; echo
```

Check xem có thể Backup và Restore Gitlab bình thường ko là OK:  
```
kubectl exec gitlab-task-runner-7d686c6474-w8mnt -it backup-utility -n gitlab
WARNING: This version of GitLab depends on gitlab-shell 11.0.0, but you're running Unknown. Please update gitlab-shell.
2020-02-21 09:26:19 +0000 -- Dumping database ... 
Dumping PostgreSQL database gitlabhq_production ... [DONE]
2020-02-21 09:26:22 +0000 -- done
WARNING: This version of GitLab depends on gitlab-shell 11.0.0, but you're running Unknown. Please update gitlab-shell.
2020-02-21 09:26:32 +0000 -- Dumping repositories ...
2020-02-21 09:26:32 +0000 -- done
Dumping registry ...
empty
Dumping uploads ...
empty
Dumping artifacts ...
empty
Dumping lfs ...
empty
Dumping packages ...
empty
WARNING: This version of GitLab depends on gitlab-shell 11.0.0, but you're running Unknown. Please update gitlab-shell.
Packing up backup tar
Copying file:///srv/gitlab/tmp/backup_tars/1582277165_2020_02_21_12.7.6_gitlab_backup.tar [Content-Type=application/x-tar]...
/ [1 files][150.0 KiB/150.0 KiB]
Operation completed over 1 objects/150.0 KiB.
[DONE] Backup can be found at gs://xxx-gitlab-backups/1582277165_2020_02_21_12.7.6_gitlab_backup.tar
```

Nếu backup bị lỗi đỏ hoặc có lỗi kiểu `Bucket not found: registry. Skipping backup of registry` thì có nghĩa là registry bucket không nhìn thấy, cần check lại file values nhé

DONE! :tada::tada::tada:

## 14. Clean up
- Nên chắc chắn rằng bạn đã xóa Cluster, VPC  
- Vào Service Cloud DNS, xóa các record được sinh ra bởi ExternalDNS  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/cleanup-cloud-dns-k8s-ix.jpg)    
- Vào IAM - Service Account xóa service account `gitlab` mà bạn đã tạo  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/cleanup-iam-sa-k8s-ix.jpg)  
- Vào Compute Engine - Disk xóa các disk được tạo bởi Cluster   
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/cleanup-disk-k8s-x.jpg)  
- Vào Storage, xóa các bucket `*-gitlab-*` bạn đã tạo ra  


# CREDIT

https://docs.gitlab.com/charts/
https://docs.gitlab.com/charts/charts/globals.html#connection
https://ruzickap.github.io/k8s-harbor/part-03/#install-nginx-ingress
https://gitlab.com/gitlab-org/charts/gitlab/issues/1464
https://docs.gitlab.com/charts/backup-restore/backup.html

