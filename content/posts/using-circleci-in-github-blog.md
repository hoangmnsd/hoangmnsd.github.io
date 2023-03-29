---
title: "Áp Dụng CircleCI Vào Github Blog"
date: 2019-06-24T11:11:35+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Blog,CircleCI]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Giả định là bạn đã có 1 Github Blog rồi"
---

## Yêu cầu

Giả định là bạn đã có 1 Github Blog rồi, có thể tạo theo link sau:  
[Create a Gihub Blog by Hugo](../../posts/create-a-github-blog-by-hugo/) 

Và bạn đã tạo trên github 2 repo là:
`username` và `username.github.io`

Trong đó thì `username` là repo mà mình sẽ làm việc (viết post mới, sửa chức năng v..v)

Còn `username.github.io` là repo sẽ dc tự động generate ra code và phản ánh nội dung trang web trên đường link `https://username.github.io`

Giờ cần setup CircleCI cho repo `username`. Mục tiêu là:

> Mỗi lần push code mới lên nhánh master của repo `username` thì repo `username.github.io` cũng sẽ dc cập nhật tự động, từ đó nội dung trang web 
`https://username.github.io` cũng sẽ thay đổi theo ý mình

Trên máy tính windows của bạn thì đã có 2 folder cho mỗi repo như sau:

`username` và `username.github.io` ở trong 1 folder cha là `Sites`

## Cách làm

### 1. Chọn docker image phù hợp cho CircleCI

- CircleCI cần 1 docker image để nó pull về rồi chạy các command mà mình define trước.

- Nên chọn những image đã cài đặt sẵn git bash và hugo,
ở đây mình sẽ chọn docker image là `https://hub.docker.com/r/andthensome/alpine-hugo-git-bash`

- Để đó đã.

### 2. Đăng nhập vào `https://circleci.com` bằng account github của mình

- CircleCI sẽ tự động liệt kê ra các repo trên github của mình.

- Chọn repo `username`.

- Chọn language `other`.

- Nó hướng dẫn các step để setup CircleCI. (Có thể các bạn sẽ cần tạo Deploy key và add vào Github repository)

- Sau đó ấn button `Start Building`.

### 3. Setup CircleCI cho project của bạn như sau:

- Tạo folder `.circleci` ở trong project `username`

- Trong folder `.circleci` thì tạo file `config.yml`

- Nội dung file `config.yml` là:

```sh
version: 2
jobs:
  build:
    branches:
      only:
        - master
    docker:
      - image: andthensome/alpine-hugo-git-bash
    steps:
      - checkout
      - run:
          name: Upgrade hugo
          command: |
            apk update && apk add ca-certificates && update-ca-certificates && apk add openssl && apk add openssh-client
            wget https://github.com/gohugoio/hugo/releases/download/v0.55.6/hugo_0.55.6_Linux-64bit.tar.gz
            tar xzf hugo_0.55.6_Linux-64bit.tar.gz -C /usr/local/bin/ 
      - run:
          name: Config git
          command: |
            git config --global user.email "username@gmail.com"
            git config --global user.name "username"
      - run:
          name: Publish site to github
          command: sh publish.sh
```
#### 3.a. Giải thích nội dung file trên

Ở đây mình đang define: 

- Chỉ chạy job này khi có sự thay đổi ở nhánh master.

- Chọn image là `andthensome/alpine-hugo-git-bash`.

- Các step lần lượt là:

  - Checkout src code nhánh master của `https://github.com/username/username.git` về.

  - Upgrade hugo lên version `0.55`.

  - Config git.

  - Chạy file `publish.sh` mà mình tự tạo.

### 4. Quay lại folder `Sites/username` tạo file `publish.sh`

```sh
#!/bin/bash

pwd
# Get environment from circleci, token is a env variable in circleci, also a personal access token from github
# this token has granted access to push commit to repo
export GITHUB_TOKEN=$token

# Clone from repository which serve the blog
git clone https://github.com/username/username.github.io.git

# Generate the source code to new folder
hugo -d username.github.io

# Publish the blog by push all generated resource to reposiotry
cd username.github.io
git remote set-url origin https://$GITHUB_TOKEN:x-oauth-basic@github.com/username/username.github.io.git
git add .
git commit -m "push to username/username.github.io.git by [publish.sh]"
git push origin master
```

### 5. Setup Personal access token (PAT) giữa CircleCI và Github

Ở file `publish.sh` trên để ý thấy biến `$token`,  
Đây là biến mình setup để CircleCI sử dụng push source code đã generate lên nhánh master của repo `username.github.io`

Cách setup như sau: 

#### 5.a. Trên Github

- vào link https://github.com/settings/tokens

- Ấn button `Generate new token`

- ở đây mình đang chọn Classic Token

- Đặt tên cho nó là `circlecikey` chẳng hạn

- Chọn quyền cho key đó, mình chọn quyền admin có quyền `write`

- Copy cái key đó ra, chú ý copy giữ cẩn thận đừng để mất, vì nó chỉ hiển thị 1 lần thôi

Sự khác nhau giữa deploy key và PAT thể hiện ở đây:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/circleci-github-pat.jpg)

Deploy key là CircleCI dùng để pull code từ private repo về,   
còn PAT là github dùng để push code từ trong pipeline lên public repo.  

Có thể bạn sẽ hỏi tại sao ko dùng hết 1 loại key/token thôi, cái này mình cũng chưa rõ lắm.

Cái deploy key thì chắc chắn sẽ cần vì CircleCI ngay từ bước setup đã yêu cầu rồi. 
Nhưng để tạo deploy key thì bạn phải generate 1 cặp public/private key trước, 
Sau đó đưa private key cho CircleCI giữ.  

Còn PAT thì chỉ cần 1 token thôi cũng có thể vừa pull/push code được, tiện lợi hơn deploy key.  
Nhưng PAT Classic lại ko thể giới hạn 1 repo như deploy key được. (PAT Fine-grained thì có thể)

#### 5.b. Trên CircleCI

- Vào trang https://circleci.com, đăng nhập bằng github account của mình, vào job `username`

- Trong mục setting của mỗi job sẽ có phần setting `environment variables`, 

- Add variable mới tên là `token`

- Value của variable thì paste cái key ở bước `5.a` lúc nãy ra

Rồi test thử commit lên private repo xem thế nào?

### 6. Troubleshoot

Trong quá trình trên làm từng bị lỗi như sau: 
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/error-github-not-push-empty-folder.jpg)

Đây là do github ko push những folder empty lên, dẫn đến việc không có layout để hugo trong images generate ra đủ số pages.

Vì vậy trong những folder empty như `layout`, `resources/_gen/assets` và `resources/_gen/images` thì nên tạo 1 file `.gitkeep` để nó push folder đó lên github


Done! giờ thì mỗi khi push code lên nhánh master của repo `username`

CircleCI sẽ nhận nhận ra có sự thay đổi và chạy file `.circleci/config.yml` rồi file `publish.sh` để generate source cuối cùng push lên repo `username.github.io`

Từ đó trang web https://username.github.io cũng sẽ được cập nhật







