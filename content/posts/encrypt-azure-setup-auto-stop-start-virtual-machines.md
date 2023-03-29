---
title: "Azure: Setup Auto Stop/Start on schedule for Virtual Machines"
date: 2020-08-31T21:47:51+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Azure]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Nên sử dụng Automation service của Azure"
---

Nên sử dụng Automation service của Azure

Giả sử bạn đã tạo 1 Resource Group tên là: `test-auto-startstop-vm`

Trong Resource Group đó bạn có 2 VM như sau (ảnh):
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-2vm-test-auto-stopstart.jpg)

Chọn Resource Group mà bạn muốn apply stop/start solution vào, chọn `Add` (ảnh):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-rg-auto-stopstart-vm-init.jpg)

Search `Automation` (ảnh):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-search-auto-acc.jpg)

Chọn `Create` (ảnh):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-search-auto-acc-done.jpg)

Tạo `Automation Account`. Điền thông tin phù hợp với bạn và tiếp tục chọn `Create` (ảnh):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-add-auto-acc.jpg)

Quay lại portal của `Resource Group` bạn sẽ thấy có thêm các resource được tạo ra. Ấn vào `automation-account` (ảnh):  
1 Automation Account và 3 Runbook  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-rg-auto-acc-created.jpg)

Ở màn hình portal của `Automation Account`, kéo xuống chọn `Runbook Gallery`, chọn tiếp `Stop-Start-AzureVM (Scheduled VM Shutdown/Startup)` - `Created by: Pradebban Raja`. Những cái khác cũng là của cộng đồng đóng góp bạn có thể thử. Tuy nhiên mình chọn cái này vì nó cung cấp đồng thời cả Stop/Start VM, mà cũng được rate khá cao.  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-choose-runbook-community.jpg)

Chọn `Import` để sử dụng Runbook (ảnh):   
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-import-runbook.jpg)

Quay lại portal của `Resource Group`, bạn sẽ thấy Runbook vừa import đã được hiện ra, ấn vào nó (ảnh):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-choose-runbook-from-portal.jpg)

Ở màn hình portal của `Runbook`, hãy chọn `Edit`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-edit-runbook.jpg)

Ở đây hãy paste nội dung sau vào terminal:  
```sh
Workflow Stop-Start-AzureVM 
{ 
    Param 
    (    
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
        [String] 
        $AzureSubscriptionId, 
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
        [String] 
        $AzureVMList="All", 
        [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] 
        [String] 
        $Action 
    ) 
    
    $connectionName = "AzureRunAsConnection"
    try
    {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

        "Logging in to Azure..."
        Add-AzureRmAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
    }
    catch {
        if (!$servicePrincipalConnection)
        {
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        } else{
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }

    if($AzureVMList -ne "All") 
    { 
        $AzureVMs = $AzureVMList.Split(",") 
        [System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs 
    } 
    else 
    { 
        $AzureVMs = (Get-AzureRmVM).Name 
        [System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs 
 
    } 
 
    foreach($AzureVM in $AzureVMsToHandle) 
    { 
        if(!(Get-AzureRmVM | ? {$_.Name -eq $AzureVM})) 
        { 
            throw " AzureVM : [$AzureVM] - Does not exist! - Check your inputs " 
        } 
    } 
 
    if($Action -eq "Stop") 
    { 
        Write-Output "Stopping VMs"; 
        foreach -parallel ($AzureVM in $AzureVMsToHandle) 
        { 
            Get-AzureRmVM | ? {$_.Name -eq $AzureVM} | Stop-AzureRmVM -Force 
        } 
    } 
    else 
    { 
        Write-Output "Starting VMs"; 
        foreach -parallel ($AzureVM in $AzureVMsToHandle) 
        { 
            Get-AzureRmVM | ? {$_.Name -eq $AzureVM} | Start-AzureRmVM 
        } 
    } 
}
```

Sau đó chọn `Save` và `Publish` nhé

Đến đây có thể các bạn sẽ tự hỏi tại sao phải update code, ko dùng cái có sẵn của Runbook à?   
**Giải thích**: Đúng vậy, chạy Code có sẵn các bạn rất nhiều khả năng sẽ bị dính lỗi sau đây:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-error-suspended.jpg)

khả năng là do đoạn code Login vào Azure của nó có vấn đề, thế nên cần sử dụng đoạn code mà mình thay thế ở bên trên

Quay lại portal của `Runbook`, chọn `Link to schedule`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-runbook-link-to-sched.jpg)

Click vào phần setting Schedule trước rồi `Create new schedule`:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-runbook-setting-schedule.jpg)

Tạo 1 schedule sẽ run vào lúc nào đó tùy bạn, ở đây mình lấy ví dụ là 11:10PM:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-setting-new-schedule.jpg)

Tiếp tục chọn phần config Parameter như hình này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-runbook-setting-params.jpg)

Ở đây bạn cần điền thông tin:  
`AZURESUBSCRIPTIONID`: subscription id,  
`AZUREVMLIST`: list các VM sẽ stop (ngăn cách bằng dấu phẩy, ko space),   
`ACTION`: chỉ đc ghi `Stop` hoặc `Start`. Ở ví dụ này mình sẽ điền Stop    
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-runbook-setting-params-2.jpg)

tiếp tục chọn OK, ở màn hình portal `Runbook` bạn chọn tab `Schedule` ở panel tay trái, sẽ thấy Schedule đã được lên lịch, sẽ run vào lúc 11h10PM:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-runbook-schedule-done.jpg)

Chờ đến 11h10PM, các bạn có thể chuyển sang tab `Job` để xem trạng thái Job của bạn chạy thành công hay thất bại:   
Nếu thành công sẽ là `Completed`, nếu lỗi thì sẽ là `Suspended`
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-job-completed-stt.jpg)

Xem log thấy như này là OK, ko có ERROR, WARNING gì cả:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-job-stt-log.jpg)

Quay lại portal của Virtual Machine sẽ thấy các VMs đã được stop.
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-stopped.jpg)

Giờ các bạn có thể tự tạo Schedule Auto Start VM nữa như sau:   
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-auto-stopstart-vm-schedule-stop-start-done.jpg)

Đi ngủ và tận hưởng thành quả thôi ^^

# Chú ý

1. Để dùng lâu dài và thường xuyên thì PowerShell script rất không ổn định, nhiều lúc bị lỗi ko thể start/stop VM được, vì thế mình khuyên các bạn nên tự viết các hàm python để thay thế cho PowerShell

2. Chú ý khi tạo Automation Account, nó có auto tạo certificate ko. Nếu có thì cert ấy sẽ tự động hết hạn sau 1 năm.
Cần có giải pháp: hoặc là try-catch chỗ authenticate code của Runbook nếu lỗi thì raise lên cho mình vào renew cert. 
Hoặc là sửa code thành authen vào Azure bằng identity. Hoặc là 1 năm sau nhớ vào gia hạn.

Script python sample:
```python
"""
Automation runbook for Stop/Start VMs on Azure

Parameters - Required:
[PARAMETER 1] : stop | start
[PARAMETER 2] : VM name - separated by comma (,)
[PARAMETER 3] : Resource group name that contains VM

This runbook will stop/start all VMs specified in [PARAMETER 2]

"""
import azure.mgmt.resource
import automationassets
from msrestazure.azure_cloud import AZURE_PUBLIC_CLOUD
import sys
from azure.mgmt.compute import ComputeManagementClient
from msrestazure.azure_exceptions import CloudError
import requests, json

def get_automation_runas_credential(runas_connection, resource_url, authority_url):
    """ Returns credentials to authenticate against Azure resoruce manager """
    from OpenSSL import crypto
    from msrestazure import azure_active_directory
    import adal

    # Get the Azure Automation RunAs service principal certificate
    cert = automationassets.get_automation_certificate("AzureRunAsCertificate")
    pks12_cert = crypto.load_pkcs12(cert)
    pem_pkey = crypto.dump_privatekey(crypto.FILETYPE_PEM, pks12_cert.get_privatekey())

    # Get run as connection information for the Azure Automation service principal
    application_id = runas_connection["ApplicationId"]
    thumbprint = runas_connection["CertificateThumbprint"]
    tenant_id = runas_connection["TenantId"]

    # Authenticate with service principal certificate
    authority_full_url = (authority_url + '/' + tenant_id)
    context = adal.AuthenticationContext(authority_full_url)
    return azure_active_directory.AdalAuthentication(
        lambda: context.acquire_token_with_client_certificate(
            resource_url,
            application_id,
            pem_pkey,
            thumbprint)
    )

def start_vm(vm, resource_group, compute_client):
    try:
        print("Try to start vm [%s]" % vm)
        async_vm_start = compute_client.virtual_machines.start(resource_group, vm)
        async_vm_start.wait()
        print("vm [%s] was successfully started" % vm)
        return True
    except CloudError as err:
        if 'ThrottlingException' in str(err):
            print("Start command throttled, automatically retrying...")
            start_vm(vm, resource_group, compute_client)
        else:
            print("Start command failed!\n%s" % str(err))
            return False
    except:
        raise

def stop_vm(vm, resource_group, compute_client):
    try:
        print("Try to stop vm [%s]" % vm)
        async_vm_stop = compute_client.virtual_machines.power_off(resource_group, vm)
        async_vm_stop.wait()
        print("vm [%s] was successfully stopped" % vm)
        return True
    except CloudError as err:
        if 'ThrottlingException' in str(err):
            print("Stop command throttled, automatically retrying...")
            stop_vm(vm, resource_group, compute_client)
        else:
            print("Stop command failed!\n%s" % str(err))
            return False
    except:
        raise

def alert_on_slack(vm, resource_group):
    try:
        hook_url = "https://hooks.slack.com/services/XXXX/YYYY/ZZZZZ"
        payload={"text": "Something wrong when stop/start vm [%s] [%s].\nPlease go to Azure portal to take action." % (vm, resource_group)}

        response = requests.post(
            hook_url,
            data = json.dumps(payload),
            headers = {'Content-Type': 'application/json'}
        )
        print("Alert!")
        if response.status_code != 200:
            raise ValueError(
                'Request to slack returned an error %s, the response is:\n%s'
                % (response.status_code, response.text)
            )
        return response
    except:
        raise

def main():
    if len(sys.argv) >= 3:
        action = str(sys.argv[1])
        vm_list = str(sys.argv[2])
        resource_group = str(sys.argv[3])
        # need some regex to validate argument variables

    else:
        error_msg = "Positional parameters action, vm_list and resource_group are required..."
        print(error_msg)
        raise Exception(error_msg)
    vm_list = vm_list.split(",")

    # authenticate to Azure Cloud
    runas_connection = automationassets.get_automation_connection("AzureRunAsConnection")
    resource_url = AZURE_PUBLIC_CLOUD.endpoints.active_directory_resource_id
    authority_url = AZURE_PUBLIC_CLOUD.endpoints.active_directory
    resourceManager_url = AZURE_PUBLIC_CLOUD.endpoints.resource_manager
    azure_credential = get_automation_runas_credential(runas_connection, resource_url, authority_url)

    compute_client = ComputeManagementClient(
        azure_credential,
        str(runas_connection["SubscriptionId"])
    )
    # stop/start VM base on action
    if action.lower() == "start":
        for vm in vm_list:
            response = start_vm(vm, resource_group, compute_client)
            if response != True:
                alert_on_slack(vm, resource_group)
    elif action.lower() == "stop":
        for vm in vm_list:
            response = stop_vm(vm, resource_group, compute_client)
            if response != True:
                alert_on_slack(vm, resource_group)
    
if __name__ == '__main__':
    main()

```
