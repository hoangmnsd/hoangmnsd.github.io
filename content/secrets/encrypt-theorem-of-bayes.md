---
title: "Định lý Bayes - Credit Youtube: Bài Học 10 Phút"
date: 2022-02-28T22:20:01+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Non-Tech]
tags: []
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Memo về định lý Bayes..."
---


# Đề bài

- có 1 căn bệnh có xác suất 1%. Cứ 100 người thì có 1 người mắc bệnh.  
- có 1 loại kít xét nghiệm A có xác suất là 95% dương tính nếu người xét nghiệm mắc bệnh. TỨc là cứ 100 người bị bệnh thì cái kít này sẽ báo dương tính 95 người.  
- kít A còn có xác suất là 90% âm tính nếu người xét nghiệm ko bệnh. Tức là cứ 100 người khỏe mạnh thì kít sẽ báo âm tính 90 người.  
- câu hỏi là vậy thì nếu 1 người mà kít xét nghiệm dương tính thì người đó có bao nhiêu phần trăm bị bệnh thực sự?  

Tưởng là nhiều nhưng sự thực thì chỉ có 9% người đó bị bệnh mà thôi. 

# Giải thích

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/bayes-1-baihoc10p.jpg)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/bayes-2-baihoc10p.jpg)

- có 1 căn bệnh có xác suất 1%. Cứ 100 người thì có 1 người mắc bệnh. => P(A) = 1%  
- cứ 100 người bị bệnh thì cái kít này sẽ báo dương tính 95 người => P(B|A) = 95%  
- cần tìm P(A|B)  
- kết quả cuối cùng là 9%

# CREDIT

https://www.youtube.com/watch?v=7DD0MPjlcfI&ab_channel=B%C3%A0iH%E1%BB%8Dc10Ph%C3%BAt
