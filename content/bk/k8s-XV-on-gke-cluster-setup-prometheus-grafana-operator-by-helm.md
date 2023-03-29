---
title: "K8S 15: (on GKE Cluster) Setup Prometheus + Grafana Operator by Helm"
date: 2020-09-19T16:05:40+07:00
draft: true
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Prometheus,Grafana,Kubernetes,Helm]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Xây dựng hệ thống monitoring Prometheus và Grafana"
---
Làm theo bài K8S 9 để setup TLS DNS Cert Manager, cùng với đó setup 1 Java Maven App xong đã  
Bài K8S 9 sẽ cần set các biến như sau:  
```sh
export PROJECT_ID="your-project-id"
export DOMAIN="your-domain.net"
export SUBDOMAIN="your-subdomain.your-domain.net"
export YOUR_EMAIL_ADDRESS="your-email@gmail.com"
# Cloud DNS service account nên là unique để tránh lỗi khi issue Certificate, nên mình cho thêm hậu tố `date` vào như sau:   
export CLOUD_DNS_SA="certmng-cdns-$(date +%d%m%Y-%H)"
export SPRINGAPP_SUBDOMAIN="springapp.your-subdomain.your-domain.net"
export CLUSTER_NAME="your-cluster-name"
export TLS_SECRET_NAME="echo-tls-secret-prod"

kubectl annotate service nginx-ingress-controller "external-dns.alpha.kubernetes.io/hostname=${SPRINGAPP_SUBDOMAIN}.,*.${SUBDOMAIN}.,${SUBDOMAIN}." -n nginx-ingress --overwrite
```

sang đến phần setup Prometheus và Grafana:  
```sh
export PROMETHEUS_SUBDOMAIN="prometheus.your-subdomain.your-domain.net"
export GRAFANA_SUBDOMAIN="grafana.your-subdomain.your-domain.net"
kubectl create namespace prometheus-operator
kubectl label namespace prometheus-operator app=kubed
kubectl annotate secret ${TLS_SECRET_NAME} -n default kubed.appscode.com/sync="app=kubed" # Nếu đã tồn tại secrets rồi thì ko cân làm bước này
kubectl annotate service nginx-ingress-controller "external-dns.alpha.kubernetes.io/hostname=${GRAFANA_SUBDOMAIN}.,${PROMETHEUS_SUBDOMAIN}.,${SPRINGAPP_SUBDOMAIN}.,*.${SUBDOMAIN}.,${SUBDOMAIN}." -n nginx-ingress --overwrite
```

copy file này về, đổi tên thành `prometheus-operator-values.yaml` và edit những đoạn sau:  
https://github.com/helm/charts/blob/master/stable/prometheus-operator/values.yaml

đoạn 1:  
```sh
grafana:
  enabled: true
  namespaceOverride: ""

  ## Deploy default dashboards.
  ##
  defaultDashboardsEnabled: true

  adminPassword: prom-operator

  ingress:
    ## If true, Grafana Ingress will be created
    ##
    enabled: true 

    ## Annotations for Grafana Ingress
    ##
    annotations: 
      kubernetes.io/ingress.class: nginx 
      kubernetes.io/tls-acme: "true" 

    ## Labels to be added to the Ingress
    ##
    labels: {}

    ## Hostnames.
    ## Must be provided if Ingress is enable.
    ##
    hosts: 
      - grafana.your-subdomain.your-domain.net 
    # hosts: []

    ## Path for grafana ingress
    path: /

    ## TLS configuration for grafana Ingress
    ## Secret must be manually created in the namespace
    ##
    tls: 
    - secretName: echo-tls-secret-prod 
      hosts: 
      - grafana.your-subdomain.your-domain.net 
```

đoạn 2:  
```sh
prometheus:
~~ *******shorten .......~~*******
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: nginx
    labels: {}

    ## Hostnames.
    ## Must be provided if Ingress is enabled.
    ##
    hosts:
      - prometheus.your-subdomain.your-domain.net
    # hosts: []

    ## Paths to use for ingress rules - one path should match the prometheusSpec.routePrefix
    ##
    paths:
    - /

    ## TLS configuration for Prometheus Ingress
    ## Secret must be manually created in the namespace
    ##
    tls:
      - secretName: echo-tls-secret-prod
        hosts:
          - prometheus.your-subdomain.your-domain.net
```

Install bằng Helm với command sau:  
```sh
helm install --name prometheusoperator stable/prometheus-operator --namespace prometheus-operator --values prometheus-operator-values.yaml
```
