---
title: "Azure AKS with Helm at 2024"
date: 2024-06-19T21:50:50+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Azure,Kubernetes,AKS,Helm]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Năm 2024 ôn tập lại 1 chút về Azure AKS và Helm"
---

Sau 1 thời gian khá lâu (từ 2020) ko đụng đến k8s và helm, giờ 2024 quay lại để review kiến thức 1 chút

## 1. Môi trường làm việc

Windows WSL Ubuntu 20, hoặc Ubuntu 20 VM, Docker và Docker-compose, az-cli, maven, java 8

## 2. Create AKS Cluster, ACR

Đầu tiên cần tạo 1 AKS cluster, 1 ACR. Mình sẽ ko nói về phần này vì tạo khá dễ.

Có 1 số yêu cầu về AKS, nên ở trong 1 VNET/subnet, có 1 NSG gắn vào subnet đó (để sau này chúng ta kiểm soát traffic ra/vào)

Tạo sẵn 1 RG, Vnet, subnet, ACR để đó.

Nếu bạn muốn AKS pod có thể call đến các VM khác trong cùng Vnet thì cần enable Azure CNI lên nhé (nếu chưa enable thì phải tạo lại AKS Cluster)

Còn nếu bạn muốn các VM có thể call đến AKS service thì chỉ cần tạo service type internal Load Balancer là được.

Vào trang này `https://portal.azure.com/#create/Microsoft.Template`, paste đoạn code sau để deploy AKS, các thông tin cần điền vào giao diện là Vnet Name, Subnet Name, SSH public key source nên chọn `Use existing public key` rồi paste 1 public key của bạn vào, key này dùng để tạo AKS Node VM:

<details>
  <summary>Click me</summary>

  ```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": {
      "type": "string",
      "defaultValue": "westeurope",
      "metadata": {
        "description": "The location/region of the resources"
      }
    },
    "client": {
      "type": "string",
      "defaultValue": "hoang",
      "metadata": {
        "description": "The client name"
      }
    },
    "environment": {
      "type": "string",
      "defaultValue": "dev",
      "metadata": {
        "description": "The deploy environment"
      }
    },
    "whitelistIp": {
      "type": "string",
      "defaultValue": "103.162.11.14,102.97.70.31,103.95.30.23"
    },
    "vnetName": {
      "type": "string",
      "metadata": {
        "description": "Existing Vnet"
      }
    },
    "aksSnetName": {
      "type": "string",
      "metadata": {
        "description": "Existing Subnet"
      }
    },
    "clusterName": {
      "type": "string",
      "defaultValue": "akscluster01",
      "metadata": {
        "description": "The name of the Managed Cluster resource."
      }
    },
    "sku": {
      "type": "string",
      "defaultValue": "Base",
      "allowedValues": [
        "Base",
        "Automatic"
      ],
      "metadata": {
        "description": "The type of sku."
      }
    },
    "tier": {
      "type": "string",
      "defaultValue": "Standard",
      "allowedValues": [
        "Free",
        "Standard",
        "Premium"
      ],
      "metadata": {
        "description": "The type of tier."
      }
    },
    "osDiskSizeGB": {
      "type": "int",
      "defaultValue": 32,
      "minValue": 0,
      "maxValue": 1023,
      "metadata": {
        "description": "Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize."
      }
    },
    "agentCount": {
      "type": "int",
      "defaultValue": 1,
      "minValue": 1,
      "maxValue": 50,
      "metadata": {
        "description": "The number of nodes for the cluster."
      }
    },
    "agentVMSize": {
      "type": "string",
      "defaultValue": "Standard_DS2_v2",
      "metadata": {
        "description": "The size of the Virtual Machine."
      }
    },
    "linuxAdminUsername": {
      "type": "string",
      "defaultValue": "deploy",
      "metadata": {
        "description": "User name for the Linux Virtual Machines."
      }
    },
    "sshRSAPublicKey": {
      "type": "string",
      "metadata": {
        "description": "Configure all linux machines with the SSH RSA public key string. Your key should include three parts, for example 'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm'"
      }
    },
    "osType": {
      "type": "string",
      "defaultValue": "Linux",
      "allowedValues": [
        "Linux"
      ],
      "metadata": {
        "description": "The type of operating system."
      }
    }
  },
  "variables": {
    "deploymentId": "[uniqueString(subscription().subscriptionId, resourceGroup().id)]",
    "aksServiceName": "[concat('aks-', parameters('client'), '-', parameters('environment'), '-', parameters('location'), '-', variables('deploymentId'))]",
    "managedIdentityName": "[concat('id-', parameters('client'), '-', parameters('environment'), '-', parameters('location'), '-', variables('deploymentId'))]",
    "aksNsgName": "[concat(variables('aksServiceName'), '-nsg')]",
    "tags": {
      "client": "[parameters('client')]",
      "env": "[parameters('environment')]"
    }
  },
  "resources": [
    // Network Security Group
    {
      "type": "Microsoft.Network/networkSecurityGroups",
      "apiVersion": "2022-05-01",
      "name": "[variables('aksNsgName')]",
      "location": "[parameters('location')]",
      "tags": "[variables('tags')]",
      "properties": {
        "securityRules": [
          {
            "name": "Allow_WhiteIPAddresses",
            "properties": {
              "priority": 1000,
              "access": "Allow",
              "direction": "Inbound",
              "protocol": "TCP",
              "sourceAddressPrefixes": "[split(parameters('whitelistIp'),',')]",
              "sourcePortRange": "*",
              "destinationAddressPrefix": "Any",
              "destinationPortRange": "*"
            }
          }
        ]
      }
    },
    {
      "type": "Microsoft.Resources/deployments",
      "apiVersion": "2020-10-01",
      "name": "aks-nsg",
      "resourceGroup": "[resourceGroup().name]",
      "dependsOn": [
        "[resourceId('Microsoft.Network/networkSecurityGroups', variables('aksNsgName'))]"
      ],
      "properties": {
        "mode": "Incremental",
        "template": {
          "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
          "contentVersion": "1.0.0.0",
          "resources": [
            {
              "type": "Microsoft.Network/virtualNetworks/subnets",
              "apiVersion": "2020-11-01",
              "name": "[concat(parameters('vnetName'), '/', parameters('aksSnetName'))]",
              "location": "[parameters('location')]",
              "properties": {
                "addressPrefix": "[reference(resourceId('Microsoft.Network/virtualNetworks/subnets', parameters('vnetName'), parameters('aksSnetName')), '2020-11-01').addressPrefix]",
                "networkSecurityGroup": {
                  "id": "[resourceId('Microsoft.Network/networkSecurityGroups', variables('aksNsgName'))]"
                }
              }
            }
          ]
        }
      }
    },
    {
      "type": "Microsoft.ManagedIdentity/userAssignedIdentities",
      "name": "[variables('managedIdentityName')]",
      "apiVersion": "2018-11-30",
      "location": "[parameters('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Resources/deployments', 'aks-nsg')]"
      ]
    },
    {
      "type": "Microsoft.ContainerService/managedClusters",
      "apiVersion": "2024-02-01",
      "name": "[parameters('clusterName')]",
      "location": "[parameters('location')]",
      "tags": "[variables('tags')]",
      "dependsOn": [
        "[resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', variables('managedIdentityName'))]"
      ],
      "sku": {
        "name": "[parameters('sku')]",
        "tier": "[parameters('tier')]"
      },
      "properties": {
        "dnsPrefix": "[parameters('clusterName')]",
        "agentPoolProfiles": [
          {
            "name": "agentpool",
            "osDiskSizeGB": "[parameters('osDiskSizeGB')]",
            "count": "[parameters('agentCount')]",
            "vmSize": "[parameters('agentVMSize')]",
            "osType": "[parameters('osType')]",
            "mode": "System",
            "vnetSubnetID": "[resourceId('Microsoft.Network/virtualNetworks/subnets', parameters('vnetName'), parameters('aksSnetName'))]"
          }
        ],
        "linuxProfile": {
          "adminUsername": "[parameters('linuxAdminUsername')]",
          "ssh": {
            "publicKeys": [
              {
                "keyData": "[parameters('sshRSAPublicKey')]"
              }
            ]
          }
        }
      },
      "identity": {
        "type": "UserAssigned",
        "userAssignedIdentities": {
          "[resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', variables('managedIdentityName'))]": {}
        }
      }
    }
  ],
  "outputs": {
    "controlPlaneFQDN": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.ContainerService/managedClusters', parameters('clusterName')), '2024-02-01').fqdn]"
    }
  }
}
  ```
</details>

AKS cluster sẽ tạo kèm theo 1 RG có tên dạng: `MC_rg-XXX_akscluster01_westeurope` đó là điều bình thường, nó chứa các VM Scale Set của AKS.

AKS nên được attach với ACR (`Azure portal -> Overview -> AKS cluster service -> Container registries -> attach ACR`)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aks-acr-azure-attach.jpg)

NSG của AKS nên mở 1 inbound rule như sau: Source: Ip address của bạn, Destination: Any. Port: Any. Để sau này nếu bạn có 1 service expose ra internal thì IP của bạn có thể access được service đó từ Internet.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aks-acr-azure-nsg.jpg)

Script trên có tạo 1 Managed Identity attach vào AKS, Hãy add thêm quyền cho nó `Managed Identity -> identity gắn vào AKS -> Azure role assignment -> Add role assignment -> Contributor cho Resource group chứa AKS cluster (chứ ko phải RG chứa VM Scale Set đâu nhé)`

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aks-acr-azure-attach-managed-identity.jpg)

Connect vào AKS bằng `az-cli`:

```sh
$ az aks get-credentials --resource-group <AZ-RG-NAME> --name <AZ-AKS-NAME>
$ kubectl get nodes
```

Clone source từ đây về: https://github.com/hoangmnsd/kubernetes-series

## 3. Install maven, docker, java

Nếu bạn máy Windows local của bạn, hãy cài WSL Ubuntu 20, Docker for Desktop. Trên WSL Ubuntu 20 run các command sau cài maven, java 8.
Nếu bạn dùng Ubuntu 20 VM thì cũng được, cài docker, docker-compose, maven, java 8.

```sh
# install java 8
$ sudo apt install openjdk-8-jdk
$ sudo apt install -y openjdk-8-jre

$ java -version
openjdk version "1.8.0_412"
OpenJDK Runtime Environment (build 1.8.0_412-8u412-ga-1~20.04.1-b08)
OpenJDK 64-Bit Server VM (build 25.412-b08, mixed mode)

# install java 11 (optional)
$ sudo apt update
$ sudo apt install default-jre
$ sudo apt install default-jdk

$ java --version
openjdk 11.0.23 2024-04-16
OpenJDK Runtime Environment (build 11.0.23+9-post-Ubuntu-1ubuntu120.04.2)
OpenJDK 64-Bit Server VM (build 11.0.23+9-post-Ubuntu-1ubuntu120.04.2, mixed mode, sharing)

$ javac -version
javac 11.0.23

# install maven
$ mkdir ~/download-maven/
$ cd ~/download-maven/
$ wget https://dlcdn.apache.org/maven/maven-3/3.9.8/binaries/apache-maven-3.9.8-bin.zip
$ unzip apache-maven-3.9.8-bin.zip
$ export PATH="~/download-maven/apache-maven-3.9.8/bin:$PATH"

$ mvn --version
Apache Maven 3.9.8 (36645f6c9b5079805ea5009217e36f2cffd34256)
Maven home: ~/download-maven/apache-maven-3.9.8
Java version: 11.0.23, vendor: Ubuntu, runtime: /usr/lib/jvm/java-11-openjdk-amd64
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "5.15.0-1064-azure", arch: "amd64", family: "unix"

# Set default java 8
$ sudo update-alternatives --config java
$ sudo update-alternatives --config javac

# Set JAVA_HOME env
$ sudo nano /etc/environment
# add: JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
```

## 4. Build maven artifact

```sh
$ cd kubernetes-series/spring-maven-postgres-docker-k8s
$ mvn clean package
```

## 5. Build docker image and push to ACR

```sh
$ cd kubernetes-series/spring-maven-postgres-docker-k8s
$ docker build -f Dockerfile -t <AZ_ACR_NAME>.azurecr.io/test/docker_spring-boot-containers .
$ docker push <AZ_ACR_NAME>.azurecr.io/test/docker_spring-boot-containers

$ cd kubernetes-series/spring-maven-postgres-docker-k8s/docker/postgres
$ docker build -f Dockerfile -t <AZ_ACR_NAME>.azurecr.io/test/docker_postgres .
$ docker push <AZ_ACR_NAME>.azurecr.io/test/docker_postgres
```

## 6. Install Helm 3

```sh
$ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
$ chmod 700 get_helm.sh
$ ./get_helm.sh
$ helm version
version.BuildInfo{Version:"v3.15.2", GitCommit:"1a500d5625419a524fdae4b33de351cc4f58ec35", GitTreeState:"clean", GoVersion:"go1.22.4"}
```

## 7. Install Helm chart

Cách để tạo Helm chart khi bạn đã có các files resource manifest yaml:

```sh
cd kubernetes-series/
helm create spring-maven-postgres-docker-k8s-helm-2024
# Nếu folder "spring-maven-postgres-docker-k8s-helm-2024" đã tồn tại thì bạn nên đặt tên khác nhé
```

Delete all files in `spring-maven-postgres-docker-k8s-helm-2024/templates/*`

Copy 5 files cho vào folder `spring-maven-postgres-docker-k8s-helm-2024/templates/`:  
- `docker_postgres-deployment.yaml`  
- `docker_postgres-service.yaml`  
- `docker_spring-boot-containers-deployment.yaml`  
- `docker_spring-boot-containers-service.yaml`  
- `serviceaccount.yaml`  

Sửa file `spring-maven-postgres-docker-k8s-helm-2024/values.yaml`, add thêm:

```yml
...
replicaCount: 1

springBootImage:
  repository: <AZ_ACR_NAME>.azurecr.io/docker_spring-boot-containers
  tag: latest
  pullPolicy: Always
  containerPort: 12345

postgresImage:
  repository: <AZ_ACR_NAME>.azurecr.io/docker_postgres
  tag: latest
  pullPolicy: Always
  containerPort: 5432

springBootService:
  type: LoadBalancer
  port: 80
  targetPort: 12345
  internal: "false"

postgresService:
  type: ClusterIP
  port: 5432
  targetPort: 5432

imagePullSecrets: []
...
```

```sh
$ cd kubernetes-series/
$ helm install spring-maven-postgres-docker-k8s-helm-2024 ./spring-maven-postgres-docker-k8s-helm-2024
$ helm list

# if any changes
$ helm upgrade spring-maven-postgres-docker-k8s-helm-2024 ./spring-maven-postgres-docker-k8s-helm-2024

# Delete installation
$ helm uninstall spring-maven-postgres-docker-k8s-helm-2024
release "spring-maven-postgres-docker-k8s-helm-2024" uninstalled
```

## 8. Verify

```
$ kubectl get svc
NAME                            TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)        AGE
docker-postgres                 ClusterIP      10.0.29.175   <none>         5432/TCP       3h8m
docker-spring-boot-containers   LoadBalancer   10.0.37.74    57.153.38.69   80:30901/TCP   3h8m
kubernetes                      ClusterIP      10.0.0.1      <none>         443/TCP        2d23h

$ kubectl get pods
NAME                                            READY   STATUS    RESTARTS   AGE
docker-postgres-5cdbc99bf-ps2bf                 1/1     Running   0          3h9m
docker-spring-boot-containers-6f6897589-9dbsv   1/1     Running   0          3h9m
```

Truy cập http://57.153.38.69 để thấy API có hoạt động

Và làm 1 số bước test để call API như trong bài này https://hoangmnsd.github.io/posts/k8s-v-using-helm-chart-w-kubectl/

## 9. Internal Load balancer

Khi muốn AKS cluster là 1 backend service để bạn có thể call từ 1 VM khác thì hãy, sửa file `values.yaml`

Chú ý là bạn có thể gặp lỗi Internal Load Balancer mãi ko tạo được vẫn Pending. Thì hãy xem lại quyền mà bạn cấp cho AKS Cluster.

```
$ kubectl describe svc docker-spring-boot-containers
Name:                     docker-spring-boot-containers
Namespace:                default
Labels:                   app=docker-spring-boot-containers
                          app.kubernetes.io/managed-by=Helm
Annotations:              meta.helm.sh/release-name: spring-maven-postgres-docker-k8s-helm
                          meta.helm.sh/release-namespace: default
                          service.beta.kubernetes.io/azure-load-balancer-internal: true
Selector:                 app=docker-spring-boot-containers
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.0.190.29
IPs:                      10.0.190.29
Port:                     <unset>  80/TCP
TargetPort:               12345/TCP
NodePort:                 <unset>  32642/TCP
Endpoints:                10.244.0.18:12345
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type     Reason                  Age                  From                Message
  ----     ------                  ----                 ----                -------
  Normal   EnsuringLoadBalancer    55s (x5 over 2m11s)  service-controller  Ensuring load balancer
  Warning  SyncLoadBalancerFailed  55s (x5 over 2m10s)  service-controller  Error syncing load balancer: failed to ensure load balancer: Retriable: false, RetryAfter: 0s, HTTPStatusCode: 403, RawError: {"error":{"code":"AuthorizationFailed","message":"The client '01be0e49-XXXX-XXXX-XXXX-5e4a2a3f6289' with object id '01be0e49-XXXX-XXX-XXXX-5e4a2a3f6289' does not have authorization to perform action 'Microsoft.Network/virtualNetworks/subnets/read' over scope '/subscriptions/XXX/resourceGroups/rg-XXX/providers/Microsoft.Network/virtualNetworks/miningageVnet/subnets/aksSnet' or the scope is invalid. If access was recently granted, please refresh your credentials."}}
```
Nhiều khả năng bạn sẽ cần vào `Managed Identity -> identity gắn vào AKS -> Azure role assignment -> Add role assignment -> Contributor cho Resource group chứa AKS cluster`

Sau khi Helm Install ko có lỗi gì là OK.

Check Ip của Internal Load Balancer:

```
$ kubectl get svc
NAME                            TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
docker-postgres                 ClusterIP      10.0.31.132   <none>        5432/TCP       78s
docker-spring-boot-containers   LoadBalancer   10.0.66.6     10.10.14.5    80:30309/TCP   78s
kubernetes                      ClusterIP      10.0.0.1      <none>        443/TCP        3d1h
```

Từ 1 VM khác call đến AKS service internal load balancer xem:

```
$ curl 10.10.14.5
{
  "_links" : {
    "persistantProducts" : {
      "href" : "http://10.10.14.5/persistantProducts{?page,size,sort}",
      "templated" : true
    },
    "profile" : {
      "href" : "http://10.10.14.5/profile"
    }
  }
}
```

## REFERENCES

https://learn.microsoft.com/en-us/azure/aks/quickstart-helm?tabs=azure-cli

https://hoangmnsd.github.io/posts/k8s-v-using-helm-chart-w-kubectl/

https://learn.microsoft.com/en-us/azure/aks/internal-lb?tabs=set-service-annotations

