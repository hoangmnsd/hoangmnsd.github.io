---
title: "Setup Ansible Dynamic Inventory Aws"
date: 2019-07-02T22:33:24+09:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Ansible]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Khi setup Ansible thì có 2 cách, 1 là dùng `Static inventory`, 2 là `Dynamic inventory`"
---
Khi setup Ansible thì có 2 cách, 1 là dùng "Static inventory", 2 là "Dynamic inventory"

Trên AWS thì nên sử dụng `cách 2`, đây là best practice của Ansible.

Bài này sẽ tập trung nói về `cách 2`, phần cuối sẽ nói về `cách 1` (Cách 1 setup sẽ dễ hơn nhiều)

## Yêu cầu
Giả định là bạn đã có 1 tài khoản AWS rồi, có thể tạo được EC2

Có base kiến thức cơ bản về AWS, biết cách SSH vào EC2

## Cách làm
### 1. Tạo bộ key cho Ansible

Vào AWS IAM tạo user "ansible" (hoặc bất cứ tên gì) cấp policy phù hợp (ví dụ chọn AdministratorAccess).

Vào tab Security cedentials tạo Key cho User đó.

Copy bộ access key id và sceret access key ra để sau này dùng.
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iam-ansible-user.jpg)

Launch 2 Amazon Linux EC2 cùng mở port 22, 1 EC2 là `ansible-master`, 1 EC2 là `ansible-client`.

2 con EC2 này cùng sử dụng 1 file key pem (giả sử đặt tên là `key.pem`).

SSH vào con `ansible-master` làm tất cả các step dưới:

### 2. Install Ansible

```sh
sudo pip install ansible
sudo pip install boto
```

### 3. Setup AWS Dynamic Inventory

#### 3.a. Export AWS KEY
Sử dụng 2 cái key đã chuẩn bị ở step 1:
```sh
export AWS_ACCESS_KEY_ID='AKIA3RRRRRRRVPGEZ6'
export AWS_SECRET_ACCESS_KEY='ICUZP9+++++++++++++++++1USvtY/FSJt9'
```

#### 3.b. Tạo folder và download 2 file cần thiết `ec2.py` và `ec2.ini` về:
```sh
sudo mkdir /etc/ansible
cd /etc/ansible
sudo wget https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/ec2.py
sudo wget https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/ec2.ini
sudo chmod +x ec2.py
```
#### 3.c. Edit file `ec2.ini` cho phù hợp:
Ở đây cần sửa phần regions và regions_exclude:
```sh
sudo nano ec2.ini
```
Tìm đến 2 dòng sau và sửa regions = us-east-1 và comment out cái dòng regions_exclude:
```
regions = us-east-1
#regions_exclude = us-gov-west-1
```
`Ctr+X` rồi `Yes-Enter` để save file

#### 3.d. Setup `ansible.cfg`:
```sh
cd /etc/ansible
sudo nano ansible.cfg
```
Thêm dòng sau vào:
```
[defaults]
inventory = /etc/ansible/ec2.py
```
`Ctr+X` rồi `Yes-Enter` để save file

#### 3.e. Copy file key pem vào con `ansible-master`:
```sh
cd  ~/.ssh/
nano key.pem
```
Paste vào đây nội dung trong file key pem mà mình dùng để SSH vào chính con EC2 này

`Ctr+X` rồi `Yes-Enter` để save file

Change permission cho file `key.pem`:
```sh
cd  ~/.ssh/
chmod 600 key.pem
```

#### 3.f. Test connection giữa 2 con EC2:
Từ con master SSH đến con client xem đã dùng đúng file key pem chưa:
```sh
ssh -i  key.pem  ec2-user@`private-ip-của-ansible-client`
```
Nếu connect thành công nghĩa là đã dùng đúng file `key.pem`.

#### 3.g. Test ansible connection bằng file key pem đó:
exit khỏi terminal, SSH vào `ansible-master`:  
```sh
ansible --private-key ~/.ssh/key.pem --user=ec2-user -m ping all
```
Nếu ping thành công sẽ hiện như sau:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/ansible-ping-1.jpg)

Có thể xảy ra khả năng `Unreachable` với chính nó, nhưng ko sao làm tiếp.

#### 3.h. Để ko phải lần nào cũng chỉ định private-key trong command?
Thế thì sửa file `~/.ssh/config` như sau:
```sh
nano ~/.ssh/config
```
Sửa nội dung file config như sau:
```
IdentityFile ~/.ssh/key.pem
User ec2-user
StrictHostKeyChecking no
PasswordAuthentication no
```
`Ctr+X` rồi `Yes-Enter` để save file

Change permission cho file `~/.ssh/config`:
```sh
chmod 600 ~/.ssh/config
```

#### 3.i. Test ansible connection lại lần nữa ko cần chỉ định `private-key`:
```sh
ansible -m ping all
```
Nếu ping thành công sẽ hiện như sau:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/ansible-ping-2.jpg)

#### 3.j. Test thử chạy lệnh `df -h` và check version của bash trên 2 server master và client:
```sh
ansible all -a "df -h"
ansible all -a "bash --version"
```
Done `cách 2`!

### 4. Setup AWS Static Inventory
Cách này cần yêu cầu như sau:

Launch 2 Amazon Linux EC2 cùng mở port 22, 1 EC2 là `ansible-master`, 1 EC2 là `ansible-client`.

2 con EC2 này cùng sử dụng 1 file key pem (giả sử đặt tên là `key.pem`).

SSH vào con `ansible-master` làm các step dưới:

#### 4.a. Install Ansible
```sh
sudo pip install ansible
sudo pip install boto
```

#### 4.b. Tạo folder /etc/ansible và Sửa file hosts
```sh
sudo mkdir /etc/ansible
cd /etc/ansible
sudo nano hosts
```
Điền pirvate IP của con `ansible-client` và `ansible-master` vào:
```
[client]
172.31.27.78
[master]
172.31.29.91
```
`Ctr+X` rồi `Yes-Enter` để save file.

Ở trên vì muốn ansible connect được đến chính nó nên mình thêm ip của master vào file hosts.

Cũng có thể dùng `public ip` nhưng nên dùng `private ip` để nó ko bị thay đổi.

#### 4.c. Generate key
```sh
ssh-keygen -t rsa
cd ~/.ssh
cat id_rsa.pub
```
Copy nội dung file `id_rsa.pub` để chuẩn bị cho bước sau.

#### 4.d. SSH vào `ansible-client` để add key vừa được generate
SSH vào con EC2 `ansible-client`, sửa file `~/.ssh/authorized_keys`:
```sh
cd ~/.ssh
ll -lsa
nano authorized_keys
```
Paste nội dung file `id_rsa.pub` của `ansible-master` mà mình đã copy ở bước `4.c`.

Chú ý là tạo thêm 1 dòng nữa chứ đừng xóa cái key cũ trong file `authorized_keys` đi.

`Ctr+X` rồi `Yes-Enter` để save file.

#### 4.e. SSH vào `ansible-master`để test Ansible connection
Giờ đã có thể ping client từ master rồi
SSH vào `ansible master`:
```sh
ansible -m ping all
```
Hiện màu xanh lè không có lỗi `UNREACHABLE` là OK rồi

Done `cách 1`! 