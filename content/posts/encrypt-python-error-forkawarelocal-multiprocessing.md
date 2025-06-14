---
title: "Python Error: ForkAwareLocal Multiprocessing"
date: 2023-02-11T23:43:22+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [Python]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Lỗi AttributeError: 'ForkAwareLocal' object has no attribute 'connection'"
---

Lỗi này xảy ra với hàm schedule-check-blog-comment-v3 của mình, 

Cái nguy hiểm của nó là thi thoảng mói xảy ra. Lúc test thì ngon lành, nếu ko monitor thường xuyên thì sẽ ko biết có lỗi

Gần đây check cái log monitoring của Lambda mới thấy tỉ lệ lỗi khá nhiều: (ảnh) trong 14 lần chạy gần nhất thì lỗi đến 6 lần

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/lambda-monitor-error-count.jpg)

Sau khi tìm xem log thì thấy lỗi `AttributeError: 'ForkAwareLocal' object has no attribute 'connection'` này:

```
2023-03-07T15:00:10.186+07:00    [INFO] 2023-03-07T08:00:10.186Z Current datetime: 2023-03-07 08:00:10.186406    
2023-03-07T15:00:10.209+07:00    START RequestId: 3bd7d8xxxxxd9xxx6b8d1 Version: $LATEST    
2023-03-07T15:00:21.933+07:00    Process Process-68:    
2023-03-07T15:00:22.214+07:00    Traceback (most recent call last):    
2023-03-07T15:00:22.214+07:00    File "/var/lang/lib/python3.9/multiprocessing/managers.py", line 802, in _callmethod    
2023-03-07T15:00:22.214+07:00    conn = self._tls.connection    
2023-03-07T15:00:22.215+07:00    AttributeError: 'ForkAwareLocal' object has no attribute 'connection'    
2023-03-07T15:00:22.215+07:00    During handling of the above exception, another exception occurred:    
2023-03-07T15:00:22.215+07:00    Traceback (most recent call last):    
2023-03-07T15:00:22.215+07:00    File "/var/lang/lib/python3.9/multiprocessing/process.py", line 315, in _bootstrap    
2023-03-07T15:00:22.215+07:00    self.run()    
2023-03-07T15:00:22.215+07:00    File "/var/lang/lib/python3.9/multiprocessing/process.py", line 108, in run    
2023-03-07T15:00:22.215+07:00    self._target(*self._args, **self._kwargs)    
2023-03-07T15:00:22.215+07:00    File "/var/task/lambda_function.py", line 104, in check_comment    
2023-03-07T15:00:22.215+07:00    cmt_total.append("yes")    
2023-03-07T15:00:22.215+07:00    File "<string>", line 2, in append    
2023-03-07T15:00:22.215+07:00    File "/var/lang/lib/python3.9/multiprocessing/managers.py", line 806, in _callmethod    
2023-03-07T15:00:22.215+07:00    self._connect()    
2023-03-07T15:00:22.215+07:00    File "/var/lang/lib/python3.9/multiprocessing/managers.py", line 793, in _connect    
2023-03-07T15:00:22.215+07:00    conn = self._Client(self._token.address, authkey=self._authkey)    
2023-03-07T15:00:22.215+07:00    File "/var/lang/lib/python3.9/multiprocessing/connection.py", line 507, in Client     
2023-03-07T15:00:22.215+07:00    c = SocketClient(address)    
2023-03-07T15:00:22.215+07:00    File "/var/lang/lib/python3.9/multiprocessing/connection.py", line 635, in SocketClient   
2023-03-07T15:00:22.215+07:00    s.connect(address)    
2023-03-07T15:00:22.215+07:00    ConnectionRefusedError: [Errno 111] Connection refused    
```

Có vẻ link này hữu dụng: https://stackoverflow.com/questions/60049527/shutting-down-manager-error-attributeerror-forkawarelocal-object-has-no-attr

Đúng là hiện tại code xử lý kiểu dùng chung nhiều multiprocessing.Manager object như này:  

```
# Prepair variables that use to share in multi-processing
manager = multiprocessing.Manager()
cmt_total = manager.list()
new_cmt = manager.list()
post_have_new_cmt = manager.list()

# rồi bên dưới chạy logic kiểu:
for div in comment_meta:
    new_cmt.append("xxx")
    cmt_total.append("xxx")
    post_have_new_cmt.append("xxx")
```

Cần phải sửa lại như này:  

```
# Prepair variables that use to share in multi-processing
cmt_total_manager = multiprocessing.Manager()
cmt_total = cmt_total_manager.list()

new_cmt_manager = multiprocessing.Manager()
new_cmt = new_cmt_manager.list()

post_have_new_cmt_manager = multiprocessing.Manager()
post_have_new_cmt = post_have_new_cmt_manager.list()

# rồi bên dưới chạy logic kiểu:
for div in comment_meta:
    new_cmt.append("xxx")
    cmt_total.append("xxx")
    post_have_new_cmt.append("xxx")
```

Thì hiện tại sau khoảng 2 tuần thì ko có tý lỗi `AttributeError: 'ForkAwareLocal' object has no attribute 'connection'` nào xuất hiện nữa. 😘

# CREDIT

https://stackoverflow.com/questions/60049527/shutting-down-manager-error-attributeerror-forkawarelocal-object-has-no-attr