---
title: "AWS Lambda Development with SAM"
date: 2025-03-28T21:46:36+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [AWS,Lambda,SAM]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "AWS Lambda Development with SAM"
---

repo: https://gitlab.com/inmessionante/test-lambda-local-develop-lab.git

# 1. Overview

Nói về 2 method để làm việc với AWS Lambda từ môi trường local

+ Method 1: Using sam-cli type zip
+ Method 2: Using sam-cli type docker image 

- Method 1 thường dùng cho các ứng dụng vừa và nhỏ, vì có giới hạn của zip file là 250MB (Kể cả có áp dụng Layer).
  ưu điểm là khi deploy lên AWS Lambda, bạn có thể vào nhìn và chỉnh sửa trực tiếp luôn bằng Browser IDE luôn.

- Method 2 thường dùng cho các ứng dụng lớn, giới hạn container image có thể lên 10GB.
  nhược điểm là sau khi deploy lên AWS Lambda, bạn vào console sẽ ko nhìn thấy code, ko chỉnh sửa được gì.

Bài này chúng ta chỉ tập trung vào Deploy Lambda, ko muốn SAM tạo thêm các resource ko mong muốn, thế nên có 1 số thứ cần chuẩn bị trước:

- 1 S3 bucket để SAM dùng lưu artifact. (cả 2 Method đều dùng)
- 1 IAM User và access key dùng để cho SAM authen. (cả 2 Method đều dùng)
- 1 IAM Role sẽ dùng để attach vào Lambda function (trong `template.yaml` sẽ reference đến Role này).(cả 2 Method đều dùng)
- 1 Lambda Layer để cho Lambda function dùng. (chỉ Method 1 dùng được Layer)
- 1 ECR repo để chứa các Docker image tạo ra bởi sam deploy. (Chỉ Method 2 dùng được ECR)

# 2. Method #1: Using sam-cli type Zip

## 2.1. Init, Build, Local invoke, Deploy to AWS

```sh
cd sam-dev/

python3 -m venv .venv

source .venv/bin/activate

pip install aws-sam-cli
```

init sam app:

```sh
$ sam init \
   --name hmnsd-function-sam \
   --app-template hello-world \
   --runtime python3.10 \
   --dependency-manager pip \
   --package-type Zip \
   --no-tracing

        SAM CLI now collects telemetry to better understand customer needs.

        You can OPT OUT and disable telemetry collection by setting the
        environment variable SAM_CLI_TELEMETRY=0 in your shell.
        Thanks for your help!

        Learn More: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-telemetry.html


Cloning from https://github.com/aws/aws-sam-cli-app-templates (process may take a moment)
```

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-lambda-local-dev-sam-tree.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-lambda-local-dev-sam-tree-samconfig.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-lambda-local-dev-sam-tree-template.jpg)

Build:

```sh
$ cd hmnsd-function-sam/

$ sam build --use-container

Starting Build use cache
Starting Build inside a container
Cache is invalid, running build and copying resources for following functions (HelloWorldFunction)
Building codeuri: /home/USERNAME/test-lambda-local-develop/sam-dev/hmnsd-function-sam/hmsd-function runtime: python3.10 architecture: x86_64 functions:
HelloWorldFunction

Fetching public.ecr.aws/sam/build-python3.10:latest-x86_64 Docker container image...........................................................................................................................................................................................................
Mounting /home/USERNAME/test-lambda-local-develop/sam-dev/hmnsd-function-sam/hmsd-function as /tmp/samcli/source:ro,delegated, inside runtime container
 Running PythonPipBuilder:ResolveDependencies
 Running PythonPipBuilder:CopySource

Build Succeeded

Built Artifacts  : .aws-sam/build
Built Template   : .aws-sam/build/template.yaml

Commands you can use next
=========================
[*] Validate SAM template: sam validate
[*] Invoke Function: sam local invoke
[*] Test Function in the Cloud: sam sync --stack-name {{stack-name}} --watch
[*] Deploy: sam deploy --guided
```

Validate:

```sh
$ sam validate
/home/USERNAME/test-lambda-local-develop/sam-dev/hmnsd-function-sam/template.yaml is a valid SAM Template
```

Local invoke:

```sh
$ sam local invoke

No current session found, using default AWS::AccountId
Invoking app.lambda_handler (python3.10)
Local image was not found.
Removing rapid images for repo public.ecr.aws/sam/emulation-python3.10
Building image..........................
Using local image: public.ecr.aws/lambda/python:3.10-rapid-x86_64.

Mounting /home/USERNAME/test-lambda-local-develop/sam-dev/hmnsd-function-sam/.aws-sam/build/HelloWorldFunction as /var/task:ro,delegated, inside runtime container
START RequestId: 6f8bf614-7d02-496a-81d3-319b49ba9fa5 Version: $LATEST
END RequestId: 9031bddd-6a0a-4889-b9f8-cf50c67b4e96
REPORT RequestId: 9031bddd-6a0a-4889-b9f8-cf50c67b4e96  Init Duration: 0.02 ms  Duration: 25.25 ms      Billed Duration: 26 ms                                          Memory Size: 128 MB      Max Memory Used: 128 MB
{"statusCode": 200, "body": "{\"message\": \"hello world\"}"}

$ docker images

REPOSITORY                            TAG                            IMAGE ID       CREATED          SIZE
public.ecr.aws/lambda/python          3.10-rapid-x86_64              e8a6a2e933fc   31 seconds ago   580MB
public.ecr.aws/sam/build-python3.10   latest-x86_64                  fd91d15ef2bb   3 hours ago      1.59GB
public.ecr.aws/lambda/python          3.10-x86_64                    04d11c0728ec   2 days ago       562MB
```

Sửa `samconfig.toml` và `template.yaml` để chỉ định exist s3 bucket và exist IAM Role cho Lambda function:

`samconfig.toml`:
```
s3_bucket = "sam-deploy-hmnsd"
s3_prefix = "hmnsd-function-sam"
region = "us-east-1"
```

`template.yaml`:
```yaml
Resources:
  HelloWorldFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: hmsd-function/
      Handler: app.lambda_handler
      Runtime: python3.10
      Architectures:
        - x86_64
      Role: arn:aws:iam::123123123:role/lambda_xxxx
```

Authen:

Vào AWS Console tạo 1 user để lây access key.

User cần có vừa đủ quyền để access vào các resource trên AWS, ở đây mình gán 1 IAM policy như sau:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "s3-object-lambda:*"
            ],
            "Resource": [
                "arn:aws:s3:::sam-deploy-hmnsd",
                "arn:aws:s3:::sam-deploy-hmnsd/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:ListRolePolicies",
                "iam:ListRoles",
                "iam:PassRole",
                "lambda:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "cloudformation:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:CreateLogGroup",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
```

=> **IAM role này vẫn còn quá rộng, Nếu sau này deploy dùng lâu dài thì nên hạn chế quyền vừa đủ mà thôi.**

```sh
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
cp -rp /usr/local/bin/aws /usr/bin/

$ aws configure
AWS Access Key ID [None]: YYY
AWS Secret Access Key [None]: XXX
Default region name [None]: us-east-1
Default output format [None]: json
```

Deployment:

```sh
$ sam deploy
File with same data already exists at hmnsd-function-sam/c5a75ed4d93ba77b3ca5d33d70f5effb, skipping upload

        Deploying with following values
        ===============================
        Stack name                   : hmnsd-function-sam
        Region                       : us-east-1
        Confirm changeset            : True
        Disable rollback             : False
        Deployment s3 bucket         : sam-deploy-hmnsd
        Capabilities                 : ["CAPABILITY_IAM"]
        Parameter overrides          : {}
        Signing Profiles             : {}

Initiating deployment
=====================

        Uploading to hmnsd-function-sam/347424cc63f1d4f1eb0cc3179b7a1fb6.template  584 / 584  (100.00%)


Waiting for changeset to be created..

CloudFormation stack changeset
-----------------------
Operation                                 LogicalResourceId                         ResourceType                              Replacement
-----------------------
+ Add                                     HelloWorldFunction                        AWS::Lambda::Function                     N/A
-----------------------


Changeset created successfully. arn:aws:cloudformation:us-east-1:123123123:changeSet/samcli-deploy1743133812/fbc20b10-76cf-473c-9359-54f1eb8ae944


Previewing CloudFormation changeset before deployment
======================================================
Deploy this changeset? [y/N]: y

2025-03-28 10:52:35 - Waiting for stack create/update to complete

CloudFormation events from stack operations (refresh every 5.0 seconds)
-----------------------
ResourceStatus                            ResourceType                              LogicalResourceId                         ResourceStatusReason
-----------------------
CREATE_IN_PROGRESS                        AWS::CloudFormation::Stack                hmnsd-function-sam                        User Initiated
CREATE_IN_PROGRESS                        AWS::Lambda::Function                     HelloWorldFunction                        -
CREATE_COMPLETE                           AWS::Lambda::Function                     HelloWorldFunction                        -
CREATE_COMPLETE                           AWS::CloudFormation::Stack                hmnsd-function-sam                        -
-----------------------


Successfully created/updated stack - hmnsd-function-sam in us-east-1
```

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-lambda-local-dev-remote-lambda-created.jpg)

Có thể thấy có nhiều library được được vào, do chúng ta chưa gắn layer vào.

Nguyên nhân là do trong folder `hmsd-function` có file `requirements.txt`

File `template.yaml` có trỏ đến folder `CodeUri: hmsd-function/`:

```yml
...
Resources:
  HelloWorldFunction:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: hmnsd-function-sam
      CodeUri: hmsd-function/
```

Khi run `sam build` các python library trong `requirements.txt` sẽ dc packaged vào folder `.aws-sam/build` và dc push lên AWS Lambda.

Nếu rename file thành `requirements.txt.DEV` thì `.aws-sam/build` sẽ ko bị included các libraries nữa.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-lambda-local-dev-remote-lambda-created-no-libs.jpg)

Nếu trong `template.yaml` ta chỉ định layer sẽ được gắn vào Lambda function:

```yml
...
Resources:
  HmnsdFunction:
    Type: AWS::Serverless::Function # More info about Function Resource: https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md#awsserverlessfunction
    Properties:
      FunctionName: hmnsd-function-sam
      Description: This is hmnsd-function-sam
      CodeUri: hmnsd-function/
      Handler: app.lambda_handler
      Runtime: python3.10
      Architectures:
        - x86_64
      Role: arn:aws:iam::123123123:role/lambda-role
      Layers:
        - arn:aws:lambda:us-east-1:123123123:layer:sayanbot-layer:7
```

thì khi Local invoke Layer sẽ được download về như này:

```sh
$ sam local invoke
Invoking app.lambda_handler (python3.10)
Downloading arn:aws:lambda:us-east-1:123123123:layer:sayanbot-layer  [####################################]  26976061/26976061
Local image was not found.
Building image.......................
Using local image: samcli/lambda-python:3.10-x86_64-5bf55d5f7cb8aab8d164c5ee3.

Mounting /home/USER/test-lambda-local-develop/sam-dev/hmnsd-function-sam/.aws-sam/build/HmnsdFunction as /var/task:ro,delegated, inside runtime container
START RequestId: ab3a0572-1467-4137-a2ac-1146cce37fdf Version: $LATEST
END RequestId: 60ca55e1-9a8b-47af-8280-9f0fb3b200c9
REPORT RequestId: 60ca55e1-9a8b-47af-8280-9f0fb3b200c9  Init Duration: 0.03 ms  Duration: 33.77 ms      Billed Duration: 34 ms                                         Memory Size: 128 MB      Max Memory Used: 128 MB
{"statusCode": 200, "body": "{\"message\": \"hello world\"}"}
```


Delete resources:

```sh
$ sam delete --stack-name hmnsd-function-sam
        Are you sure you want to delete the stack hmnsd-function-sam in the region us-east-1 ? [y/N]: y
        Are you sure you want to delete the folder hmnsd-function-sam in S3 which contains the artifacts? [y/N]: y
        - Deleting S3 object with key hmnsd-function-sam/689bf3b4529156d13aa654f83d23d86e
        - Deleting S3 object with key hmnsd-function-sam/11280ef2e53d71bb7164d643957d8062.template
        - Deleting Cloudformation stack hmnsd-function-sam

Deleted successfully
```

## 2.2. Deploy Lambda Layer to AWS

Deploy Lambda Layer bằng SAM CLI: 

source: https://jun711.github.io/aws/create-aws-lambda-layers-using-aws-sam-yaml-tutorial/

Đầu tiên tạo folder và files theo structure này:

```sh
sam-dev/hmnsd-layer-sam$ tree -L 2
.
└── hmnsd-layer-01
    ├── package
        ├── python
    ├── requirements.txt
    ├── samconfig.toml
    └── template.yaml
```

File `requirements.txt` chứa các python lib mà mình sẽ cài ví dụ như `requests==2.32.3`

Run command để export các libraries vào folder `package/python`:
```sh
cd hmnsd-layer-sam/hmnsd-layer-01/
python3.10 -m pip install \
    --target=./package/python \
    -r requirements.txt
```

File `samconfig.toml`:

```
# More information about the configuration file can be found here:
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-config.html
version = 0.1

[default.global.parameters]
stack_name = "hmnsd-layer-sam"
region = "us-east-1"

[default.build.parameters]
cached = true
parallel = true

[default.validate.parameters]
lint = true

[default.deploy.parameters]
capabilities = "CAPABILITY_IAM"
confirm_changeset = true
s3_bucket = "sam-deploy-hmnsd"
s3_prefix = "hmnsd-layer-sam"

[default.package.parameters]
resolve-s3 = true

[default.sync.parameters]
watch = true

[default.local_start_api.parameters]
warm_containers = "EAGER"

[default.local_start_lambda.parameters]
warm_containers = "EAGER"
```

File `template.yaml`:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: >
  hmnsd-layer-sam

  Sample SAM Template for hmnsd-layer-sam

# More info about Globals: https://github.com/awslabs/serverless-application-model/blob/master/docs/globals.rst
Globals:
  Function:
    Timeout: 3

Resources:
  AwsServices:
    Type: AWS::Serverless::LayerVersion
    Properties:
      LayerName: hmnsd-layer-01
      Description: This is hmnsd-layer-01
      ContentUri: ./package
      CompatibleRuntimes:
        - python3.10
      LicenseInfo: MIT
      RetentionPolicy: Retain
```

Build:

```sh
$ sam build
Starting Build use cache

Build Succeeded

Built Artifacts  : .aws-sam/build
Built Template   : .aws-sam/build/template.yaml

Commands you can use next
=========================
[*] Validate SAM template: sam validate
[*] Invoke Function: sam local invoke
[*] Test Function in the Cloud: sam sync --stack-name {{stack-name}} --watch
[*] Deploy: sam deploy --guided
```

Deploy Layer:

```sh
$ sam deploy
        Uploading to hmnsd-layer-sam/68ab0beff948e23bad0939c58ec8558d  943054 / 943054  (100.00%)

        Deploying with following values
        ===============================
        Stack name                   : hmnsd-layer-sam
        Region                       : us-east-1
        Confirm changeset            : True
        Disable rollback             : False
        Deployment s3 bucket         : sam-deploy-hmnsd
        Capabilities                 : ["CAPABILITY_IAM"]
        Parameter overrides          : {}
        Signing Profiles             : {}

Initiating deployment
=====================

        Uploading to hmnsd-layer-sam/fb49202dd4d07796a3db763e67fd6b2f.template  587 / 587  (100.00%)


Waiting for changeset to be created..

CloudFormation stack changeset
-----------------------
Operation                                 LogicalResourceId                         ResourceType                              Replacement
-----------------------
+ Add                                     AwsServices3d3a407f2f                     AWS::Lambda::LayerVersion                 N/A
-----------------------


Changeset created successfully. arn:aws:cloudformation:us-east-1:123123123:changeSet/samcli-deploy1743143604/ed63cf25-e818-4dae-90e8-986f30e3e785


Previewing CloudFormation changeset before deployment
======================================================
Deploy this changeset? [y/N]: y

2025-03-28 13:33:51 - Waiting for stack create/update to complete

CloudFormation events from stack operations (refresh every 5.0 seconds)
-----------------------
ResourceStatus                            ResourceType                              LogicalResourceId                         ResourceStatusReason
-----------------------
CREATE_IN_PROGRESS                        AWS::CloudFormation::Stack                hmnsd-layer-sam                           User Initiated
CREATE_IN_PROGRESS                        AWS::Lambda::LayerVersion                 AwsServices3d3a407f2f                     -
CREATE_IN_PROGRESS                        AWS::Lambda::LayerVersion                 AwsServices3d3a407f2f                     Resource creation Initiated
CREATE_COMPLETE                           AWS::Lambda::LayerVersion                 AwsServices3d3a407f2f                     -
CREATE_COMPLETE                           AWS::CloudFormation::Stack                hmnsd-layer-sam                           -
-----------------------


Successfully created/updated stack - hmnsd-layer-sam in us-east-1
```

## 2.3. Work with Environment variables

### 2.3.1. Nếu bạn cần deploy để thay đổi Env variables trên AWS Lambda function

Step này thực ra ko nên làm vì dev trong local nên dùng riêng env variable đối với trên AWS Lambda, để tránh bị leak values.

Việc dev trực tiếp thay đổi value trên AWS Lambda env cũng ko nên khuyến khích vì trên đó có thể là môi trường dùng chung của nhiều người.

Trong file `template.yaml` cần khai báo Parameters:
```yaml
Parameters:
  SomeVar:
    Type: String
    Description: This is environment variable
    Default: default value

Resources:
  HmnsdFunction:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: hmnsd-function-sam
      ....
      Environment:
        Variables:
          SOME_VAR: !Ref SomeVar
```

Khi deploy thì run command như này để input value cho env variables:

```sh
$ sam deploy --parameter-overrides SomeVar=command-values123
```

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-lambda-local-dev-remote-lambda-env.jpg)

### 2.3.2. Nếu bạn cần run local invoke với những biến môi trường tại local

Tạo file `env.local.json`:

```json
{
    "HmnsdFunction": {
        "SOME_VAR": "123 from env.local.json"
    }
}
```
Trong Lambda function retrieve env bằng os kiểu như bình thường:

```s
....
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": f"hello world. {os.getenv('SOME_VAR')}",
            # "location": ip.text.replace("\n", "")
        }),
    }
```

Khi run local invoke thì run như này:

```sh
$ sam local invoke --env-vars env.local.json


Invoking app.lambda_handler (python3.10)
arn:aws:lambda:us-east-1:123123123:layer:layer01:7 is already cached. Skipping download
Local image is up-to-date
Using local image: samcli/lambda-python:3.10-x86_64-5bf55d5f7cb8aab8d164c5ee3.

Mounting /home/USER/test-lambda-local-develop/sam-dev/hmnsd-function-sam/.aws-sam/build/HmnsdFunction as /var/task:ro,delegated, inside runtime container
START RequestId: 0f20ef9f-d328-4a01-8377-04404f0b0226 Version: $LATEST
END RequestId: d587222c-03dc-463f-9642-c078d003f45b
REPORT RequestId: d587222c-03dc-463f-9642-c078d003f45b  Init Duration: 0.05 ms  Duration: 79.00 ms      Billed Duration: 80 ms                                         Memory Size: 128 MB      Max Memory Used: 128 MB
{"statusCode": 200, "body": "{\"message\": \"hello world. 123 from env.local.json\"}"}
```

Vậy nghĩa là môi trường Dev bạn có thể dùng 1 file `env.local.json` riêng biệt đối với AWS Lambda.

Nếu trong file `env.local.json` có sensitive info thì nên ignore nó khỏi git hoặc aws

# 3. Method 2: Using sam-cli type docker image 

## 3.1. Init, Build, Local invoke, Deploy to AWS Lambda

Init project:

```sh
$ sam init \
   --name hmnsd-function-sam-docker \
   --app-template hello-world \
   --runtime python3.10 \
   --dependency-manager pip \
   --package-type Image \
   --no-tracing
```
-> repo strucuture tạo ra vẫn cần thay đổi:

Add `Dockerfile`:
```
FROM public.ecr.aws/lambda/python:3.10

COPY hello_world/. ./

RUN python3.10 -m pip install -r requirements.txt

CMD ["app.lambda_handler"]
```

File `samconfig.toml` thêm những biến sau:
```
....
image_repository = "123123123.dkr.ecr.us-east-1.amazonaws.com/lambda-deployment/hmnsd-function-sam-docker"
s3_bucket = "sam-deploy-hmnsd"
s3_prefix = "hmnsd-function-sam-docker"
```

File `template.yaml` sửa thành:

```yaml
....
Resources:
  HelloWorldFunction:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: hmnsd-function-sam-docker
      Description: This is hmnsd-function-sam-docker
      PackageType: Image
      ImageConfig:
        Command: ["app.lambda_handler"]

    Metadata:
      Dockerfile: Dockerfile
      DockerContext: .
      DockerTag: v1
```

Build docker image:

```sh
$ sam build --use-container -t template.yaml


Starting Build inside a container
Building codeuri: /home/USER/test-lambda-local-develop/docker-dev/hmnsd-function-sam-docker runtime: python3.10 architecture: x86_64 functions:
HelloWorldFunction
Building image for HelloWorldFunction function
Setting DockerBuildArgs for HelloWorldFunction function
Step 1/4 : FROM public.ecr.aws/lambda/python:3.10
3.10: Pulling from lambda/python
Status: Downloaded newer image for public.ecr.aws/lambda/python:3.10 ---> 04d11c0728ec
Step 2/4 : COPY hello_world/. ./
 ---> 29f68d828ecf
Step 3/4 : RUN python3.10 -m pip install -r requirements.txt
 ---> Running in 11f50cebd9e8
Collecting requests
  Downloading requests-2.32.3-py3-none-any.whl (64 kB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 64.9/64.9 kB 870.3 kB/s eta 0:00:00
Collecting certifi>=2017.4.17
  Downloading certifi-2025.1.31-py3-none-any.whl (166 kB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 166.4/166.4 kB 2.4 MB/s eta 0:00:00
Collecting idna<4,>=2.5
  Downloading idna-3.10-py3-none-any.whl (70 kB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 70.4/70.4 kB 8.9 MB/s eta 0:00:00
Collecting urllib3<3,>=1.21.1
  Downloading urllib3-2.3.0-py3-none-any.whl (128 kB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 128.4/128.4 kB 9.1 MB/s eta 0:00:00
Collecting charset-normalizer<4,>=2
  Downloading charset_normalizer-3.4.1-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (146 kB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 146.1/146.1 kB 8.5 MB/s eta 0:00:00
Installing collected packages: urllib3, idna, charset-normalizer, certifi, requests
Successfully installed certifi-2025.1.31 charset-normalizer-3.4.1 idna-3.10 requests-2.32.3 urllib3-2.3.0
WARNING: Running pip as the 'root' user can result in broken permissions and conflicting behaviour with the system package manager. It is recommended to use a virtual environment instead: https://pip.pypa.io/warnings/venv

[notice] A new release of pip is available: 23.0.1 -> 25.0.1
[notice] To update, run: pip install --upgrade pip
 ---> Removed intermediate container 11f50cebd9e8
 ---> e993ca4ce9d3
Step 4/4 : CMD ["app.lambda_handler"]
 ---> Running in d97ae93f76ed
 ---> Removed intermediate container d97ae93f76ed
 ---> f16aa71e2c5c
Successfully built f16aa71e2c5c
Successfully tagged helloworldfunction:v1


Build Succeeded

Built Artifacts  : .aws-sam/build
Built Template   : .aws-sam/build/template.yaml

Commands you can use next
=========================
[*] Validate SAM template: sam validate
[*] Invoke Function: sam local invoke
[*] Test Function in the Cloud: sam sync --stack-name {{stack-name}} --watch
[*] Deploy: sam deploy --guided


$ docker images
REPOSITORY                                                                                 TAG                                     IMAGE ID       CREATED             SIZE
helloworldfunction                                                                         rapid-x86_64                            f7569300470d   3 minutes ago       584MB
123123123.dkr.ecr.us-east-1.amazonaws.com/lambda-deployment/hmnsd-function-sam-docker      helloworldfunction-f16aa71e2c5c-v1      f16aa71e2c5c   About an hour ago   565MB
helloworldfunction                                                                         v1                                      f16aa71e2c5c   About an hour ago   565MB
samcli/lambda-python                                                                       3.10-x86_64-5bf55d5f7cb8aab8d164c5ee3   40779d4604ba   3 hours ago         652MB
public.ecr.aws/lambda/python                                                               3.10-rapid-x86_64                       e8a6a2e933fc   7 hours ago         580MB
public.ecr.aws/sam/build-python3.10                                                        latest-x86_64                           fd91d15ef2bb   11 hours ago        1.59GB
public.ecr.aws/lambda/python                                                               3.10                                    04d11c0728ec   2 days ago          562MB
public.ecr.aws/lambda/python                                                               3.10-x86_64                             04d11c0728ec   2 days ago          562MB
```

Run local invoke:

```sh
$ sam local invoke

Invoking Container created from helloworldfunction:v1
Local image was not found.
Removing rapid images for repo helloworldfunction
Building image.................
Using local image: helloworldfunction:rapid-x86_64.

START RequestId: 5d19d569-3574-4d1e-9c16-cfbac48d08a0 Version: $LATEST
END RequestId: 77a98d95-0a00-421e-8320-2b7b564d1b7f
REPORT RequestId: 77a98d95-0a00-421e-8320-2b7b564d1b7f  Init Duration: 0.04 ms  Duration: 64.65 ms      Billed Duration: 65 ms                                         Memory Size: 128 MB      Max Memory Used: 128 MB
{"statusCode": 200, "body": "{\"message\": \"hello world\"}"}
```

Deploy to AWS Lambda:

Tạo ECR repo vì quá trình deploy sẽ cần store docker image vào ECR:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-lambda-local-dev-remote-ecr-repo.jpg)

IAM User (để SAM authen) cần add thêm policy sau để làm việc được với ECR (Policy này hơi open, nên specify ECR repo để hạn chế permission):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:SetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:DescribeImages",
                "ecr:BatchGetImage",
                "ecr:GetLifecyclePolicy",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:ListTagsForResource",
                "ecr:DescribeImageScanFindings",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:PutImage"
            ],
            "Resource": "*"
        }
    ]
}
```

Deploy command:

```sh
$ sam deploy
5225e7d2433d: Layer already exists
1d9b8ff5363e: Layer already exists
164296996de3: Layer already exists
c711a64a5333: Layer already exists
b5da4b018965: Layer already exists
472e69502b5d: Layer already exists
d0845bc8229f: Layer already exists
92ebca667691: Layer already exists
helloworldfunction-f16aa71e2c5c-v1: digest: sha256:b572f5a775b0180ddee354fe5f016116094e903178d928583329ada8d2e2c77c size: 1999

        Deploying with following values
        ===============================
        Stack name                   : hmnsd-function-sam-docker
        Region                       : us-east-1
        Confirm changeset            : True
        Disable rollback             : False
        Deployment image repository  :
                                       123123123.dkr.ecr.us-east-1.amazonaws.com/lambda-deployment/hmnsd-function-sam-docker
        Deployment s3 bucket         : sam-deploy-hmnsd
        Capabilities                 : ["CAPABILITY_IAM"]
        Parameter overrides          : {}
        Signing Profiles             : {}

Initiating deployment
=====================

        Uploading to hmnsd-function-sam-docker/cf5fbab5d2d0db0c30d51305742847b1.template  894 / 894  (100.00%)


Waiting for changeset to be created..

CloudFormation stack changeset
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Operation                                 LogicalResourceId                         ResourceType                              Replacement
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
+ Add                                     HelloWorldFunction                        AWS::Lambda::Function                     N/A
---------------------------------------------------------------------------------------------------------------------------------------------------------------------


Changeset created successfully. arn:aws:cloudformation:us-east-1:123123123:changeSet/samcli-deploy1743155799/634ed742-94be-4754-8fbf-756ef5e32326


Previewing CloudFormation changeset before deployment
======================================================
Deploy this changeset? [y/N]: y

2025-03-28 16:57:13 - Waiting for stack create/update to complete

CloudFormation events from stack operations (refresh every 5.0 seconds)
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
ResourceStatus                            ResourceType                              LogicalResourceId                         ResourceStatusReason
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE_IN_PROGRESS                        AWS::CloudFormation::Stack                hmnsd-function-sam-docker                 User Initiated
CREATE_IN_PROGRESS                        AWS::Lambda::Function                     HelloWorldFunction                        -
CREATE_IN_PROGRESS                        AWS::Lambda::Function                     HelloWorldFunction                        Resource creation Initiated
CREATE_IN_PROGRESS -                      AWS::Lambda::Function                     HelloWorldFunction                        Eventual consistency check initiated
CONFIGURATION_COMPLETE
CREATE_IN_PROGRESS -                      AWS::CloudFormation::Stack                hmnsd-function-sam-docker                 Eventual consistency check initiated
CONFIGURATION_COMPLETE
CREATE_COMPLETE                           AWS::Lambda::Function                     HelloWorldFunction                        -
CREATE_COMPLETE                           AWS::CloudFormation::Stack                hmnsd-function-sam-docker                 -
---------------------------------------------------------------------------------------------------------------------------------------------------------------------


Successfully created/updated stack - hmnsd-function-sam-docker in us-east-1
```

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-lambda-local-dev-docker-remote-created.jpg)


Clear resource:

```sh
$ sam delete --stack-name hmnsd-function-sam-docker
        Are you sure you want to delete the stack hmnsd-function-sam-docker in the region us-east-1 ? [y/N]: y
        Are you sure you want to delete the folder hmnsd-function-sam-docker in S3 which contains the artifacts? [y/N]: y
        - Deleting ECR image helloworldfunction-f16aa71e2c5c-v1 in repository lambda-deployment/hmnsd-function-sam-docker
        - Deleting S3 object with key hmnsd-function-sam-docker/5e300dfdd830ff4122c2b92260e64bae.template
        - Deleting S3 object with key hmnsd-function-sam-docker/7c164e8dad7b06478d5f2c8665586c04.template
        - Deleting S3 object with key hmnsd-function-sam-docker/cf5fbab5d2d0db0c30d51305742847b1.template
        - Deleting Cloudformation stack hmnsd-function-sam-docker

Deleted successfully
```

## 3.2. Work with Environment variables

### 3.2.1. Nếu bạn cần run local invoke với những biến môi trường tại local

Tạo file `env.local.json`:

```json
{
    "HmnsdFunction": {
        "SOME_VAR": "123 from env.local.json"
    }
}
```
Trong Lambda function retrieve env bằng os kiểu như bình thường:

```s
....
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": f"hello world. {os.getenv('SOME_VAR')}",
            # "location": ip.text.replace("\n", "")
        }),
    }
```

Khi run local invoke thì run như này:

```sh
$ sam local invoke --env-vars env.local.json

Invoking Container created from helloworldfunction:v1
Building image.................
Using local image: helloworldfunction:rapid-x86_64.

START RequestId: 574933c3-de87-487e-8a76-b6f6a563b996 Version: $LATEST
END RequestId: f9e2fc83-8a1f-4dfb-8636-19e80f26c811
REPORT RequestId: f9e2fc83-8a1f-4dfb-8636-19e80f26c811  Init Duration: 0.12 ms  Duration: 24.07 ms      Billed Duration: 25 ms                                                                                   Memory Size: 128 MB      Max Memory Used: 128 MB
{"statusCode": 200, "body": "{\"message\": \"hello world. 123 from env.local.json\"}"}
```

### 3.2.2. Nếu bạnmuốn mỗi lần `sam deploy` sẽ không overide Lambda env varialbes

Hiện tại Dev ở local có 1 file env riêng, trên AWS Lambda có 1 set các env đã đc configured riêng.

Nếu muốn mỗi khi dev `sam deploy` **KHÔNG** làm thay đổi Lambda env đã set thì, Developer cần run command sau:

```sh
sam deploy --no-confirm-changeset
```

ChatGPT còn suggest 1 cách khác:

```yaml
Parameters:
  UpdateEnvVariables:
    Type: String
    Default: 'false' # false = keep currently env variables set on AWS Lambda console
    AllowedValues:
      - 'true'
      - 'false'

Conditions:
  ShouldUpdateEnv:
    !Equals [!Ref UpdateEnvVariables, 'true']

Resources:
  HmnsdDockerFunction:
    Type: AWS::Serverless::Function # More info about Function Resource: https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md#awsserverlessfunction
    Properties:
      Description: Lambda function run on Container image
      PackageType: Image
      ImageConfig:
        Command: ["app.lambda_handler"]
      MemorySize: 512
      EphemeralStorage: 
        Size: 512
      Environment:
        SOME_VAR: !If [ShouldUpdateEnv, 'new_value', !Ref "AWS::NoValue"]
```

### 3.3. Troubleshoot & Debug

Giả sử bạn vừa build image bằng `sam build`

Muốn exec vào xem các fodler, package trong image đó để ở đâu

```sh
$ sam build

$ docker images
REPOSITORY                     TAG       IMAGE ID       CREATED          SIZE
hmnsddockerfunction            v1        c6af27ee2acd   11 seconds ago   972MB

$ docker run -it --name my_temp_container hmnsddockerfunction:v1 /bin/bash
30 Mar 2025 09:54:18,772 [INFO] (rapid) exec '/var/runtime/bootstrap' (cwd=/var/task, handler=)
```

Sau đó vào Docker Desktop xem các package như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-lambda-local-dev-docker-image-inspect.jpg)



# REFERENCES

https://dev.to/skabba/mastering-local-aws-lambda-development-18mg

https://dev.to/randiakm/developing-aws-lambda-functions-locally-4iam

