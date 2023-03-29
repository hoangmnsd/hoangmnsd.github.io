---
title: "Aws Lambda get Current Date Time Wrong"
date: 2019-08-27T17:34:21+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [AWS,Lambda]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Chia sẻ về 1 lỗi khi sử dụng AWS Lambda"
---
# 1. Mô tả
Chia sẻ về 1 lỗi khi sử dụng AWS Lambda:  

Mình dùng Lambda để get current timestamp, lambda này được trigger bởi Cloudwatch cứ 5 giây chạy 1 lần.  

Mình phát hiện ra là lần đầu thì Lambda return kết quả đúng `2019-08-27 08:46:54.867900`.  

Nhưng sau đó 5 giây vào check log trong Cloudwatch thì thấy vẫn trả về timestamp cũ `2019-08-27 08:46:54.867900`.  

Cứ thế, dù 5 10 15 phút sau mình cứ chạy lại là log trả về timestamp cũ.

# 2. Tái hiện lỗi
Tạo 1 funtion lambda `get-current-time` đơn giản như này:
```sh
import datetime, boto3, time, logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

#Get current datetime
currentDT = datetime.now()

def lambda_handler(event, context):
    logger.info("Current datetime: %s" % currentDT)
```
Test function Lambda trên  
Lần đầu trả về đúng timestamp:
```
Current datetime: 2019-08-27 08:46:54.867900
```
Chạy lại khoảng vài giây sau, kết quả không đổi vẫn là:  
```
Current datetime: 2019-08-27 08:46:54.867900
```

# 3. Nguyên nhân
Nguyên nhân là do Lambda đã cache lại giá trị trả về lần đầu 

và bởi hàm Lambda của mình không thay đổi gì, 

cả event trigger cũng ko thay đổi, thế nên Lambda cứ lấy giá trị đã cache được ở lần trước thôi.

# 4. Giải pháp
Mình cần tạo 1 update đối với chính hàm `get-current-time` này, 

để mỗi lần chạy, Lambda sẽ nhận ra là function có sự thay đổi. Khi đó nó sẽ ko lấy giá trị cũ trả về cho mình nữa.

Ở đây mình sẽ update lại phần Description của function `get-current-time`.

Sửa function lambda lại như sau:
```sh
import datetime, boto3, time, logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

#Get current datetime
currentDT = datetime.now()

def lambda_handler(event, context):
    logger.info("Current datetime: %s" % currentDT)
    client = boto3.client('lambda')
    client.update_function_configuration(
        FunctionName="get-current-time",
        Description="lambda run at [%s]" % currentDT
    )
```
Nhớ Role của Lambda function cần có quyền sau:
`lambda:UpdateFunctionConfiguration`

Test lại function trên:
```
Current datetime: 2019-08-27 13:58:52.281869
```

Test lại vài lần:
```
Current datetime: 2019-08-27 13:59:21.350455
```

Done!