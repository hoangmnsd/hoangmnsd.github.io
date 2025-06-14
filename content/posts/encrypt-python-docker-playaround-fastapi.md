---
title: "Playaround with FastAPI Github Actions and Lambda"
date: 2023-06-10T14:32:58+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [AWS,FastAPI,GithubActions]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "FastAPI python app with GitHub Actions for CICD, also able to deploy to AWS Lambda"
---

Gần đây mình đi tìm job mới, được 1 ông người Hàn bên Mỹ thi phải cho 1 bài test coding. 

Thì mình cũng làm thôi, nhưng qua quá trình làm và suy nghĩ thì mình thấy trước giờ mình chưa làm 1 project như vậy bao giờ.

Tất nhiên là cuối cùng vẫn tạch job đó, nhưng có mấy cái nên note lại.

# 1. Requirements

Đề bài là: 

- Backend cho 1 app diagram như Canva
- Tự design data structures, objects, properties, functions/methods
- App đó có thể có nhiều shape khác nhau, tròn vuông chữ nhật...
- User có thể drag/drop để create/move/resize/delete shape.
- User có thể vẽ connection từ shape này đến shape khác.
- User có thể multi select shapes, bằng cách rê chuột thành hình chữ nhật để chọn các shapes.
- Sau đó User có thể move/resize/delete group các shape vừa chọn bằng cách trên.  
- Không yêu cầu có Database, làm trên memory là đủ.
- Mục đích là test skills in software design and implementation, encapsulation, extensibility, data structures, basic algorithms.
- Cần viết Unit test.
- Build CICD pipeline trên Github Workflow để tự động chạy Unit test và có report.  

# 2. Stacks

Mình chọn:  

- Vì đề bài chỉ yêu cầu code Backend. Nên mình chọn FastAPI của Python để làm. Vì đọc nhiều thấy gần đây FastAPI nổi lên được nhiều ng ưa chuộng.  
- Mình muốn App này có thể run Local để dev nhanh chóng, Run trên Docker được để dễ deploy và CICD...
- Project này sẽ làm template để sau này mình phát triển các app khác phức tạp hơn.   

- Ngoài ra, mình còn muốn dễ dàng deploy lên AWS Lambda nữa. -> Cái này ko chắc có thể làm được song song cùng các cái bên trên ko? - PENDING

Ngắn ngủi vài ngày nhưng có nhiều thứ phải tìm phết. May mà google ra 1 github repo có sẵn hầu hết:  
https://github.com/alehpineda/fastapi_test

Mình sẽ sửa lại CICD Workflow 1 chút để phù hợp:   
1 - Flake8 - Check code quality  
2 - Pytest - Run unit tests  
3 - Py Charm Security checks  
4 - Build Docker Image and push to Hub  

Đụng đến coding là cần phải chọn 1 cái tool để nó gen ra 1 folder structure theo best practice cho mình, nên mình chọn [manage-fastapi](https://github.com/ycd/manage-fastapi)

Python version: 3.9 -> vì mình thấy hầu hết mọi người hiện tại đang dùng version này.

```
$ pip install manage-fastapi

$ fastapi startproject fastapi-github-cicd
FastAPI project created successfully! 🎉

$ tree
fastapi-github-cicd/
├── README.md
├── app
│   ├── __init__.py
│   ├── core
│   │   ├── __init__.py
│   │   └── config.py
│   └── main.py
├── requirements.txt
└── tests
    ├── __init__.py

```

Cấu trúc này rất hay, nhưng lại phức tạp đối với mình, nên mình xóa hết các phần phức tạp đi, giữ lại thế này thôi:  

```
fastapi-github-cicd/
├── Dockerfile
├── README.md
├── app
│   ├── __init__.py
│   └── main.py
├── requirements.txt
└── tests
    ├── __init__.py
    └── test_main.py

```
# 3. Code demo with Github Actions

Xem code đầy đủ tại đây: https://github.com/hoangmnsd/fastapi-github-cicd

Vào phần Action -> Sẽ thấy Code đã pass qua được gần hết step:

Code Quality -> Unit Testing -> Security Check -> dừng lại ở Build Image push lên Dockerhub thôi. Cái này do mình chưa setting Docker Hub Token thôi.  

Tiếp theo sẽ tìm cách để Deploy được lên AWS Lambda.

# 4. Deploy to Lambda

IAM -> Create an User `gh_action_deployment` with Customer inline policy:  
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "iam:ListRoles",
        "lambda:*"
      ],
      "Resource": [
        "arn:aws:lambda:<AWS_REGION>:<AWS_ACCOUNT_ID>:function:<lambda_function_name>",
        "arn:aws:lambda:<AWS_REGION>:<AWS_ACCOUNT_ID>:layer:<lambda_layer_name>",
        "arn:aws:lambda:<AWS_REGION>:<AWS_ACCOUNT_ID>:layer:<lambda_layer_name>:*"
      ]
    }
  ]
}
```

Từ user trên -> tạo CLI key `AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY` (Key này được sử dụng khi Github Action chạy sẽ dùng)

AWS IAM -> create a new Role `lambda_fastapi_gh_action` với customer inline policy:  

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "lambda:UpdateFunctionConfiguration",
                "logs:CreateLogGroup",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
```

AWS Lambda -> Create 1 new layer `fastapi-gh-action-layer`. Layer version cần bạn upload 1 file zip lên, cứ upload bừa 1 cái. Quan trọng là chúng ta có được ARN của Layer thôi.  

AWS Lambda -> Create 1 new function `fastapi-github-cicd`, attach role vừa tạo ở trên (Role này được sử dụng để khi Lambda chạy sẽ dùng).  
Không cân attach layer vào nhé, vì sau khi chạy Pipeline thì layer sẽ được add vào function.  

Trong CICD workflow của project sử dụng Github Action sau:  

```yml
name: CI/CD

on: 
  push:
    branches: [master] 

jobs:

  aws_lambda_deploy:
    name: Deploy to AWS Lambda
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Deploy code to Lambda
      uses: duoi/py-lambda-action@1.0.9
      with:
        lambda_layer_arn: 'arn:aws:lambda:<AWS_REGION>:<AWS_ACCOUNT_ID>:layer:<lambda_layer_name>'
        lambda_function_name: 'fastapi-github-cicd'
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_DEFAULT_REGION: 'us-east-1' 

```

Chú ý `duoi/py-lambda-action@1.0.9` không phải là 1 action phổ biến, nên tự làm action thì hơn

Sau khi push code lên thấy Lambda function của bạn sẽ tự động được attach cái layer mới vào.

Lambda function -> kéo xuống Runtime settings -> Edit, Sửa Handler `lambda_function.lambda_handler` thành `app.main.handler`

Sau đó thử test event của Lambda: Configure Test event -> name: `getShape1`. Template chọn `API Gateway AWS Proxy`. Sửa event thành như này:  

```json
{
  "body": "eyJ0ZXN0IjoiYm9keSJ9",
  "resource": "/{proxy+}",
  "path": "/shapes/1",
  "httpMethod": "GET",
  "isBase64Encoded": true,

  "pathParameters": {
    "proxy": "/path/to/resource"
  },
  "stageVariables": {
    "baz": "qux"
  },
...
}
```

Rồi test, vì chưa có data nên nếu trả về 404 Not Found là OK

Cần test cả trường hợp POST request xem thế nào đã.

```json
{
  "body": "{\"type\": \"circle\",\"position\": {\"x\": 1,\"y\": 1},\"size\": {\"width\": 10,\"height\": 10}}",
  "resource": "/{proxy+}",
  "path": "/shapes",
  "httpMethod": "POST",
  "isBase64Encoded": true,

  "pathParameters": {
    "proxy": "/path/to/resource"
  },
  "stageVariables": {
    "baz": "qux"
  },
...
}

...

Sau đó tích hợp với API Gateway để test. Pending vì đã có bug mình chưa có thời gian troubleshoot... 


```


# CREDIT

Course about FastAPI:  
https://www.fastapitutorial.com/blog/fastapi-course/  

https://www.pythoncentral.io/fastapi-tutorial-for-beginners-the-resources-you-need/   
https://www.youtube.com/watch?v=qQNGw_m8t0Y&t=178s   

This is a playground to test CI/CD tools such as Jenkins, Sonar, Docker, Jfrog Artifactory and kubernetes:  
https://github.com/kaisbettaieb/fastapi-examle   

https://github.com/apryor6/fastapi_example   

Tutorial for FastAPI deploy to Azure with GithubAction:   
https://towardsdatascience.com/deploy-fastapi-on-azure-with-github-actions-32c5ab248ce3   

Test fastapi and Docker CI/CD using actions:  
https://github.com/alehpineda/fastapi_test  

The solution was to manually build SQLite:  
https://stackoverflow.com/questions/72165451/pytest-is-failing-on-github-actions-but-succeeds-locally?rq=4  

FastAPI with AWS Lambda and AWS SAM:  
https://www.eliasbrange.dev/posts/deploy-fastapi-on-aws-part-1-lambda-api-gateway/  

Example of AWS SAM and Python and AWS Lambda, with 3 envs Dev,Stage,Prod:  
Cái này khá hay để làm theo tuy nhiên mình chưa thấy làm cho trường hợp test trên local??. Nếu làm lại mình sẽ thêm phần run local trên Docker, hoặc chuyển sang dùng Serverless Framework (thay thế cho AWS SAM), vì nghe nói Serverless có thể run Lambda trên local được. Mà nghe nói AWS SAM cũng có thể run Lambda trên local nhưng cần cài thêm gì đó:  
https://www.eliasbrange.dev/posts/aws-sam-template/  
https://github.com/eliasbrange/aws-sam-template  

Simple FastAPI with Lambda:  
https://www.deadbear.io/simple-serverless-fastapi-with-aws-lambda/  

1 Bài khá chi tiết có mô tả về cách config API Gateway và cả Authorization nữa:  
https://guillaume-martin.github.io/deploy-fastapi-on-aws-lambda.html  

1 Tutorial dùng với serverless framework:  
https://ademoverflow.com/blog/tutorial-fastapi-aws-lambda-serverless/  

