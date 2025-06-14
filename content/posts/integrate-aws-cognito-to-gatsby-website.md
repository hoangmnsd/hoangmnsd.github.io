---
title: "Integrate AWS Cognito to Gatsby Website"
date: 2021-07-25T16:40:11+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [GatsbyJS,Cognito,AWS]
comments: false
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Gần đây khi tìm hiểu về frontend thì mình biết rằng Hugo không thể cung cấp tính năng Authenticate cho website của mình."
---

# 1. Giới thiệu

Gần đây khi tìm hiểu về frontend thì mình biết rằng Hugo không thể cung cấp tính năng Authenticate cho website của mình.
Vì bản thân Hugo là 1 Static Site Generator (SSG), nó ko có trách nhiệm biến website của bạn thành dynamic.  

Tiếp tục tìm hiểu thì mình biết thêm về GatsbyJS, cũng là 1 Static Site Generator, nhưng nó based trên ReactJS và có nhiều plugin để biến trang web thành dynamic.  
Ví dụ như mình có thể tích hợp tính năng Login/Logout vào cho 1 website được xây dựng bằng Gatsby 1 cách nhanh chóng.

Mình hướng tới việc xây dựng những website Serverless hoàn toàn, tốn ít công sức tìm hiểu về Framework mới, nên sẽ sử dụng thirdparty authenticator như AWS Cognito.

Cũng như Hugo, Gatsby có 1 cộng đồng rộng lớn, họ đóng góp nhiều những theme đẹp và free cho mọi người. Bạn có thể tham khảo tại đây:  
https://www.gatsbyjs.com/starters/?  
https://gatsbytemplates.io/free/  
https://themejam.gatsbyjs.org/showcase  
https://jamtemplates.com/  
https://github.com/algokun/gatsby_starter_portfolio  
(224) https://jamstackthemes.dev/ssg/gatsby/    
https://github.com/stackbit/jamstackthemes  



# 2. Bắt đầu 

## 2.1. Chọn Theme

Bài này mình sẽ chọn 1 theme free tên là `Serif Gatsby Starter` để demo việc integrate với Cognito.
Github của nó ở đây: https://github.com/zerostaticthemes/gatsby-serif-theme

Tất nhiên để sử dụng Gatsby bạn cần cài đặt 1 số thứ:  
```sh
node –v
npm -v
npm install –global gatsby-cli
```

Clone source của Theme mà ta đã chọn về:
```sh
git clone https://github.com/zerostaticthemes/gatsby-serif-theme
cd gatsby-serif-theme
```

## 2.2. Run local

Run project ở local:  
```sh
npm install
npm start
```

Giờ hãy vào địa chỉ `http://localhost:8000` để xem kết quả:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gatsby-serif-theme-home-default.jpg)

Rất nhanh chóng phải ko các bạn đã có 1 website rất chuyên nghiệp rồi. Giờ chỉ cần thay đổi phần content, hình ảnh nữa.  
Content được đặt trong `/src/content/`, gồm toàn các file Markdown (rất quen thuộc). Bạn thay đổi nội dung của mình vào đó là xong.

## 2.3. Integrate with AWS Cognito

Giờ làm sao để integrate phần Authentication vào?  
Sẽ có lúc các bạn muốn website của mình được bảo vệ, trang Home Page thì ai cũng xem được, nhưng các trang khác thì phải yêu cầu đăng nhập (chẳng hạn như trang Team, About, ...etc).   

Đây là lúc cần chức năng Authentication, nhưng chẳng lẽ lại phải học code ReactJS để thêm tính năng Login, Logout, Sign Up hay sao, rồi Database User nữa sẽ để ở đâu? Nghe có vẻ dễ nhưng vào làm sẽ loẳng ngoằng đấy, nhất là với những bussiness nhỏ muốn mọi thứ cần hoàn thiện nhanh.  

Vì vậy mà Gatsby cung cấp nhiều plugin được cộng đồng đóng góp, chỉ cần chỉnh sửa 1 ít, bạn vẫn đem được tính năng Login/Logout vào trang web của mình.

### 2.3.1. Bước 1

đầu tiên install package mới:  
```sh
npm install --save @hoangmnsd/gatsby-theme-amplify-cognito
```
### 2.3.2. Bước 2

Tiếp theo là setup AWS Cognito User Pool và tạo App Client, **Nhớ là đừng chọn `Generate client secret`**:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gatsby-cognito-appclient-setting.jpg)

### 2.3.3. Bước 3

Sửa file `gatsby-config.js` để add plugin vào:  
`gatsby-config.js`
```
module.exports = {
  plugins: [
    {
      resolve: `@hoangmnsd/gatsby-theme-amplify-cognito`,
      options: {
        region: "us-east-1", // replace with region of user pool
        userPoolId: 'us-east-1_OZIxeIDqs",', // replace with user pool id
        identityPoolId: "23ab3gt81t2sanvfg84mh7xnpp", // replace with identity pool associated with user pool
        userPoolWebClientId:
          "us-east-1:bc89f200-299e-4269-8fd2-7caf9e8b0547", // replace with app client id

        // optional, array of paths that won't be authenticated
        doNotAuthenticate: ["/", "/services/"],
      },
    },
  ],
}
```
Trong đoạn code trên, giá trị `identityPoolId` là optional, các bạn có thể để trống.  
Giá trị `doNotAuthenticate` là chứa các path mà mình sẽ ko áp dụng Authenticate (ví dụ trên bao gồm trang Home Page, và Services Page)

### 2.3.4. Bước 4

Giờ add nút SignOut vào Page bạn muốn, mình sẽ sửa file `src\pages\team.js`:  
```
....
import { SignIn, SignOut } from "@hoangmnsd/gatsby-theme-amplify-cognito";
const Team = props => {
  const team = props.data.team.edges;
  const { intro } = props.data;
  const introImageClasses = `intro-image ${intro.frontmatter.intro_image_absolute && 'intro-image-absolute'} ${intro.frontmatter.intro_image_hide_on_mobile && 'intro-image-hide-mobile'}`;

  return (
    (props.authState !== "signedIn") ?
    <SignIn authState={props.authState} /> :
    <Layout bodyClass="page-teams">
      <SignOut /><SEO title="Team" />
....      
```

### 2.3.5. Bước 5

Giờ test thôi:  
```sh
npm start
```
Khi bạn load trang Home Page và Service Page vẫn bình thường, nhưng khi click vào Team Page thì sẽ ra màn hình Login như sau:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gatsby-cognito-login-page.jpg)

Việc bạn Login/SignUp/CreateAccount/ForgetPassword/ResetPassword hoàn toàn là bạn làm việc với AWS Cognito, bạn ko cần code thêm gì cả. Rất tiện lợi phải ko?

Khi bạn đã login thành công, màn hình sẽ redirect về trang bạn đang muốn truy cập:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/gatsby-cognito-logout-page.jpg)

Ở đây mình chưa tìm ra cách để sửa nút SignOut sang 1 chỗ khác nhưng mình nghĩ nó sẽ ko phải là vấn đề

Vậy là xong rồi, khá đơn giản phải ko, các bạn chỉ cần tập trung vào phần content thôi, còn lại thì Gatsby và Cognito đã lo hết rồi😎

## 2.4. Build artifact

Để build ra artifact rồi đưa lên các nơi host website của bạn (AWS S3 hoặc bất kỳ nơi nào bạn muốn) thì hãy dùng command sau:  
```sh
npm run build
```
artifact sẽ được sinh ra trong folder `public` nhé.


# CREDIT
Thanks to awsome works:  
https://github.com/trsben/gatsby-theme-amplify-cognito  
https://www.gatsbyjs.com/plugins/@webriq/gatsby-theme-amplify-cognito/  





