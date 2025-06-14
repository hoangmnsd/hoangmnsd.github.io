---
title: "Azure AKS with DNS Zone, cert-manager, traefik"
date: 2024-07-04T21:50:50+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Azure,Kubernetes,AKS,Helm,Traefik,CertManager]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Setup Azure AKS + Azure DNS zone Helm cert-manager with Letsencrypt HTTPS + traefik as ingress"
---


## 1. Diagram Architecture

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-aks-dns-certmanager-traefik-diagram.jpg)

1 số chú ý:

Traefik hoạt động tương tự là Nginx-ingress-controller. Được recommend.

Enable Azure CNI for AKS: Thường thì 1 hệ thống infra sẽ tồn tại **hầm bà lằng** các kiểu vừa AKS cluster, vừa VM, vừa container. Khi đó sẽ xuất hiện yêu cầu connect giữa các service đó. Và muốn AKS pod có thể connect đến các VM IP thì bạn cần enable Azure CNI khi tạo AKS cluster (ko thể enable Azure CNI trên 1 AKS cluster đã tồn tại). Khi Đã enable Azure CNI thì các pod đều sẽ có 1 IP lấy từ subnet.


## 2. Prerequisites

Bạn đã mua domain riêng của bạn và setup Azure DNS Zone:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-dns-zone-overview.jpg)

Bạn đã có sẵn Vnet/Subnet. Mình có 1 script ARM để deploy nhanh như này, chú ý script này:  
 - enable sẵn Azure CNI mode.  
 - tạo 1 "user assign identity" gán vào AKS.  
 - tạo 1 NSG cho AKS.  
 - tạo 2 nodepool. 1 Nodepool mode System, 1 Nodepool mode User. Với nhu cầu test thì ko cần lắm, bạn sửa lại 1 Nodepool System thôi là ok.
   Sự khác nhau giữa 2 mode:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aks-nodepool-mode-system-vs-user.jpg)
 

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
      "defaultValue": "13.34.56.78"
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
      "defaultValue": "akscluster04",
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
              "destinationAddressPrefix": "*",
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
        // Phải dùng networkPlugin=azure để enable Azure CNI, mới có khả năng từ trong Pod AKS call ra IP internal của VM 
        "networkProfile": {
          "networkPlugin": "azure"
        },
        "agentPoolProfiles": [
          {
            "name": "poolsystem",
            "osDiskSizeGB": "[parameters('osDiskSizeGB')]",
            "count": "[parameters('agentCount')]",
            "vmSize": "[parameters('agentVMSize')]",
            "osType": "[parameters('osType')]",
            "mode": "System",
            "vnetSubnetID": "[resourceId('Microsoft.Network/virtualNetworks/subnets', parameters('vnetName'), parameters('aksSnetName'))]"
          },
          // Phải tạo thêm Mode User Pool vì Có 1 số Helm chart code sử dụng nodeSelector là "kubernetes.azure.com/mode: user"
          // Ko thể chỉ tạo Mode User node pool, Azure bắt phải có 1 System Node pool
          {
            "name": "pooluser",
            "osDiskSizeGB": "[parameters('osDiskSizeGB')]",
            "count": "[parameters('agentCount')]",
            "vmSize": "[parameters('agentVMSize')]",
            "osType": "[parameters('osType')]",
            "mode": "User",
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

## 3. Install Traefik Helm chart

```sh
# Install CRDs:

$ k apply -f https://raw.githubusercontent.com/prometheus-community/helm-charts/main/charts/kube-prometheus-stack/charts/crds/crds/crd-servicemonitors.yaml

$ helm repo add traefik https://traefik.github.io/charts

$ k create ns traefik
helm --namespace traefik install traefik traefik/traefik --version 23.1.0

$ k get all -n traefik
NAME                           READY   STATUS    RESTARTS   AGE
pod/traefik-58fbf7c94b-q5vj7   1/1     Running   0          11m

NAME              TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)                      AGE
service/traefik   LoadBalancer   10.0.218.206   108.141.152.214   80:30575/TCP,443:30833/TCP   11m

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/traefik   1/1     1            1           11m

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/traefik-58fbf7c94b   1         1         1       11m
```

Traefik sẽ tạo 1 external LB với external IP để expose ra Internet. `108.141.152.214`

## 4. Setup Cert Manager Helm chart and issue Lets Encrypt

### 4.1. Chú ý

Trước đây (2021) mình dùng "Managed Identity Using AAD Pod Identities" nhưng nó đã bị deprecated, giờ phải dùng Workload Identity:  

> ⚠️ The open source Azure AD pod-managed identity (preview) in Azure Kubernetes Service has been deprecated as of 10/24/2022. Use Workload Identity instead. https://cert-manager.io/docs/configuration/acme/dns01/azuredns/

Tài liệu của cert manager về cách setup AKS dùng Workload identity: 
https://cert-manager.io/docs/tutorials/getting-started-aks-letsencrypt/  
https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster  

Nên update az CLI lên version mới, mình là 2.61.0 on Windows Ubuntu Subsystem:
https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux

```sh
sudo apt-get update && apt-get install -y libssl-dev libffi-dev python3-dev build-essential
# exit to user normal (ex: lhhoang)
exit
curl -L https://aka.ms/InstallAzureCli | bash
```

### 4.2. Update AKS cluster: enable workload identity, oidc issuer

Sau khi tạo AKS, run các command sau trên Azure CloudShell (Nếu run trên WSL Ubuntu bị lỗi `unrecognized arguments: --enable-oidc-issuer --enable-workload-identity`)  

```sh
az extension add --name aks-preview

az feature register --namespace "Microsoft.ContainerService" --name "EnableWorkloadIdentityPreview"

# It takes a few minutes for the status to show Registered. Verify the registration status by using the az feature list command:
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableWorkloadIdentityPreview')].{Name:name,State:properties.state}"

# When ready, refresh the registration of the Microsoft.ContainerService resource provider by using the az provider register command:
az provider register --namespace Microsoft.ContainerService

RESOURCE_GROUP=<YOUR_RESOURCE_GROUP_NAME>
CLUSTER_NAME=<YOUR_CLUSTER_NAME>
az aks update \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${CLUSTER_NAME}" \
    --enable-oidc-issuer \
    --enable-workload-identity
```

### 4.3. Install cert-manager Helm chart

File `values-cert-manager.yaml`:  

```yaml
podLabels:
  azure.workload.identity/use: "true"
serviceAccount:
  labels:
    azure.workload.identity/use: "true"
```

```sh
k create ns cert-manager
helm --namespace cert-manager install cert-manager jetstack/cert-manager \
  --version 1.15.1 \
   --set installCRDs=true \
  --values values-cert-manager.yaml

kubectl describe pod -n cert-manager -l app.kubernetes.io/component=controller
```

### 4.4. Tạo User Assign Identity cho AKS, nếu đã có rồi (qua ARM script) thì thôi

```sh
export USER_ASSIGNED_IDENTITY_NAME=id-xxx
az identity create --name "${USER_ASSIGNED_IDENTITY_NAME}"
```

Assign role:

```sh
# Get resource ID của DNS Zone, Chú ý có thể có TH DNS Zone nằm ở 1 Subscription khác:
export DOMAIN_NAME=azure.hoangmnsd.net
az network dns zone show --name $DOMAIN_NAME --resource-group <DNS_ZONE_RG> --subscription <DNS_ZONE_SUBSCRIPTION_ID> -o tsv --query id

export SCOPE_DNS_RESOURCE_ID=$(az network dns zone show --name $DOMAIN_NAME --resource-group ĐNS_ZONE_RG_NAME --subscription <DNS_ZONE_SUBSCRIPTION_ID> -o tsv --query id)
# Result: /subscriptions/DNS_ZONE_SUBSCRIPTION_ID/resourceGroups/ĐNS_ZONE_RG_NAME/providers/Microsoft.Network/dnszones/azure.hoangmnsd.net

export USER_ASSIGNED_IDENTITY_CLIENT_ID=$(az identity show --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group <IDENTITY_RG_NAME> --query 'clientId' -o tsv)

az role assignment create \
    --role "DNS Zone Contributor" \
    --assignee $USER_ASSIGNED_IDENTITY_CLIENT_ID \
    --scope $SCOPE_DNS_RESOURCE_ID
```

Verify: Vào Portal -> $USER_ASSIGNED_IDENTITY_NAME của AKS -> "Azure role assignments" -> chọn subscription của DNS Zone sẽ thấy đã được tạo role assignment:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-aks-identity-dnszone.jpg)

### 4.5. Tạo federated-credential cho identity

Nếu command dưới đây trên WSL bị lỗi thì hãy chạy trên Azure CloudShell:

```sh
export SERVICE_ACCOUNT_NAME=cert-manager # ℹ️ This is the default Kubernetes ServiceAccount used by the cert-manager controller.
export SERVICE_ACCOUNT_NAMESPACE=cert-manager # ℹ️ This is the default namespace for cert-manager.
export RESOURCE_GROUP=<YOUR_RG_NAME>
export AKS_OIDC_ISSUER="$(az aks show --name "${CLUSTER_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    --query "oidcIssuerProfile.issuerUrl" \
    --output tsv)"

echo $AKS_OIDC_ISSUER
# Result: https://westeurope.oic.prod-aks.azure.com/XXX/YYY/
```

Chú ý nếu ko có kết quả `$AKS_OIDC_ISSUER` thì có nghĩa là lỗi. Hãy thử lại trên Azure Cloudshell thì chắc chắn sẽ lấy được `$AKS_OIDC_ISSUER`

```sh
az identity federated-credential create \
  --name "cert-manager" \
  --resource-group "${RESOURCE_GROUP}" \
  --identity-name "${USER_ASSIGNED_IDENTITY_NAME}" \
  --issuer "${AKS_OIDC_ISSUER}" \
  --subject "system:serviceaccount:${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME}"
```

Verify: Vào Portal -> $USER_ASSIGNED_IDENTITY_NAME của AKS -> Settings -> Federated credentials -> sẽ thấy cái cert-manager hiện ra.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-aks-identity-federated-credentials.jpg)

### 4.6. Create ClusterIssuer staging by DNS01 resolver

Sửa file `clusterissuer-dns01-staging.yaml`, nhớ chỗ `managedIdentity.clientID` value là giá trị của biến `USER_ASSIGNED_IDENTITY_CLIENT_ID`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: <YOUR_EMAIL>@gmail.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - dns01:
        azureDNS:
          resourceGroupName: <DNS_ZONE_RG_NAME> # RG where you store DNS Zone
          subscriptionID: <DNS_ZONE_SUBSCRIPRION_ID> # Subscription where you store DNS Zone
          hostedZoneName: azure.yourdomain.net
          environment: AzurePublicCloud
          managedIdentity:
            clientID: <USER_ASSIGNED_IDENTITY_CLIENT_ID>
```

```sh
$ k apply -f clusterissuer-dns01-staging.yaml
clusterissuer.cert-manager.io/letsencrypt-staging created

$ k get clusterissuer -A
NAME                  READY   AGE
letsencrypt-staging   True    3s

$ k describe clusterissuer letsencrypt-staging
```

### 4.7. Create Certificate staging in your app namespace

Để chuẩn bị cho domain của app (app ví dụ là `echo1`):

Hãy vào Azure portal, DNS Zone của bạn -> create 1 A record trỏ đến Public IP của Traefik LB.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-dns-a-record-echo1.jpg)

Mỗi namespace sẽ đc deploy 1 service/app của bạn, trong namespace đó cần có 1 Certificate:

File `certificate-echo1-staging.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: echo1-cert-staging
spec:
  commonName: "echo1.azure.yourdomain.net"
  secretName: echo1-cert-staging
  dnsNames:
    - "echo1.azure.yourdomain.net"
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-staging
```

```sh
k create ns echo1
k apply -f certificate-echo1-staging.yaml -n echo1
```

❌Chú ý chỗ này rất quan trọng, Certificate cần được issue thành công rồi mới làm gì thì làm

**Troubleshooting**:

Nếu bị lỗi `Waiting on certificate issuance from order echo1/echo1-cert-staging-1-3661808977: "pending"` thì cứ `k describe` cho đến khi tìm được lỗi:

```sh
$ k describe certificate echo1-cert-staging -n echo1
$ k describe CertificateRequest "echo1-cert-staging-1" -n echo1
$ k describe Order echo1-cert-staging-1-3661808977 -n echo1
$ k describe Challenge "echo1-cert-staging-1-3661808977-2575380763"  -n echo1

# Lỗi tìm được cuối cùng:
PUT https://management.azure.com/subscriptions/SUPSCRIPTION_ID/resourceGroups/YOUR_RG_NAME/providers/Microsoft.Network/dnsZones/azure.yourdomain.net/TXT/_acme-challenge.echo1
--------------------------------------------------------------------------------
RESPONSE 404 Not Found
ERROR CODE: ParentResourceNotFound
--------------------------------------------------------------------------------
see logs for more information
  State:  pending
Events:
  Type     Reason        Age                From                     Message
  ----     ------        ----               ----                     -------
  Normal   Started       84s                cert-manager-challenges  Challenge scheduled for processing
  Warning  PresentError  17s (x5 over 83s)  cert-manager-challenges  Error presenting challenge: request error:
PUT https://management.azure.com/subscriptions/SUPSCRIPTION_ID/resourceGroups/YOUR_RG_NAME/providers/Microsoft.Network/dnsZones/azure.yourdomain.net/TXT/_acme-challenge.auditenv01
--------------------------------------------------------------------------------
RESPONSE 404 Not Found
ERROR CODE: ParentResourceNotFound
--------------------------------------------------------------------------------
see logs for more information
```

Nguyên nhân lỗi trong file ClusterIssuer trỏ sai RG Name và Subscription Name. Sửa lại rồi `k apply` lại là OK.

Verify: Bao giờ như này là OK:

```sh
$ k describe certificate echo1-cert-staging -n echo1

Status:
  Conditions:
    Last Transition Time:  2024-07-06T04:15:40Z
    Message:               Certificate is up to date and has not expired
    Observed Generation:   1
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Not After:               2024-10-04T03:15:35Z
  Not Before:              2024-07-06T03:15:36Z
  Renewal Time:            2024-09-04T03:15:35Z
  Revision:                1
Events:
  Type    Reason     Age   From                                       Message
  ----    ------     ----  ----                                       -------
  Normal  Issuing    108s  cert-manager-certificates-trigger          Issuing certificate as Secret does not exist
  Normal  Generated  108s  cert-manager-certificates-key-manager      Stored new private key in temporary Secret resource "echo1-cert-staging-t6cf2"
  Normal  Requested  108s  cert-manager-certificates-request-manager  Created new CertificateRequest resource "echo1-cert-staging-1"
  Normal  Issuing    7s    cert-manager-certificates-issuing          The certificate has been successfully issued


$ k get cert -n echo1
NAME                 READY   SECRET               AGE
echo1-cert-staging   True    echo1-cert-staging   11m

```
🎉Đây là 1 bước tiến quan trọng khi bạn dã issue được 1 certificate staging thành công. Sau này làm tương tự với production là sẽ ko vấn đề gì.

### 4.8. Deploy app echo1 without using TLS echo1-cert-staging

Sửa file `echo1-app.yml`, Chú ý mình đã comment phần sử dụng TLS `echo1-cert-staging`:

```yaml
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
        - "-text=Echo1!"
        ports:
        - containerPort: 5678

---
# Nếu muốn dùng IngressRoute thay vì Ingress
# apiVersion: traefik.containo.us/v1alpha1
# kind: IngressRoute
# metadata:
#   name: echo1-ingroute
# spec:
#   routes:
#     - match: Host(`echo1.azure.yourdomain.net`)
#       kind: Rule
#       services:
#         - name: echo
#           port: 80
#   tls:
#     secretName: echo1-cert-staging

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo1-ingress
spec:
  ingressClassName: traefik
  rules:
  - host: echo1.azure.yourdomain.net
    http:
      paths:
      - backend:
          service:
            name: echo
            port:
              number: 80
        path: /
        pathType: Prefix
  # tls:
  # - hosts:
  #   - echo1.azure.yourdomain.net
  #   secretName: echo1-cert-staging
```

```sh
$ k apply -f echo1-app.yml -n echo1

service/echo created
deployment.apps/echo created
ingress.networking.k8s.io/echo1-ingress created

$ k get all -n echo1
NAME                        READY   STATUS    RESTARTS   AGE
pod/echo-54f79c9797-7lzxq   1/1     Running   0          19s

NAME           TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
service/echo   ClusterIP   10.0.26.226   <none>        80/TCP    19s

NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/echo   1/1     1            1           20s

NAME                              DESIRED   CURRENT   READY   AGE
replicaset.apps/echo-54f79c9797   1         1         1       20s
```

Giờ khi browser access sẽ thấy app như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-dns-a-record-echo1-access-not-https.jpg)

### 4.9. Re-Deploy app echo1 with using TLS echo1-cert-staging

Sừa file bỏ comment đoạn `Ingress` để dùng tls `echo1-cert-staging`:

```yaml
...
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo1-ingress
spec:
  ingressClassName: traefik
  rules:
  - host: echo1.azure.yourdomain.net
    http:
      paths:
      - backend:
          service:
            name: echo
            port:
              number: 80
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - echo1.azure.yourdomain.net
    secretName: echo1-cert-staging
```

Rồi apply lại:

```sh
$ k apply -f echo1-app.yml -n echo1

service/echo unchanged
deployment.apps/echo unchanged
ingress.networking.k8s.io/echo1-ingress configured
```

✨ Tada~ Giờ bạn access lại từ browser sẽ có thể qua `https://`, insecure vì là cert staging:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-dns-a-record-echo1-access-https-insecure.jpg)

### 4.10. Deploy second app echo2 with HTTPS

Giả sử bạn có nhiều app muốn expose ra Internet qua Traefik và có https. (ví dụ app echo1, echo2)

Tương tự echo1,

Thì đầu tiên cần tạo 1 A record cho app echo2 trên Azure DNS Zone, vẫn trỏ IP vào Traefik Public LB IP.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-dns-a-record-echo2.jpg)

Sau đó là Issue 1 Certificate `echo2-cert-staging` trong namespace của app echo2:

File `certificate-echo2-staging.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: echo2-cert-staging
spec:
  commonName: "echo2.azure.yourdomain.net"
  secretName: echo2-cert-staging
  dnsNames:
    - "echo2.azure.yourdomain.net"
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-staging
```

```sh
k create ns echo2
k apply -f certificate-echo2-staging.yaml -n echo2
```

Verify như này là OK:

```
$ k get cert echo2-cert-staging -n echo2
NAME                 READY   SECRET               AGE
echo2-cert-staging   True    echo2-cert-staging   97s

$ k describe cert echo2-cert-staging -n echo2

Status:
  Conditions:
    Last Transition Time:  2024-07-06T06:12:06Z
    Message:               Certificate is up to date and has not expired
    Observed Generation:   1
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Not After:               2024-10-04T05:12:01Z
  Not Before:              2024-07-06T05:12:02Z
  Renewal Time:            2024-09-04T05:12:01Z
  Revision:                1
Events:
  Type    Reason     Age    From                                       Message
  ----    ------     ----   ----                                       -------
  Normal  Issuing    2m16s  cert-manager-certificates-trigger          Issuing certificate as Secret does not exist
  Normal  Generated  2m16s  cert-manager-certificates-key-manager      Stored new private key in temporary Secret resource "echo2-cert-staging-q466g"
  Normal  Requested  2m16s  cert-manager-certificates-request-manager  Created new CertificateRequest resource "echo2-cert-staging-1"
  Normal  Issuing    47s    cert-manager-certificates-issuing          The certificate has been successfully issued
```

Giờ deploy app `echo2`, file `echo2-app.yml`, Chú ý mình đã sử dụng TLS `echo2-cert-staging`:

```yaml
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
        - "-text=Echo2!"
        ports:
        - containerPort: 5678

---
# Nếu bạn muốn dùng IngressRoute thay vì Ingress
# apiVersion: traefik.containo.us/v1alpha1
# kind: IngressRoute
# metadata:
#   name: echo2-ingroute
# spec:
#   routes:
#     - match: Host(`echo2.azure.yourdomain.net`)
#       kind: Rule
#       services:
#         - name: echo
#           port: 80
#   tls:
#     secretName: echo2-cert-staging

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo2-ingress
spec:
  ingressClassName: traefik
  rules:
  - host: echo2.azure.yourdomain.net
    http:
      paths:
      - backend:
          service:
            name: echo
            port:
              number: 80
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - echo2.azure.yourdomain.net
    secretName: echo2-cert-staging
```

```sh
$ k apply -f echo2-app.yml -n echo2

$ k get all -n echo2
NAME                       READY   STATUS    RESTARTS   AGE
pod/echo-cc6ff9c6d-6j4cr   1/1     Running   0          85s

NAME           TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/echo   ClusterIP   10.0.231.213   <none>        80/TCP    87s

NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/echo   1/1     1            1           86s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/echo-cc6ff9c6d   1         1         1       87s
```

🎉Giờ bạn đã có thể access echo2 qua HTTPS (insecure do dùng staging cert):

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-dns-a-record-echo2-access-https-insecure.jpg)

### 4.11. Deploy 2 app echo1/echo2 with HTTPS use path-based routing

Nếu bạn có nhiều service và muốn các service đó sẽ được gọi từ cùng 1 domain từ Internet gọi vào qua các path khác nhau. Ví dụ:

- https://echo-backend.azure.yourdomain.net/echo1 -> service echo1

- https://echo-backend.azure.yourdomain.net/echo2 -> service echo2

Đầu tiên xóa các app echo1, echo2 mà mình vừa tạo ở step trên.

```sh
$ k delete -f echo1-app.yml -n echo1
service "echo" deleted
deployment.apps "echo" deleted
ingress.networking.k8s.io "echo1-ingress" deleted

$ k delete -f echo2-app.yml -n echo2
service "echo" deleted
deployment.apps "echo" deleted
ingress.networking.k8s.io "echo2-ingress" deleted
```

Tạo 1 DNS A record cho `echo-backend.azure.yourdomain.net` trỏ đến IP của Traefik LB Public IP:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-dns-a-record-echo-backend.jpg)

#### 4.11.1. Deploy certificate TLS dùng chung 2 app

2 app này sẽ cùng 1 namespace `echo-ns` để chúng dùng chung 1 TLS certificate

File `certificate-echo-backend-staging.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: echo-backend-cert-staging
spec:
  commonName: "echo-backend.azure.yourdomain.net"
  secretName: echo-backend-cert-staging
  dnsNames:
    - "echo-backend.azure.yourdomain.net"
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-staging
```

```sh
$ k create ns echo-ns
$ k apply -f certificate-echo-backend-staging.yaml -n echo-ns

# Verify READY=True là OK
$ k get cert echo-backend-cert-staging -n echo-ns
NAME                        READY   SECRET                      AGE
echo-backend-cert-staging   True    echo-backend-cert-staging   97s
```

#### 4.11.2. Deploy app echo1 vào path /echo1

File `echo1-app-pathbased.yml`. Chú ý Ingress trỏ đến `path: /echo1`, service name, deployment name có tên unique `echo1`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: echo1
spec:
  ports:
  - port: 80
    targetPort: 5678
  selector:
    app: echo1

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo1
spec:
  selector:
    matchLabels:
      app: echo1
  replicas: 1
  template:
    metadata:
      labels:
        app: echo1
    spec:
      containers:
      - name: echo1
        image: hashicorp/http-echo
        args:
        - "-text=Echo1!"
        ports:
        - containerPort: 5678

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo1-ingress
spec:
  ingressClassName: traefik
  rules:
  - host: echo-backend.azure.yourdomain.net
    http:
      paths:
      - backend:
          service:
            name: echo1
            port:
              number: 80
        path: /echo1
        pathType: Prefix
  tls:
  - hosts:
    - echo-backend.azure.yourdomain.net
    secretName: echo-backend-cert-staging
```

```sh
$ k apply -f echo1-app-pathbased.yml -n echo-ns
service/echo1 created
deployment.apps/echo1 created
ingress.networking.k8s.io/echo1-ingress created
```

Giờ đã có thể access thông qua Browser đến `https://echo-backend.azure.yourdomain.net/echo1`:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-dns-echo-backend-echo1-access-https-insecure.jpg)

#### 4.11.3. Deploy app echo2 vào path /echo2

File `echo2-app-pathbased.yml`. Chú ý Ingress trỏ đến `path: /echo2`, service name, deployment name có tên unique `echo2`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: echo2
spec:
  ports:
  - port: 80
    targetPort: 5678
  selector:
    app: echo2

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo2
spec:
  selector:
    matchLabels:
      app: echo2
  replicas: 1
  template:
    metadata:
      labels:
        app: echo2
    spec:
      containers:
      - name: echo2
        image: hashicorp/http-echo
        args:
        - "-text=Echo2!"
        ports:
        - containerPort: 5678

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo2-ingress
spec:
  ingressClassName: traefik
  rules:
  - host: echo-backend.azure.yourdomain.net
    http:
      paths:
      - backend:
          service:
            name: echo2
            port:
              number: 80
        path: /echo2
        pathType: Prefix
  tls:
  - hosts:
    - echo-backend.azure.yourdomain.net
    secretName: echo-backend-cert-staging
```

```sh
$ k apply -f echo2-app-pathbased.yml -n echo-ns
service/echo2 created
deployment.apps/echo2 created
ingress.networking.k8s.io/echo2-ingress created
```

Giờ đã có thể access thông qua Browser đến `https://echo-backend.azure.yourdomain.net/echo2`:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-dns-echo-backend-echo2-access-https-insecure.jpg)

### 4.12. Nếu ko muốn dùng DNS01 resolver, có thể dùng HTTP01 resolver

Nhớ lại khi tạo ClusterIssuer, chúng ta đã dùng DNS01 resolver, cách này yêu cầu setup khá lằng nhằng, cần cả chỉ định DNS Zone RG Name, Subscription Name, User assign identity... (nhưng có thể whitelist 1 số IP access đến Traefik LB)

Nếu dùng HTTP01 resolver, sẽ ko cần các bước setup loằng ngoằng, chỉ cần open port 80,443 cho Internet đến Traefik LB là được. (sửa trong AKS NSG)

Sau đó file `clusterissuer-http01-staging.yaml` như sau:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: <YOUR_EMAIL@gmail.com>
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
          ingress:
            serviceType: ClusterIP
            ingressClassName: traefik
```

```sh
k apply -f clusterissuer-http01-staging.yaml
```

Các bước còn lại như create Certificate thì tương tự như trên.

### 4.13. Deploy ClusterIssuer dùng production HTTPS secure

Sau khi đã xài staging certficate ok, bạn có thể Chuyển sang dùng production certficate được rồi.

Chú ý Issue Certificate dùng prod endpoint rất rate limit, sai phát là domain đấy lỗi luôn ko lấy cert nữa. Phải chắc chắn đã test OK với staging thì mới chuyển sang prod.

Ở đây mình tiếp tục dùng dns01 resolver. 

Cần deploy ClusterIssuer của prod.

File `clusterissuer-dns01-prod.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: <YOUR_EMAIL>@gmail.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - dns01:
        azureDNS:
          resourceGroupName: <DNS_ZONE_RG_NAME> # RG where you store DNS Zone
          subscriptionID: <DNS_ZONE_SUBSCRIPRION_ID> # Subscription where you store DNS Zone
          hostedZoneName: azure.yourdomain.net
          environment: AzurePublicCloud
          managedIdentity:
            clientID: <USER_ASSIGNED_IDENTITY_CLIENT_ID>
```

```sh
k apply -f clusterissuer-dns01-prod.yaml
```

File `certificate-echo-backend-prod.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: echo-backend-cert-prod
spec:
  commonName: "echo-backend.azure.yourdomain.net"
  secretName: echo-backend-cert-prod
  dnsNames:
    - "echo-backend.azure.yourdomain.net"
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-prod
```

```sh
k apply -f certificate-echo-backend-prod.yaml -n echo-ns
```

❗Chú ý: Chỉ khi get cert `echo-backend-cert-prod` thấy status `The certificate has been successfully issued` thì bạn mới có thể thở phào nhẹ nhõm là thành công. Thông thường mất khoảng 1 phút.

Việc còn lại là sửa Ingress để sử dụng cert `echo-backend-cert-prod` vừa issue thành công thôi. 😍


## REFERENCES

Tài liệu của cert manager về cách setup AKS dùng Workload identity: 
https://cert-manager.io/docs/tutorials/getting-started-aks-letsencrypt/  
https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster  

Tutorial khá dễ hiểu: Configure HTTPS in Traefik with cert-manager and Let’s Encrypt:
https://medium.com/@faturrahmanmakruf/configure-https-in-traefik-with-cert-manager-and-lets-encrypt-db60960e2283


Khá dài, chi tiết, nhiều thông tin, là 1 bài trong 1 series:
https://medium.com/geekculture/aks-with-cert-manager-f24786e87b20
AKS with external-dns: (https://joachim8675309.medium.com/extending-aks-with-external-dns-3da2703b9d52)
AKS with ingress-nginx: (https://joachim8675309.medium.com/aks-with-ingress-nginx-7c51da500f69)
AKS with cert-manager: (https://medium.com/geekculture/aks-with-cert-manager-f24786e87b20)
AKS with GRPC and ingress-nginx: (https://joachim8675309.medium.com/aks-with-grpc-and-ingress-nginx-32481a792a1)


Tutorial chính thức và up-to-date của Traefik:  
https://traefik.io/blog/secure-web-applications-with-traefik-proxy-cert-manager-and-lets-encrypt/


Tutorial chính thức và up-to-date của Cert Manager cho AKS:  
https://cert-manager.io/docs/tutorials/getting-started-aks-letsencrypt/#add-a-federated-identity


Wild card certificate using cert-manager in Kubernetes:  
https://medium.com/@harsh.manvar111/wild-card-certificate-using-cert-manager-in-kubernetes-3406b042d5a2


Implementing Cert-Manager and Cert-Issuer with Azure DNS:  
https://medium.com/@rituraj0tiwari/implementing-cert-manager-and-cert-issuer-with-azure-dns-48d32ea1d90c