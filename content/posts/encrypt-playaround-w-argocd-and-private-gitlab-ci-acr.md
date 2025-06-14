---
title: "GitOps: Playaround with ArgoCD and private Gitlab CI, ACR"
date: 2021-11-01T21:16:47+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Azure,Kubernetes,Argocd,Gitlab]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Demo about ArgoCD with private Gitlab CI repository, private ACR"
---

## 1. Intro

Demo about ArgoCD with private Gitlab CI repository, private ACR
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/argocd-gitops-diagram.jpg)

## 2. Prerequisites

- Basic knowledge about Azure, ssh-keygen, K8S, Gitlab, Docker commands  
- Workspace: run commands on Azure Cloudshell  
- Prepare an AKS cluster (Standard_DS2_v2, kubernetes version 1.21.2)  
- Prepare an ACR (Azure container registry) with credential  
```sh
export ACR_SERVER="YOUR_ACR_NAME.azurecr.io"
export ACR_USER="YOUR_ACR_USER_NAME"
export ACR_PASSWORD="YOUR_ACR_PASSWORD"
```

Clone 2 projects to your workspace:  
- https://gitlab.com/argocd-demo2801/gitops-chart  
- https://gitlab.com/argocd-demo2801/webapp  

## 3. Setup

### 3.1. Config on Webapp repository

https://gitlab.com/argocd-demo2801/webapp 

Generate an SSH keypair by `ssh-keygen` command, you'll have a pair of `SSH_PRIVATE_KEY and SSH_PUBLIC_KEY`

Set variables (Setting -> CI/CD -> Variables): 
`CI_REGISTRY_PASSWORD, CI_REGISTRY_URL, CI_REGISTRY_USER, SSH_PRIVATE_KEY`  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gitops-argocd-webapp-repo.jpg)


### 3.2. Config on GitOps repository

https://gitlab.com/argocd-demo2801/gitops-chart  

- Go to Setting -> Repository -> Deploy Key,  set `Deploy Key`: paste the `SSH_PUBLIC_KEY` value (grant write permission to it)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gitops-argocd-deploykey.jpg)  

- Edit `gitops-chart/argocd/argocd-apps/webapp-python.yml` file, Update 3 places of `<YOUR_ACR_NAME>`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/argocd-acr-image-repository.jpg)  

and push it to master branch again.  


### 3.3. Confirm the Pipeline

Try to run the CI to confirm everything OK, Gitlab Pipeline of "https://gitlab.com/argocd-demo2801/webapp" should finish successful.  
You should push some small changes to `dev` branch, and `master` branch to see.  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gitops-argocd-pipeline.jpg)  


### 3.4. Config on Cluster

Prepare namespaces:
```sh
#Create namespaces for dev,staging,prod environment
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace prod
```

Create k8s secret to store ACR credential:  
```sh
kubectl create secret docker-registry regcred \
    --docker-server=$ACR_SERVER \
    --docker-username=$ACR_USER \
    --docker-password=$ACR_PASSWORD \
    --namespace=dev

kubectl create secret docker-registry regcred \
    --docker-server=$ACR_SERVER \
    --docker-username=$ACR_USER \
    --docker-password=$ACR_PASSWORD \
    --namespace=staging

kubectl create secret docker-registry regcred \
    --docker-server=$ACR_SERVER \
    --docker-username=$ACR_USER \
    --docker-password=$ACR_PASSWORD \
    --namespace=prod
```

Install ArgoCD:  
```sh
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

cd gitops-chart/argocd/argocd-install/
helm install argocd -n argocd argo/argo-cd -f values-override.yml
```

Get ArgoCD public IP:   
```sh
kubectl get svc -n argocd
```
Get ArgoCD login password, update it (username: `admin`):  
```sh
ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login <ARGOCD_SERVER_IP> --username admin --password $ARGOCD_PWD

# change password
argocd account update-password
```

Add gitops-chart repository to ArgoCD: 
```sh
argocd repo add https://gitlab.com/argocd-demo2801/gitops-chart.git --username <YOUR_GITLAB_USER> --password <Gitlab personal access token>
```
If above command failed for some reason, you can add by using UI, just ensure that it's working as the image below on ArgoCD Admin UI:   
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gitops-argocd-repos.jpg)  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gitops-argocd-apps.jpg)  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gitops-argocd-proj.jpg)  

## 4. Understand the file structure

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/argocd-gitops-diagram.jpg)

File `gitops-chart/argocd/argocd-install/values-override.yml` at step "Install ArgoCD" create:
- 2 Apps: `argocd-appprojects` and `argocd-apps`. (They have responsibility to sync template in `argocd/argocd-apps` and `argocd/argocd-appprojects/`.  )  
- 1 special Project: `argocdprojects`. (It contains 2 above applications `argocd-appprojects` and `argocd-apps`.)    

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/argocd-gitops-file-structure.jpg)  

File `gitops-chart/argocd/argocd-install/argocd-appprojects/prj-1.yml` create:
- 1 Project named `prj-1`. It can access to (dev,staging,prod) namespaces only (it's syncing)

3 folders in `gitops-chart/charts/webapp-python` create:  
- 3 Apps named `webapp-python-dev` , `webapp-python-staging`, `webapp-python-prod`. They belong to `prj-1`. (They're syncing)

## 5. Understand the CICD Flow

The `gitlab-ci.yml` file described everything:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/argocd-git-cicd-flow.jpg)

We have 3 envs: `Dev, Staging, Prod`. 2 branchs: `dev` and `master`  

Changes made to branch `dev` reflect to `Dev env` only.  

Changes made to branch `master` reflect to `Staging env` first, and you need to approve maunally later to reflect on `Prod env`.  


## 6. Test

### 6.1. Commit some changes
Now you can test by push some changes to project `https://gitlab.com/argocd-demo2801/webapp.git` in branch `dev`:  
Changes will reflect to the `Dev` environment.  

When you merge branch `dev` to `master`:  
Changes will reflect to the `Staging` environment first, then you need to manual approve to trigger deploy to `Prod` environment.    

### 6.2. Make some changes
Make some changes on `argocd/argocd-appprojects/`, or add new yml file then push to `master` branch: It will reflect to K8S automatically   

Make some changes on `argocd/argocd-apps/`, or add new yml file then push to master branch: It will reflect to K8S automatically   
For instance:   
- You can create new environment named `QA` for the `webapp-python` by edit file `webapp-python.yml` and `charts/webapp-python`  

### 6.3. If your new app dont have Helm chart
If your new app dont have Helm chart (just manifest yaml files). Follow this demo to see. I will create a new `spring-maven-postgres-docker-k8s` app, it belongs to `prj-2` project. It's in `dev` environment only.   
- Create new `prj-2.yml` file in folder `argocd/argocd-appprojects`:  
```yaml
# this AppProject can access only to "dev,prod" namespaces
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: prj-2
  namespace: argocd
spec:
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  destinations:
  - namespace: dev
    server: https://kubernetes.default.svc
  - namespace: prod
    server: https://kubernetes.default.svc
  orphanedResources:
    warn: false
  sourceRepos:
  - '*'
```
- Create new `spring-maven-postgres-docker-k8s.yml` file in folder `argocd/argocd-appps`:  
```yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: spring-maven-postgres-docker-k8s-dev
  namespace: argocd
spec:
  project: prj-2
  source:
    path: charts/spring-maven-postgres-docker-k8s/dev
    repoURL: https://gitlab.com/argocd-demo2801/gitops-chart.git
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
```
- Create new directory to store manifest `charts/spring-maven-postgres-docker-k8s/dev`, it includes 4 files:  
+ First file: `docker_postgres-deployment.yaml`  

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docker-postgres
  labels:
    app: docker-postgres
spec:
  selector:
     matchLabels:
       app: docker-postgres
  replicas: 1
  minReadySeconds: 15
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    metadata:
      labels:
        app: docker-postgres
    spec:
      containers:
        - image: hoangmnsd/docker_postgres
          env:
          - name: POSTGRES_USER
            value: dbuser
          - name: POSTGRES_PASSWORD
            value: password
          - name: POSTGRES_DB
            value: store
          imagePullPolicy: Always
          name: docker-postgres
          ports:
            - containerPort: 5432

```

+ Second file: `docker_postgres-service.yaml`   

```yaml
apiVersion: v1
kind: Service
metadata:
  name: docker-postgres
spec:
  ports:
    - port: 5432
      protocol: TCP
      targetPort: 5432
  selector:
    app: docker-postgres

```

+ Third file: `docker_spring-boot-containers-deployment.yaml`  

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docker-spring-boot-containers
  labels:
    app: docker-spring-boot-containers
spec:
  selector:
    matchLabels:
      app: docker-spring-boot-containers
  replicas: 1
  minReadySeconds: 15
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    metadata:
      labels:
        app: docker-spring-boot-containers
    spec:
      containers:
        - image: hoangmnsd/docker_spring-boot-containers
          imagePullPolicy: Always
          name: docker-spring-boot-containers
          ports:
            - containerPort: 12345

```

+ Fourth file: `docker_spring-boot-containers-service.yaml`  

```yaml
apiVersion: v1
kind: Service
metadata:
  name: docker-spring-boot-containers
spec:
  type: LoadBalancer
  ports:
  - port: 80
    protocol: TCP
    targetPort: 12345
  selector:
    app: docker-spring-boot-containers

```

- Push them to master branch to see changes apply to ArgoCD  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gitops-argocd-apps-spring-mv-postgres.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gitops-argocd-proj-prj2.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gitops-argocd-apps-spring-mv-postgres-dev.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gitops-argocd-apps-spring-mv-postgres-details.jpg)  

## 7. Open Issue

In file `/argocd_demo2801/gitops-chart/argocd/argocd-apps/webapp-python.yml`,  
I am hardcoding the `image.repository` parameter when create ArgoCD Application kind, because there is no way to secure it from local environment variable. The issue's reported here:  
https://github.com/argoproj/argo-cd/issues/1786  

I heard the same complaint from other people with them ending up choosing Flux over Argo for this sole reason.  
There are also some workaround to get over this, but not solve problem completely.  
I want to use `envsubst` to workaround in this tutorial but Azure Cloudshell doesn't support  `envsubst` command.  
For someone who want to see answer about `envsubst`: https://stackoverflow.com/a/68936302/9922066


## 8. Clean up

Notes:
When you delete files on `gitops-chart/argocd/argocd-appprojects`, `gitops-chart/argocd/argocd-apps`, and push changes to master branch, the applications and project will be remove on ArgoCD (it makes sense and that's what we think).  
But the deployment/pod/svc are not removed from K8S Cluster at all. They remain until we execute this command:  
```sh
kubectl delete svc docker-spring-boot-containers -n dev
kubectl delete deployment docker-spring-boot-containers -n dev
``` 
Not sure it is an issue or just a feature of ArgoCD? 🤔

```sh
# delete helm argocd release
helm uninstall argocd -n argocd
```

# CREDITS
https://medium.com/devopsturkiye/self-managed-argo-cd-app-of-everything-a226eb100cf0  
https://levelup.gitconnected.com/gitops-in-kubernetes-with-gitlab-ci-and-argocd-9e20b5d3b55b  
https://medium.com/@andrew.kaczynski/gitops-in-kubernetes-argo-cd-and-gitlab-ci-cd-5828c8eb34d6  
https://github.com/kurtburak/argocd  