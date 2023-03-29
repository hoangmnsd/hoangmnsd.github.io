---
title: "Simple Demo: Data transfer between Raspberry Pi and AWS IoT Core"
date: 2022-04-11T14:13:16+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [RaspberryPi,AWS,IoT]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "1 demo giúp mình hiểu về cách sử dụng đơn giản AWS IoT"
---

# 1. Cách làm

## 1.1. Trên AWS IoT Core, tạo things 

Go to `Manage -> Thing -> Create single thing`  

Note to select `Auto-generate a new certificate (Recommended)`  

Download all 5 files (Certificate and Key)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iot-thing-download-key-cert.jpg)

Đổi tên các file đó cho dễ nhớ, rồi dùng WinSCP để transfer 5 file đó lên RPi của bạn

## 1.2. Trên AWS IoT Core, tạo policy

Goto `Secure ->  Policies -> Create Policy`  

điền như hình sau:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iot-thing-create-policy.jpg)

## 1.3. Trên AWS IoT Core, chọn: Secure -> Certificates

Bạn sẽ thấy đã có sẵn 1 certificate như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iot-thing-cert-on-aws.jpg)
Nó được tạo cùng lúc với `Thing` mà bạn đã tạo

- Attach policy vừa tạo:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iot-thing-cert-attach-policy.jpg)

- Attach thing vừa tạo:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iot-thing-cert-attach-things.jpg)

## 1.4. Trên AWS Cognito, tạo Managed Identity Pool  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iot-thing-create-cognito-id-pool.jpg)

Khi tạo identity pool chú ý `Enable access to unauthenticated identities`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iot-thing-create-cognito-id-pool-enable-unauthen.jpg)

# 2. Test 

## 2.1. Test Sucscribe topic

SSH vào RPi, tạo file `demo-data-transfer.py` với content như sau:  
```python
import time
from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient
'''
sudo apt-get update
sudo apt-get install python3-pip
pip install AWSIoTPythonSDK
'''
def helloworld (self, params, packet):
    print("Received msg from AWS IOT Core")
    print("Topic: "+ packet.topic)
    print("Payload: ", (packet.payload))

myMQTTClient = AWSIoTMQTTClient("YOUR_THING_NAME") #random key, if another connection using the same key is opened the previous one is auto closed by AWS IOT
myMQTTClient.configureEndpoint("YOUR_THING_ARN_ENDPOINT", 8883)

myMQTTClient.configureCredentials("/home/pi/awsiot/AmazonRootCA1.pem", "/home/pi/awsiot/YOUR_THING_NAME-private.pem.key", "/home/pi/awsiot/YOUR_THING_NAME-certificate.pem.crt")

myMQTTClient.configureOfflinePublishQueueing(-1) # Infinite offline Publish queueing
myMQTTClient.configureDrainingFrequency(2) # Draining: 2 Hz
myMQTTClient.configureConnectDisconnectTimeout(10) # 10 sec
myMQTTClient.configureMQTTOperationTimeout(5) # 5 sec
print ('Initiating Realtime Data Transfer From Raspberry Pi...')
myMQTTClient.connect()
myMQTTClient.subscribe("home/helloworld",1,helloworld)

while True:
    time.sleep(5)

# print("Publish message to AWS IoT Core")
# myMQTTClient.publish(
#     topic="home/helloworld2",
#     QoS=1,
#     payload="{'Message': 'Message by MyRPi'}"
# )

```
Sửa `YOUR_THING_NAME` thành tên của thing mà bạn đã tạo trên AWS IoT Core.  
Sửa `YOUR_THING_ARN_ENDPOINT` bằng cách vào đây để lấy arn endpoint tương ứng với things:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iot-thing-arn-endpoint.jpg)

Sửa line này: 
```sh
myMQTTClient.configureCredentials("/home/pi/awsiot/AmazonRootCA1.pem", "/home/pi/awsiot/YOUR_THING_NAME-private.pem.key", "/home/pi/awsiot/YOUR_THING_NAME-certificate.pem.crt")
``` 
thành các đường dẫn chính xác đến các file Key của bạn 

Sau khi đã sửa xong. Run các command sau để download các module cần thiết: 
```s
sudo apt-get update
sudo apt-get install python3-pip
pip install AWSIoTPythonSDK
```

Run code để test thôi:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iot-thing-waiting-for-received-msg.jpg)

Dùng AWS IoT Core để publish message Test:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iot-thing-rpi-received-msg.jpg)  
step 1-5 bạn thực hiện publish 1 message lên topic `home/helloworld`   
step 6 chính là kết quả, RPi vì đang subscribe topic đó nên nó đã nhận được message của bạn và hiển thị ra.  

## 2.2. Test Publish message to topic

vẫn là file code trên, sửa thành như sau:
```python
...
# myMQTTClient.subscribe("home/helloworld",1,helloworld)

# while True:
#    time.sleep(5)

print("Publish message to AWS IoT Core")
myMQTTClient.publish(
    topic="home/helloworld2",
    QoS=1,
    payload="{'Message': 'Message sent by MyRPi'}"
)
```
Vào AWS IoT Core Test, Subscribe topic `home/helloworld2`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iot-thing-aws-iot-core-waiting-for-msg.jpg)

Trên RPi, run code:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iot-thing-rpi-published-msg.jpg)

Gần như ngay lập tức, trên AWS IoT Core, bạn sẽ thấy Message gửi từ RPi:   
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/iot-thing-aws-iot-core-received-msg.jpg)

Về cơ bản thì chỉ có vậy thôi. Cần kết hợp với việc config phần cứng trên RPi, cảm biến các thứ nữa.


# REFERENCES  
https://www.youtube.com/watch?v=kPLafcrng-c  

