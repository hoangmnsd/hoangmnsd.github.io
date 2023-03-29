---
title: "Using Packer + Ansible to Create Image"
date: 2019-08-15T16:48:35+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Packer,Ansible,AWS]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Giả định là bạn đã có 1 tài khoản AWS rồi, có thể tạo được EC2, có base kiến thức cơ bản về AWS, Linux biết cách SSH vào EC2"
---

## Yêu cầu
Giả định là bạn đã có 1 tài khoản AWS rồi, có thể tạo được EC2

Có base kiến thức cơ bản về AWS, Linux biết cách SSH vào EC2

## Cách làm
### 1. Tạo bộ AWS key cho Packer user
Vào AWS IAM tạo user "packer" (hoặc bất cứ tên gì, ở đây mình lấy ảnh cũ chọn user "ansible") cấp policy phù hợp (ví dụ chọn AdministratorAccess).

Vào tab `Security cedentials` tạo Key cho User đó.

Copy bộ access key id và sceret access key ra để bước sau dùng.
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iam-ansible-user.jpg)

Launch 1 Amazon Linux EC2, SSH vào và làm các bước tiếp theo:

### 2. Install Packer
```sh
export PACKER_RELEASE="1.4.3"
cd /tmp/
wget --no-check-certificate https://releases.hashicorp.com/packer/${PACKER_RELEASE}/packer_${PACKER_RELEASE}_linux_amd64.zip
unzip packer_${PACKER_RELEASE}_linux_amd64.zip
sudo mv packer /usr/local/bin
export PATH=$PATH:/usr/local/bin/packer
source ~/.bashrc
packer version
```
Nếu install thành công sẽ check được version của packer:
```
[ec2-user@ip-172-31-16-113 ~]$ packer version
Packer v1.4.3
```

### 3. Export AWS KEY của Packer user
Sử dụng 2 cái key đã chuẩn bị ở step 1:
```sh
export AWS_ACCESS_KEY_ID='AKIARRRRRRRRRRRRRRZ6'
export AWS_SECRET_ACCESS_KEY='ICUZE333sjfio899EEEEEEEEEEUr7'
```
Đến đây mình sẽ đưa ra 2 demo:  
Demo 1 là Dùng Packer để build Amazon image (AMI)  
Demo 2 là Dùng Packer + Ansible để build Docker image  
Tất nhiên có thể có nhiều cách kết hợp, nhưng mình chỉ đưa 2 cái ví dụ cơ bản

### 4. Dùng Packer để build Amazon image
#### 4.1. Tạo file Packer template
file mình đặt là `basic.json`
Chú ý đang làm trên "region": "us-east-1", nên nếu bạn làm khác region thì phải chọn ami phù hợp
```sh
{
  "variables": {
    "aws_access_key": "{{env `AWS_ACCESS_KEY_ID`}}",
    "aws_secret_key": "{{env `AWS_SECRET_ACCESS_KEY`}}"
  },
  "builders": [{
    "type": "amazon-ebs",
    "access_key": "{{user `aws_access_key`}}",
    "secret_key": "{{user `aws_secret_key`}}",
    "region": "us-east-1",
    "source_ami_filter": {
      "filters": {
      "virtualization-type": "hvm",
      "name": "ubuntu/images/*/ubuntu-xenial-16.04-amd64-server-*",
      "root-device-type": "ebs"
      },
      "owners": ["099720109477"],
      "most_recent": true
    },
    "instance_type": "t2.micro",
    "ssh_username": "ubuntu",
    "ami_name": "packer-example {{timestamp}}"
  }],
  "provisioners": [{
    "type": "shell",
    "inline": [
      "sleep 30",
      "sudo apt-get update",
      "sudo apt-get install -y redis-server"
    ]
  }]
}
```
#### 4.2. Validate Packer template
```sh
packer validate basic.json
```
Nếu template của bạn ko có lỗi syntax gì thì hiện như sau:
```
[ec2-user@ip-172-31-16-113 ~]$ packer validate basic.json
Template validated successfully.
```
#### 4.3. Build Packer template
```sh
packer build basic.json
```
Nó sẽ tạo ra AMI trên AWS console cho mình, trong AMI đấy đã install redis như đc define trong `basic.json`
vào Console check nếu tạo ra AMI là ok

### 5. Dùng Packer + Ansible để build Docker image
#### 5.1. Install Docker
```sh
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
exit
exit
```
rồi SSH lại vào EC2, và các làm bước sau

#### 5.2. Tạo file Packer template
Mình đặt tên file là `container.json`
```sh
{
  "builders": [{
      "type": "docker",
      "image": "centos:7",
      "export_path": "image.tar"
    }],
  "provisioners":[{
      "type": "shell",
      "inline": [
        "yum -y update",
        "yum -y install epel-release",
        "yum -y install python-pip",
        "pip install --upgrade pip",
        "pip install ansible==2.5.0"
      ]}, {
      "type": "ansible-local",
      "playbook_file": "container_base.yml"
    }],
  "post-processors": [{
      "type": "docker-import",
      "repository": "ansible-dockerimage",
      "tag": "0.1.0"
    }]
}
```

#### 5.3. Tạo file Ansible playbook
Vì trong file `container.json` sẽ gọi đến Ansible playbook `container_base.yml`  
Nên mình đặt tên file là `container_base.yml`
```sh
- hosts: all
  become: True
  tasks:
    - name: install package
      yum: name={{ item }} state=present
      with_items:
        - git
        - htop
```

#### 5.4. Build Packer template
```sh
packer build container.json
```

chạy có thể bị lỗi `TLS handshake timeout` thì chạy lại là được (ảnh)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/packer-build-docker-error-tls-hanshake.jpg)

chạy OK sẽ thấy toàn màu xanh và khi gõ "docker images" sẽ thấy images dc tạo ra (ảnh)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/packer-build-docker-img.jpg)

Done!