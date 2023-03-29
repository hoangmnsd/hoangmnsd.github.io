---
title: "Secure API Gateway by AWS Cognito User Pool (in ReactJS based Gatsby App)"
date: 2021-07-31T09:53:45+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [GatsbyJS,AWS,APIGateway,Cognito]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bài này giải thích về cách secure API Gateway enpoint bằng cách dùng Cognito User Pool Authorizer. "
---

# Giới thiệu

Bài này giải thích về cách secure API Gateway enpoint bằng cách dùng Cognito User Pool Authorizer.  
Frontend trong bài này sử dụng Reacjs nhé.  
API Gateway của AWS thì có 2 loại chia theo protocol: HTTP API và REST API (Bài này nói về REST API). 

# Yêu cầu

Các bạn cần có base kiến thức về ReactJS 1 chút, biết làm thế nào để viết 1 component, export nó ra như nào, 
làm sao để apply authenticate vào Gatsby, cách viết 1 component, create pages, pass `props` qua các page, export page ...

Đã tạo 1 Cognito User Pool,
các bạn nên hoàn thành hoặc đọc qua bài này trước để biết cách integrate AWS Cognito vào Gatsby website:  
[Integrate AWS Cognito to Gatsby Website](../../posts/integrate-aws-cognito-to-gatsby-website/)

Bạn cũng cần đã biết về cách config API Gateway REST, đã tạo được RESOURCES, METHOD và integrate được nó với Lambda function.

# Cách làm

Backend của chúng ta chuẩn bị 1 hàm Lambda đơn giản như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-rest-cognito-uspool-lambda.jpg)

Config trong API Gateway REST:  
Tạo 1 resource `/interact` và method POST cho nó  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-rest-cognito-uspool-authorizer-resources-interact.jpg)  

method OPTION được tạo ra 1 cách tự động nên bạn ko cần động đến nó làm gì nhé.  

Sau đó integrate nó với hàm Lambda mà chúng ta đã chuẩn bị ở trên
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-rest-cognito-uspool-authorizer-post-integrate-lambda.jpg)  

Vào tab `Authorizers`, tạo 1 cái Authorizer, nhớ chọn Cognito User Pool mà bạn đã có, chú ý chỗ Token Source điền `Authorization` nhé:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-rest-cognito-uspool-authorizer-create0.jpg)

Quay lại tab `Resources`, chọn Method POST -> Method Request, phần Authorization hãy chọn cái Authorizer mà bạn vừa tạo ở trên:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-rest-cognito-uspool-authorizer-resource-post.jpg)

Save xong thì quay lại, màn hình của resource `/interact` nó sẽ như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-rest-cognito-uspool-authorizer1.jpg)

Enable CORS và deploy lại API Gateway:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-rest-cognito-uspool-authorizer-cors.jpg)  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-rest-cognito-uspool-authorizer-deploy.jpg)


Trong code của Frontend thì cần đưa `token` vào trong header như sau, dưới đây là code cho 1 component. Tên file là `InteractRestApiGW.js`:    
```js
import React, { useState } from 'react';

import { useForm } from 'react-hook-form';

const GATEWAY_URL = "https://xxxxxxxxx.execute-api.us-east-1.amazonaws.com/dev/interact"; // REST API Gateway (API has applied Authorizer already)
var msgFromLambda = "Nothing, something go wrong..";

const InteractRestApiGW = ({ token }) => {
    const [submitted, setSubmitted] = useState(false);
    
    const {
        register,
        handleSubmit,
        setError,
        reset,
        formState: { errors, isSubmitting }
    } = useForm();

    const onSubmit = async data => {
        const payload = {
            "message": {
                "name": data.myName,
            }
        }

        try {
            const response = await fetch(GATEWAY_URL, {
                method: "POST",
                mode: "cors",
                contentType: "application/json",
                body: JSON.stringify(payload),
                headers: {
                    "Content-type": "application/json; charset=UTF-8",
                    "Accept": "application/json",
                    "Authorization": token,
                }
            });
            const result = await response.json();
            msgFromLambda = result.text
            setSubmitted(true);
            reset();
        } catch (error) {
            setError(
                "submit",
                "submitError",
                `Oops! There seems to be an issue! ${error.message}`
            );
        }
    };

    const showThankYou = (
        <div className="msg-confirm">
            <p>Awesome! Your command was sent. The response is: </p> 
            <p style={{fontWeight: "bold"}}>{msgFromLambda}</p>
            <p style={{fontSize: '13px'}}><i>If the response is a Hello your name from Lambda, it means Backend recognized you. Congras!
                Otherwise, please debug it for more detail...</i></p>
            <button className="btn btn-info my-3" type="button" onClick={() => setSubmitted(false)}>
                Send another command?
            </button>
        </div>
    );

    const showSubmitError = msg => <p className="msg-error">{msg}</p>;

    const showForm = (
        <form onSubmit={handleSubmit(onSubmit)} method="post">
            <p>This text box send command to REST API Gateway URL
                (which is applied Cognito User Pool Authorizer already.
                It means if someone has URL, they still can not send requests to it unless they authenticated this page): </p>
            <label htmlFor="myName">
                <input
                    className="form-control"
                    type="myName"
                    name="myName"
                    id="myName"
                    placeholder="Your name"
                    {...register("myName", {
                        required: "Dont forget your name!",
                    })}
                    disabled={isSubmitting}
                />
                {errors.myName && <div className="msg-error">{errors.myName.message}</div>}
            </label>
            <div className="submit-wrapper">
                <button className="btn btn-info my-3" type="submit" disabled={isSubmitting}>Send command</button>
            </div>
        </form>
    );

    return (
        <div className="container my-4">
            {errors && errors.submit && showSubmitError(errors.submit.message)}
            <div className="form-side">{submitted ? showThankYou : showForm}</div>
        </div>
    )
}

export default InteractRestApiGW
```

Có thể các bạn sẽ tự hỏi `token` lấy đâu ra?  
Trả lời: Thì để có token này bạn cũng cần sửa nơi các bạn apply Authentication 1 chút.  

Giả sử đây là code của Home Page (index.js) của bạn, như bạn thấy chúng ta đã import component `InteractRestApiGW` vừa tạo ra ở trên, sử dụng nó gần cuối đoạn code, và truyền biến `token` lấy từ `props` của quá trình authen đến Cognito:  

```js
import React from 'react'
import { SignIn, SignOut } from "@hoangmnsd/gatsby-theme-amplify-cognito";
import InteractRestApiGW from '../components/InteractRestApiGW';

const PrivateSpace = props => {
    return (
        (props.authState !== "signedIn") ?
            <SignIn authState={props.authState} /> :
                <SignOut />
                <div className="container about my-5">
                    <h1 className="font-weight-bold">Hello my friend,</h1>
                    <h2>This space requires an authenticated user</h2>
                    <InteractRestApiGW 
                        token={props.authData.signInUserSession.idToken.jwtToken}
                    />
                </div>
    )
}

export default PrivateSpace

```

Phần UI của đoạn code trên như sau:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-rest-cognito-uspool-authorizer-ui-reactjs.jpg)

Khi bạn nhập tên vào chỗ Your name, App sẽ gửi request đến API Gateway, trong header của request đó có token của bạn, token này bạn lấy được sau khi login bằng Cognito identity. Nếu ko có token đó, API Gateway sẽ ko trả về kết quả. Như vậy là secure rồi đúng ko?

API gửi tên bạn (vừa nhập vào) đến backend cho Lambda xử lý, Lambda trả về respone và gửi lại kết quả cho APIGateway, từ đó trả về cho bạn nội dung "Hello <your-name> from Lambda" như hình sau:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-rest-cognito-uspool-authorizer-ui-reactjs-response.jpg)

Nói thì có vẻ khó hiểu, nhưng nhìn hình sau các bạn chắc sẽ thấy đơn giản:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/apigw-rest-cognito-uspool-authorizer-diagram.jpg)

Done!

# CREDITS

https://seifi.org/reactjs/build-a-contact-form-in-gatsby-part-2-react-hook-form.html  
https://seifi.org/aws/build-a-contact-form-in-gatsby-part-1-aws-lambda-simple-email-service-and-api-gateway.html  
https://github.com/bengladwell/inside-story  
https://www.bengladwell.com/gatsby-site-with-authentication/  