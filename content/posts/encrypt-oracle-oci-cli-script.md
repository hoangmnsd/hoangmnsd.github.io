---
title: "Oracle Cloud Infrastructure CLI scripts"
date: 2023-01-20T23:09:57+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [OracleCloud]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Sử dụng oci-cli để automate 1 số tác vụ trên Oracle Cloud Console"
---

# Story

Gần đây sau khi tạo account Oracle mới (region Singapore), mình gặp khó khăn khi ko thể tạo VM được vì lỗi: `Error: 500-InternalError, Out of host capacity.`

Mỗi region chỉ có 1 số lượng có hạn các VM CPU và RAM thôi, nên nếu ai hên thì mới tạo được VM. Nếu cứ lúc nào nghĩ đến mới vào tạo thì sẽ chẳng bao giờ cạnh tranh được.

Cần phải scripting và auto create VM thôi. 1 Bash shell script sử dụng `oci-cli` là đủ.

# 1. oci-cli

Install oci-cli theo [guideline](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/climanualinst.htm)

```sh
sudo apt update
sudo apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev
sudo apt update && sudo apt install python3 python3-pip python3-venv
python3 -m pip install oci-cli
```

```
$ oci --version
3.24.0
```

# 2. Config credential

Tham khảo bài này:
https://archive.ph/OjSqw#selection-755.0-755.27

Tạo API Key:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-cloud-api-key.jpg)

Download Private key, public key (optional), ấn Add:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-cloud-api-key-dl-key.jpg)

Hiện ra 1 bảng hướng dẫn setup config file:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-cloud-api-key-config-file.jpg)

Sau đó, trên local của mình (Rasbperry Pi), tạo file `~/.oci/config`, paste nội dung bên trên vào:  
Chú ý chỗ bôi vàng trỏ tới đường dẫn chứa Private Key vừa download về nhé

```sh
mkdir ~/.oci
nano ~/.oci/config
```

Set permission cho credential:

```sh
oci setup repair-file-permissions --file ~/.oci/config

oci setup repair-file-permissions --file <PRIVATE_KEY>.pem
```

Test API Key, nhớ tìm user_id của bạn để thay vào nhé:

```sh
export user_id="ocid1.user.oc1..xyz"
oci --config-file ~/.oci/config iam user get --user-id $user_id
```

Trả về 1 chuỗi JSON ko có lỗi là OK

Việc tạo API Key trên Oracle như này mình thấy hơi kém:
- Key ko có set thời gian expire.
- Key ko được set quyền để hạn chế việc sử dụng các resource khác.
- Sử dụng Key khá cồng kềnh, phải tạo cả `~/.oci/config` file, trong đó trỏ đến 1 file private key PEM 😫.


# 3. Lên Oracle Console tạo Stack

Tạo VM như bình thường, sau đó chọn "Save as stack":  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-cloud-create-vm-save-stack.jpg)

Stack này được back bởi Terraform:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-cloud-create-vm-create-stack.jpg)

Như vậy sau này mỗi lần vào Console chỉ cần vào Stack (resource manager) rồi ấn Apply là sẽ tự run code để tạo VM thôi:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-cloud-create-vm-stack-detail.jpg)

Giờ tìm cách để Run Apply Stack bằng oci-cli là ok

# 4. Viết script để apply Stack bằng oci-cli

Format command lấy từ nguồn official [này](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/create-job.htm )

```
oci resource-manager job create-apply-job --execution-plan-strategy AUTO_APPROVED --stack-id <stack_ocid>
```

script `create-vm-oracle-sg.sh`:  

```sh
#!/bin/bash

# Crontab every 2 minutes usage, run crontab -e:
# */2 * * * * bash PATH_TO_THIS_SCRIPT.sh >> PATH_TO_LOG.log

# Prepare YOUR OWN variable
stack_ocid_1cpu="ocid1.ormstack.oc1.ap-singapore-1.XXX"
compartment_id="ocid1.tenancy.oc1..YYY"
TELEGRAM_API_TOKEN="123456789:ZZZ"
TELEGRAM_CHAT_ID="123123123"
MSG_SENT_PATH="/opt/devops/oracle-rm-lab/MSG_SENT"
MSG_SENT=$(cat $MSG_SENT_PATH)
oci="/home/pi/.local/bin/oci --config-file /home/pi/.oci/config-sg"

# Print Date
datetime=$(date '+%Y%m%d-%H%M%S');
echo "==============="
echo "==============="
echo "DATE: $datetime"
echo "MSG_SENT: $MSG_SENT"
echo "oci version: "
$oci --version

# Get Instance List
INSTANCE_LIST=$($oci compute instance list --compartment-id $compartment_id)

# if instace list has value, it mean the vm has been created, notify via telegram
if [ ! -z ${INSTANCE_LIST} ];
then
  echo "Instance exist"
  # if Telegram has not been sent, sent it
  if [ $MSG_SENT == 'FALSE' ];
  then
    MESSAGE="Your OC VM has been created, check it out!"
    curl -s -X POST https://api.telegram.org/bot$TELEGRAM_API_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="$MESSAGE"
    echo "Message just sent"
    echo "TRUE" > $MSG_SENT_PATH
  fi
fi

# if instance list empty
if [ -z ${INSTANCE_LIST} ];
then
  echo "Instance list empty, applying Job 1cpu..."
  APPLY_JOB=$($oci resource-manager job create-apply-job --execution-plan-strategy AUTO_APPROVED --stack-id $stack_ocid_1cpu)
  JOB_ID=$(echo "$APPLY_JOB" | jq -r '.data.id')
  echo $JOB_ID
fi
echo "Done"

```

Giải thích script trên:  
- Các bạn cần tìm trên Console các OCID để điền vào phần `# Prepare YOUR OWN variable`
- Script này check nếu đã có VM rồi thì sẽ gửi message lên Telegram, nếu bạn ko muốn dùng Telegram thì xóa đoạn code đó đi.  


# 5. Edit crontab và test

```
crontab -e
```

Run every 2 minutes and log to file:

```
# */2 * * * * bash PATH_TO_THIS_SCRIPT.sh >> PATH_TO_LOG.log
```

Chờ 2 phút và lên giao diện Console check có job được tạo ra là OK nhé, hầu hết là FAILED như này :))
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-cloud-stack-rm-failed.jpg)

Không biết cách này có work ko, vì đến hiện tại sau 1 ngày run Script liên tục mỗi 2 phút, mình vẫn chưa tạo được VM

Có người nói họ chạy 2 tháng rồi vẫn chưa tạo được VM 😂

Có người nói Nếu bạn upgrade từ Alway Free Tier lên Pay-As-You-Go thì bạn sẽ được ưu tiên nếu tạo VM (Cái này mình ko dám làm)

Nhưng ít nhất thì cơ hội sẽ nhiều hơn là "thi thoảng nhớ ra thì vào Browser tạo" đúng ko?

Chúc các bạn thành công 😁

# 6. Script auto-start VM if Oracle stop it

Gần đây mình nhận được 1 email từ Oracle như này:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-cloud-reclaim-res-free.jpg)

Đại khái họ sẽ "reclaim" idle resource bằng cách stop VM của mình.  

Nếu mình upgrade account Alway Free Tier lên Pay-As-You-Go thì sẽ ko sao.

Có thể đây là chiến dịch để dọn người cũ cho ng mới có cơ hội tạo VM đây :))

Mình nghĩ ngay đến việc sẽ viết 1 script để check 1 phút 1 lần xem VM đã bị stop chưa, nếu stop thì restart nó lại ngay lập tức

Script `start-vm-oracle-london.sh`:  

```sh
#!/bin/bash

# Crontab every 2 minutes usage, run crontab -e:
# */2 * * * * bash PATH_TO_THIS_SCRIPT.sh >> PATH_TO_LOG.log

# Prepare YOUR OWN variable
compartment_id="ocid1.tenancy.oc1..xxx"
instance_id="ocid1.instance.oc1.uk-london-1.yyy"
TELEGRAM_API_TOKEN="1234567890:zzz"
TELEGRAM_CHAT_ID="123123123"
oci="/home/pi/.local/bin/oci --config-file /home/pi/.oci/config-london"

# Print Date
datetime=$(date '+%Y%m%d-%H%M%S');
echo "==============="
echo "==============="
echo "DATE: $datetime"
echo "oci version: "
$oci --version

# Get instance state
INSTANCE_STATE_DETAIL=$($oci compute instance get --instance-id $instance_id)
INSTANCE_STATE=$(echo "$INSTANCE_STATE_DETAIL" | jq -r '.data."lifecycle-state"')
echo $INSTANCE_STATE

# if instance is not running, notify via telegram
if [ $INSTANCE_STATE != 'RUNNING' ];
then
  echo "Instance is not running"
  # send Telegram message
  MESSAGE="Your OC VM is not running, take a look!"
  curl -s -X POST https://api.telegram.org/bot$TELEGRAM_API_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="$MESSAGE"
  echo "Message just sent"
fi

# if instance is stopped, notify via telegram, then start it
if [ $INSTANCE_STATE == 'STOPPED' ];
then
  echo "Instance stopped"
  START_VM=$($oci compute instance action --action START --instance-id $instance_id)
  # send Telegram message
  MESSAGE="Your OC VM has been stopped, I just restarted it, take a look!"
  curl -s -X POST https://api.telegram.org/bot$TELEGRAM_API_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="$MESSAGE"
  echo "Message just sent"
fi

echo "Done"
```

Giải thích script trên:  
- Nếu thấy VM đang runnning, do nothing.  
- Nếu thấy VM đang ko phải runnning, gửi message vào Telegram.  
- Nếu VM đang stopped, start lên, gửi message vào Telegram.  


# CREDIT

https://www.reddit.com/r/oraclecloud/
https://www.reddit.com/r/oraclecloud/comments/11u6t9q/oracle_cloud_out_of_host_capacity_resolving/
https://archive.ph/OjSqw#selection-755.0-755.27
https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/climanualinst.htm
https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/create-job.htm 
https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.24.0/oci_cli_docs/cmdref/compute/instance.html#available-commands
