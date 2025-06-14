---
title: "Azure Function App development with CLI"
date: 2025-01-20T12:52:01+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Azure,Serverless,AzureFunction]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Run Azure Function CLI from WSL and deploy to Azure Function App"
---

# Run Azure Function serverless trên WSL

## Install

```sh
$ curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
$ sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg

$ sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs 2>/dev/null)-prod $(lsb_release -cs 2>/dev/null) main" > /etc/apt/sources.list.d/dotnetdev.list'

$ sudo apt-get update
$ sudo apt-get install azure-functions-core-tools-4

$ func --version
4.0.6821
```

## Activate, init and run

```sh
$ python -m venv .venv

$ source .venv/bin/activate (OPTIONAL)

$ func init test-az-function-01 --worker-runtime python

$ cd ./test-az-function-01/

$ func new --template "Http Trigger" --name main
Select a number for Auth Level:
1. FUNCTION
2. ANONYMOUS
3. ADMIN
Choose option: 2
Appending to /home/USERNAME/test-az-function-01/function_app.py
The function "main" was created successfully from the "Http Trigger" template.

$ func start --python
Found Python version 3.10.12 (python3).

Azure Functions Core Tools
Core Tools Version:       4.0.6821 Commit hash: N/A +c09a2033XXXf83 (64-bit)
Function Runtime Version: 4.1036.1.23224

[2025-01-20T07:49:32.610Z] Worker process started and initialized.
Functions:
        main:  http://localhost:7071/api/main

```

Truy cập vào http://localhost:7071/api/main để xem

Như vậy là có thể run python function ở local OK.

Giờ Deploy lên Azure Function

## Deploy to Azure Function

```sh
$ az login --use-device-code

Để login vào account bạn muốn

$ func azure functionapp publish <Azure Function App Name>
...
Deployment successful. deployer = Push-Deployer deploymentPath = Functions App ZipDeploy. Extract zip. Remote build.
Remote build succeeded!
[2025-01-20T08:14:36.764Z] Syncing triggers...
Functions in <Azure Function App Name>:
    main - [httpTrigger]
        Invoke url: https://<Azure Function App Name>.azurewebsites.net/api/main

```

Vào trang `https://<Azure Function App Name>.azurewebsites.net/api/main` check OK

Giờ tạo thêm 1 route function (ví dụ hello) nữa trong file `function_app.py`. Lên giao diện sẽ thấy trong cái `Azure Function App Name` sẽ xuất hiện 2 function: hello, main

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-function-app.jpg)

Tóm lại command `func azure functionapp publish <Azure Function App Name>` sẽ deploy toàn bộ các function trong folder hiện tại lên `Azure Function App Name`.

Nếu muốn tạo 1 project folder mới tách biệt với project vừa xong, thì bạn cần tạo 1 `Azure Function App Name` mới trên Azure Portal để làm endpoint cho nó.

# REFERENCES

https://learn.microsoft.com/en-us/azure/azure-functions/create-first-function-cli-python?tabs=linux%2Cbash%2Cazure-cli%2Cbrowser -> Có thể bị lỗi

https://dev.to/manukanne/azure-functions-and-fastapi-14b6 => OK hơn
