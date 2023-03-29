---
title: "OpenSSL with Python and Bash"
date: 2022-11-20T23:09:57+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [Python,OpenSSL,Notes]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Archive 1 script nhỏ demo về dùng openssl aes256"
---

# Story

Bài toán là: viết 2 script (Bashell và python3.9) để encrypt string theo AES-256 sao cho kết quả phải giống nhau giữa Bashell và Python3.9

Khi chạy bashell thì đơn giản, chúng ta cần dùng openssl version 1.1.1:
```sh
$ echo -n Hello | openssl enc -aes-256-cbc  -pass pass:"qwerty" -e -base64 -nosalt -md md5 -p
*** WARNING : deprecated key derivation used.
Using -iter or -pbkdf2 would be better.
key=D8578EDF8458CE06FBC5BB76A58C5CA452E5CFB01236818B586F3F17BEF92D59
iv =7CE322DF4C30C37DDD74C05B170A74E6
wMdoe1EZD4tVU9Fm/AWbXg==
```
-> Command trên: 
- Encrpyt string `Hello` với password để encrypt là `qwerty`.   
- Output ra dưới dạng base64.  
- Chọn option `-nosalt` để đảm bảo có execute bao nhiêu lần cũng ra giống nhau. (cái này ko đc recommend lắm, nhưng bài toán của mình cần kết quả giống nhau thì hoặc là chọn `nosalt` hoặc là chỉ định rõ giá trị của Salt. Ở đây minh chọn `nosalt`).   
- Chọn thuật toán để encrypt là `md5`, bạn có thể chọn `SHA256` nữa. Nhưng chú ý chỉ định rõ dùng cái nào nhé.   
- Chọn `-p` để nó output ra `key` và `iv`.  
- `key` và `iv` là 2 chuỗi string được tạo ra bởi password mà chúng ta cung cấp, openssl sẽ dùng key và iv để encrypt string `Hello`.  


Còn đây là kết quả của function python3:  
```sh
$ python3 test-aes-ok.py

salt=
key=D8578EDF8458CE06FBC5BB76A58C5CA452E5CFB01236818B586F3F17BEF92D59
iv=7CE322DF4C30C37DDD74C05B170A74E6

Cipher (CBC) - Base64 without salt:      wMdoe1EZD4tVU9Fm/AWbXg==
```

-> Có thể thấy key,iv,cipher base64 quả đều giống nhau -> OK


Sau đây là function python3.9 mình đã viết sau khi cóp nhặt trên internet: 
(Các bạn có thể test cả tính năng chỉ định giá trị cho Salt. Kết quả vẫn sẽ ra giống nhau) 

```python
# https://asecuritysite.com/encryption/aes_python
from Crypto.Cipher import AES

import base64
import Padding
import binascii

'''
USAGE example: python3 test-aes-ok.py

Install python3.9 and library:
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.9
sudo apt-get install python3-pip
sudo apt install python3.9-distutils
pip3 install --upgrade setuptools
pip3 install --upgrade pip
pip3 install --upgrade distlib
pip3 install pycryptodome
pip3 install Padding

Description:
This script try to get same result of bash shell commands:
echo -n Hello | openssl enc -aes-256-cbc  -pass pass:"qwerty" -e -base64 -S 241fa86763b85341 -md md5 -p
echo -n Hello | openssl enc -aes-256-cbc  -pass pass:"qwerty" -e -base64 -nosalt -md md5 -p
'''

def get_key_and_iv(password, salt, klen=32, ilen=16, msgdgst='md5'):

    mdf = getattr(__import__('hashlib', fromlist=[msgdgst]), msgdgst)
    password = password.encode('ascii', 'ignore')  # convert to ASCII
    salt = bytearray.fromhex(salt) # convert to ASCII

    try:
        maxlen = klen + ilen
        keyiv = mdf((password + salt)).digest()
        tmp = [keyiv]
        while len(tmp) < maxlen:
            tmp.append( mdf(tmp[-1] + password + salt).digest() )
            keyiv += tmp[-1]  # append the last byte
        key = keyiv[:klen]
        iv = keyiv[klen:klen+ilen]
        print('\nsalt=' + binascii.hexlify(salt).decode('ascii').upper())
        print('key=' + binascii.hexlify(key).decode('ascii').upper())
        print('iv=' + binascii.hexlify(iv).decode('ascii').upper())
        return key, iv
    except UnicodeDecodeError:
         return None, None

def encrypt(plaintext,key, mode,salt):
    key,iv=get_key_and_iv(key,salt)

    encobj = AES.new(key,mode,iv)
    return(encobj.encrypt(plaintext.encode()))

# '''
# # Test #1 with salt, same ressult to command:
# # echo -n Hello | openssl enc -aes-256-cbc  -pass pass:"qwerty" -e -base64 -S 241fa86763b85341  -md md5 -p
# '''
# plaintext_1='Hello'
# pwd_1='qwerty'
# salt_1='241fa86763b85341'

# plaintext = Padding.appendPadding(plaintext_1,mode='CMS')
# ciphertext = encrypt(plaintext,pwd_1,AES.MODE_CBC,salt_1)
# ctext = b'Salted__' + bytearray.fromhex(salt_1) + ciphertext
# print ("\nCipher (CBC) - Base64 with salt:\t",base64.b64encode(bytearray(ctext)).decode())


'''
# Test #2 with nosalt, same ressult to command:
# echo -n Hello | openssl enc -aes-256-cbc  -pass pass:"qwerty" -e -base64 -nosalt -md md5 -p
'''
plaintext_2='Hello'
pwd_2='qwerty'
salt_2=''

plaintext = Padding.appendPadding(plaintext_2,mode='CMS')
ciphertext = encrypt(plaintext,pwd_2,AES.MODE_CBC,salt_2)
print ("\nCipher (CBC) - Base64 without salt:\t",base64.b64encode(bytearray(ciphertext)).decode())


# '''
# # Test #3 with nosalt, same ressult to command:
# # echo -n bbbb | openssl enc -aes-256-cbc  -pass pass:"XXXXX" -e -base64 -nosalt -md md5 -p
# '''
# plaintext_3='bbbb'
# pwd_3='XXXXX'
# salt_3=''

# plaintext = Padding.appendPadding(plaintext_3,mode='CMS')
# ciphertext = encrypt(plaintext,pwd_3,AES.MODE_CBC,salt_3)
# print ("\nCipher (CBC) - Base64 without salt:\t",base64.b64encode(bytearray(ciphertext)).decode())
```

# Quản lý multi-version cho python trên ubuntu18.04

https://hackersandslackers.com/multiple-python-versions-ubuntu-20-04/

```sh
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.9
```

Để xem trên máy hiện tại có những version python3 nào:  
```sh
ls /usr/bin/python3*
/usr/bin/python3            /usr/bin/python3-jsonpointer  /usr/bin/python3.6m         /usr/bin/python3m-config
/usr/bin/python3-config     /usr/bin/python3-jsonschema   /usr/bin/python3.6m-config
/usr/bin/python3-jsondiff   /usr/bin/python3.6            /usr/bin/python3.9
/usr/bin/python3-jsonpatch  /usr/bin/python3.6-config     /usr/bin/python3m
```
-> có 2 version 3.6 và 3.9

Set alternative versions for Python:  
```sh
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 2

$ update-alternatives --list python3
/usr/bin/python3.8
/usr/bin/python3.9
```

Giờ nếu muốn swap giữa các version python:  
```sh
$ update-alternatives --config python3
There are 2 choices for the alternative python3 (providing /usr/bin/python3).

  Selection    Path                Priority   Status
------------------------------------------------------------
* 0            /usr/bin/python3.9   2         auto mode
  1            /usr/bin/python3.6   1         manual mode
  2            /usr/bin/python3.9   2         manual mode

Press <enter> to keep the current choice[*], or type selection number:
```

# CREDIT

https://asecuritysite.com/encryption/aes_python