---
title: "Azure: Create AKS Cluster by ARM and ACI (using CNAB, porter.sh)"
date: 2021-08-10T15:03:08+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Azure,CNAB,ACI,AKS,Kubernetes]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bạn muốn deploy Azure AKS Cluster bằng ARM và Azure Container Instance, sau đó deploy helm chart lên AKS cluster đó."
---
Bạn muốn deploy Azure AKS Cluster bằng ARM và Azure Container Instance, sau đó deploy helm chart lên AKS cluster đó.

# 1. Giới Thiệu

### CNAB là gì?  
https://cnab.io/  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-standfor.jpg)  

CNAB là Cloud Native Application Bundle. Nó được thiết kế để bundling, installing, managing các distributed app.  
Nó được design bởi MS, Docker, Bitami, Hashicorp, Pivotal, codefresh.  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-3modules.jpg)

1 CNAB bao gồm 3 thành phần: Application Image, Invocation Image, Bundle descriptor.  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-benefits.jpg)

Tác dụng mà CNAB đem lại: Package toàn bộ app của bạn, ko cần cấu trúc phức tạp,...

### Porter là gì?  
https://porter.sh/  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-tools.jpg)

Trong các CNAB tools, để tạo ra CNAB thì có 1 số tool được sử dụng: Porter, Duffle, Docker App

-> Như vậy Porter là 1 tools để tạo ra CNAB



# 2. Yêu Cầu

## 2.1. Service Principal credential  

### 2.1.a. Create Service principal

Hãy chắc chắn bạn đã có 1 Azure Service Principal Credential, và add permission cho nó vào Subscription mà bạn định deploy. Nếu chưa có thì làm theo các step sau:  

Cách 1 là run command, mình tạo 1 credential tên là `CNAB_PORTER_APP`:  
```sh
az ad sp create-for-rbac -n "CNAB_PORTER_APP" --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"
```
bạn nhận dc kết quả trả về là 1 đoạn json kiểu sau, hãy giữ nó bí mật:  
```json
{
  "client_id": "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx",
  "client_secret": "yyyyyyyy_yyyyyyyyyy",
  "tenant_id": "zzzz-zzzz-zzzz-zzzz-zzzzzzzzzzz"
}
```
Cách 2 nếu bạn ko muốn run command thì vào giao Azure Portal để tạo, từ Home, chọn `Azure Active Directory AAD`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-ad-app-regis-new.jpg)

màn hình sau đó nhập tên App, chọn `Accounts in this organizational directory only` (hoặc tùy ý bạn nếu hiểu) -> `Register`

Chọn cái App mà bạn vừa tạo, chọn tab `Certificates & secrets`, tạo 1 secrets:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-ad-app-regis-new-secret.jpg)

Hãy để ý tab `Overview`, Client ID của App ở đây:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-ad-app-regis-new-ovview.jpg)

Tất cả những gì bạn cần ghi lại, save lại là Client ID và Client secret mà bạn vừa tạo ra.  
Chúng sẽ có ích về sau.

### 2.1.b. Grant permission Service principal on Subscription

Tiếp theo hãy gán quyền cho cái App bạn vừa tạo, chúng cần quyền trên toàn `Subscription` mà bạn sẽ sử dụng.
Như hình sau, hãy chắc chắn App của bạn nằm trong List `Role assignments` với role `Contributors`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-subscription-access-role-assignment.jpg)

Nếu ko phải, hoặc chưa đúng, hãy chọn nút khoanh đỏ `Add` để add role assignment cho App của bạn.

## 2.2. ACR 

Sau này bạn sẽ muốn các images chứa code của mình được giữ ở Private Registry của riêng mình.  
Hãy tạo cho mình 1 Azure Container Registry, nơi sẽ lưu giữ các Porter Images của bạn.
Chú ý enable `Admin User` vì sau này bạn sẽ cần.  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-acr-accessk.jpg)

# 3. Cách làm

## 3.1. Cài đặt

Theo official docs: https://porter.sh/install/

Mình dùng linux nên chỉ cần run command sau:  
```sh
curl -L https://cdn.porter.sh/latest/install-linux.sh | bash
```

## 3.2. porter.yaml

Tại workspace của bạn, tạo 1 file tên là `porter.yaml`:   
**chú ý thay `YOUR_ACR_NAME` bằng tên ACR của riêng bạn.**   
```yaml
name: aks
version: 0.1.6
description: "Azure Kubernetes Service (AKS)"
registry: YOUR_ACR_NAME.azurecr.io/porter

credentials:
- name: azure_client_id
  env: AZURE_CLIENT_ID
  description: AAD Client ID for Azure account authentication - used for AKS Cluster SPN details and for authentication to azure to get KubeConfig
- name: azure_tenant_id
  env: AZURE_TENANT_ID
  description: Azure AAD Tenant Id for Azure account authentication - used to authenticate to Azure to get KubeConfig 
- name: azure_client_secret
  env: AZURE_CLIENT_SECRET
  description: AAD Client Secret for Azure account authentication - used for AKS Cluster SPN details and for authentication to azure to get KubeConfig
- name: azure_subscription_id
  env: AZURE_SUBSCRIPTION_ID
  description: Azure Subscription Id used to set the subscription where the account has access to multiple subscriptions

parameters:
- name: resource_group
  env: CNAB_PARAM_resource_group
  type: string
  description: The name of the resource group to create the AKS Cluster in
- name: cluster_name
  env: CNAB_PARAM_cluster_name
  type: string
  description: The name to use for the AKS Cluster
- name: azure_location
  env: CNAB_PARAM_azure_location
  type: string
  description: The Azure location to create the resources in
  applyTo:
    - "install"
- name: kubernetes_version
  env: CNAB_PARAM_kubernetes_version
  type: string
  description: The Kubernetes version to use
  default: "1.21.2"
  applyTo:
    - "install"
- name: node_vm_size
  env: CNAB_PARAM_node_vm_size
  type: string
  description: The VM size to use for the cluster
  default: "Standard_DS2_v2"
  applyTo:
    - "install"
- name: node_count
  env: CNAB_PARAM_node_count
  type: integer
  minimum: 1
  description: The VM size to use for the cluster
  default: 1
  applyTo:
    - "install"
- name: vm_set_type
  env: CNAB_PARAM_vm_set_type
  type: string
  enum: 
  - VirtualMachineScaleSets
  - AvailabilitySet
  description: Agent pool VM set type
  default: VirtualMachineScaleSets
  applyTo:
    - "install"
- name: installation_name
  env: CNAB_PARAM_installation_name
  type: string
  description: Installation name for Helm deployment
  default: wordpress
  applyTo:
    - "install"
- name: helm_chart_version
  env: CNAB_PARAM_helm_chart_version
  type: string
  description: Version number for the Helm chart
  default: 7.6.5
  applyTo:
    - "install"
    - "upgrade"
- name: namespace
  env: CNAB_PARAM_namespace
  type: string
  description: Kubernetes namespace for installation
  default: wordpress
  applyTo:
    - "install"

mixins:
  - exec
  - az
  - helm

install:
  - az: 
      description: "Azure CLI login"
      arguments: 
        - "login" 
      flags:
        service-principal:
        username: "{{ bundle.credentials.azure_client_id}}"
        password: "{{ bundle.credentials.azure_client_secret}}"
        tenant: "{{ bundle.credentials.azure_tenant_id}}"

  - az: 
      description: "Azure set subscription Id"
      arguments: 
        - "account" 
        - "set" 
      flags:
        subscription: "{{ bundle.credentials.azure_subscription_id}}"

  - az: 
      description: "Create resource group if not exists"
      arguments: 
        - "group" 
        - "create" 
      flags:
        name: "{{ bundle.parameters.resource_group }}"
        location: "{{ bundle.parameters.azure_location }}"
  
  - exec: 
      description: "Create AKS if not exists"
      command: "bash"
      arguments:
        - "aks.sh"
        - "create-aks"
        - "{{ bundle.parameters.cluster_name }}"
        - "{{ bundle.parameters.resource_group }}"
        - "{{ bundle.parameters.kubernetes_version }}"
        - "{{ bundle.parameters.node_vm_size }}"
        - "{{ bundle.parameters.node_count }}"
        - "{{ bundle.credentials.azure_client_id}}"
        - "{{ bundle.credentials.azure_client_secret}}"
        - "{{ bundle.parameters.azure_location }}"
        - "{{ bundle.parameters.vm_set_type }}"

  - az: 
      description: "Azure CLI AKS get-credentials"
      arguments: 
        - "aks" 
        - "get-credentials" 
      flags:
        resource-group: "{{ bundle.parameters.resource_group }}"
        name: "{{ bundle.parameters.cluster_name }}"

  
  - helm:
      description: Install wordpress
      name: '{{ bundle.parameters.installation_name }}'
      chart: stable/wordpress
      version: '{{ bundle.parameters.helm_chart_version }}'
      namespace: '{{ bundle.parameters.namespace }}'
      replace: true

 
uninstall:
  - az: 
      description: "Azure CLI login"
      arguments: 
        - "login" 
      flags:
        service-principal: 
        username: "{{ bundle.credentials.azure_client_id }}"
        password: "{{ bundle.credentials.azure_client_secret }}"
        tenant: "{{ bundle.credentials.azure_tenant_id }}"

  - az: 
      description: "Azure set subscription Id"
      arguments: 
        - "account" 
        - "set" 
      flags:
        subscription: "{{ bundle.credentials.azure_subscription_id }}"

  - exec: 
      description: "Delete AKS"
      command: bash
      arguments: 
        - "aks.sh" 
        - "delete-aks" 
        - "{{ bundle.parameters.cluster_name }}"
        - "{{ bundle.parameters.resource_group }}"
```

File `porter.yaml` này mô tả tất cả các step sẽ được chạy khi ACI của bạn start.  
Nó giống như 1 kiểu wrapper lên `az-cli`, run các command từ `az login`, rồi `az create aks`, `helm`...etc

File bên trên với action `install`, nó sẽ login vào az bằng service principal mà bạn cung cấp, tạo AKS cluster nếu chưa có, deploy Helm chart của Wordpress. End! Rất đơn giản thế thôi.  

File tiếp theo bạn cần chuẩn bị là file shell `aks.sh`:  
```sh
function create-aks {
    if [[ -z $(az aks show --name $1 --resource-group $2 2> /dev/null) ]]
    then
        az aks create \
        --name $1 \
        --resource-group $2 \
        --kubernetes-version $3 \
        --node-vm-size $4 \
        --node-count $5 \
        --service-principal $6 \
        --client-secret $7 \
        --location $8 \
        --vm-set-type $9 \
        --generate-ssh-keys
    else
        echo "AKS cluster already exists in specified resource group with specified name"
    fi
}

function delete-aks {
    az aks delete --name $1 --resource-group $2 --yes
}

"$@"
```

Giờ làm sau để đóng gói hết các step đó vào 1 Docker image, rồi publish nó lên ACR? 

## 3.3. Build images

Run command sau để build Docker image:  
chú ý trỏ đến nơi bạn đang chứa file `porter.yaml` và `aks.sh`

```sh
porter build
```
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-acr-porter-build.jpg)

Nó sẽ tạo ra 1 Docker image gọi là `invocation image` ở local máy bạn.  
bạn thử run command `docker images` sẽ thấy nó:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-acr-docker-images.jpg)
 
## 3.4. Publish images & bundle

Giờ làm sao để sử dụng được nó?  
Chắc bạn nghĩ rằng chỉ cần `docker push ...` là images sẽ lên ACR của mình rồi đúng ko? - Không đơn giản thế

Để sử dụng được nó, ACR của bạn cần chứa images và 1 thứ gọi là bundle. Nếu bạn chỉ push mỗi image lên thì vô dụng.
Vì image này do Porter tạo ra, nên hãy push nó lên ACR bằng command của porter.

```sh
porter publish
```
Cả image và bundle sẽ được push lên ACR mà bạn đã chỉ định trong file `porter.yaml`

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-acr-porter-publish.jpg)

như hình trên bạn đã thấy images là `/porter/aks-installer:v0.1.6`  
và bundle là `/porter/aks:v0.1.6`. Đều nằm trên ACR của bạn.

## 3.5. Write ARM

Làm sao để sử dụng images chứa các step trên trong ACI ?

Tiếp theo sẽ cần viết 1 ARM template để deploy ra 1 ACI, nơi sẽ run các step mình đã define trong `porter.yaml`

tạo 1 file ARM template tên tùy ý: `deploy-aks-by-aci-cnab.json`

```json
{
	"$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
	"contentVersion": "1.0.0.0",
	"parameters": {
		"cluster_name": {
			"type": "string",
			"defaultValue": "akstest001",
			"metadata": {
				"description": "The name to use for the AKS Cluster"
			}
		},
		"cnab_action": {
			"type": "string",
			"defaultValue": "install",
			"metadata": {
				"description": "The name of the action to be performed on the application instance."
			}
		},
		"cnab_azure_client_id": {
			"type": "string",
			"metadata": {
				"description": "AAD Client ID for Azure account authentication - used to authenticate to Azure using Service Principal for ACI creation."
			}
		},
		"cnab_azure_client_secret": {
			"type": "securestring",
			"metadata": {
				"description": "AAD Client Secret for Azure account authentication - used to authenticate to Azure using Service Principal for ACI creation."
			}
		},
		"kubernetes_version": {
			"type": "string",
			"defaultValue": "1.21.2",
			"metadata": {
				"description": "The Kubernetes version to use"
			}
		},
		"node_count": {
			"type": "int",
			"defaultValue": 1,
			"metadata": {
				"description": "The VM size to use for the cluster"
			},
			"minValue": 1
		},
		"node_vm_size": {
			"type": "string",
			"defaultValue": "Standard_DS2_v2",
			"metadata": {
				"description": "The VM size to use for the cluster"
			}
		},
		"resource_group": {
			"type": "string",
			"defaultValue": "[concat(parameters('cluster_name'),'-RG')]",
			"metadata": {
				"description": "The name of the resource group to create the AKS Cluster in"
			}
		},
		"vm_set_type": {
			"type": "string",
			"defaultValue": "VirtualMachineScaleSets",
			"allowedValues": [
				"VirtualMachineScaleSets",
				"AvailabilitySet"
			],
			"metadata": {
				"description": "Agent pool VM set type"
			}
		},
		"registry_server": {
			"type": "string",
			"defaultValue": "",
			"metadata": {
				"description": "REGISTRY server"
			}
		},
		"registry_username": {
			"type": "string",
			"defaultValue": "",
			"metadata": {
				"description": "REGISTRY username"
			}
		},
		"registry_password": {
			"type": "securestring",
			"metadata": {
				"description": "REGISTRY password"
			}
		},
		"installation_name": {
			"type": "string",
			"defaultValue": "wordpress",
			"metadata": {
				"description": "REGISTRY username"
			}
		},
		"helm_chart_version": {
			"type": "string",
			"defaultValue": "7.6.5",
			"metadata": {
				"description": "helm chart version"
			}
		},
		"namespace": {
			"type": "string",
			"defaultValue": "wordpress",
			"metadata": {
				"description": "namespace"
			}
		}
	},
	"variables": {
		"aci_location": "[resourceGroup().Location]",
		"cnab_action": "[parameters('cnab_action')]",
		"cnab_azure_client_id": "[parameters('cnab_azure_client_id')]",
		"cnab_azure_client_secret": "[parameters('cnab_azure_client_secret')]",
		"cnab_azure_location": "[resourceGroup().Location]",
		"cnab_azure_subscription_id": "[subscription().subscriptionId]",
		"cnab_azure_tenant_id": "[subscription().tenantId]",
		"cnab_installation_name": "aks",
		"containerGroupName": "[concat('cg-',uniqueString(resourceGroup().id, 'aks'))]",
		"containerName": "[concat('cn-',uniqueString(resourceGroup().id, 'aks'))]"
	},
	"resources": [
		{
			"type": "Microsoft.ContainerInstance/containerGroups",
			"name": "[variables('containerGroupName')]",
			"apiVersion": "2018-10-01",
			"location": "[variables('aci_location')]",
			"properties": {
				"imageRegistryCredentials": [
					{
						"server": "[parameters('registry_server')]",
						"username": "[parameters('registry_username')]",
						"password": "[parameters('registry_password')]"
					}
				],
				"containers": [
					{
						"name": "[variables('containerName')]",
						"properties": {
							"image": "YOUR_ACR_NAME.azurecr.io/porter/aks-installer:v0.1.6",
							"resources": {
								"requests": {
									"cpu": 1.0,
									"memoryInGb": 1.5
								}
							},
							"environmentVariables": [
								{
									"name": "CNAB_ACTION",
									"value": "[variables('cnab_action')]"
								},
								{
									"name": "CNAB_INSTALLATION_NAME",
									"value": "[variables('cnab_installation_name')]"
								},
								{
									"name": "AZURE_LOCATION",
									"value": "[variables('cnab_azure_location')]"
								},
								{
									"name": "AZURE_CLIENT_ID",
									"value": "[variables('cnab_azure_client_id')]"
								},
								{
									"name": "AZURE_CLIENT_SECRET",
									"secureValue": "[variables('cnab_azure_client_secret')]"
								},
								{
									"name": "AZURE_SUBSCRIPTION_ID",
									"value": "[variables('cnab_azure_subscription_id')]"
								},
								{
									"name": "AZURE_TENANT_ID",
									"value": "[variables('cnab_azure_tenant_id')]"
								},
								{
									"name": "VERBOSE",
									"value": "false"
								},
								{
									"name": "CNAB_BUNDLE_NAME",
									"value": "aks"
								},
								{
									"name": "CNAB_BUNDLE_TAG",
									"value": "YOUR_ACR_NAME.azurecr.io/porter/aks:v0.1.6"
								},
								{
									"name": "CNAB_PARAM_azure_location",
									"value": "[variables('cnab_azure_location')]"
								},
								{
									"name": "CNAB_PARAM_cluster_name",
									"value": "[parameters('cluster_name')]"
								},
								{
									"name": "CNAB_PARAM_kubernetes_version",
									"value": "[parameters('kubernetes_version')]"
								},
								{
									"name": "CNAB_PARAM_node_count",
									"value": "[parameters('node_count')]"
								},
								{
									"name": "CNAB_PARAM_node_vm_size",
									"value": "[parameters('node_vm_size')]"
								},
								{
									"name": "CNAB_PARAM_resource_group",
									"value": "[parameters('resource_group')]"
								},
								{
									"name": "CNAB_PARAM_vm_set_type",
									"value": "[parameters('vm_set_type')]"
								},
								{
									"name": "CNAB_PARAM_installation_name",
									"value": "[parameters('installation_name')]"
								},
								{
									"name": "CNAB_PARAM_helm_chart_version",
									"value": "[parameters('helm_chart_version')]"
								},
								{
									"name": "CNAB_PARAM_namespace",
									"value": "[parameters('namespace')]"
								}
							]
						}
					}
				],
				"osType": "Linux",
				"restartPolicy": "Never"
			}
		}
	],
	"outputs": {
		"CNAB Package Action Logs Command": {
			"type": "string",
			"value": "[concat('az container logs -g ',resourceGroup().name,' -n ',variables('containerGroupName'),'  --container-name ',variables('containerName'), ' --follow')]"
		}
	}
}
```
tìm 2 chỗ `YOUR_ACR_NAME` và sửa bằng ACR name của bạn 

bạn sẽ thấy Bundle cần đặt ở đâu và Images cần đặt ở đâu.

Mình sẽ ko đi sâu vào logic code, các bạn làm theo đúng và chạy được OK đã, sau đó hãy quay lại để tìm hiểu logic thì sẽ dễ hiểu hơn. Trong quá trình fix cho code chạy được, các bạn cũng sẽ hiểu logic hơn là ngồi đọc chay.


## 3.6. Deploy ARM template

Vào link sau để deploy ARM template mình vừa viết:  
https://portal.azure.com/#create/Microsoft.Template

Chọn hình bút chì `Build your own template in the editor`

Copy toàn bộ nội dung ARM vừa viết paste đè lên -> ấn nút `Save`

Tại màn hình tiếp theo, Hãy nhập `Client ID`, `Client secret`, `Registry server/username/password` (chú ý bôi vàng):  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-arm-input-params.jpg)

ấn `Review and create`

Chờ đến khi màn hình này hiện ra, nghĩa là ACI của bạn đã được tạo ra: 
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-arm-completed.jpg)

Tuy nhiên đến đây thì các command/step của bạn vẫn đang chạy trong ACI, hãy xem log của nó là success hay fail:
Vào Azure Container Instance, chọn Instance mới do bạn tạo ra, -> vào `Container` -> `Log`,

Nếu màn hình log như sau, có nghĩa là nó đã qua hết các step từ AZ login, AZ create AKS, Helm chart để cuối cùng có 1 trang Wordpress cho bạn:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-cnab-aci-log.jpg)

Tất nhiên bạn có thể login vào AKS cluster xem các pod, các namespace, services được rồi

Done!

Chúc bạn thành công 😜

# 4. Troubleshooting

## 4.1. ERROR: (AuthorizationFailed)

Nếu bạn gặp lỗi này khi xem Logs của Container: 
```
Azure set subscription Id
Create resource group if not exists
ERROR: (AuthorizationFailed) The client 'xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx' with object id 'xxxxxxx-xxxx-xxxx-yyyy-yyyyy' does not have authorization to perform action 'Microsoft.Resources/subscriptions/resourcegroups/write' over scope '/subscriptions/*******/resourcegroups/akstest001-RG' or the scope is invalid. If access was recently granted, please refresh your credentials.
err: error running command /cnab/app az group create --location westeurope --name akstest001-RG --output json: exit status 1
```
-> Có nghĩa là App Client Id/Secret của bạn đang ko có quyền tạo Resource Group. Bạn hãy chú ý App Registration của bạn cần dc có quyền COntributor trên scope là Subscription, ko phải chỉ 1 Resource group nào đó. (Xem kỹ lại step `2.1.b.`)

# 5. Tìm hiểu thêm về Porter

Trong quá trình phát triển, bạn sẽ không muốn mỗi lần sửa code muốn test thì lại phải `porter publish` rồi lại deploy ARM template. Như vậy sẽ rất tốn thời gian (Mỗi lần `porter publish` phải mất khoảng 10-15 phút để nó upload được images xấp xỉ 2Gb lên Registry của bạn)

Thế nên sau bước `porter build`, bạn có thể test luôn image trước khi publish nó bằng cách dùng các command `porter install` 

Nhưng để dùng thì bạn cần truyền các credential vào trước đã:  
```sh
porter credentials generate [YOUR_CRED_NAME]
```  
1 list các lựa chọn hiện ra, sau đó bạn insert các giá trị credential (Service Principal Client ID, secret, registry user name, password, ...etc)

(Optional) Bạn cũng có thể tạo các Parameter set:  
```sh
porter parameters generate [YOUR_PARAM_SET_NAME]
```  

Cuối cùng thì có thể test Images:  
```sh
porter install --cred [YOUR_CRED_NAME] --parameter-set [YOUR_PARAM_SET_NAME]
```

Câu lệnh trên sẽ tạo ra container ngay trên máy local của bạn, giúp bạn nhanh chóng debug nếu có vấn đề.

List các command của Porter ở đây: https://porter.sh/cli/porter/#see-also

# CREDITS

https://porter.sh/  
https://github.com/Azure/azure-cnab-quickstarts  
https://www.youtube.com/watch?v=z1lnQfaAVeg&ab_channel=endjin