---
title: "Integrate Telegram Bot With ChatGPT"
date: 2023-02-16T23:37:13+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Telegram,ChatGPT]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Tạo 1 Telegram bot sử dụng API của ChatGPT"
---


# 1. Run trên máy local

mình sẽ sử dụng repo này: https://github.com/acheong08/ChatGPT

Mình sẽ cần install python3 trước

```sh
python -m pip install --upgrade pip
pip3 install --upgrade revChatGPT
```

Get API Key: https://platform.openai.com/account/api-keys  
(Bước này vì mình đã mua 1 account ChatGPT 250k có sẵn 18$ credit rồi nên lấy API key khá dễ)

API Key có dạng: `sk-xxx`

file `basic-sample.py`:  

```
from revChatGPT.V3 import Chatbot
chatbot = Chatbot(api_key="sk-xxx")
response = chatbot.ask("Hello")
print("ChatGPT: " + response)
```

Run: `python3 basic-sample.py`, ChatGPT sẽ in ra câu trả lời.

# 2. Run on AWS Lambda

1 số thứ cần chuẩn bị mà mình sẽ bỏ qua vì đã viết nhiều rồi:  
- Setup AWS API Gateway.  
- Setup để lấy Telegram token của bot.  

## 2.1. Package Lambda layer `revChatGPT`

Mình chọn python3.9 vì trên AWS Lambda hầu hết các function của mình đang dùng python3.9

Dưới máy local đang là python3.6 mặc định:  

```sh
# check default python3 version
$ python3 --version
Python 3.6.9

# check default pip3 version
$ pip3 --version
pip 9.0.1 from /usr/lib/python3/dist-packages (python 3.6)
# => means you are using pip3 from python3.6
```

Mình muốn chuyển sang mặc định python3.9 để package layer:  

```sh
# install python3.9
sudo apt-get update
sudo apt-get upgrade -y

sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.9
sudo apt install python3-pip

# check default python3 version, still python3.6
$ python3 --version
Python 3.6.9

# now, check pip3 version, still pip3 from python3.6
$ pip3 --version
pip 9.0.1 from /usr/lib/python3/dist-packages (python 3.6)
# => understandable

# now install pip3 for python3.9
# https://stackoverflow.com/questions/65644782/how-to-install-pip-for-python-3-9-on-ubuntu-20-04
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo apt install python3.9-distutils
python3.9 get-pip.py

# change default python3 to python3.9
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 2

update-alternatives --config python3
# => select number of python3.9

# check default python3 version
$ python3 --version
Python 3.9.16
# => ok, default python3 is now python3.9

$ pip3 --version
pip 9.0.1 from /usr/lib/python3/dist-packages (python 3.9)
# => OK, default pip3 is from python3.9
```

Có thể sẽ gặp 1 số lỗi khi install package, nên run mấy command này trước, cũng chả mất gì:

```sh
# Some recommend command to fix errors
# https://bobbyhadz.com/blog/python-attributeerror-htmlparser-object-has-no-attribute-unescape
pip install --upgrade setuptools
pip3 install --upgrade setuptools

pip install --upgrade distlib
pip3 install --upgrade distlib

pip3 install --upgrade pip
```

Đinh ninh là dùng python3.9 là kiểu gì cũng ok:  

```sh
# Now install chatGPT to folder layer
mkdir -p ./package/python

# package to zip layer for using on AWS LAMBDA
pip3 install --upgrade --target ./package/python revChatGPT
cd package/
zip -r9 ${OLDPWD}/layer.zip .
```

Cuối cùng upload package khoảng 15MB lên AWS Lambda layer xong run Lambda thì bị lỗi syntax gì đó:

```
{
  "errorMessage": "Syntax error in module 'lambda_function': invalid syntax (lambda_function.py, line 14)",
  "errorType": "Runtime.UserCodeSyntaxError",
  "stackTrace": [
    "  File \"/var/task/lambda_function.py\" Line 14\n    def get_inventory(instanceid)\n"
  ]
}
```

Sau 1 hồi debug thì lỗi ở cái library mà mình import từ layer `revChatGPT`.

Không hiểu vì sao Lambda bị lỗi, sau khi thử đủ các thể loại, mất công cài python3.9 xong lại chả dùng được 😫

Đến khi dùng python3.6 và pip3 from python3.6 để package thì Lambda lại run OK.  

...Sau vài hôm thì tác giả của Library update version mới, mình có thể dùng python3.9 để package layer và Lambda lại run OK.

Chú ý là sau khi sử dụng layer mới - Được package từ pip3 (python3.9) khoảng 15MB, thì Lambda liên tục bị timeout error. Phải tăng CPU lên 512MB, còn RAM vẫn 512MB thì kết quả mới trả về nhanh được.



## 2.2. Code Lambda

Trên thực tế mình được chatGPT vào 1 function Lambda có sẵn đang làm nhiệm vụ khác (get blog pwd),  

Về cơ bản code sẽ như này, đây là bản mình đã lược bỏ 1 số function ko liên quan, nên cũng chưa test xem chạy ok ko:  

```sh
import boto3
import requests
import logging
import datetime
from botocore.exceptions import ClientError
from datetime import datetime
import json
import os
import sys
from os.path import exists

from revChatGPT.V3 import Chatbot

'''
Please config Environment variable: ALLOWED_CHAT_ID (comma separated), CHATGPT_API_KEY, CONVERSATION_ID, FUNCTION_NAME, TELEGRAM_TOKEN

Install library:
pip3 install --upgrade revChatGPT (use pip3 of python3.6, if you use pip3 of python3.9 lambda will raise error)

Functions: 
This script also forwards your question to ChatGPT and response its answer 
To add this bot to a group chat: You should talk to BotFather to disable privacy first, 
then add it to group chat, and promote it as administrator. 
It may takes some time to Telegram takes the change (1 hour in my case)
'''

here = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(here, "./vendored"))


# Logger settings - CloudWatch
# Set level to DEBUG for debugging, INFO for general usage.
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Get Lambda environment variables
TOKEN = os.environ.get('TELEGRAM_TOKEN')
ALLOWED_CHAT_ID = os.environ.get('ALLOWED_CHAT_ID')
CHATGPT_API_KEY = os.environ.get('CHATGPT_API_KEY')
CONVERSATION_ID = os.environ.get('CONVERSATION_ID')
FUNCTION_NAME = os.environ.get('FUNCTION_NAME')

# Get current datetime
currentDT = datetime.now()

# supported command
SUPPORTED_CMD = ["/help", "/gpt YOUR_QUESTION", "/new"]

# conversation data file, store in temporary of Lambda instance
TMP_CONVERSATION_DATA = "/tmp/conversation.json"
    
def send_telegram_msg(msg, chat_id):
    """
    Tries to Send Telegram message. If a ThrottlingException is encountered
    recursively calls itself until success.
    """
    try:
        BASE_URL = "https://api.telegram.org/bot{}".format(TOKEN)
        url = BASE_URL + "/sendMessage"
        data = {"text": msg.encode("utf8"), "chat_id": chat_id}
        requests.post(url, data)
    except ClientError as err:
        if 'ThrottlingException' in str(err):
            logger.info(
                "Send message to Telegram command throttled, automatically retrying...")
            send_telegram_msg(msg, chat_id)
        else:
            logger.error(
                "Send message to Telegram command Failed!\n%s", str(err))
            return False
    except:
        raise
        
def chat_gpt(question, conversation_id, chat_id):
    """
    Tries to ask ChatGPT a question
    """
    try:
        chatbot = Chatbot(api_key=CHATGPT_API_KEY)
        # Check if conversation data file is exist or not
        file_exists = exists(TMP_CONVERSATION_DATA)
        logger.info("Conversation data exist?: %s" % file_exists)
        logger.info("Conversation ID: %s" % conversation_id)
        # if data file exist, load it to conversation
        if file_exists == True:
            chatbot.load(TMP_CONVERSATION_DATA)
        # send question to chatGPT, belong to specific conversation
        response = chatbot.ask(question, role="user", convo_id=conversation_id)
        # save conversation data to a json file
        chatbot.save(TMP_CONVERSATION_DATA)
        return response
    except Exception as err:
        if '500 Internal Server Error' in str(err):
            logger.error("Error happens!\n%s", str(err))
            msg = "Please try again. Internal Server Error: %s" + str(err)
            send_telegram_msg(msg, chat_id)
            return False
    except:
        raise

def update_lambda_env_variable(function_name, key, value):
    """
    Tries to update Lambda Env variable. If a ThrottlingException is encountered
    recursively calls itself until success.
    """
    try:
        client = boto3.client('lambda')
        client.update_function_configuration(
            FunctionName=function_name,
            Environment={
                'Variables': {
                    key: value,
                    "ALLOWED_CHAT_ID": ALLOWED_CHAT_ID,
                    "CHATGPT_API_KEY": CHATGPT_API_KEY,
                    "PASSWORD": ENCRYPT_PASSWORD,
                    "TELEGRAM_TOKEN": TOKEN,
                    "FUNCTION_NAME": function_name
                    
                }
            }
        )
        logger.info('============Update Lambda Env Variable Successfully')
        return True
    except ClientError as err:
        if 'ThrottlingException' in str(err):
            logger.info("Update Lambda Env Variable throttled, automatically retrying...")
            update_lambda_env_variable(function_name, key, value)
        else:
            logger.error("Update Lambda Env Variable Failed!\n%s", str(err))
            return False
    except:
        raise

def lambda_handler(event, context):
    print('------------------')
    logger.debug(event)
    data = json.loads(event["body"])
    try:
        # if you not set enough admin right for Telegram bot in a group chat, 
        # it may get some error since response will not have `message` element
        # that's why I put this in try catch
        message = str(data["message"]["text"]) 
        # need to convert chat_id to string to find it it list
        chat_id = str(data["message"]["chat"]["id"]) 
        logger.info(chat_id)
        allowed_chat_id_list = list(ALLOWED_CHAT_ID.split(","))
        if chat_id in allowed_chat_id_list:
            logger.info("chat_id is allowed")
            encrypt_password = ENCRYPT_PASSWORD
            # first_name = data["message"]["chat"]["first_name"]
            # msg = "Please /help, {}".format(first_name)

            # help command
            if SUPPORTED_CMD[0] in message:
                joined_msg = "\n".join(SUPPORTED_CMD)
                msg = "There are only a few commands that I understand:\n%s" % joined_msg
                # send telegram message
                logger.info(msg)
                send_telegram_msg(msg, chat_id)

            # return answer for question via chatGPT
            elif message.startswith('/gpt '):
                question = message.split(" ", 1)[1]
                logger.info(question)
                msg = chat_gpt(question, CONVERSATION_ID, chat_id)
                # send telegram message
                # logger.info(msg)
                send_telegram_msg(msg, chat_id)

            # increase conversation_id and update the enviroment variable
            elif message.startswith('/new'):
                conversation_id = int(CONVERSATION_ID) + 1
                key = "CONVERSATION_ID"
                value = str(conversation_id)
                update_lambda_env_variable(FUNCTION_NAME, key, value)
                msg = "OK, new conversation starts"
                send_telegram_msg(msg, chat_id)

            return True
        else:
            logger.info("chat_id is not allowed")
            return False

    except KeyError as err:
        logger.error("Invalid response format! \n%s", str(err))
        return False
    except:
        raise
```

Về mặt logic:  
- Mỗi khi muốn hỏi chatGPT 1 câu thì gõ như ví dụ: "/gpt quả táo là gì?".  
- Sau mỗi câu trả lời hàm `chat_gpt` sẽ save/load conversation vào 1 file `/tmp/conversation.json` của Lambda container.  
- Thế nên nó có thể reply liên tục như 1 conversation ngoài đời thật. (Muốn test thì nói "continue") để nó tiếp tục chủ đề vừa hỏi.   
- Nhưng vì đặt trong `/tmp/conversation.json` của Lambda container, nên nếu ko chat 1 thời gian, file này sẽ bị xóa vì container đã bị AWS delete.  
- Nếu đang chat liên tục mà lại muốn chatGPT quên hết những chủ đề vừa xong, bắt đầu 1 conversation mới thì gõ `/new`.  



## 2.3. Troubleshooting

Trong quá trình làm thì:

Nếu Telegram bot ko thể nhận được message từ 1 group chat. Mặc dù run OK khi chat riêng với nó.

Tình trạng y như này: https://stackoverflow.com/questions/64435576/telegram-webhook-doesnt-send-text-from-group-chats

sau 1 lúc thì lại ko thấy lỗi nữa, khó hiểu. Có vẻ như telegram api bị cache ở đâu đó, nên việc mình remove/add bot làm admin và disable privacy mất 1 lúc để nó nhận ra. 

Nếu muốn test việc write và read file từ folder /tmp của Lambda:  
```sh
import json
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

logger.info("writing...")
body = {"a": "v"}
data = json.dumps(body)
with open('/tmp/conversation.json', 'w') as f:
    f.write(data)
logger.info("reading...")
with open(/tmp/conversation.json, 'r') as openfile:
    json_object = json.load(openfile)
print(json_object)
```

Nhược điểm của revChatGPT.V1 là chậm, phải authen bằng `access_token` (sống dc 2 tuần), hoặc `user/password` (dễ bị Cloudflare hỏi thăm), hoặc `session_token` (sống được ngắn).  
Dùng revChatGPT.V3 thì có thể dùng `API_KEY` (sống lâu, nhưng mất tiền), phản hồi khá nhanh.  

Dùng revChatGPT.V3 mà muốn chatGPT nhớ được conversation cũ thì nó yêu cầu save và load conversation từ JSON file như code phía trên.  

Dùng revChatGPT.V1 mà muốn chatGPT nhớ được conversation cũ thì cần làm kiểu này:  

```sh
from revChatGPT.V1 import Chatbot

config = {
    "access_token": "eyJ..."
}
chatbot = Chatbot(config)
response = ""
conversation =""
parent_id =""

chatbot.conversation_id = conversation
chatbot.parent_id = parent_id

for data in chatbot.ask("continue"):
    response = data["message"]
    conversation = data['conversation_id']
    parent_id = data['parent_id']

print(response)
print(conversation)
print(parent_id)

del chatbot

chatbot = Chatbot(config)
chatbot.conversation_id = conversation
chatbot.parent_id = parent_id
for data in chatbot.ask("continue"):
    response = data["message"]
print(response)
```

Sau đó lên khung chat trên Browser sẽ thấy 1 đoạn conversation mới được tạo ra, điểm này revChatGPT.V3 hiện ko làm được.

Nhưng nói chung là nên dùng revChatGPT.V3 vì nó là official API của OpenAI, sớm muộn cũng sẽ thay thế V1.  

# 3. Sử dụng framework AWS Chalice

https://github.com/aws/chalice

Chalice là 1 framework của AWS phát triển, dành riêng cho các ứng dụng serverless ngôn ngữ Python.

Nó giúp bạn deploy 1 ứng dụng rất nhanh lên AWS. Nó config API Gateway thay bạn, tạo IAM Role thay bạn, tạo Lambda function thay bạn luôn.  

Bạn chỉ cần đưa Access Key và Secret Key để nó làm thay bạn thôi.  

## 3.1. Configure aws cli

https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

```sh
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
```

Configure aws credential: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html

Tạo user trên IAM để get Access Key và Secret Key. Nên tạo 1 user với quyền vừa đủ thôi.  

Tạo inline policy vừa đủ quyền cho user đó: (credit: https://github.com/aws/chalice/issues/59)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1471020565000",
            "Effect": "Allow",
            "Action": [
                "iam:AttachRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:DetachRolePolicy",
                "iam:CreateRole",
                "iam:PutRolePolicy",
                "iam:GetRole",
                "iam:PassRole"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1471020565001",
            "Effect": "Allow",
            "Action": [
                "apigateway:GET",
                "apigateway:POST"
            ],
            "Resource": [
                "arn:aws:apigateway:us-east-1::/restapis",
                "arn:aws:apigateway:us-east-1::/restapis/*/resources",
                "arn:aws:apigateway:us-east-1::/restapis/*/resources/*"
            ]
        },
        {
            "Sid": "Stmt1471020565002",
            "Effect": "Allow",
            "Action": [
                "apigateway:DELETE"
            ],
            "Resource": [
                "arn:aws:apigateway:us-east-1::/restapis/*/resources/*"
            ]
        },
        {
            "Sid": "Stmt1471020565003",
            "Effect": "Allow",
            "Action": [
                "apigateway:POST"
            ],
            "Resource": [
                "arn:aws:apigateway:us-east-1::/restapis/*/deployments",
                "arn:aws:apigateway:us-east-1::/restapis/*/resources/*"
            ]
        },
        {
            "Sid": "Stmt1471020565004",
            "Effect": "Allow",
            "Action": [
                "apigateway:PUT"
            ],
            "Resource": [
                "arn:aws:apigateway:us-east-1::/restapis/*/methods/GET",
                "arn:aws:apigateway:us-east-1::/restapis/*/methods/GET/*",
                "arn:aws:apigateway:us-east-1::/restapis/*/methods/POST",
                "arn:aws:apigateway:us-east-1::/restapis/*/methods/POST/*",
                "arn:aws:apigateway:us-east-1::/restapis/*/methods/PUT",
                "arn:aws:apigateway:us-east-1::/restapis/*/methods/PUT/*"
            ]
        },
        {
            "Sid": "Stmt1471020565005",
            "Effect": "Allow",
            "Action": [
                "apigateway:PATCH"
            ],
            "Resource": [
                "arn:aws:apigateway:us-east-1::/restapis/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "lambda:*",
            "Resource": "*"
        }
    ]
}

```

(Mặc dù app chatGPT này ko dùng API Gateway nhưng mình vẫn đưa vào cái json policy trên vì biết đâu sau này cần)

Run `aws configure` để nhập Access key và Secret key bên trên


## 3.2. Setup môi trường python

```sh
git clone https://github.com/franalgaba/chatgpt-telegram-bot-serverless
cd chatgpt-telegram-bot-serverless
```

sửa python3 mặc định sang python3.9, pip3 mặc định cũng phải của python3.9:   

```
update-alternatives --config python3
sudo apt-get install python-virtualenv
apt install python3.9-dev python3.9-venv
```

```sh
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Deploy:  

```sh
$ chalice deploy
Creating deployment package.
Reusing existing deployment package.
Creating IAM role: chatgpt-telegram-bot-dev-message-handler-lambda
Creating lambda function: chatgpt-telegram-bot-dev-message-handler-lambda
Resources deployed:
  - Lambda ARN: arn:aws:lambda:us-east-1:85xxxxx188:function:chatgpt-telegram-bot-dev-message-handler-lambda

```

Nếu có udpate gì trong code thì cứ run `chalice deploy` lại thôi.  

Lên AWS Lambda sẽ thấy 1 Lambda function mới được tạo ra: `chatgpt-telegram-bot-dev-message-handler-lambda`

Lên AWS IAM sẽ thấy 1 IAM role mới được tạo ra: `chatgpt-telegram-bot-dev-message-handler-lambda`

## 3.3. Tạo Telegram Bot để test

Chat với BotFather, tạo 1 con bot Telegram mới để test, ví dụ ChaliceTL_bot, lấy được token: `5xxxxxx40:AAxxxxxxxxxxxxxxxxxx998k`

## 3.4. Expose AWS Lambda ra internet

Hồi xưa thì bắt buộc phải call Lambda qua API Gateway, giờ AWS đã cho thêm cái Function URL này để call trực tiếp Lambda khá tiện.  

Go to the AWS Console -> Lambda -> `chatgpt-telegram-bot-dev-message-handler-lambda` -> Configuration -> Function URL.

Click Create Function URL and set Auth type to NONE.

Được 1 Function URL: `https://sbhtxxxxxxxxxxxxpn.lambda-url.us-east-1.on.aws/`

## 3.5. Configure webhook cho Telegram bot

```
$ curl --request POST --url https://api.telegram.org/bot<YOUR_TELEGRAM_TOKEN>/setWebhook --header 'content-type: application/json' --data '{"url": "<YOUR_FUNCTION_URL"}'

{"ok":true,"result":true,"description":"Webhook was set"}
```

Done! Test thôi.😁

Đọc code thì thấy khá đơn giản (chỉ có 1 file thôi)

Ví dụ này giúp ta hiểu được cách sử dụng AWS Chalice để deploy ứng dụng rất nhanh lên AWS (Developer sẽ ko cần phải lên AWS Console upload Layer như mình làm hồi trước nữa)

## 3.6. Clean

Run `chalice delete` để xóa toàn bộ những gì chalice đã tạo ra (cũng khá tiện, ko sợ bị xóa nhầm, xóa xót resource)

Điều mình concern là làm thế nào để bảo vệ cái access_key và secret_key thôi


# CREDIT

So sánh AWS Chalice với các serverless framework: https://medium.com/@ndh175/should-i-use-aws-chalice-for-my-next-project-e445f262a49b   
https://stackoverflow.com/questions/64435576/telegram-webhook-doesnt-send-text-from-group-chats
https://github.com/acheong08/ChatGPT  
https://github.com/acheong08/ChatGPT/discussions/521#discussioncomment-4878935  
https://github.com/acheong08/ChatGPT/issues/7#issuecomment-1338930770  
https://github.com/acheong08/ChatGPT/wiki/V3  
https://github.com/acheong08/ChatGPT/issues/574     
https://github.com/acheong08/ChatGPT/discussions/1055  
https://github.com/franalgaba/chatgpt-telegram-bot-serverless  
https://github.com/aws/chalice  






