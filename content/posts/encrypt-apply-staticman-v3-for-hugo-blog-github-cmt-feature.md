---
title: "Apply Staticman v3/v2 for Hugo blog Github to enable comment feature"
date: 2020-03-28T22:24:39+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Blog]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Nếu bạn đang host 1 Hugo blog trên Github, hẳn bạn sẽ muốn người khác có thể comment trên blog của mình"
---
# Yêu Cầu

Bạn đã có 1 Github Pages Blog dựng bằng Hugo, sử dụng theme `Minimo` hoặc những theme tương tự như Minimo

# Giới thiệu

Nếu bạn đang host 1 Hugo blog trên Github, hẳn bạn sẽ muốn người khác có thể comment trên blog của mình

Nhưng vì blog của bạn là static site. Nếu người khác có thể comment dc thì chẳng phải là dynamic site sao :v 

Để làm điều này bạn cần 1 bên thứ 3 để host cái chức năng này, ở đây mình chỉ ra 2 cách:

-Cách 1: Sử dụng `staticmanlab` của @VincentTam

-Cách 2: Tự setup 1 hệ thống Staticman làm comment system riêng trên Heroku free plan

-Cách 3 (Recommend): Tự setup 1 hệ thống Staticman làm comment system riêng trên 1 VM 

**Cách 1** thì do chúng ta sử dụng API của đồng chí @VincentTam tạo ra trên Heroku nên nó phụ thuộc vào đồng chí ấy, nếu vì 1 lý do nào đó anh ta xóa app thì chức năng comment sẽ bị disable. Thế nên cách này hiện tại dùng được, nhưng ko hoàn toàn đảm bảo trong tương lai.  

**Cách 2** thì bạn sẽ tự host app đó trên Heroku server của bạn nên bao giờ bạn ko dùng Heroku nữa thì mới thôi (nhiều khả năng vì Heroku ko cho xài free nên bạn ko dùng nữa 🤣)  

**Cách 3** thì bạn sẽ tự host app đó trên server riêng của bạn nên bao giờ bạn stop server thì mới thôi.  

Giờ mình sẽ giới thiệu Cách 1:   
## 1. Cách 1: Sử dụng `staticmanlab` của @VincentTam  

1- Add @staticmanlab vào collaborator github setting của github repo Hugo blog:   
![staticmanlab-add-github-as-collaborator](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/staticmanlab-add-github-as-collaborator.jpg)


2- Access vào link sau để active cái @staticmanlab:  
`https://staticman3.herokuapp.com/v3/connect/github/<GITHUB_USER>/<REPO_NAME>/`  
nhớ sửa `<GITHUB_USER>`,`<REPO_NAME>` là của bạn
Màn hình trả về nếu thấy chữ `OK!` thì mới là thành công nhé  

3- Add file `staticman.yml` vào root folder (cùng vị trí với file `config.toml`), nội dung file `staticman.yml` như sau, nhớ sửa lại dòng `name: '<REPO_NAME>'` tùy theo repository name của bạn:  
```sh
comments:
  allowedFields: ['author', 'content', 'email', 'parent_id', 'permalink', 'site']
  branch: 'master'
  commitMessage: "add [comment]: by {fields.author} <Staticman>\n\n{fields.permalink}#comment-{@id}"
  filename: '{@id}'
  format: 'yaml'
  generatedFields:
    date:
      type: date
      options:
        format: 'timestamp'
  moderation: false
  name: '<REPO_NAME>'
  path: 'data/comments/{options.postId}'
  requiredFields: ['author', 'content', 'email']
  reCaptcha:
    enabled: false
    # siteKey: ''
    # secret: ''
  transforms:
    email: md5
```
4- Update file `config.toml` như đoạn này, nhớ sửa `<GITHUB_USER>` và `<REPO_NAME>` phù hợp với thông tin của bạn:  
```sh
# Staticman
[params.comments.staticman]
enable = true
apiEndpoint = "https://staticman3.herokuapp.com/v3/entry/github"
maxDepth = 2

[params.comments.staticman.github]
username = "<GITHUB_USER>"
repository = "<REPO_NAME>"
branch = "master"
```

Vậy là xong, giờ push những thay đổi vừa xong lên nhánh master thôi.

**Giải thích**:  
Mỗi khi có người comment, đồng nghĩa với việc họ sẽ gửi 1 POST request đến Staticman API của đồng chí @VincentTam đã tạo ra trên Heroku.  
Sau khi API đó nhận được nội dung comment, nó sẽ commit nội dung comment đó vào branch `master` của Blog chúng ta (Cụ thể thì nội dung comment đó sẽ dc push vào folder `/data/comments`).  
Khi nhánh master phát hiện commit mới đó, nó sẽ build lại page và hiển thị lại nội dung comment trên page. Đơn giản thế thôi. :satisfied:

![demo-comment](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/demo-comment.jpg)

## 2. Cách 2: Tự setup 1 hệ thống Staticman v2 (dùng Heroku free plan)

### 2.1. Yêu cầu

Bạn đang dùng Windows, đã cài Gitbash, Visual Studio Code, đã đăng ký tài khoản Heroku (rất đơn giản, đăng ký cũng free), đã cài Heroku CLI vào máy

### 2.2. Cách làm

#### 2.2.1. Tạo RSA Private key

Mở GitBash lên, chạy command sau để generate ra RSA Private key
```sh
openssl genrsa -out key.pem
```
Nó sẽ tạo ra 1 file `key.pem`

#### 2.2.2. Tạo 1 account Github riêng (gọi là bot account) phục vụ mục đích dùng Staticman

Login vào bot account, dùng link này để tạo Personal Access Token:  
`https://github.com/settings/tokens`  
Hãy chọn những quyền như `read:packages, repo, write:packages`  
**Nhớ copy cái chuỗi token đó ra đâu đó lát nữa dùng nhé**  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/staticman-github-token.jpg)

#### 2.2.3. Clone source `staticman` về và cd vào nó

```sh
git clone https://github.com/eduardoboucas/staticman
cd staticman
```

Mở folder staticman đó trong Visual Studio Code (VSC) để dùng Powershell terminal của VSC (từ bước này ko dùng GitBash nữa vì GitBash ko đăng nhập Heroku được)

#### 2.2.4. Tạo 1 file tên là `Procfile` trong folder `staticman` 

nội dung file chỉ có 1 dòng là:  
```
web: npm start
```

#### 2.2.5. Tạo file `config.production.json`  trong folder `staticman`

nội dung file:  
```
{
  "githubToken": process.env.GITHUB_TOKEN,
  "rsaPrivateKey": JSON.stringify(process.env.RSA_PRIVATE_KEY),
  "port": 8080
}
```

#### 2.2.6. Sửa file .gitignore

add thêm dòng sau:
```
!config.production.json
```

#### 2.2.7. Login vào Heroku
```sh
heroku login
```

Tạo app trên Heroku
```sh
heroku create <app_name>
```

Tạo biến môi trường của app trên Heroku
```sh
heroku config:set GITHUB_TOKEN="<Paste token lấy được ở step 2>"
heroku config:set RSA_PRIVATE_KEY="$(cat ../key.pem)"
heroku config:set NODE_ENV="production"
```

check logs nhìn đẹp đẹp, ko có ERROR gì là được:
```sh
heroku logs --tail
```

Tạo branch `production`:
```sh
git checkout -b production 
```

Commit thay đổi lên Heroku:  
```sh
git add .
git commit -m "Setup Staticman v2 to Heroku"
git push heroku production:master
```

check logs nhìn đẹp đẹp kiểu này là ok:
```sh
heroku logs --tail
```
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/heroku-tail-logs.jpg)

Truy cập vào link này để check app đã hoạt động chưa:
`https://<app_name>.herokuapp.com`  
Nếu trả về `Hello from Staticman version 3.0.0!` nghĩa là đã deploy thành công

#### 2.2.8. Add bot account vào làm Collaborator

Login vào Github chính chủ của bạn (ko phải bot account nhé)  

Vào repository chứa blog của bạn, chọn mục `Settings -> Manage Access -> Invite a Collaborator`  

Gõ username của bot account vào, và Invite nó  

Đến đây thì **ĐỪNG** login vào con bot account để accept lời mời bằng tay nhé!

Bạn cần phải truy cập vào link này để accept mới được:  
 (chú ý thay đổi `<app_name>, <GITHUB_USER>, <REPO_NAME>` cho phù hợp)
`https://<app_name>.herokuapp.com/v2/connect/<GITHUB_USER>/<REPO_NAME>/`
Nếu hiện chữ `OK!` có nghĩa là đã accept invitation thành công. 

#### 2.2.9. Giờ cần sửa 1 chút cái Blog repository của bạn nữa

9.1- Add file `staticman.yml` vào root folder (cùng vị trí với file `config.toml`),  
nội dung file `staticman.yml` như sau, nhớ sửa lại dòng `name: '<REPO_NAME>'` tùy theo repo name của bạn:  
```sh
comments:
  allowedFields: ['author', 'content', 'email', 'parent_id', 'permalink', 'site']
  branch: 'master'
  commitMessage: "add [comment]: by {fields.author} <Staticman>\n\n{fields.permalink}#comment-{@id}"
  filename: '{@id}'
  format: 'yaml'
  generatedFields:
    date:
      type: date
      options:
        format: 'timestamp'
  moderation: false
  name: '<REPO_NAME>'
  path: 'data/comments/{options.postId}'
  requiredFields: ['author', 'content', 'email']
  reCaptcha:
    enabled: false
    # siteKey: ''
    # secret: ''
  transforms:
    email: md5
```
9.2- Update file `config.toml` như đoạn này, nhớ sửa `<GITHUB_USER>`, `<app_name>` và `<REPO_NAME>` phù hợp với thông tin của bạn:  
```sh
# Staticman
[params.comments.staticman]
enable = true
apiEndpoint = "https://<app_name>.herokuapp.com/v2/entry"
maxDepth = 2

[params.comments.staticman.github]
username = "<GITHUB_USER>"
repository = "<REPO_NAME>"
branch = "master"
```
Giờ push những thay đổi vừa xong lên nhánh master thôi.

Giờ bạn đã có thể comment vào blog để xem Staticman của riêng bạn hoạt động thế nào rồi :satisfied::satisfied:

Tuy nhiên thì Heroku cũng có 1 số nhược điểm người ta liệt kê như sau:


> Limitations of Heroku apps
Free Heroku apps come with some limitations. The most important limitation is that the number of free dyno hours is limited. A dyno is the isolated container in which your application is running. A free dyno begins to sleep after 30 mins of inactivity. Otherwise, it is always on as long as you still have remaining dyno hours (currently 550 free dyno hours per month).

> When your free dyno hours are exhausted, all of your free dynos start sleeping. You will receive a notification from Heroku before this happens though. If the only app that you are running is Staticman, however, it is unlikely that you will use up you free dyno hours because this would mean that you are receiving comments for more than 18 hours per day, which would be quite a lot.

> So, the main disadvantage of free dynos when is that posting comments will be slow (delay of a few seconds) when no one has posted anything within a while (30 minutes). In my opinion, this limitation is sufferable for a free service. If you want to get rid of this limitation or if you need more dyno hours, you can always upgrade to a paid dyno.


Trong tương lai có thể mình sẽ dùng thêm 1 số feature nữa, như Captcha, Mailgun

### 2.3. Bật tính năng Captcha cho các comment (cho Cách 2 dùng Heroku free plan)

Gần đây mình phát hiện có 1 số comment trên blog của mình có nội dung rất lạ, comment không liên quan bài viết, hoặc comment chứa những đường link mã độc rất nguy hiểm. Thi thoảng mình phải vào và xóa comment đó đi.

Thế nên mình quyết định apply reCaptcha cho tính năng comment này. Ít nhất thì cũng làm khó 1 chút cho bọn bot.

#### 2.3.1. Đăng ký ReCaptcha để lấy key

vào link sau để đăng ký nhé:  
https://www.google.com/recaptcha/admin

Nhập các thông tin như này và ấn `Submit`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/staticman-recaptcha-reg.jpg)

Sau khi submit bạn sẽ nhận được `SiteKey` và `Secret`, hãy giữ chúng cẩn thận

#### 2.3.2. Encrypt `Secret` bằng cách truy cập link sau    

`https://<app_name>.herokuapp.com/v3/encrypt/<Secret>`

Vì mình build Static trên Heroku nên dường link của mình nó trông như vậy.  
Bạn xem Staticman ApiEnpoint của bạn là gì để call đến đường dẫn tương ứng nhé.  

Nó sẽ trả về kết quả là 1 chuỗi kí tự đã mã hóa hãy copy chuỗi ấy.  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/staticman-recaptcha-res.jpg)

#### 2.3.3. Sửa file `staticman.yml`

```sh
~~~
  reCaptcha:
    enabled: true
    siteKey: '65AAAAAABkgfodgkeMK_VmkgmkKkf3'
    secret: 'PxQcp............'
~~~
```

#### 2.3.4. Hãy chắc chắn rằng theme mà bạn đang dùng có hỗ trợ reCaptcha  

Ví dụ mình đang dùng theme Minimo. Trong đường link `themes/minimo/layouts/partials/comments/staticman/form.html`, mình có thể thấy từ năm 2019 họ mới add thêm các mã html để hỗ trợ reCaptcha (trước đó là không có, nếu muốn phải tự viết)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/staticman-recaptcha-minimo-theme.jpg)

Giờ push tất cả lên nhánh master và tận hưởng thành quả thôi. :satisfied::satisfied:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/staticman-recaptcha-view.jpg)

## 3. Cách 3: Tự setup 1 hệ thống Staticman v2 (dùng Cloud VM)

Phần này được update vào 12/2022, khi mà Heroku ko cho dùng free nữa. Mình phải chuyển server Staticman qua 1 VM free khác, là Oracle Cloud VM.

Cách này có 1 nhược điểm là do Server expose ra IP endpoint thôi nên ko có HTTPS, dẫn đến khi comment sẽ có warning như ảnh ở cuối bài.  

Mình sẽ dùng Docker để run app staticman.

Clone source về `/opt/devops/`

Copy file key.pem vào trong folder source.

Tạo file `config.development.json`:  
```json
{
  "githubToken": process.env.GITHUB_TOKEN,
  "rsaPrivateKey": JSON.stringify(process.env.RSA_PRIVATE_KEY),
  "port": 8080
}
```

Sửa file `docker-compose.development.yml`, add thêm các biến ENV, chú ý biến `RSA_PRIVATE_KEY` hãy paste nội dùng file `key.pem` vào:  
```yml
version: '2'
services:
  staticman:
    container_name: staticman
    extends:
      file: docker-compose.yml
      service: staticman
    environment:
      PORT: 3000
      NODE_ENV: development
      GITHUB_TOKEN: "cb9xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx26"
      RSA_PRIVATE_KEY: "-----BEGIN RSA PRIVATE KEY-----\n
MAIDpcccccccccccccccccccccccccccccccccccccccccccccccccccccccct3W
....
aYxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxp
ivvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvwyYA==\n
-----END RSA PRIVATE KEY-----"
    volumes:
      - ./:/app
```
Run:  
```sh
docker-compose -f docker-compose.development.yml up -d
docker ps
```

Truy cập vào Browser, VM public IP port 8080, example: http://111.222.333.444:8080/

Nếu trả về: `Hello from Staticman version 3.0.0!` nghĩa là đã OK

Chuyển sang làm trên production, stop môi trường development:  
```sh
docker stop staticman
```

Tạo file `config.production.json`:   
```json
{
    "githubToken": process.env.GITHUB_TOKEN,
    "rsaPrivateKey": JSON.stringify(process.env.RSA_PRIVATE_KEY),
    "port": 8080
}
```

Tạo file `docker-compose.production.yml`:  
```yml
version: '2'
services:
  staticman:
    container_name: staticman
    extends:
      file: docker-compose.yml
      service: staticman
    environment:
      PORT: 3000
      NODE_ENV: production
      GITHUB_TOKEN: "cbxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx26"
      RSA_PRIVATE_KEY: "-----BEGIN RSA PRIVATE KEY-----\n
MAIDpcccccccccccccccccccccccccccccccccccccccccccccccccccccccct3W
....
aYxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxp
ivvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvwyYA==\n
-----END RSA PRIVATE KEY-----"
    volumes:
      - ./:/app
```

Run:  
```sh
docker-compose -f docker-compose.production.yml up -d
docker ps
```

Truy cập vào VM public IP port 8080, example: http://111.222.333.444:8080/

Nếu trả về: `Hello from Staticman version 3.0.0!` nghĩa là đã OK

Muốn sửa port ko dùng 8080 mà dùng port khác (8811 chẳng hạn) thì sửa 2 file:  
- file `docker-compose.yml`: `- '8811:3000'`.  
- file `config.production.json`:  `"port": 8811`.  

Làm lại step 2.2.8. Giờ add account Github của con bot as collaborator và accept invitation

Nếu trước đây đã add account con bot rồi thì remove đi và add lại nhé:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/staticmanlab-add-github-as-collaborator-1.5.jpg)

Để màn hình này là OK:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/staticmanlab-add-github-as-collaborator-2.jpg)

Accept bằng cách truy cập link của Staticman server:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/staticman-accept-invi.jpg)

Làm lại step 2.2.9. Chú ý apiEndpoint trong file `config.toml`:  

```yml
# Staticman
[params.comments.staticman]
enable = true
apiEndpoint = "http://VM_PUBLIC_IP:PORT/v2/entry"
maxDepth = 2
```

Giờ tiếp tục làm phần reCapcha

Vì mình đã làm step 2.3.1. nên đã có `Secret` rồi

Làm lại step 2.3.2. thôi:  

Truy cập link staticman Server để encrypt Secret: 
`http://VM_PUBLIC_IP:PORT/v3/encrypt/<Secret>`

sẽ nhận được 1 string, copy và sửa file `staticman.yml` như step 2.3.3.

Confirm lại step 2.3.4. rồi push lên nhánh master để test.

Giờ push những thay đổi vừa xong lên nhánh master thôi.

Cách #3 này có 1 nhược diểm là Bởi vì mình expose ra endpoint ko có HTTPS (chỉ HTTP thôi), nên mỗi khi comment sẽ có warning như này:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/staticman-comment-test1.jpg)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/staticman-comment-test2.jpg)

### Update 2023/07: Kết hợp docker-swag để expose ra HTTPS endpoint

Sau 1 thời gian sử dụng và setup/debug với swag thì mình nghĩ swag có thể giúp mình expose endpoint staticman ra HTTPS

Đây là config để mình gen certificate wildcard băng swag cho subdomain của duckdns

```yml
services:
  swag:
    image: lscr.io/linuxserver/swag:1.30.0
    container_name: swag
    cap_add:
      - NET_ADMIN
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ho_Chi_Minh
      - URL=<REDACTED>.duckdns.org
      - VALIDATION=duckdns
      - SUBDOMAINS=wildcard, #optional
      - CERTPROVIDER= #optional
      - DNSPLUGIN=duckdns #optional
      - PROPAGATION= #optional
      - DUCKDNSTOKEN= #optional
      - EMAIL= #optional
      - ONLY_SUBDOMAINS=true #optional
      - EXTRA_DOMAINS= #optional
      - STAGING=true #optional
    volumes:
      - /opt/devops/swag/config:/config
    ports:
      - 443:443
      - 80:80 #optional
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "10"
```

Nên giờ bất cứ subdomain nào dưới dạng `xyz.<REDACTED>.duckdns.org` cũng sẽ có valid HTTPS. (Cái này đã test ko cần show evident)

Do swag đang nằm trong network `devops_default` còn staticman đang nằm trong network `staticman_default` nên mình sẽ sửa lại staticman `docker-compose.production.yml` file 1 chút, thêm phần networks vào:

```yml
version: '3'
networks:
  external_nw:
    external:
      name: devops_default
services:
  staticman:
    networks:
    - external_nw
    container_name: staticman
    extends:
      file: docker-compose.yml
      service: staticman
    environment:
      PORT: 3000
      NODE_ENV: production
      GITHUB_TOKEN: "Nên thay bằng token mới, Làm sao để lấy token thì đọc lại phần 1"
      RSA_PRIVATE_KEY: "-----BEGIN RSA PRIVATE KEY-----\n
.................REDACTED.....
-----END RSA PRIVATE KEY-----"
    volumes:
      - ./:/app
```

Test connection từ trong swag có thể call qua port 3000 là OK:

```
$ docker exec -it swag sh
root@074c9822ed36:/# curl staticman:8121
curl: (7) Failed to connect to staticman port 8121 after 0 ms: Connection refused
root@074c9822ed36:/# curl staticman:3000
Hello from Staticman version 3.0.0!
```

Giờ tạo file nginx conf cho staticman trong folder `/opt/devops/swag/config/nginx/proxy-confs/staticman.subdomain.conf`:  

```
server {

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name staticman.*;

    include /config/nginx/ssl.conf;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app staticman;
        set $upstream_port 3000;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}

```

restart swag container, check từ giao diện vào được `https://staticman.<REDACTED>.duckdns.org/` và thấy Hello... là OK!

Không cần expose port 8121 nữa, nhưng do ko biết cần sửa những chỗ nào, có ảnh hưởng gì ko nên thôi mình cứ để tạm.

Sửa lại file `config.toml`:  

```yml
# Staticman
[params.comments.staticman]
enable = true
apiEndpoint = "https://staticman.<REDACTED>.duckdns.org/v2/entry"
maxDepth = 2
```

Test xem có comment được ko, khi comment có bị Warning nữa ko? Không bị nữa là ngon 😘

## 4. Troubleshooting

Nếu khi comment bị lỗi Yisk... gì đó thì có nghĩa là bạn cần phải add lại collaborator nhé. Hãy remove Github bot account đi rồi invite lại.

Nếu bạn bị stuck ở đoạn cố gắng accept collaborator invitation bằng link như này:

```
$ curl https://staticman.<REDACTED>.duckdns.org/
Hello from Staticman version 3.0.0!

$ curl https://staticman.<REDACTED>.duckdns.org/v2/connect/hoangmnsd/hoangmnsd
.....
```

Như hồi trước thì đáng nhẽ phải trả về OK. Nhưng giờ nó cứ đơ mãi luôn 😢 Logs:

```
$ docker logs -f staticman

> staticman@3.0.0 prestart /app
> if [ ! -d node_modules ]; then npm install; fi


> staticman@3.0.0 start /app
> node index.js

Staticman API running on port 3000

(node:27) UnhandledPromiseRejectionWarning: HttpError: Bad credentials
    at response.text.then.message (/app/node_modules/@octokit/request/dist-node/index.js:66:23)
    at <anonymous>
    at process._tickDomainCallback (internal/process/next_tick.js:228:7)
(node:27) UnhandledPromiseRejectionWarning: Unhandled promise rejection. This error originated either by throwing inside of an async function without a catch block, or by rejecting a promise which was not handled with .catch(). (rejection id: 1)
(node:27) [DEP0018] DeprecationWarning: Unhandled promise rejections are deprecated. In the future, promise rejections that are not handled will terminate the Node.js process with a non-zero exit code.
^C
```

Mình cố gắng convert lại như cũ, thử bằng call đến http://IP:8121 cũng vẫn lỗi.

Nguyên nhân là do cái `GITHUB_TOKEN` đã bị xóa hoặc hết hạn từ lâu, cần phải login vào acc Github Bot, tạo Personal Access Token mới. Rồi sửa lại trong file `docker-compose.production.yml` rồi thử lại là OK!


# CREDIT

https://github.com/eduardoboucas/staticman/issues/296  
https://dreambooker.site/2019/08/17/Hugo-Staticman-Travis/  
https://minimo.netlify.com/docs/comments-support/   
https://github.com/eduardoboucas/staticman  
https://github.com/eduardoboucas/staticman/issues/243  
https://yasoob.me/posts/running_staticman_on_static_hugo_blog_with_nested_comments/#    
https://vincenttam.gitlab.io/post/2018-09-16-staticman-powered-gitlab-pages/2/  
https://www.datascienceblog.net/post/other/staticman_comments/  
https://github.com/eduardoboucas/staticman-recaptcha  
