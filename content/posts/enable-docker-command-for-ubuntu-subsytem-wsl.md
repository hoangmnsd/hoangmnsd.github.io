---
title: "Run docker command from Ubuntu Subsystem of Windows (WSL)"
date: 2021-08-02T09:53:45+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [WSL,Ubuntu,Docker,Windows]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Chắc các bạn hẳn đã từng gặp lỗi này khi dùng Ubuntu subsystem trên Windows: > The command 'docker' could not be found in this WSL1 distro. We recommend to convert this distro into WSL 2 and activate the WSL integration in Docker Desktop settings. "
---

# Giới thiệu

Chắc các bạn hẳn đã từng gặp lỗi này khi dùng Ubuntu subsystem trên Windows:  
> The command 'docker' could not be found in this WSL1 distro. We recommend to convert this distro into 
WSL 2 and activate the WSL integration in Docker Desktop settings.

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/docker-command-not-found-this-wsl1.jpg)

Vậy cần làm gì để convert WSL 1 sang WSL 2?

# Yêu cầu

- Phải là Windows 10  
- Bật CMD, run `winver` để xem version Windows của bạn đang dùng là gì? version nhỏ hơn 18362 là ko làm được đâu nhé.  
> Builds lower than 18362 do not support WSL 2.  

# Cách làm

Download latest package from this step: https://docs.microsoft.com/en-us/windows/wsl/install-win10#step-4---download-the-linux-kernel-update-package

In short, download from this link and install it: https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi


Bật PowerShell, Run command sau để set WSL version 2 cho Ubuntu-18.04:  
`wsl --set-version Ubuntu-18.04 2`

```
For information on key differences with WSL 2 please visit https://aka.ms/wsl2
PS C:\Users\abc> wsl --list --verbose
  NAME                   STATE           VERSION
* Ubuntu-18.04           Stopped         1
  docker-desktop         Running         2
  docker-desktop-data    Running         2

PS C:\Users\abc> wsl --set-version Ubuntu-18.04 2
Conversion in progress, this may take a few minutes...
For information on key differences with WSL 2 please visit https://aka.ms/wsl2
Conversion complete.
PS C:\Users\abc> wsl --list --verbose
  NAME                   STATE           VERSION
* Ubuntu-18.04           Stopped         2
  docker-desktop         Running         2
  docker-desktop-data    Running         2
PS C:\Users\abc>
``` 

Như đoạn log màn hình trên mà các bạn thấy, ban đầu mình list các wsl hiện có thì Ubuntu-18.04 đang chạy Version 1.  
Sau khi setting lại thì nó chuyển sang version 2.  

Chưa hết bạn cần setting trong Docker Windows App nữa, vào SETTING -> RESOURCES -> WSL Integration, chọn như hình này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/docker-command-not-found-setting-wsl-integrate.jpg)

Xong rồi, vào Ubuntu subsystem để gõ docker thôi.

Chúc bạn thành công!

# CREDITS

https://docs.microsoft.com/en-us/windows/wsl/install-win10#step-4---download-the-linux-kernel-update-package

