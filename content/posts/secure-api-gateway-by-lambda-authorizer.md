---
title: "Secure API Gateway by Lambda Authorizer"
date: 2019-07-29T09:53:45+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [AWS,APIGateway,Lambda]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bài này sẽ giải thích cách Secure API Gateway bằng Lambda Authorizer đơn giản. "
---
Bài này sẽ giải thích cách Secure API Gateway bằng Lambda Authorizer đơn giản. 

Nếu API không được secure thì bất cứ ai có API URL cũng có thể gửi request đến server và lấy được data trong DynamoDB của mình.

Nên cần phải setup Authorization cho API Gateway.

## 1. Tạo table trong DynamoDB
Table name: authors

Primary key: id

Tạo vài item trong table authors
```sh
{
  "firstName": "Hoang",
  "id": "le-hoang",
  "lastName": "Le"
},
{
  "id": "linoel-messi",
  "firstName": "lionel",
  "lastName": "messi"
},
{
  "id": "jonesta-smaldini",
  "firstName": "jonesta",
  "lastName": "smaldini"
},
{
  "firstName": "Fred",
  "id": "fred",
  "lastName": "the-red"
}
```
## 2. Tạo role cho Lambda function
Đoạn code bên dưới bạn cần sửa `region` và `accountId` phù hợp với môi trường bạn đang test:
ví dụ `region` = us-east-1, `accountId` = 923423492348

```sh
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:Scan",
                "dynamodb:UpdateItem"
            ],
            "Resource": "arn:aws:dynamodb:region:accountId:table/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
```
## 3. Tạo Lambda function "get-all-authors-py" để get all thông tin user từ DynamoDB
Gắn Role vừa tạo ở Step 2 vào.

Nội dung function viết bằng python 3.7:
```sh
import boto3
import json

print('Loading function')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('authors')

def respond(err, res=None):
    return {
        'statusCode': '400' if err else '200',
        'body': err.message if err else  json.dumps(res),
        'headers': {
            'Content-Type': 'application/json',
        },
    }
def lambda_handler(event, context):
    scan_response = table.scan()
    print(scan_response)
    # return respond(None, scan_response['Items'])
    return scan_response['Items']
```
## 4. Setup API Gateway
Tạo resource: /authors

Trong resource /authors, tạo method GET

Phần Integration Request chọn Lambda function vừa tạo `get-all-authors-py`

Ban đầu chưa cần setup Authorization cho method này nên hãy để NONE (ảnh)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-setup-get-not-authorization.jpg)

Test thử xem lấy được data là OK (ảnh)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-setup-get-not-authorization-test.jpg)

Deploy API

## 5. Secure API Gateway bằng Lambda Authorizer (Cách 1, Đơn giản)
Bản chất là mình sẽ tạo thêm 1 function Lambda nữa để nó handler các request gửi tới API Gateway, 
nhiệm vụ là xác định request đó có hợp lệ không, 
nếu hợp lệ thì mới từ API Gateway chuyển request đến Lambda function `get-all-authors-py`.

### 5.1. Tạo 1 Lambda function để thực hiện nhiệm vụ Authorizer
Tên function: "tokenBasedLambdaAuthorizerBasic".
Gắn Role vừa tạo ở Step 2 vào.

Source này mình lấy từ Blueprint của AWS (blueprint là những template AWS recommend mình sử dụng), thêm 1 đoạn code nhỏ: 

Nếu Header của request mà có authorizationToken="what-the-fuck" thì dc allowAllMethods, ngược lại thì denyAllMethods

```sh
"""
Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at

     http://aws.amazon.com/apache2.0/

or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
"""
from __future__ import print_function

import re
import time, datetime
import pprint
import json


def lambda_handler(event, context):
    print("Client token: " + event['authorizationToken'])
    print("Method ARN: " + event['methodArn'])
    """validate the incoming token"""
    """and produce the principal user identifier associated with the token"""
    # Hoang start
    token=event["authorizationToken"]
    principalId = token
    print("principalId: " + principalId)
    # Hoang end

    """this could be accomplished in a number of ways:"""
    """1. Call out to OAuth provider"""
    """2. Decode a JWT token inline"""
    """3. Lookup in a self-managed DB"""
    # principalId = "user|a1b2c3d4"

    """you can send a 401 Unauthorized response to the client by failing like so:"""
    """raise Exception('Unauthorized')"""

    """if the token is valid, a policy must be generated which will allow or deny access to the client"""

    """if access is denied, the client will recieve a 403 Access Denied response"""
    """if access is allowed, API Gateway will proceed with the backend integration configured on the method that was called"""

    """this function must generate a policy that is associated with the recognized principal user identifier."""
    """depending on your use case, you might store policies in a DB, or generate them on the fly"""

    """keep in mind, the policy is cached for 5 minutes by default (TTL is configurable in the authorizer)"""
    """and will apply to subsequent calls to any method/resource in the RestApi"""
    """made with the same token"""

    """the example policy below denies access to all resources in the RestApi"""
    tmp = event['methodArn'].split(':')
    apiGatewayArnTmp = tmp[5].split('/')
    awsAccountId = tmp[4]

    policy = AuthPolicy(principalId, awsAccountId)
    policy.restApiId = apiGatewayArnTmp[0]
    policy.region = tmp[3]
    policy.stage = apiGatewayArnTmp[1]
    # Hoang start
    if (principalId == "what-the-fuck"):
        policy.allowAllMethods()
    else:
        policy.denyAllMethods()
    # Hoang end
    """policy.allowMethod(HttpVerb.GET, "/pets/*")"""

    # Finally, build the policy
    authResponse = policy.build()
 
    # new! -- add additional key-value pairs associated with the authenticated principal
    # these are made available by APIGW like so: $context.authorizer.<key>
    # additional context is cached
    context = {
        'key': 'value', # $context.authorizer.key -> value
        'number' : 1,
        'bool' : True
    }
    # context['arr'] = ['foo'] <- this is invalid, APIGW will not accept it
    # context['obj'] = {'foo':'bar'} <- also invalid
 
    authResponse['context'] = context
    
    return authResponse

class HttpVerb:
    GET     = "GET"
    POST    = "POST"
    PUT     = "PUT"
    PATCH   = "PATCH"
    HEAD    = "HEAD"
    DELETE  = "DELETE"
    OPTIONS = "OPTIONS"
    ALL     = "*"

class AuthPolicy(object):
    awsAccountId = ""
    """The AWS account id the policy will be generated for. This is used to create the method ARNs."""
    principalId = ""
    """The principal used for the policy, this should be a unique identifier for the end user."""
    version = "2012-10-17"
    """The policy version used for the evaluation. This should always be '2012-10-17'"""
    pathRegex = "^[/.a-zA-Z0-9-\*]+$"
    """The regular expression used to validate resource paths for the policy"""

    """these are the internal lists of allowed and denied methods. These are lists
    of objects and each object has 2 properties: A resource ARN and a nullable
    conditions statement.
    the build method processes these lists and generates the approriate
    statements for the final policy"""
    allowMethods = []
    denyMethods = []

    restApiId = "*"
    """The API Gateway API id. By default this is set to '*'"""
    region = "*"
    """The region where the API is deployed. By default this is set to '*'"""
    stage = "*"
    """The name of the stage used in the policy. By default this is set to '*'"""

    def __init__(self, principal, awsAccountId):
        self.awsAccountId = awsAccountId
        self.principalId = principal
        self.allowMethods = []
        self.denyMethods = []

    def _addMethod(self, effect, verb, resource, conditions):
        """Adds a method to the internal lists of allowed or denied methods. Each object in
        the internal list contains a resource ARN and a condition statement. The condition
        statement can be null."""
        if verb != "*" and not hasattr(HttpVerb, verb):
            raise NameError("Invalid HTTP verb " + verb + ". Allowed verbs in HttpVerb class")
        resourcePattern = re.compile(self.pathRegex)
        if not resourcePattern.match(resource):
            raise NameError("Invalid resource path: " + resource + ". Path should match " + self.pathRegex)

        if resource[:1] == "/":
            resource = resource[1:]

        resourceArn = ("arn:aws:execute-api:" +
            self.region + ":" +
            self.awsAccountId + ":" +
            self.restApiId + "/" +
            self.stage + "/" +
            verb + "/" +
            resource)

        if effect.lower() == "allow":
            self.allowMethods.append({
                'resourceArn' : resourceArn,
                'conditions' : conditions
            })
        elif effect.lower() == "deny":
            self.denyMethods.append({
                'resourceArn' : resourceArn,
                'conditions' : conditions
            })

    def _getEmptyStatement(self, effect):
        """Returns an empty statement object prepopulated with the correct action and the
        desired effect."""
        statement = {
            'Action': 'execute-api:Invoke',
            'Effect': effect[:1].upper() + effect[1:].lower(),
            'Resource': []
        }

        return statement

    def _getStatementForEffect(self, effect, methods):
        """This function loops over an array of objects containing a resourceArn and
        conditions statement and generates the array of statements for the policy."""
        statements = []

        if len(methods) > 0:
            statement = self._getEmptyStatement(effect)

            for curMethod in methods:
                if curMethod['conditions'] is None or len(curMethod['conditions']) == 0:
                    statement['Resource'].append(curMethod['resourceArn'])
                else:
                    conditionalStatement = self._getEmptyStatement(effect)
                    conditionalStatement['Resource'].append(curMethod['resourceArn'])
                    conditionalStatement['Condition'] = curMethod['conditions']
                    statements.append(conditionalStatement)

            statements.append(statement)

        return statements

    def allowAllMethods(self):
        """Adds a '*' allow to the policy to authorize access to all methods of an API"""
        self._addMethod("Allow", HttpVerb.ALL, "*", [])

    def denyAllMethods(self):
        """Adds a '*' allow to the policy to deny access to all methods of an API"""
        self._addMethod("Deny", HttpVerb.ALL, "*", [])

    def allowMethod(self, verb, resource):
        """Adds an API Gateway method (Http verb + Resource path) to the list of allowed
        methods for the policy"""
        self._addMethod("Allow", verb, resource, [])

    def denyMethod(self, verb, resource):
        """Adds an API Gateway method (Http verb + Resource path) to the list of denied
        methods for the policy"""
        self._addMethod("Deny", verb, resource, [])

    def allowMethodWithConditions(self, verb, resource, conditions):
        """Adds an API Gateway method (Http verb + Resource path) to the list of allowed
        methods and includes a condition for the policy statement. More on AWS policy
        conditions here: http://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements.html#Condition"""
        self._addMethod("Allow", verb, resource, conditions)

    def denyMethodWithConditions(self, verb, resource, conditions):
        """Adds an API Gateway method (Http verb + Resource path) to the list of denied
        methods and includes a condition for the policy statement. More on AWS policy
        conditions here: http://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements.html#Condition"""
        self._addMethod("Deny", verb, resource, conditions)

    def build(self):
        """Generates the policy document based on the internal lists of allowed and denied
        conditions. This will generate a policy with two main statements for the effect:
        one statement for Allow and one statement for Deny.
        Methods that includes conditions will have their own statement in the policy."""
        if ((self.allowMethods is None or len(self.allowMethods) == 0) and
            (self.denyMethods is None or len(self.denyMethods) == 0)):
            raise NameError("No statements defined for the policy")

        policy = {
            'principalId' : self.principalId,
            'policyDocument' : {
                'Version' : self.version,
                'Statement' : []
            }
        }

        policy['policyDocument']['Statement'].extend(self._getStatementForEffect("Allow", self.allowMethods))
        policy['policyDocument']['Statement'].extend(self._getStatementForEffect("Deny", self.denyMethods))

        return policy
```
### 5.2. Setup Authorizer trong API Gateway
Trong API Gateway, vào phần Authorizer, tạo 1 Authorizer tên `coursesLambdaAuthorizer` như sau (ảnh):
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/api-gateway-authorizer.jpg)

Vào phần Resource /authors, sửa Method Request GET như sau (ảnh):
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-resource-get-authors-method-request.jpg)

Enable CORS, sửa cái Access-Control-Allow-Headers lại bằng giá trị mình đã set ở Authorizer như hình sau (ảnh):
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-enable-cors.jpg)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-enable-cors-2.jpg)

Deploy lại API.

### 5.3. Test method GET trên Postman
Nếu test trên console thì mặc định AWS sẽ bypass cái Authorizer luôn, nên phải test trên Postman

Nếu ko truyền gì vào Header `authorizationToken` thì message nội dung sẽ là unauthorized (ảnh)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-test-authorizer-postman-1.jpg)

Nếu truyền "what-the-fuck" vào sẽ lấy được data (ảnh)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-test-authorizer-postman-2.jpg)

Nếu truyền linh tinh thì message nội dung deny (ảnh)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-test-authorizer-postman-3.jpg)

## 6. Secure API Gateway bằng Lambda Authorizer (Cách 2, dùng encode và decode JWT)
### 6.1. Tạo 1 Lambda function để thực hiện nhiệm vụ Authorizer
Cách tạo như sau, vì cần import thư viện bên ngoài (jwt), ko có sẵn của AWS Lambda nên phải làm cách này:

Vào Lambda tạo 1 function trống tên "tokenBasedLambdaAuthorizer", 
Gắn role dc tạo từ Step 2, rồi để đó.

Dựng 1 Ec2 từ ami này "ami-0080e4c5bc078760e"

SSH vào Ec2, tạo lambda function file:
```sh
nano lambda_function.py
```
Đây là fuction được lấy từ blueprint của AWS, rồi mình modifed.

Nội dung add thêm là: 

Đầu tiên decode token nhận dc, từ token đó lấy ra "userRole", nếu "userRole==admin" thì allowAllMethods, còn ko thì denyAllMethods.

```sh
"""
Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at

     http://aws.amazon.com/apache2.0/

or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
"""
from __future__ import print_function

import re
import time, datetime
import pprint
import json
from jose import jwk, jwt
from jose.utils import base64url_decode


def lambda_handler(event, context):
    print("Client token: " + event['authorizationToken'])
    print("Method ARN: " + event['methodArn'])
    """validate the incoming token"""
    """and produce the principal user identifier associated with the token"""
    # Hoang start
    secret="my-secret"
    token=event["authorizationToken"]
    decoded=jwt.decode(token, secret,algorithms=['HS256'])
    principalId = decoded["userRole"]
    print("principalId: " + principalId)
    # Hoang end

    """this could be accomplished in a number of ways:"""
    """1. Call out to OAuth provider"""
    """2. Decode a JWT token inline"""
    """3. Lookup in a self-managed DB"""
    # principalId = "user|a1b2c3d4"

    """you can send a 401 Unauthorized response to the client by failing like so:"""
    """raise Exception('Unauthorized')"""

    """if the token is valid, a policy must be generated which will allow or deny access to the client"""

    """if access is denied, the client will recieve a 403 Access Denied response"""
    """if access is allowed, API Gateway will proceed with the backend integration configured on the method that was called"""

    """this function must generate a policy that is associated with the recognized principal user identifier."""
    """depending on your use case, you might store policies in a DB, or generate them on the fly"""

    """keep in mind, the policy is cached for 5 minutes by default (TTL is configurable in the authorizer)"""
    """and will apply to subsequent calls to any method/resource in the RestApi"""
    """made with the same token"""

    """the example policy below denies access to all resources in the RestApi"""
    tmp = event['methodArn'].split(':')
    apiGatewayArnTmp = tmp[5].split('/')
    awsAccountId = tmp[4]

    policy = AuthPolicy(principalId, awsAccountId)
    policy.restApiId = apiGatewayArnTmp[0]
    policy.region = tmp[3]
    policy.stage = apiGatewayArnTmp[1]
    # Hoang start
    if (principalId == "admin"):
        policy.allowAllMethods()
    else:
        policy.denyAllMethods()
    # Hoang end
    """policy.allowMethod(HttpVerb.GET, "/pets/*")"""

    # Finally, build the policy
    authResponse = policy.build()
 
    # new! -- add additional key-value pairs associated with the authenticated principal
    # these are made available by APIGW like so: $context.authorizer.<key>
    # additional context is cached
    context = {
        'key': 'value', # $context.authorizer.key -> value
        'number' : 1,
        'bool' : True
    }
    # context['arr'] = ['foo'] <- this is invalid, APIGW will not accept it
    # context['obj'] = {'foo':'bar'} <- also invalid
 
    authResponse['context'] = context
    
    return authResponse

class HttpVerb:
    GET     = "GET"
    POST    = "POST"
    PUT     = "PUT"
    PATCH   = "PATCH"
    HEAD    = "HEAD"
    DELETE  = "DELETE"
    OPTIONS = "OPTIONS"
    ALL     = "*"

class AuthPolicy(object):
    awsAccountId = ""
    """The AWS account id the policy will be generated for. This is used to create the method ARNs."""
    principalId = ""
    """The principal used for the policy, this should be a unique identifier for the end user."""
    version = "2012-10-17"
    """The policy version used for the evaluation. This should always be '2012-10-17'"""
    pathRegex = "^[/.a-zA-Z0-9-\*]+$"
    """The regular expression used to validate resource paths for the policy"""

    """these are the internal lists of allowed and denied methods. These are lists
    of objects and each object has 2 properties: A resource ARN and a nullable
    conditions statement.
    the build method processes these lists and generates the approriate
    statements for the final policy"""
    allowMethods = []
    denyMethods = []

    restApiId = "*"
    """The API Gateway API id. By default this is set to '*'"""
    region = "*"
    """The region where the API is deployed. By default this is set to '*'"""
    stage = "*"
    """The name of the stage used in the policy. By default this is set to '*'"""

    def __init__(self, principal, awsAccountId):
        self.awsAccountId = awsAccountId
        self.principalId = principal
        self.allowMethods = []
        self.denyMethods = []

    def _addMethod(self, effect, verb, resource, conditions):
        """Adds a method to the internal lists of allowed or denied methods. Each object in
        the internal list contains a resource ARN and a condition statement. The condition
        statement can be null."""
        if verb != "*" and not hasattr(HttpVerb, verb):
            raise NameError("Invalid HTTP verb " + verb + ". Allowed verbs in HttpVerb class")
        resourcePattern = re.compile(self.pathRegex)
        if not resourcePattern.match(resource):
            raise NameError("Invalid resource path: " + resource + ". Path should match " + self.pathRegex)

        if resource[:1] == "/":
            resource = resource[1:]

        resourceArn = ("arn:aws:execute-api:" +
            self.region + ":" +
            self.awsAccountId + ":" +
            self.restApiId + "/" +
            self.stage + "/" +
            verb + "/" +
            resource)

        if effect.lower() == "allow":
            self.allowMethods.append({
                'resourceArn' : resourceArn,
                'conditions' : conditions
            })
        elif effect.lower() == "deny":
            self.denyMethods.append({
                'resourceArn' : resourceArn,
                'conditions' : conditions
            })

    def _getEmptyStatement(self, effect):
        """Returns an empty statement object prepopulated with the correct action and the
        desired effect."""
        statement = {
            'Action': 'execute-api:Invoke',
            'Effect': effect[:1].upper() + effect[1:].lower(),
            'Resource': []
        }

        return statement

    def _getStatementForEffect(self, effect, methods):
        """This function loops over an array of objects containing a resourceArn and
        conditions statement and generates the array of statements for the policy."""
        statements = []

        if len(methods) > 0:
            statement = self._getEmptyStatement(effect)

            for curMethod in methods:
                if curMethod['conditions'] is None or len(curMethod['conditions']) == 0:
                    statement['Resource'].append(curMethod['resourceArn'])
                else:
                    conditionalStatement = self._getEmptyStatement(effect)
                    conditionalStatement['Resource'].append(curMethod['resourceArn'])
                    conditionalStatement['Condition'] = curMethod['conditions']
                    statements.append(conditionalStatement)

            statements.append(statement)

        return statements

    def allowAllMethods(self):
        """Adds a '*' allow to the policy to authorize access to all methods of an API"""
        self._addMethod("Allow", HttpVerb.ALL, "*", [])

    def denyAllMethods(self):
        """Adds a '*' allow to the policy to deny access to all methods of an API"""
        self._addMethod("Deny", HttpVerb.ALL, "*", [])

    def allowMethod(self, verb, resource):
        """Adds an API Gateway method (Http verb + Resource path) to the list of allowed
        methods for the policy"""
        self._addMethod("Allow", verb, resource, [])

    def denyMethod(self, verb, resource):
        """Adds an API Gateway method (Http verb + Resource path) to the list of denied
        methods for the policy"""
        self._addMethod("Deny", verb, resource, [])

    def allowMethodWithConditions(self, verb, resource, conditions):
        """Adds an API Gateway method (Http verb + Resource path) to the list of allowed
        methods and includes a condition for the policy statement. More on AWS policy
        conditions here: http://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements.html#Condition"""
        self._addMethod("Allow", verb, resource, conditions)

    def denyMethodWithConditions(self, verb, resource, conditions):
        """Adds an API Gateway method (Http verb + Resource path) to the list of denied
        methods and includes a condition for the policy statement. More on AWS policy
        conditions here: http://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements.html#Condition"""
        self._addMethod("Deny", verb, resource, conditions)

    def build(self):
        """Generates the policy document based on the internal lists of allowed and denied
        conditions. This will generate a policy with two main statements for the effect:
        one statement for Allow and one statement for Deny.
        Methods that includes conditions will have their own statement in the policy."""
        if ((self.allowMethods is None or len(self.allowMethods) == 0) and
            (self.denyMethods is None or len(self.denyMethods) == 0)):
            raise NameError("No statements defined for the policy")

        policy = {
            'principalId' : self.principalId,
            'policyDocument' : {
                'Version' : self.version,
                'Statement' : []
            }
        }

        policy['policyDocument']['Statement'].extend(self._getStatementForEffect("Allow", self.allowMethods))
        policy['policyDocument']['Statement'].extend(self._getStatementForEffect("Deny", self.denyMethods))

        return policy
```

### 6.2. Rồi run các command sau để đóng package lambda với thư viện jwt bên ngoài lại
```sh
pip install --target ./package python-jose
cd package/
zip -r9 ${OLDPWD}/lambda_function.zip .
cd ..
zip -g lambda_function.zip lambda_function.py
```
### 6.3. Rồi giờ up file zip này lên AWS Lambda
```sh
aws lambda update-function-code --function-name tokenBasedLambdaAuthorizer --zip-file fileb://lambda_function.zip --region us-east-1
```
Vào nhìn nó sẽ có 1 đống thư viện ở bên cạnh như này:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/lamba-with-jwt-lib.jpg)

### 6.5. Setup Authorizer trong API Gateway
Trong API Gateway tạo 1 Authorizer như sau:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/api-gateway-authorizer-jwt.jpg)

Đối với Method GET của resource /authors, add cái authorizer vừa tạo vào phần Authorization
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-resource-get-authors-method-request-jwt.jpg)

Enable CORS, sửa cái Access-Control-Allow-Origin lại bằng giá trị mình đã set ở Authorizer
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-enable-cors-jwt.jpg)

Deploy API.

### 6.6. Test method GET trên Postman
Nếu test trên console thì mặc định AWS sẽ bypass cái Authorizer luôn, nên phải test trên Postman.

Trước tiên cần tạo token để Lambda function có thể decode.

Vào jwt.io để tạo token, sửa code bên Decoded để tạo token ở cột Encoded.
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/jwt-io-encoded.jpg)

Tạo dc token rồi thì vào Postman test

Gửi đúng token của admin thì sẽ lấy dc data:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-test-authorizer-postman-jwt-1.jpg)

Token mà sai thì nhận dc thông báo:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-test-authorizer-postman-jwt-2.jpg)

Không gửi token mà gửi linh tinh thì nhận dc cái sau:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-test-authorizer-postman-jwt-3.jpg)

Done!

Ngoài ra, 1 số web có ích, demo hoàn chỉnh về dùng Google-sigin button với API Gateway: 
https://blog.codecentric.de/en/2018/04/aws-lambda-authorizer/


## Source tham khảo

Step 5:

https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html

https://medium.com/@checko/how-to-create-an-aws-lambda-authorizer-for-api-gateway-45df4745a0e

https://github.com/awslabs/aws-apigateway-lambda-authorizer-blueprints/blob/master/blueprints/python/api-gateway-authorizer-python.py

Step 6:

http://www.awsomeblog.com/api-gateway-custom-authorization/

https://github.com/awslabs/aws-apigateway-lambda-authorizer-blueprints/blob/master/blueprints/python/api-gateway-authorizer-python.py

https://blog.codecentric.de/en/2018/04/aws-lambda-authorizer/

https://github.com/awslabs/aws-support-tools/issues/34

https://docs.aws.amazon.com/lambda/latest/dg/lambda-python-how-to-create-deployment-package.html


