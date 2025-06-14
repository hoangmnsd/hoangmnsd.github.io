---
title: "Lambda + API Gateway, Telegram Bot and Serverless Webapp"
date: 2021-03-10T00:43:59+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Telegram,Lambda,AWS,Ajax,Jquery]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Phần 1 mình sẽ nói về cách để tạo 1 Serverless Telegram bot dùng Lambda + API Gateway. Phần 2 mình sẽ nói về cách để trigger Lambda từ 1 Web Browser host trên S3 bucket dùng Ajax Jquery (cũng cần có API Gateway)"
---

Phần 1 mình sẽ nói về cách để tạo 1 Serverless Telegram bot dùng Lambda + API Gateway

Phần 2 mình sẽ nói về cách để trigger Lambda từ 1 Web Browser host trên S3 bucket dùng Ajax Jquery (cũng cần có API Gateway)

# 1. Sererless Telegram Bot using Lambda + API Gateway

## 1.1. Tạo Bot bằng cách chat với @BotFather

Đăng nhập vào Telegram, tìm @BotFather và chat với nó để tạo bot của bạn.
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/telegram_botfather.jpg)

Bạn sẽ được nó nhắn cho 1 TELEGRAM TOKEN, hãy keep secure token đó nhé.  
Giả sử token mà nó gửi cho bạn là `1123123303:AAF4Kz3kTxxxxxxxxxxxxxxxxxxxFcGRs`

## 1.2. Create Lambda function

Tạo 1 hàm Lambda trong AWS của bạn (chú ý chọn Runtime là **Python 3.7** trở lên) 

```sh
'''
Please config Environment variable: TELEGRAM_TOKEN
From Python 3.7 it supports `requests` package already, you should use it as the Runtime
'''

import json
import os
import sys

here = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(here, "./vendored"))

import requests

TOKEN = os.environ.get('TELEGRAM_TOKEN')
BASE_URL = "https://api.telegram.org/bot{}".format(TOKEN)


def lambda_handler(event, context):
    try:
        print(event)
        data = json.loads(event["body"])
        message = str(data["message"]["text"])
        chat_id = data["message"]["chat"]["id"]
        first_name = data["message"]["chat"]["first_name"]
        
        response = "Please /start, {}".format(first_name)

        if "start" in message:
            response = "Hello {}".format(first_name)

        data = {"text": response.encode("utf8"), "chat_id": chat_id}
        url = BASE_URL + "/sendMessage"
        requests.post(url, data)

    except Exception as e:
        print(e)

    return {"statusCode": 200}
```
Chú ý trong đoạn code trên refer đến biến môi trường `TELEGRAM_TOKEN`,  
hãy config TOKEN mà bạn nhận được ở bước 1.1 vào biến `TELEGRAM_TOKEN` này.  

Rồi deploy Lambda này là ok xong bước này.

## 1.3. Tạo API Gateway 

Vào API Gateway tạo 1 API gateway của bạn, hãy chọn HTTP protocol vì nó sẽ rẻ hơn so với REST Protocol  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-http-protocol1.jpg)

Phần Route mình tạo 1 route /sendMsg với method POST:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-http-protocol1-route.jpg)

Phần Integration chọn chính function Lambda mà bạn đã tạo ở trên:   
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-http-protocol1-integration.jpg)

Phần CORS hãy config như sau:   
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-http-protocol1-cors.jpg)

Chúng ta được `invoke URL` của Route /sendMsg có dạng kiểu như này:  

`https://23s2cdzxtrd.execute-api.us-east-1.amazonaws.com/dev/sendMsg`

## 1.4. Connect API Gateway to Telegram Bot

Giờ cần làm sao để Telegram Bot bạn vừa tạo hiểu được là nó cần gửi request đến Backend ở đâu.

Hãy dùng POSTMAN gửi `invoke URL` (nhận được ở bước `1.3.`) đến `https://api.telegram.org/bot<Your Telegram TOKEN>/setWebhook` nhé:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/telegram_bot_connect_apigw.jpg)

kết quả trả về ok = true, Webhook was set là đã thành công!

Check confirm:  
- Gửi GET request đến: `https://api.telegram.org/bot<Your Telegram TOKEN>/getWebhookInfo` (làm theo tài liệu trong link này: https://core.telegram.org/bots/api#getwebhookinfo)

## 1.5. Test

Giờ hãy thử chat với con Bot của bạn để xem nó run các Login code trong Lambda như thế nào nhé:

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/telegram_bot_chatlog.jpg)

Con bot này tương tác ngay lập tức sau mỗi command của bạn, đây là điểm hay.

# 2. Trigger Lambda from Web browser using Ajax JQuery

Giả sử bạn có 1 website mà static được host trên S3. Bạn muốn có 1 page mà user sẽ nhập vào thông tin và ấn 1 nút, từ đó trigger hàm lambda của bạn.  
Đây chính là 1 process basic về Serverless web app.

## 2.1. Create Lambda function

Tạo 1 hàm Lambda trong AWS của bạn (chú ý chọn Runtime là **Python 3.7** trở lên), ví dụ ở đây mình tạo function tên là `invoked-by-ajax-jquery`
```sh
import json

def lambda_handler(event, context):
    # TODO implement
    data = json.loads(event["body"])
    name = str(data["name"])
    print("Input name: " + name)
    return {
        'statusCode': 200,
        'body': json.dumps("Hello " + name + " from Lambda!")
    }
```

## 2.2. Create Route in API Gateway

Ở đây API Gateway của mình vẫn dùng HTTP protocol nhé (để cho rẻ)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-http-protocol1.jpg)

Tạo 1 Route tên là `/invokedByAjaxJq` sử dụng Method POST:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-http-protocol1-route2.jpg)

Method POST đó sẽ integrate với hàm Lambda mà mình đã tạo ra ở bước `2.1`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-http-protocol1-integration2.jpg)

CORS vẫn thế ko đổi gì, nhưng để cho secure hơn thì sau này nên sửa lại Origin nha
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-http-protocol1-cors.jpg)

Chúng ta được `invoke URL` của Route /sendMsg có dạng kiểu như này:  

`https://23s2cdzxtrd.execute-api.us-east-1.amazonaws.com/dev/invokedByAjaxJq`

## 2.3. Create S3 bucket for hosting

Hãy tạo 1 S3 bucket với config như sau ở tab `Permission`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/s3bucket-webhosting-permission-tab1.jpg)

Phần `Bucket policy` cần edit bằng đoạn JSON code như sau:  
```sh
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "AllowPublicRead",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::htmljsajaxjqlambda/*"
        },
        {
            "Sid": "AllowPublicList",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::htmljsajaxjqlambda"
        }
    ]
}
```
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/s3bucket-webhosting-permission-tab1-policy.jpg)

Phần Access Control List cần allow quyền LIST và READ cho All User như sau:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/s3bucket-webhosting-permission-tab1-acl.jpg)

Note: Phần CORS ko cần đụng đến nhé

Quay lại tab `Properties`, enable Website static hosting lên:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/s3bucket-webhosting-prop-tab1.jpg)
  
Bạn đã có được 1 URL đến website như sau:  
`http://htmljsajaxjqlambda.s3-website-us-east-1.amazonaws.com`

Nhưng vì S3 bucket của bạn chưa có file nên cần phải tạo và upload lên đã: 

file đầu tiên là `index.html`:  
```html

<head>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js"></script>
<script src="./js/my.js"></script>
<link rel="shortcut icon" href="#">
</head>
<form id="contact-form" method="post">
      <h4>Name:</h4>
      <input type="text" style="height:35px;" id="name-input" placeholder="Enter name here" class="form-control" style="width:100%;" /><br/>
      <div class="g-recaptcha" data-sitekey="6Lc7cVMUAAAAAM1yxf64wrmO8gvi8A1oQ_ead1ys" class="form-control" style="width:100%;"></div>
      <button type="button" onClick="submitToAPI(event)" class="btn btn-lg" style="margin-top:20px;">Submit</button>
</form>

```
file thứ 2 là `my.js` trong folder js, chú ý sửa phần tử `url` bằng link invoke URL mà bạn đã tạo ra ở bước `2.2` :  
```js
function submitToAPI(e) {
 e.preventDefault();

      var Namere = /[A-Za-z]{1}[A-Za-z]/;
      if (!Namere.test($("#name-input").val())) {
                   alert ("Name can not less than 2 char");
          return;
      }


 var name = $("#name-input").val();

 var data = {
    name : name,
  };

 $.ajax({
   type: "POST",
   url : "https://23s2cdzxtrd.execute-api.us-east-1.amazonaws.com/dev/invokedByAjaxJq",
   dataType: "json",
   crossDomain: "true",
   contentType: "application/json; charset=utf-8",
   data: JSON.stringify(data),
   
   success: function (response) {
     // clear form and show a success message
     console.log("Response: "+ response);
     alert("Success");
     document.getElementById("contact-form").reset();
 location.reload();
   },
   error: function () {
     // show an error message
     alert("Failed");
   }});
}
```

Upload lên S3:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/s3bucket-webhosting-obj.jpg)

## 2.4. Test

Giờ truy cập URL S3 static web hosting, và ấn F12 để xem log nhé:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/s3bucket-webhosting-live1.jpg)

Thử nhập tên vào và ấn `Submit`.  
Bạn sẽ thấy popup Success hiện ra như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/s3bucket-webhosting-live2.jpg)

Nhìn xuống dưới phần Console bạn sẽ thấy Message `Response: Hello Park Ji Sung from Lambda!`

Điều này có nghĩa Lambda function của bạn đã chạy thành công và trả về kết quả cho Client. 🎉

Chúc bạn thành công! 😁


# CREDIT

https://hackernoon.com/serverless-telegram-bot-on-aws-lambda-851204d4236c  
https://aws.amazon.com/blogs/architecture/create-dynamic-contact-forms-for-s3-static-websites-using-aws-lambda-amazon-api-gateway-and-amazon-ses/  

