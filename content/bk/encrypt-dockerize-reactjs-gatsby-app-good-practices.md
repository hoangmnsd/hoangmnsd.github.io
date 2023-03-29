---
title: "Dockerize ReactJS/GatsbyJS app and Run it in Dev environment + good practices"
date: 2022-10-22T00:07:17+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [ReactJS,GatsbyJS,Docker]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Mình có 1 static site tạo ra bằng GatsbyJS (1 framework base trên ReactJS) đã lâu, giờ muốn Dockerize nó"
---

# 1. Story

Mình có 1 static site tạo ra bằng GatsbyJS (1 framework base trên ReactJS) đã lâu, cách đây khoảng 1 năm:  
https://github.com/hoangmnsd/hoangmnsd-the404blog-theme.git  

Giờ đổi máy muốn tiếp tục quay lại phát triển app đó. Nhưng laptop yếu quá ko thể npm install nổi.  
-> Mình chuyển hướng sang deploy app đó trên 1 server riêng như RasberryPi, nhưng lại dính đến network bandwidth quá chậm, `npm install` rất tốn thời gian.  
-> Mình chuyển tiếp sang hướng deploy app đó trên 1 VM để tận dụng network bandwidth siêu nhanh của họ.  

Môi trường mình dùng là: Canonical-Ubuntu-18.04-aarch64-2022.04.24-0. 

Ban đầu chỉ định install nodejs và npm trên VM rồi build & run luôn, nhưng thấy nhiều lỗi liên quan đến OS quá, fix và đổi version nodejs để test liên tục khá mệt,
nhiều khi ko biết fix được lỗi là do command nào...   

-> Mình quyết định chuyển sang Dockerize luôn trên VM, để sau này khi đổi server sẽ tiện tạo lại môi trường. Ý tưởng sẽ là:  
- Synchronize code từ local lên VM bằng WinSCP, tất nhiên chỉ phần code mình sửa thôi, ignore node_modules,   
- App run bằng Docker Compose và được mount source code dirs từ VM vào Container  
- Mỗi khi sửa code trên local, sẽ được sync lên VM qua WinSCP, từ đó mount tự động vào Container và phản ánh lên public IP/port của VM.    

Chú ý: Việc build đi build lại Dockerfile cũng sẽ rất tốn dung lượng (có vài ngày mà mình tốn 50GB rác) nên chú ý khi chọn server nên chọn ổ disk dung lượng lớn.  

Đây là file `package.json` của repo:   
```
$ cat package.json
{
  "name": "gatsby-starter-default",
  "private": true,
  "description": "A simple starter to get up and developing quickly with Gatsby",
  "version": "0.1.0",
  "author": "Kyle Mathews <mathews.kyle@gmail.com>",
  "dependencies": {
    "@gatsby-contrib/gatsby-plugin-elasticlunr-search": "^2.3.0",
    "@hoangmnsd/gatsby-theme-amplify-cognito": "^1.1.5",
    "bootstrap": "^4.3.1",
    "disqus-react": "^1.0.6",
    "gatsby-cli": "^3.14.2",
    "gatsby": "^2.13.13",
    "gatsby-image": "^2.2.4",
    "gatsby-plugin-disqus": "^1.1.2",
    "gatsby-plugin-manifest": "^2.2.1",
    "gatsby-plugin-offline": "^2.2.1",
    "gatsby-plugin-react-helmet": "^3.1.0",
    "gatsby-plugin-sharp": "^2.2.3",
    "gatsby-plugin-transition-link": "^1.20.5",
    "gatsby-remark-copy-linked-files": "^2.1.3",
    "gatsby-remark-images": "^3.1.4",
    "gatsby-remark-prismjs": "^3.3.2",
    "gatsby-remark-responsive-iframe": "^2.2.3",
    "gatsby-remark-smartypants": "^2.1.2",
    "gatsby-source-filesystem": "^2.1.3",
    "gatsby-transformer-remark": "^2.6.3",
    "gatsby-transformer-sharp": "^2.2.1",
    "gsap": "^3.7.1",
    "jquery": "^3.4.1",
    "popper.js": "^1.15.0",
    "prismjs": "^1.16.0",
    "prop-types": "^15.7.2",
    "react": "^16.8.6",
    "react-bootstrap": "^1.6.1",
    "react-dom": "^16.8.6",
    "react-helmet": "^5.2.1",
    "react-hook-form": "^7.12.1",
    "react-social-icons": "^4.1.0",
    "sharp": "^0.27.2"
  },
  "devDependencies": {
    "prettier": "^1.18.2"
  },
  "keywords": [
    "gatsby"
  ],
  "license": "MIT",
  "scripts": {
    "build": "gatsby build",
    "develop": "gatsby develop",
    "format": "prettier --write src/**/*.{js,jsx}",
    "start": "npm run develop",
    "serve": "gatsby serve",
    "test": "echo \"Write tests! -> https://gatsby.dev/unit-testing\""
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/gatsbyjs/gatsby-starter-default"
  },
  "bugs": {
    "url": "https://github.com/gatsbyjs/gatsby/issues"
  }
}
```

# 2. Một số lỗi và command cần lưu ý khi cố gắng npm install trên VM

⛔ Lỗi `Failed at the sharp@0.27.2 install script.`  
Để fix thì mình phải đổi version nodejs để test:  
```
npm install sharp@0.27.2 --save
```

- gatsby-cli cũng có nhiều version 2/3/4 nên chú ý chọn 1 specific version:  
```
npm i gatsby@2
$ gatsby -v
Gatsby CLI version: 2.19.3
```

⛔ Nhiều lúc `npm install` thì lỗi nhưng `npm install -g` lại OK  

⛔ Có thể gặp lỗi về permision  
Solution: https://stackoverflow.com/questions/51811564/sh-1-node-permission-denied
```
npm config set user 0
npm config set unsafe-perm true
```

🆗 Cách để xác định OS architect đang sử dụng:  
```sh
$ node
Welcome to Node.js v14.20.1.
Type ".help" for more information.
> process.arch
'arm64'
> process.platform
'linux'
> process.versions
{
  node: '14.20.1',
  v8: '8.4.371.23-node.87',
  uv: '1.42.0',
  zlib: '1.2.11',
  brotli: '1.0.9',
  ares: '1.18.1',
  modules: '83',
  nghttp2: '1.42.0',
  napi: '8',
  llhttp: '2.1.6',
  openssl: '1.1.1q',
  cldr: '40.0',
  icu: '70.1',
  tz: '2021a3',
  unicode: '14.0'
}
```

🆗 Cách để check các package phù hợp và latest của npm:  
https://stackoverflow.com/a/71980468/9922066
```
$ npm outdated
Package                                           Current   Wanted  Latest  Location
sharp                                             MISSING   0.22.1  0.31.1  gatsby-starter-default
@gatsby-contrib/gatsby-plugin-elasticlunr-search    2.4.2    2.4.2   3.0.2  gatsby-starter-default
bootstrap                                           4.6.2    4.6.2   5.2.2  gatsby-starter-default
gatsby                                            2.32.13  2.32.13  4.24.5  gatsby-starter-default
gatsby-image                                       2.11.0   2.11.0  3.11.0  gatsby-starter-default
gatsby-plugin-manifest                             2.12.1   2.12.1  4.24.0  gatsby-starter-default
gatsby-plugin-offline                              2.2.10   2.2.10  5.24.0  gatsby-starter-default
gatsby-plugin-react-helmet                         3.10.0   3.10.0  5.24.0  gatsby-starter-default
gatsby-plugin-sharp                                2.14.4   2.14.4  4.24.0  gatsby-starter-default
gatsby-remark-copy-linked-files                    2.10.0   2.10.0  5.24.0  gatsby-starter-default
gatsby-remark-images                               3.11.1   3.11.1  6.24.0  gatsby-starter-default
gatsby-remark-prismjs                              3.13.0   3.13.0  6.24.0  gatsby-starter-default
gatsby-remark-responsive-iframe                    2.11.0   2.11.0  5.24.0  gatsby-starter-default
gatsby-remark-smartypants                          2.10.0   2.10.0  5.24.0  gatsby-starter-default
gatsby-source-filesystem                           2.11.1   2.11.1  4.24.0  gatsby-starter-default
gatsby-transformer-remark                          2.16.1   2.16.1  5.24.0  gatsby-starter-default
gatsby-transformer-sharp                           2.12.1   2.12.1  4.24.0  gatsby-starter-default
react                                             16.14.0  16.14.0  18.2.0  gatsby-starter-default
react-bootstrap                                     1.6.6    1.6.6   2.5.0  gatsby-starter-default
react-dom                                         16.14.0  16.14.0  18.2.0  gatsby-starter-default
react-helmet                                        5.2.1    5.2.1   6.1.0  gatsby-starter-default
react-social-icons                                  4.1.0    4.1.0  5.15.0  gatsby-starter-default
```
=> `npm install sharp@0.22.1`

🆗 Có thể bạn sẽ nghĩ rằng:  
> Nếu ko thể install https://www.npmjs.com/package/sharp/v/0.27.2 dc thì hãy chuyển sang sử dụng cái nào phù hợp vs OS của bạn.
Ở đây là ubuntu oracle cloud vm chỉ có sharp@0.22.1 là install được thì chuyển thôi.   

Tuy nhiên, muốn sử dụng sharp@0.22.1 thì cần thay đổi version của: `gatsby-transformer-sharp` và `gatsby-plugin-sharp` nữa vì chúng đang point đến sharp@0.27.2.  

Vì ko biết version nào của `gatsby-transformer-sharp` và `gatsby-plugin-sharp` sẽ phù hợp với sharp@0.22.1.   
-> nên mình bỏ cuộc, quay lại tìm cách để install được sharp@0.27.2.  

🆗 Khi `npm install -g` vẫn lỗi thiếu sharp@0.27.2 thì thử search xem package nào cần sharp@0.27.2:  
```
sudo grep -ril "0.27.2"
```

🆗 Có thể việc install với `npm install sharp@0.27.2 --ignore-scripts` sẽ được,  
nhưng mình khuyên ko nên vì install được sharp@0.27.2 theo cách đó rồi sẽ lại lỗi ở chỗ khác thôi

⛔ Trên server mà run Docker, có thể bị lỗi này khi check log container:  
https://stackoverflow.com/questions/55763428/react-native-error-enospc-system-limit-for-number-of-file-watchers-reached  
Solution:  
```
# insert the new value into the system config
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

# check that the new value was applied
cat /proc/sys/fs/inotify/max_user_watches
```

🆗 Check các LTS version của node, tại thời điểm này thì các version sau là LTS latest tương ứng với Node 12/14/16:  
```
$ nvm ls-remote
v12.22.12
v14.20.1
v16.18.0
```
Chúng ta sẽ thử lần lượt các nodejs version 12,14,16 để test.  
Nên dùng các LTS version của nodejs để sử dụng.  

⛔ 1 số command install mà chỉ định arch và platform:  
```
npm cache clean --force
npm install --arch=x64 --platform=linux --legacy-peer-deps
```
nhưng lúc run npm start thì lại lỗi:  
```
Error in "/opt/hoangmnsd-the404blog-theme/node_modules/gatsby-transformer-sharp/gatsby-node.js": 'linux-x64' binaries cannot be used on
the 'linux-arm64v8' platform. Please remove the 'node_modules/sharp' directory and run 'npm install' on the 'linux-arm64v8' platform.

  Error: 'linux-x64' binaries cannot be used on the 'linux-arm64v8' platform. Please remove the 'node_modules/sharp' directory and run 'npm ins
  tall' on the 'linux-arm64v8' platform.
```
Run lại: 
```
npm cache clean --force
npm install --arch=arm64v8 --platform=linux --legacy-peer-deps
```
-> Vẫn lỗi nhưng là lỗi khác 😭

-> Túm lại, cuối cùng quá nản nên mình chuyển sang cố gắng Dockerize, tạo Dockerfile và build image  


# 3. Một số lỗi và command cần lưu ý khi Dockerize GatsbyJS app

Có 2 loại image là Debian slim image và Alpine image thường được đề cập (https://snyk.io/blog/10-best-practices-to-containerize-nodejs-web-applications-with-docker/)

Thường thấy mọi người hay chọn Alpine image vì nó nhẹ, nhưng theo bài viết trên thì ho recommend nên chọn Debian slim image với LTS nodejs version thì tốt hơn.

Mình sẽ thử dùng Alpine image trước sau đó là Debian slim image.  

Dưới đây là 1 số lỗi khi mình cố gắng build image từ Dockerfile.  

## 3.1. Lỗi gặp khi build từ Alpine image

⛔ Lỗi ko thể install dc sharp@0.27.2: Lỗi này gặp khi dùng `FROM node:12.18.0-alpine` (mình chọn vì 12.18.0 là version mà Netlify đang chạy OK)  
```
> sharp@0.27.2 install /app/node_modules/gatsby-plugin-manifest/node_modules/sharp
> (node install/libvips && node install/dll-copy && prebuild-install) || (node-gyp rebuild && node install/dll-copy)

info sharp Downloading https://github.com/lovell/sharp-libvips/releases/download/v8.10.5/libvips-8.10.5-linuxmusl-arm64v8.tar.br
ERR! sharp Prebuilt libvips 8.10.5 binaries are not yet available for linuxmusl-arm64v8
info sharp Attempting to build from source via node-gyp but this may fail due to the above error
info sharp Please see https://sharp.pixelplumbing.com/install for required dependencies
make: Entering directory '/app/node_modules/gatsby-plugin-manifest/node_modules/sharp/build'
  CC(target) Release/obj.target/nothing/../../../node-addon-api/nothing.o
  AR(target) Release/obj.target/../../../node-addon-api/nothing.a
  COPY Release/nothing.a
  TOUCH Release/obj.target/libvips-cpp.stamp
  CXX(target) Release/obj.target/sharp/src/common.o
In file included from ../src/common.cc:24:
/usr/include/vips/vips8:35:10: fatal error: glib-object.h: No such file or directory
   35 | #include <glib-object.h>
      |          ^~~~~~~~~~~~~~~
compilation terminated.
make: Leaving directory '/app/node_modules/gatsby-plugin-manifest/node_modules/sharp/build'
make: *** [sharp.target.mk:139: Release/obj.target/sharp/src/common.o] Error 1
gyp ERR! build error
gyp ERR! stack Error: `make` failed with exit code: 2
gyp ERR! stack     at ChildProcess.onExit (/usr/local/lib/node_modules/npm/node_modules/node-gyp/lib/build.js:194:23)
gyp ERR! stack     at ChildProcess.emit (events.js:315:20)
gyp ERR! stack     at Process.ChildProcess._handle.onexit (internal/child_process.js:275:12)
gyp ERR! System Linux 5.4.0-1083-oracle
gyp ERR! command "/usr/local/bin/node" "/usr/local/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js" "rebuild"
gyp ERR! cwd /app/node_modules/gatsby-plugin-manifest/node_modules/sharp
gyp ERR! node -v v12.18.0
gyp ERR! node-gyp -v v5.1.0
```
-> Chịu ko fix được, nên đổi version nodejs khác:  
  - `FROM node:12.22.12-alpine` OK, 
  - `FROM node:14.18.2-alpine3.15` OK,  
  - `FROM node:16.18.0-alpine` OK.  


⛔ Lỗi `python2 (no such package)`: Lỗi này gặp khi dùng `FROM node:14.20.1-alpine`  
```
ERROR: unable to select packages:
  python2 (no such package):
    required by: world[python2]
The command '/bin/sh -c apk add --no-cache   python2 make gcc g++ autoconf automake libtool &&   apk add vips-dev fftw-dev --update-cache   && rm -fR /var/cache/apk/*' returned a non-zero code: 1
```
Nguyên nhân: do bạn đang dùng python2  
Solution: trong Dockerfile phải dùng python3  

⛔ Lỗi `pngquant-bin`: Lỗi này gặp khi dùng `FROM node:14.20.1-alpine`  
```
> pngquant-bin@6.0.1 postinstall /app/node_modules/pngquant-bin
> node lib/install.js

spawn Unknown system error -8
pngquant pre-build test failed
compiling from source
Error: pngquant failed to build, make sure that libpng-dev is installed
    at /app/node_modules/bin-build/node_modules/execa/index.js:231:11
    at runMicrotasks (<anonymous>)
    at processTicksAndRejections (internal/process/task_queues.js:95:5)
    at async Promise.all (index 0)
```
Nguyên nhân: https://github.com/imagemin/pngquant-bin/issues/36#issuecomment-381587705  
Solution: trong Dockerfile add thêm `bash zlib-dev libpng-dev`


⛔ Lỗi `Error [ERR_REQUIRE_ESM]: Must use import to load ES Module`: gặp phải ở các image như:   
  - `FROM node:14.18.2-alpine3.15`,  
  - `FROM node:12.22.12-alpine`  

```
internal/modules/cjs/loader.js:1102
      throw new ERR_REQUIRE_ESM(filename, parentPath, packageJsonPath);
      ^
Error [ERR_REQUIRE_ESM]: Must use import to load ES Module:
/usr/local/lib/node_modules/gatsby/node_modules/remark-mdx/index.js
require() of ES modules is not supported.
require() of /usr/local/lib/node_modules/gatsby/node_modules/remark-mdx/index.js
 from /usr/local/lib/node_modules/gatsby/node_modules/gatsby-recipes/dist/graphq
l-server/server.js is an ES module file as it is a .js file whose nearest parent
 package.json contains "type": "module" which defines all .js files in that
package scope as ES modules.
Instead rename index.js to end in .cjs, change the requiring code to use
import(), or remove "type": "module" from
/usr/local/lib/node_modules/gatsby/node_modules/remark-mdx/package.json.
```

-> https://github.com/gatsbyjs/gatsby/issues/33713  

Sau khi check file package-lock.json:  
Nguyên nhân: Do gatsby-cli@2.19.3 đang cần gatsby-recipes@0.9.3.  
Mà gatsby-recipes@0.9.3 thì lại cần remark-mdx@2.0.0-next.4 và remark-mdxjs@2.0.0-next.4.  
Solution: nên tăng version gatsby-cli lên v3:  
Sửa Dockerfile thành `RUN npm install -g gatsby@3`  
Tuy nhiên đừng nhầm lẫn mình đang dùng gatsby ver 3, trong container vẫn sẽ thấy gatsby đang ở ver 2:
```
bash-5.1$ gatsby -v
Gatsby CLI version: 3.14.2
Gatsby version: 2.32.13
```

## 3.2. Dockerfile cho Alpine image

Đây là `Dockerfile` hoàn chỉnh mà mình đã dùng để build được image từ base image là NodeJS Alpine:  
```sh
#FROM node:12.22.12-alpine
#FROM node:16.18.0-alpine
FROM node:14.20.1-alpine

RUN apk --no-cache update \
  && apk --no-cache add python3 make gcc g++ autoconf automake libtool \
  && apk add vips-dev fftw-dev zlib-dev libpng-dev bash --update-cache \
  && rm -fR /var/cache/apk/*

WORKDIR /app
COPY ./package*.json /app/

RUN npm cache clean --force
RUN npm install -g gatsby@3
RUN npm ci --only=production --no-optional
# below command work with Node v14.20.1 but not Node v16.18.0 (remember to remove package-lock.json first)
# i use npm install when I want to regenerate package-lock.json
# RUN npm install --no-optional

# fix error https://stackoverflow.com/q/67639482/9922066
RUN mkdir -p /app/.cache && chmod -R 777 /app/.cache
RUN mkdir -p /app/public && chmod -R 777 /app/public

COPY . /app
RUN chown -R node:node /app
USER node

EXPOSE 8000
CMD ["gatsby", "develop", "-H", "0.0.0.0" ]
```

## 3.3. Lỗi gặp khi build từ Debian slim image

Mình sẽ sử dụng image này: `FROM node:16.18.0-bullseye-slim`  

⛔ Lỗi `Error: pngquant failed to build, make sure that libpng-dev is installed`  
```
npm ERR! code 1
npm ERR! path /app/node_modules/pngquant-bin
npm ERR! command failed
npm ERR! command sh -c -- node lib/install.js
npm ERR! compiling from source
npm ERR! Command failed: /app/node_modules/pngquant-bin/vendor/pngquant --version
npm ERR! /app/node_modules/pngquant-bin/vendor/pngquant: 1:ELF: not found
npm ERR! /app/node_modules/pngquant-bin/vendor/pngquant: 1: G: not found
npm ERR!
npm ERR!
npm ERR! pngquant pre-build test failed
npm ERR! Error: pngquant failed to build, make sure that libpng-dev is installed
npm ERR!     at /app/node_modules/bin-build/node_modules/execa/index.js:231:11
npm ERR!     at processTicksAndRejections (node:internal/process/task_queues:96:5)
npm ERR!     at async Promise.all (index 0)
```
Nguyên nhân: Dockerfile thiếu `libpng-dev`  
Solution: trong Dockerfile add thêm `libpng-dev`  

⛔ Lỗi `Command failed: /app/node_modules/mozjpeg/vendor/cjpeg -version`  
```
npm ERR! code 1
npm ERR! path /app/node_modules/mozjpeg
npm ERR! command failed
npm ERR! command sh -c -- node lib/install.js
npm ERR! compiling from source
npm ERR! Command failed: /app/node_modules/mozjpeg/vendor/cjpeg -version
npm ERR! /app/node_modules/mozjpeg/vendor/cjpeg: 1: Syntax error: word unexpected (expecting ")")
npm ERR!
npm ERR!
npm ERR! mozjpeg pre-build test failed
npm ERR! Error: Command failed: /bin/sh -c ./configure --enable-static --disable-shared --disable-dependency-tracking --with-jpeg8  --prefix="/app/node_modules/mozjpeg/vendor" --bindir="/app/node_modules/mozjpeg/vendor" --libdir="/app/node_modules/mozjpeg/vendor"
npm ERR! ./configure: line 13631: PKG_PROG_PKG_CONFIG: command not found
npm ERR! ./configure: line 13810: syntax error near unexpected token `libpng,'
npm ERR! ./configure: line 13810: `PKG_CHECK_MODULES(libpng, libpng, HAVE_LIBPNG=1,'
npm ERR!
```
Nguyên nhân: https://stackoverflow.com/a/64927666/9922066  
Solution: trong Dockerfile add thêm `automake autoconf libtool dpkg pkg-config libpng-dev g++`  

⛔ Lỗi `Can't find Python executable "python", you can set the PYTHON env variable.`. Gặp khi dùng các image:  
  - `FROM node:16.18.0-bullseye-slim`, 
  - `FROM node:16.18.0-alpine` 

Chú ý: Nếu mình giữ nguyên package-lock.json đang trỏ đến `"sharp": "^0.28.3"`, package.json cũng đang trỏ đến `"sharp": "^0.28.3"`, run `npm ci` thì sẽ ko có lỗi này.  

Nhưng...

Quá trình làm mình thấy:  
- package.json có `"sharp": "^0.28.3"` là ko ý nghĩa lắm, 
  vì các package `gatsby-transformer-sharp` và `gatsby-plugin-sharp` vẫn đang trỏ đến sharp@0.27.2.  
- Mình thử xóa package-lock.json,  
- Sửa package.json từ `"sharp": "^0.28.3"` thành `"sharp": "^0.27.2"`. 
- Và run `RUN npm install` để generate lại package-lock.json. 

Sẽ gặp lỗi này:
```
npm ERR! code 2
npm ERR! path /app/node_modules/leveldown
npm ERR! command failed
npm ERR! command sh -c -- prebuild --install
npm ERR! prebuild info begin Prebuild version 4.5.0
npm ERR! prebuild ERR! configure error
npm ERR! prebuild ERR! stack Error: Can't find Python executable "python", you can set the PYTHON env variable.
npm ERR! prebuild ERR! stack     at PythonFinder.failNoPython (/app/node_modules/node-gyp/lib/configure.js:484:19)
npm ERR! prebuild ERR! stack     at PythonFinder.<anonymous> (/app/node_modules/node-gyp/lib/configure.js:406:16)
npm ERR! prebuild ERR! stack     at F (/app/node_modules/which/which.js:68:16)
npm ERR! prebuild ERR! stack     at E (/app/node_modules/which/which.js:80:29)
npm ERR! prebuild ERR! stack     at /app/node_modules/which/which.js:89:16
npm ERR! prebuild ERR! stack     at /app/node_modules/isexe/index.js:42:5
npm ERR! prebuild ERR! stack     at /app/node_modules/isexe/mode.js:8:5
npm ERR! prebuild ERR! stack     at FSReqCallback.oncomplete (node:fs:202:21)
```
Kể cả khi Dockerfile có `ENV PYTHON=/usr/bin/python3` thì lại sẽ gặp lỗi tiếp theo `SyntaxError: invalid syntax`:  
```
npm ERR! code 2
npm ERR! path /app/node_modules/leveldown
npm ERR! command failed
npm ERR! command sh -c -- prebuild --install
npm ERR! prebuild info begin Prebuild version 4.5.0
npm ERR! prebuild ERR! configure error
npm ERR! prebuild ERR! stack Error: Command failed: /usr/bin/python3 -c import sys; print "%s.%s.%s" % sys.version_info[:3];
npm ERR! prebuild ERR! stack   File "<string>", line 1
npm ERR! prebuild ERR! stack     import sys; print "%s.%s.%s" % sys.version_info[:3];
npm ERR! prebuild ERR! stack                       ^
npm ERR! prebuild ERR! stack SyntaxError: invalid syntax
npm ERR! prebuild ERR! stack
npm ERR! prebuild ERR! stack     at ChildProcess.exithandler (node:child_process:402:12)
npm ERR! prebuild ERR! stack     at ChildProcess.emit (node:events:513:28)
npm ERR! prebuild ERR! stack     at maybeClose (node:internal/child_process:1100:16)
npm ERR! prebuild ERR! stack     at Process.ChildProcess._handle.onexit (node:internal/child_process:304:5)
npm ERR! prebuild ERR! not ok
npm ERR! prebuild ERR! build Error: Command failed: /usr/bin/python3 -c import sys; print "%s.%s.%s" % sys.version_info[:3];
npm ERR! prebuild ERR! build   File "<string>", line 1
npm ERR! prebuild ERR! build     import sys; print "%s.%s.%s" % sys.version_info[:3];
npm ERR! prebuild ERR! build                       ^
npm ERR! prebuild ERR! build SyntaxError: invalid syntax
npm ERR! prebuild ERR! build
npm ERR! prebuild ERR! build     at ChildProcess.exithandler (node:child_process:402:12)
```
Đến lỗi này thì hơi nản, có lẽ là do python3 ko phù hợp, phải dùng python2 chăng?  

Thử sửa lại Dockerfile `RUN apt-get install python2` và `ENV PYTHON=/usr/bin/python2` thì lại gặp lỗi dị hơn:  
```
npm ERR! code 2
npm ERR! path /app/node_modules/leveldown
npm ERR! command failed
npm ERR! command sh -c -- prebuild --install
npm ERR! make: Entering directory '/app/node_modules/leveldown/build'
npm ERR!   CXX(target) Release/obj.target/leveldb/deps/leveldb/leveldb-1.18.0/db/builder.o
npm ERR! make: Leaving directory '/app/node_modules/leveldown/build'
npm ERR! prebuild info begin Prebuild version 4.5.0
npm ERR! prebuild http GET https://nodejs.org/download/release/v16.18.0/node-v16.18.0-headers.tar.gz
npm ERR! prebuild http 200 https://nodejs.org/download/release/v16.18.0/node-v16.18.0-headers.tar.gz
npm ERR! prebuild http GET https://nodejs.org/download/release/v16.18.0/SHASUMS256.txt
npm ERR! prebuild http 200 https://nodejs.org/download/release/v16.18.0/SHASUMS256.txt
npm ERR! (node:27) [DEP0150] DeprecationWarning: Setting process.config is deprecated. In the future the property will be read-only.
npm ERR! (Use `node --trace-deprecation ...` to show where the warning was created)
npm ERR! prebuild info spawn /usr/bin/python2
npm ERR! prebuild info spawn args [
npm ERR! prebuild info spawn args   '/app/node_modules/node-gyp/gyp/gyp_main.py',
npm ERR! prebuild info spawn args   'binding.gyp',
npm ERR! prebuild info spawn args   '-f',
npm ERR! prebuild info spawn args   'make',
npm ERR! prebuild info spawn args   '-I',
npm ERR! prebuild info spawn args   '/app/node_modules/leveldown/build/config.gypi',
npm ERR! prebuild info spawn args   '-I',
npm ERR! prebuild info spawn args   '/app/node_modules/node-gyp/addon.gypi',
npm ERR! prebuild info spawn args   '-I',
npm ERR! prebuild info spawn args   '/app/node_modules/leveldown/16.18.0/include/node/common.gypi',
npm ERR! prebuild info spawn args   '-Dlibrary=shared_library',
npm ERR! prebuild info spawn args   '-Dvisibility=default',
npm ERR! prebuild info spawn args   '-Dnode_root_dir=/app/node_modules/leveldown/16.18.0',
npm ERR! prebuild info spawn args   '-Dnode_gyp_dir=/app/node_modules/node-gyp',
npm ERR! prebuild info spawn args   '-Dnode_lib_file=/app/node_modules/leveldown/16.18.0/<(target_arch)/node.lib',
npm ERR! prebuild info spawn args   '-Dmodule_root_dir=/app/node_modules/leveldown',
npm ERR! prebuild info spawn args   '-Dnode_engine=v8',
npm ERR! prebuild info spawn args   '--depth=.',
npm ERR! prebuild info spawn args   '--no-parallel',
npm ERR! prebuild info spawn args   '--generator-output',
npm ERR! prebuild info spawn args   'build',
npm ERR! prebuild info spawn args   '-Goutput_dir=.'
npm ERR! prebuild info spawn args ]
npm ERR! prebuild info spawn make
npm ERR! prebuild info spawn args [ 'BUILDTYPE=Release', '-C', 'build' ]
npm ERR! In file included from ../deps/leveldb/leveldb-1.18.0/port/port_posix.h:47,
npm ERR!                  from ../deps/leveldb/leveldb-1.18.0/port/port.h:16,
npm ERR!                  from ../deps/leveldb/leveldb-1.18.0/db/filename.h:14,
npm ERR!                  from ../deps/leveldb/leveldb-1.18.0/db/builder.cc:7:
npm ERR! ../deps/leveldb/leveldb-1.18.0/port/atomic_pointer.h:211:2: error: #error Please implement AtomicPointer for this platform.
npm ERR!   211 | #error Please implement AtomicPointer for this platform.
npm ERR!       |  ^~~~~
npm ERR! make: *** [deps/leveldb/leveldb.target.mk:162: Release/obj.target/leveldb/deps/leveldb/leveldb-1.18.0/db/builder.o] Error 1
npm ERR! prebuild ERR! build error
```
Lỗi này lại chịu ko thể hiểu, coi như ko fix được.

Solution: Mình chuyển sang hướng khác, sử dụng NodeJS 14:  
  - `FROM node:14.20.1-alpine` và  
  - `FROM node:14.20.1-bullseye-slim`  
thì lại OK ko có lỗi gì, trong container khi start lên mình sẽ lấy dc package-lock.json ra OK. 🤣

Như vậy dường như version NodeJS ảnh hưởng lớn đến câu lệnh `npm install`.  

-> Kết luận lại là mình nên sử dụng NodeJS v14.20.1. 

## 3.4. Dockerfile cho Debian slim image

Đây là `Dockerfile` hoàn chỉnh mà mình đã dùng để build được image từ base image là NodeJS Deiam slim:  
```sh
# FROM node:12.22.12-bullseye-slim
# FROM node:16.18.0-bullseye-slim
FROM node:14.20.1-bullseye-slim

RUN apt-get update && apt-get install -y \
    automake \
    autoconf \
    build-essential \
    software-properties-common \
    libtool \
    dpkg \
    pkg-config \
    libpng-dev \
    g++ \
    bash \
    python3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY ./package*.json /app/

RUN npm cache clean --force
RUN npm install -g gatsby@3
RUN npm ci --only=production --no-optional
# below command work with Node v14.20.1 but not Node v16.18.0 (remember to remove package-lock.json first)
# i use npm install when I want to regenerate package-lock.json
# RUN npm install --no-optional

# fix error https://stackoverflow.com/q/67639482/9922066
RUN mkdir -p /app/.cache && chmod -R 777 /app/.cache
RUN mkdir -p /app/public && chmod -R 777 /app/public

COPY . /app
RUN chown -R node:node /app
USER node

EXPOSE 8000
CMD ["gatsby", "develop", "-H", "0.0.0.0" ]

```

# 4. Docker Compose file

Sau khi đã có Dockerfile thì có thể build dc image:  
```sh
cd /hoangmnsd-the404blog-theme/
docker build  -t gatsby-app -f Dockerfile.dev .
```

Image được build khá nặng ~3.6GB:  
```
$ docker images
REPOSITORY                      TAG                     IMAGE ID       CREATED          SIZE
gatsby-app                      latest                  ddd14693d9f3   34 minutes ago   3.62GB
node                            16.18.0-bullseye-slim   1e696a126824   3 days ago       185MB
node                            16.18.0-alpine          e20db79e2fb9   3 days ago       114MB
```

Tạo file `docker-compose.yml`:  
```yml
version: "3"
services:
  web:
    image: gatsby-app:latest
    container_name: gatsby-app
    ports:
      - "8000:8000"
    volumes:
    # map all dir but exclude `node_modules, .cache, public` dir
      - /app/node_modules
      - /app/.cache/
      - /app/public/
      - .:/app
    environment:
      - NODE_ENV=development

```

Run `docker-compose up -d` và check logs của container `docker logs gatsby-app` ko có lỗi gì đặc biệt là OK  

Truy cập vào http://VM_PUBLIC_IP:8000 thì bạn sẽ thấy môi trường develop đã ok

Bây giờ dùng WinSCP sync folder từ local lên VM:
- Chọn chế độ "Keeping remote directory up to date ..."  
- Chọn Synchronize options: Delete files, exclude các folder sau: `.git, node_modules, .cache, public`  

Giờ mở VS code, edit các file trong `/content/, /src/`, bao gồm cả các file như `/gatsby-config.js` xem sao nhé.  

Mọi thứ sẽ được sync tự động vào các volume của gatsby container, sau đó phản ánh ngay lên website của bạn ở đường dẫn http://VM_PUBLIC_IP:8000.

Cần chú ý đây là quá trình Develop thôi nhé. Trong môi trường Production, ở file `Dockerfile` - sau khi build ra được `public` folder, bạn nên đưa artifacts trong `public` vào Nginx image và chỉ release Container Nginx đó thì sẽ nhẹ hơn.  

# 5. Use multi-stage to cache node_modules

Khi build các ứng dụng NodeJS luôn phải để ý đến node_modules, đây là folder sẽ tốn nhiều thời gian để install và nó cũng khá nặng, lên tới hơn 1 Gb.  

Sử dụng multi-stage trong Dockerfile giúp chúng ta khi build lại các image mới sẽ đỡ tốn thời gian hơn.

Với Dockerfile như ở phần trước thì mỗi khi phải build lại image ta sẽ tốn 120s đến 200s cho phần run `npm ci`.

Mặc dù `npm ci` được recommend sử dụng hơn so với `npm install` nhưng nhược điểm của `npm ci` lại là nó luôn xóa node_modules trước khi install packages.

Vì thế trong Dockerfile mới sắp được viết sẽ ko dùng `npm ci` nữa mà quay lại với `npm install`.

Tuy nhiên ta biết `npm install` có 1 khuyết điểm là nó sẽ tự động update package.json và package-lock.json đây là điều mình ko mong muốn.  

Để khắc điểm khuyết điểm này thì Bạn có thể specific version của các package trong package.json bằng cách kiểu như này:  
```json
"react": "^16.0.0" // carat: allow 16.1.0
"react": "~16.0.0" // tilde: allow 16.0.1
"react": "16.0.0" // exact: only 16.0.0
```

Trong project này của mình thì ko cần nên mình sẽ để nguyên package.json như nó hiện tại.

Mình sẽ tách Dockerfile thành 2 file riêng: 
- File đầu tiên là `Dockerfile.dev-bullseye-node-cache` để build node-cache chứa node_modules.  
`Dockerfile.dev-bullseye-node-cache`:

```
FROM node:14.20.1-bullseye-slim as build

RUN apt-get update && apt-get install -y \
    automake \
    autoconf \
    build-essential \
    software-properties-common \
    libtool \
    dpkg \
    pkg-config \
    libpng-dev \
    g++ \
    bash \
    python3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY ./package*.json /app/

RUN npm install -g gatsby@3.14.2 --no-optional --no-audit --progress=false
RUN npm install --no-optional --no-audit --progress=false

FROM alpine as release

COPY --from=build /app/node_modules ./node_modules
# because gatsby@3.14.2 is global package, it's node_modules store in `/usr/local/lib/node_modules`, i need to cache it to reuse later
COPY --from=build /usr/local/lib/node_modules /usr/local/lib/global_node_modules

```

- File thứ hai là `Dockerfile.dev-bullseye-use-cache` để build image sử dụng:  

```
FROM node-cache:latest as cache

FROM node:14.20.1-bullseye-slim as build

RUN apt-get update && apt-get install -y \
    automake \
    autoconf \
    build-essential \
    software-properties-common \
    libtool \
    dpkg \
    pkg-config \
    libpng-dev \
    g++ \
    bash \
    python3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY ./package*.json /app/
COPY --from=cache /node_modules /app/node_modules
# because gatsby@3.14.2 is global package, i need to bring it from node-cache to global package path: /usr/local/lib/node_modules
COPY --from=cache /usr/local/lib/global_node_modules /usr/local/lib/node_modules
# gatsby@3.14.2 work as a binary at /usr/local/bin/gatsby - a symlink from /usr/local/lib/node_modules/gatsby/cli.js
RUN ln -s /usr/local/lib/node_modules/gatsby/cli.js /usr/local/bin/gatsby

RUN npm install --no-optional --no-audit --progress=false --prefer-offline

# fix error https://stackoverflow.com/q/67639482/9922066
RUN mkdir -p /app/.cache && chmod -R 777 /app/.cache
RUN mkdir -p /app/public && chmod -R 777 /app/public

COPY . /app
RUN chown -R node:node /app
USER node

EXPOSE 8000
CMD ["gatsby", "develop", "-H", "0.0.0.0" ]

```

Để sử dụng, đầu tiên cần build images:  

```sh
cd /hoangmnsd-the404blog-theme/
DOCKER_BUILDKIT=1 docker build  -t node-cache -f Dockerfile.dev-bullseye-node-cache .
# now you have image `node-cache:latest` for re-using in below build step
# it may take 382.1s in total to FINISHED, but you only need to run it once

docker build -t gatsby-app -f Dockerfile.dev-bullseye-use-cache .
# at first time, it may take 120s in `npm install` step
# now you have image `gatsby-app:latest`
```

If you change something in `package.json`, just rebuild the `gatsby-app` image:  

```sh
docker build -t gatsby-app -f Dockerfile.dev-bullseye-use-cache .
# from second time, it may take 25s in `npm install` step
```

Run Docker Compose:  

```sh
cd /hoangmnsd-the404blog-theme/
docker-compose up -d
# Your app is running on http://localhost:8000  
```

Now, if you change something in `./src/* or ./content/* or ./gatsby-*`, docker-compose automaticly mount them to container, no need action on re-build/ re-run container.  

⛔ Lỗi: Trên 1 số OS (dùng kiến trúc arm64), có vẻ Docker BuildKit ko nhận ra local image: https://github.com/docker/cli/issues/3286.  
Dẫn đến lỗi này:  

```
$ DOCKER_BUILDKIT=1 docker build -t gatsby-app -f Dockerfile.dev-bullseye-use-cache .             
[+] Building 0.9s (5/5) FINISHED
 => [internal] load build definition from Dockerfile.dev-bullseye-use-cache                                                                               0.0s
 => => transferring dockerfile: 61B                                                                                                                       0.0s
 => [internal] load .dockerignore                                                                                                                         0.0s
 => => transferring context: 34B                                                                                                                          0.0s
 => [internal] load metadata for docker.io/library/node:14.20.1-bullseye-slim                                                                             0.4s
 => ERROR [internal] load metadata for docker.io/library/node-cache:latest                                                                                0.8s
 => [auth] library/node-cache:pull token for registry-1.docker.io                                                                                         0.0s
------
 > [internal] load metadata for docker.io/library/node-cache:latest:
------
failed to solve with frontend dockerfile.v0: failed to create LLB definition: pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
```

Nó cứ chăm chăm tìm image `docker.io/library/node-cache:latest` tuy nhiên đó là 1 image local của mình.  
Có 1 cách workaround: https://github.com/docker/cli/issues/3286#issuecomment-1168394369.  
Hiện mình chưa thấy cách fix phù hợp vì mình ko muốn dùng `--platform=linux/arm64` trong các command build cũng như trong Dockerfile.  

⛔ Lỗi: `exec user process caused: exec format error`
-> Cùng là Ubuntu18.04 OS, nhưng nếu CPU khác nhau thì cùng 1 command vẫn có thể xảy ra tình trạng: "Máy này lỗi nhưng máy kia OK".  
Là do CPU của bạn đang dùng arm64 architecture. Trong khi phần lớn docker image dc thiết kế cho amd64 architecture.  
https://forums.docker.com/t/daemon-error-responses-exec-format-error-and-container-is-restarting-wait-until-the-container-is-running/110385/2  



# 6. Phân biệt CMD và ENTRYPOINT trong Dockerfile

1 bài viết dễ hiểu: https://phoenixnap.com/kb/docker-cmd-vs-entrypoint

Tóm tắt:  
- CMD thường để cuối cùng trong Dockerfile, dùng để run các câu lệnh default khi container được run, có thể bị ghi đè bởi `docker run`.  
- ENTRYPOINT cũng thường để cuối cùng trong Dockerfile, dùng để run các câu lệnh bắt buộc phải chạy khi container được run.  

Ex:  
```
FROM ubuntu
MAINTAINER sofija
RUN apt-get update
ENTRYPOINT ["echo", "Hello"]
CMD ["World1234"]
```

Test:  
```sh
sudo docker build . 

# run `docker run`
sudo docker run [container_name]
# output: Hello World1234

# run `docker run` with command
sudo docker run [container_name] Hoangmnsd
# output: Hello Hoangmnsd
# -> bởi vì Hoangmnsd đã ghi đè lên CMD, nhưng nó ko thể ghi đè lên ENTRYPOINT, nên vẫn có chữ Hello

```

# 7. Run on Gitlab CI [PENDING]

Phần tiếp theo mình sẽ cố gắng đưa ứng dụng này lên Gitlab CI. Ý tưởng sẽ là:  
- Dùng VM làm Gitlab Runner  
- Viết thêm vào Dockerfile phần build ra `public` folder và sử dụng nó.  
- Push code lên Gitlab, file `.gitlab-ci` sẽ trigger Runner build ra image và push image đó lên 1 Registry nào đó (Có thể ACR).    
- Ở dưới local có thể pull image vừa build về và sử dụng.  
Đây là 1 luồng cơ bản của CI.  

...

# 8. Best practices

## 8.1. Dùng `npm ci` thay cho `npm install`

Nên xem xét việc trong Dockerfile thêm `package-lock.json` vào rồi mới install node_modules. Điều đó giúp các version được lock lại. 
Theo practices thì nên sử dụng `RUN npm ci --only=production` thay cho `npm install`. 
( Adding `--only=prod` or `--production` would not install `devDependencies` and just install `dependencies`.)

## 8.2. Dùng Debian slim image thay vì Alpine image

Ưu tiên các image Debian slim image hơn Alpine image vì:  
> It uses the `bullseye` image variant which is the current stable Debian 11 version with a far enough end-of-life date. And finally it uses the `slim` image variant to specify a smaller software footprint of the operating system which results in less than 200MB of image size, including the Node.js runtime and tooling.

> Node.js Alpine is an unofficial Docker container image build that is maintained by the Node.js Docker team. The Node.js image bundles the Alpine operating system which is powered by the minimal busybox software tooling and the musl C library implementation. These two Node.js Alpine image characteristics contribute to the Docker image being unofficially supported by the Node.js team. Furthermore, many security vulnerabilities scanners can’t easily detect software artifacts or runtimes on Node.js Alpine images, which is counterproductive to efforts to secure your container images

Với Alpine image thì sẽ install các packge bằng `apk` command kiểu này:  
```
FROM node:14.20.1-alpine

RUN apk --no-cache update 
```

Với Debian slim image thì sẽ install các package bằng `apt-get` command kiểu này:  
```
FROM node:16.17.0-bullseye-slim

RUN apt-get update 
```
-> Có thể thấy `apt-get` command sẽ gần gũi thân thiện với Ubuntu/Linux hơn `apk` command.  

## 8.3. Chỉ định user node thay vì root

Không run container bằng root user, trong Dockerfile hãy dùng `USER node` để run các app nodejs.  

## 8.4. Nhớ run apt-get update

Hãy run `RUN apt-get update && apt-get upgrade -y` trong Dockerfile để fix Docker image vulnerabilities.  

## 8.5. Nên dùng file .dockerignore

Dùng `.dockerignore` file để ko đưa các file ko cần thiết vào khi build image.  

## 8.6. Dùng các tools linter và dive

https://github.com/hadolint/hadolint  -> tool để check convention cho Dockerfile.  

https://github.com/wagoodman/dive -> tool để check size của các layer, từ đó giúp bạn debug được command nào tốn nhiều dung lượng của image.  

## 8.7. COPY và chown/chmod trên cùng 1 command

Nếu dùng [dive](https://github.com/wagoodman/dive) để phân tích image tạo bởi Dockerfile như này:  
```
...
COPY . /app
RUN chown -R node:node /app
...
```
Có thể bạn sẽ thấy việc command `RUN chown -R node:node /app` sẽ tiêu thụ 1 lượng dung lượng nhất định. Đó là do việc change owner cần nó phải copy file ra 1 read-only layer và paste lại vào 1 layer mới, vô tình làm tốn thời gian và duplicate dung lượng image lên

Nên sửa lại thành:  
```
...
COPY --chown=node:node . /app
...
```
Khi đó sẽ giảm được thời gian và dung lượng image khá nhiều. Trường hợp của mình là từ 2.93 GB xuống 1.85 GB. 😍

## 8.8. Dùng multi-stage build để prevent secret leak (?)

https://snyk.io/blog/10-best-practices-to-containerize-nodejs-web-applications-with-docker/#

Dùng MULTI-STAGE BUILDS để ngăn chặn việc leak các sensitive secret vào trong image.  

Nếu bạn đang build Docker cho công việc, thì khả năng cao bạn sẽ dùng 1 private NPM registry, trong trường hợp đó bạn sẽ cần truyền NPM_TOKEN vào để run `npm install`

Ví dụ:  
```
FROM node:16.17.0-bullseye-slim

RUN apt-get update && apt-get install -y --no-install-recommends dumb-init
ENV NODE_ENV production
ENV NPM_TOKEN 1234
WORKDIR /usr/src/app
COPY --chown=node:node . .
#RUN npm ci --only=production
RUN echo "//registry.npmjs.org/:_authToken=$NPM_TOKEN" > .npmrc && \
   npm ci --only=production
USER node
CMD ["dumb-init", "node", "server.js"]
```
-> Viết như trên là **NOT GOOD** Vì đưa TOKEN vào .npmrc file nên bạn sẽ cần xóa file đó đi:  

```
RUN echo "//registry.npmjs.org/:_authToken=$NPM_TOKEN" > .npmrc && \
   npm ci --only=production; \
   rm -rf .npmrc
```

Khi build bạn sẽ truyền NPM_TOKEN vào quá biến môi trường:  
```sh
docker build . -t nodejs-tutorial --build-arg NPM_TOKEN=1234
```
-> Nhưng như thế vẫn **NOT GOOD** vì khi run `docker history IMAGE_NAME` sẽ thấy được history và giá trị của NPM_TOKEN:  
```
IMAGE          CREATED              CREATED BY                                      SIZE      COMMENT
b4c2c78acaba   About a minute ago   CMD ["dumb-init" "node" "server.js"]            0B        buildkit.dockerfile.v0
<missing>      About a minute ago   USER node                                       0B        buildkit.dockerfile.v0
<missing>      About a minute ago   RUN |1 NPM_TOKEN=1234 /bin/sh -c echo "//reg…   5.71MB    buildkit.dockerfile.v0
<missing>      About a minute ago   ARG NPM_TOKEN                                   0B        buildkit.dockerfile.v0
<missing>      About a minute ago   COPY . . # buildkit                             15.3kB    buildkit.dockerfile.v0
<missing>      About a minute ago   WORKDIR /usr/src/app                            0B        buildkit.dockerfile.v0
<missing>      About a minute ago   ENV NODE_ENV=production                         0B        buildkit.dockerfile.v0
```

Ở đây người ta hướng dẫn chia làm 2 stage:  
```
# --------------> The build image
FROM node:latest AS build
RUN apt-get update && apt-get install -y --no-install-recommends dumb-init
ARG NPM_TOKEN
WORKDIR /usr/src/app
COPY package*.json /usr/src/app/
RUN echo "//registry.npmjs.org/:_authToken=$NPM_TOKEN" > .npmrc && \
   npm ci --only=production && \
   rm -f .npmrc
 
# --------------> The production image
FROM node:16.17.0-bullseye-slim

ENV NODE_ENV production
COPY --from=build /usr/bin/dumb-init /usr/bin/dumb-init
USER node
WORKDIR /usr/src/app
COPY --chown=node:node --from=build /usr/src/app/node_modules /usr/src/app/node_modules
COPY --chown=node:node . /usr/src/app
CMD ["dumb-init", "node", "server.js"]
```

Stage build được sử dụng NPM_TOKEN và sau đó sẽ là input của stage cuối cùng. 

Khi đó `docker history IMAGE_NAME` sẽ **KHÔNG** thấy được history và giá trị của NPM_TOKEN

Tuy nhiên dùng cách này bạn sẽ cần chắc chắn file `.npmrc` ko ở trong file `.dockerignore`, vì chúng ta cần nó khi RUN `npm ci` mà.
Và lại khi run `docker build`, secret vẫn ở dang plain-text trên command.

Điều này gây ra 1 chút khó chịu vì ko đảm bảo security lắm. Hãy tìm hiểu cách tiếp theo.  

## 8.9. Dùng mount=type=secret để prevent secret leak

Với cách này bạn có thể đưa file .npmrc vào `.dockerignore` ngay từ đầu:  
file `.dockerignore`:  

```
.dockerignore
node_modules
npm-debug.log
Dockerfile
.git
.gitignore
.npmrc
```

`Dockerfile`:  

```
# --------------> The build image
FROM node:latest AS build
RUN apt-get update && apt-get install -y --no-install-recommends dumb-init
WORKDIR /usr/src/app
COPY package*.json /usr/src/app/
RUN --mount=type=secret,mode=0644,id=npmrc,target=/usr/src/app/.npmrc npm ci --only=production
 
# --------------> The production image
FROM node:16.17.0-bullseye-slim

ENV NODE_ENV production
COPY --from=build /usr/bin/dumb-init /usr/bin/dumb-init
USER node
WORKDIR /usr/src/app
COPY --chown=node:node --from=build /usr/src/app/node_modules /usr/src/app/node_modules
COPY --chown=node:node . /usr/src/app
CMD ["dumb-init", "node", "server.js"]
```
-> Bạn sẽ thấy câu lệnh `RUN --mount=type=secret,mode=0644,id=npmrc,target=/usr/src/app/.npmrc npm ci --only=production`.  
Nó đã mount cái id `id=npmrc` vào trong container ở path `/usr/src/app/.npmrc`

Câu lệnh `doker build` sẽ như này:  
```sh
docker build . -t nodejs-tutorial --secret id=npmrc,src=.npmrc
```
-> Không còn secret dưới dạng plain-text nữa. Bạn chỉ định 1 secret với id=npmrc, source file ở path `.npmrc`

Cách này có thể nói là chuyên nghiệp hơn cách trên khá nhiều đấy.  

Tương tự như file .npmrc, các bạn có thể áp dụng cho trường hợp git clone từ 1 private git repo về.  

Khi đó chắc hẳn các bạn cũng cần đưa PRIVATE_KEY vào builder để sử dụng, ko muốn cho PRIVATE_KEY vào image thì hãy dùng cách `mount=type=secret` này nhé.

## 8.10. Dùng mount=type=ssh để prevent SSH key leak

http://blog.oddbit.com/post/2019-02-24-docker-build-learns-about-secr/

1. Để test thì cần tự generate SSH keypair trên máy nào cũng được, mình tạo trên Laptop:  

```sh
ssh-keygen
# Bài này nói rằng câu lệnh trên generate ra 1 bộ key yếu và dễ bị bruteforce: 
# Source: https://dev.to/levivm/how-to-use-ssh-and-ssh-agent-forwarding-more-secure-ssh-2c32
# Nếu có thể hãy dùng command sau:  
# ssh-keygen -o -a 100 -t ed25519
```

bạn sẽ được 1 bộ key:  

```
gitlab_com_rsa
gitlab_com_rsa.pub
```

2. Tạo 1 private project trên Gitlab.  
Cái này tùy ý project nào cũng dc, mình tạo project `git@gitlab.com:inmessionante/spring-maven-postgres-docker-k8s.git`

3. Add public SSH key `gitlab_com_rsa.pub` vào Gitlab bằng cách:  
https://gitlab.com/-/profile -> `SSH Keys` Tab -> Add cái nội dung của `gitlab_com_rsa.pub` vào

4. Trên VM Run Docker, tạo folder để test:  

```sh
mkdir /opt/devops/docker-ssh-agent-lab
```

Copy file SSH private key `gitlab_com_rsa` lên `/home/ubuntu/.ssh` (chỗ này tùy bạn, để đâu cho secure cũng được)

File `/opt/devops/docker-ssh-agent-lab/Dockerfile`:  

```
# syntax=docker/dockerfile:1.0.0-experimental

FROM alpine
RUN apk add --update git openssh

# This is necessary to prevent the "git clone" operation from failing
# with an "unknown host key" error.
RUN mkdir -m 700 /root/.ssh; \
  touch -m 600 /root/.ssh/known_hosts; \
  ssh-keyscan gitlab.com > /root/.ssh/known_hosts

# This command has access to the "github" key
RUN --mount=type=ssh,id=gitlab git clone git@gitlab.com:inmessionante/spring-maven-postgres-docker-k8s.git

```

5. Run Docker Build

```sh
cd /opt/devops/docker-ssh-agent-lab
DOCKER_BUILDKIT=1 docker build --ssh gitlab=/home/ubuntu/.ssh/gitlab_com_rsa -t buildtest .
```

6. Confirm đã git clone được project vào trong image  

```sh
$ docker run buildtest ls -lsa
total 80
     4 drwxr-xr-x    1 root     root          4096 Nov  6 07:11 .
     4 drwxr-xr-x    1 root     root          4096 Nov  6 07:11 ..
     0 -rwxr-xr-x    1 root     root             0 Nov  6 07:11 .dockerenv
     0 -rw-r--r--    1 root     root             0 Nov  6 07:08 600
     4 drwxr-xr-x    2 root     root          4096 Aug  9 08:49 bin
     0 drwxr-xr-x    5 root     root           340 Nov  6 07:11 dev
     4 drwxr-xr-x    1 root     root          4096 Nov  6 07:11 etc
     4 drwxr-xr-x    2 root     root          4096 Aug  9 08:49 home
     8 drwxr-xr-x    1 root     root          4096 Aug  9 08:49 lib
     4 drwxr-xr-x    5 root     root          4096 Aug  9 08:49 media
     4 drwxr-xr-x    2 root     root          4096 Aug  9 08:49 mnt
     4 drwxr-xr-x    2 root     root          4096 Aug  9 08:49 opt
     0 dr-xr-xr-x  287 root     root             0 Nov  6 07:11 proc
     4 drwx------    1 root     root          4096 Nov  6 07:08 root
     4 drwxr-xr-x    1 root     root          4096 Nov  6 07:08 run
     4 drwxr-xr-x    2 root     root          4096 Aug  9 08:49 sbin
     4 drwxr-xr-x    7 root     root          4096 Nov  6 07:08 spring-maven-postgres-docker-k8s
     4 drwxr-xr-x    2 root     root          4096 Aug  9 08:49 srv
     0 dr-xr-xr-x   13 root     root             0 Nov  6 07:11 sys
     4 drwxrwxrwt    2 root     root          4096 Aug  9 08:49 tmp
     8 drwxr-xr-x    1 root     root          4096 Nov  6 07:08 usr
     8 drwxr-xr-x    1 root     root          4096 Nov  6 07:08 var
```
OK?

7. Dùng ssh-agent và `$SSH_AUTH_SOCK`

Sau bước 6 có vẻ đã OK? Ở bước số 5 chúng ta phải chỉ định đường dẫn của private key, mình ko thích điều này lắm.  

Nên mình sẽ dùng command này:  

```sh
cd /opt/devops/docker-ssh-agent-lab
DOCKER_BUILDKIT=1 docker build --ssh gitlab=$SSH_AUTH_SOCK -t buildtest .
```

Tuy nhiên bạn sẽ bị lỗi sau nếu ko chuẩn bị trước:  

```
$ DOCKER_BUILDKIT=1 docker build --ssh gitlab=$SSH_AUTH_SOCK -t buildtest .
could not parse ssh: [gitlab=]: invalid empty ssh agent socket, make sure SSH_AUTH_SOCK is set
```

Bạn cần đưa private key vào ssh-agent trước cho nó quản lý:  

```sh
# start the ssh-agent in the background
$ eval "$(ssh-agent -s)"
Agent pid 9501

# Add your SSH private key to the ssh-agent
$ ssh-add ~/.ssh/gitlab_com_rsa
Identity added: /home/ubuntu/.ssh/gitlab_com_rsa 

# List identities that ssh-agent is managing
$ ssh-add -L
ssh-rsa AAAA...B3NzaC1yc2EAqClFkhB9mUfuVGPMe+upN4AV7LS6toRuwHdTJoUfbcjTc9zttxtoKogMXJu/rrf6Pv7I7ksLOL26PyI3vPacnw/VcrVplNw8367TMtap4K9MoWqup2UGyozm6ycd/inMiyeIy...9s=
```

Tại thời điểm này biến môi trường `$SSH_AUTH_SOCK` đã được set, bạn có thể check bằng command:  

```
echo $SSH_AUTH_SOCK
```

Giờ chạy lại command docker build:  

```
$ DOCKER_BUILDKIT=1 docker build --ssh gitlab=$SSH_AUTH_SOCK -t buildtest .
[+] Building 8.5s (14/14) FINISHED
 => [internal] load build definition from Dockerfile                                                0.0s
 => => transferring dockerfile: 38B                                                                 0.0s
 => [internal] load .dockerignore                                                                   0.0s
 => => transferring context: 2B                                                                     0.0s
 => resolve image config for docker.io/docker/dockerfile:1.0.0-experimental                         0.9s
 => [auth] docker/dockerfile:pull token for registry-1.docker.io                                    0.0s
 => CACHED docker-image://docker.io/docker/dockerfile:1.0.0-experimental@sha256:d2d402b6fa1dae752f  0.0s
 => [internal] load build definition from Dockerfile                                                0.0s
 => => transferring dockerfile: 38B                                                                 0.0s
 => [internal] load .dockerignore                                                                   0.1s
 => => transferring context: 2B                                                                     0.0s
 => [internal] load metadata for docker.io/library/alpine:latest                                    0.6s
 => [auth] library/alpine:pull token for registry-1.docker.io                                       0.0s
 => [1/4] FROM docker.io/library/alpine@sha256:bc41182d7ef5ffc53a40b044e725193bc10142a1243f395ee85  0.0s
 => CACHED [2/4] RUN apk add --update git openssh                                                   0.0s
 => CACHED [3/4] RUN mkdir -m 700 /root/.ssh;   touch -m 600 /root/.ssh/known_hosts;   ssh-keyscan  0.0s
 => CACHED [4/4] RUN --mount=type=ssh,id=gitlab git clone git@gitlab.com:inmessionante/spring-mave  0.0s
 => exporting to image                                                                              0.0s
 => => exporting layers                                                                             0.0s
 => => writing image sha256:7d93dafe042c123483ffeafee2b63be48bcf3d30b425b47847b2988399cebc65        0.0s
 => => naming to docker.io/library/buildtest 
```

8. Sau step 7, Trên môi trường Develop bình thường thì đến đây mọi thứ có vẻ đã ổn 😂.  

Nhưng trên CI thì khác, VM này sẽ là Builder của chúng ta, việc Builder chứa private key nghe có vẻ sẽ không secure cho lắm.  

Trong trường hợp Builder này bị hack, hoặc nhiều người có quyền truy cập, chúng ta hoàn toàn có thể bị leak cái private key ấy ra ngoài.  

Vậy nếu chúng ta muốn Builder cũng không thể xem được key thì sao. Ta giả sử mình đang dùng Gitlab CI nhé.  

Modify your `.gitlab-ci.yml` with a before_script action. In the following example, a Debian based image is assumed. Edit to your needs:  

```sh
before_script:
  ##
  ## Install ssh-agent if not already installed, it is required by Docker.
  ## (change apt-get to yum if you use an RPM-based image)
  ##
  - 'command -v ssh-agent >/dev/null || ( apt-get update -y && apt-get install openssh-client -y )'

  ##
  ## Run ssh-agent (inside the build environment)
  ##
  - eval $(ssh-agent -s)

  ##
  ## Add the SSH key stored in SSH_PRIVATE_KEY variable to the agent store
  ## We're using tr to fix line endings which makes ed25519 keys work
  ## without extra base64 encoding.
  ## https://gitlab.com/gitlab-examples/ssh-private-key/issues/1#note_48526556
  ##
  - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -

  ##
  ## Create the SSH directory and give it the right permissions
  ##
  - mkdir -p ~/.ssh
  - chmod 700 ~/.ssh

  ##
  ## Optionally, if you will be using any Git commands, set the user name and
  ## and email.
  ##
  # - git config --global user.email "user@example.com"
  # - git config --global user.name "User name"
```

Như vậy là chỉ cần truyền biến môi trường trên Gitlab CI là ok, Builder sẽ không lưu các private key nữa. 

Đến đây chúng ta thấy được các tính năng hữu ích của SSH Agent 😍 nên mình quyết định xa rời chủ đề chính của bài này để take notes về SSH Agent thêm 1 chút: 

## 8.11. SSH Agent Forwarding

https://dev.to/levivm/how-to-use-ssh-and-ssh-agent-forwarding-more-secure-ssh-2c32

Giả sử bạn làm việc trên Laptop (local).  
Bạn có 1 VM Ubuntu trên Cloud. VM này có thể share cho nhiều teammate cùng nhau sử dụng. VM này cần pull source từ 1 private repository trên Gitlab.com.   
Bạn thường pull source về bằng 1 SSH private key (mà bạn đã add public key của nó vào Gitlab rồi).  
Cái private key đó bạn đang lưu trên VM.  
Giờ bạn ko muốn VM đó lưu private key nữa (Vì người khác/admin) có thể vào và lấy key đó.  
-> Đây là lúc cần sử dụng SSH Agent Forwarding.  

Ngắn gọn: Bạn forward SSH Agent session từ Laptop lên VM. Khiến nó có thể pull source code về mà ko cần lưu cái private key.  

Cần mô tả rõ, trên Laptop của bạn có 2 private key:  
- `VM_PRIVATE_KEY`: dùng để SSH từ Laptop lên VM. 
- `GITLAB_PRIVATE_KEY`: dùng để pull source từ Gitlab.com về. Trước đây bạn lưu nó trên VM, giờ ko muốn nữa.  
- `ubuntu@112.222.54.31`: user và IP của VM.  

bài này mình dùng GitBash trên Windows:  

```sh
# start the ssh-agent in the background
$ eval "$(ssh-agent -s)"
Agent pid 9501

# Add your SSH private key to the ssh-agent
$ ssh-add ./GITLAB_PRIVATE_KEY
Identity added: ...

# Tại thời điểm này: ssh-agent đã sẵn sàng cho bạn forward 

# SSH from Laptop to VM and forward agent. 
# -A option enables forwarding of the authentication agent connection. 
$ ssh -A -i VM_PRIVATE_KEY ubuntu@112.222.54.31

# Tại thời điểm này bạn đã login vào VM, 
# bạn sẽ thấy $SSH_AUTH_SOCK có giá trị 
$ echo $SSH_AUTH_SOCK
# output: /tmp/ssh-baaawdgssv/agent.12322

# Test connection
$ ssh -T git@gitlab.com
# Hãy thử pull source từ 1 private repository của bạn trên Gitlab.com về xem sao. 
# chắc chắn phải pull được mới OK nhé.  
```

Phải nói cách này khá hay và secure, tuy nhiên việc forward ssh-agent lên VM cũng chả khác nào đưa key của bạn lên VM, hãy chắc chắn xóa session trước khi bạn logout khỏi con VM dùng chung này. Có 1 vài cách để tự động chuyện clear ssh-agent là bài này: https://rabexc.org/posts/pitfalls-of-ssh-agents

Ngoài ra, trường hợp Gitlab self-hosted server đứng sau VPN thì mình chưa thử.  


# CREDIT

https://walterteng.com/gatsby-docker  
https://dev.to/stoutlabs/my-docker-setup-for-gatsbyjs-and-nextjs-5gao   
kết hợp nginx để serve public dir https://valenciandigital.com/insights/why-containerize-your-gatsby-application  
best practices: https://snyk.io/blog/10-best-practices-to-containerize-nodejs-web-applications-with-docker/    
best practices: https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md  
best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/   
best practices: https://adambrodziak.pl/dockerfile-good-practices-for-node-and-npm  
https://itnext.io/how-to-speed-up-node-js-modules-installation-in-ci-cd-pipeline-as-of-2020-4865d77c0eb7  
https://forum.gitlab.com/t/how-to-cache-node-modules-globally-for-all-pipelines-for-a-project/49169  
so sánh CMD vs ENTRYPOINT trong Dockerfile: https://phoenixnap.com/kb/docker-cmd-vs-entrypoint  
https://remelehane.dev/posts/diy-node-cache-for-docker-ci/  
https://blog.saeloun.com/2022/07/12/docker-cache.html  
https://stackoverflow.com/questions/54574821/docker-build-not-using-cache-when-copying-gemfile-while-using-cache-from#comment98285860_54574821  
https://youtu.be/r_UBWjMUd-0  
http://blog.oddbit.com/post/2019-02-24-docker-build-learns-about-secr/  
https://docs.gitlab.com/ee/ci/ssh_keys/#ssh-keys-when-using-the-docker-executor  