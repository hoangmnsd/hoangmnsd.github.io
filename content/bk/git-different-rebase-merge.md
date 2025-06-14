---
title: "Git - Difference between Rebase and Merge"
date: 2022-01-03T23:43:28+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Git]
comments: false
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Câu hỏi về So sánh `git rebase` và `git merge` đôi khi được hỏi trong phỏng vấn. Bạn nên nắm được sự khác nhau để tự tin hơn khi trả lời. "
---

Câu hỏi về So sánh `git rebase` và `git merge` đôi khi được hỏi trong phỏng vấn. Bạn nên nắm được sự khác nhau để tự tin hơn khi trả lời.

# 1. Intro

Đôi khi chúng ta thấy các Developer dùng `git rebase` để merge/lấy các thay đổi từ nhánh khác về.

Nhưng chỉ nên dùng `git rebase` trên 1 nhánh của riêng bạn (hoặc chỉ mình bạn làm việc trên nhánh đó),  

đừng nên dùng `git rebase` trên 1 nhánh mà có nhiều người cùng làm việc nhé. Tại sao thì chúng ta sẽ cùng theo dõi ví dụ sau.  

# 2. Demo

## 2.1. Git Merge

Trên Gitlab, tạo project `git-rebase-merge-test` 

Trên nhánh `main` tạo file "main01":  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-init-prj.jpg)

Commit log của nhánh `main` sẽ như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-log-main-01.jpg)

Hiện tại các bạn đang ở chỗ bôi sáng của diagram sau:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-diagram-main01.jpg)

Tại máy local, tạo branch mới là `dev` (`git checkout -b dev`), tạo file `dev01` rồi push lên remote:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-log-dev01.jpg)
Vì nhánh dev được tạo ra từ nhánh `main` nên nó mặc định có 3 commit ban đầu của `main`, tại thời điểm này bạn có thêm commit "add dev01":
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-diagram-dev01.jpg)

Trên giao diện GitLab, trên nhánh `main` tạo file `main02`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-log-main-02.jpg)

Tại thời điểm này ở local máy bạn cần sang nhánh `main` pull code latest về, bạn sẽ thấy nhánh `main` đã có file `main02`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-log-main-pull-local.jpg)

giờ switch sang nhánh `dev`, bạn tiếp tục edit file `README.md` rồi push lên remote với commit "dev edit 1 readme":  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-log-dev-edit-readme1.jpg)

Trên diagram, bạn đang ở vùng này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-diagram-dev-before-merge.jpg)

Giờ bạn đứng ở nhánh `dev`, thực hiện merge với nhánh `main` bằng command `git merge main` (`git pull origin main` cũng sẽ làm nhiệm vụ tương tự):  

bạn muốn file `main02` của nhánh `main` được xuất hiện trong nhánh `dev` của bạn đúng ko nào?

File `main02` xuất hiện:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-log-dev-merge-main.jpg)

Vẫn đang trên nhánh `dev`, bạn tạo thêm 1 file `dev02` rồi push lên remote  

**Chú ý nhé**  
Bạn sẽ thấy 1 commit được tạo tự động là "Merge branch main into dev" -> đó là commit được tạo ra bới command `git merge main`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-log-dev02.jpg)

Trên diagram, bạn đang ở vùng này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-diagram-dev02.jpg)

Vậy `git merge` đã làm gì?  

-> `git merge` đưa đúng các commit vào vị trí của nó theo thời gian:   
- Commit "Add new file main02" được đưa vào đúng vị trí là sau "add dev01".   
- Tất cả commit hash id của nhánh `dev` ko thay đổi gì.  
- Tạo thêm 1 commit (box màu hồng) là: "Merge branch main into dev".  

Tiếp theo ta tìm hiểu `git rebase` sẽ hoạt động như thế nào...

## 2.2. Git Rebase

Giờ trên giao diện Gitlab, nhánh `main` tạo 1 file mới "main03":  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-log-main-03.jpg)  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-diagram-main03.jpg)

Tại local, trên nhánh `dev`, tạo file "dev03", push lên remote. Nhánh `dev` đang ở vùng sáng này trong diagram:    
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-diagram-dev03.jpg)


edit file `README.md`, push lên remote với commit là "edit readme 2":  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-diagram-before-rebase.jpg)

Trên máy local, switch sang nhánh `main`, pull code latest về 

Rồi, giờ switch sang `dev`, đứng nhánh `dev` run `git rebase main`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-dev-rebase-maiin.jpg)

Rebase xong bạn sẽ cần push thay đổi lên nhánh `dev`:  
nếu bạn `git push origin dev` -> sẽ báo lỗi ngay  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-push-error.jpg)

thế nên bạn phải push force như sau:  
```sh
git push origin dev -f
```

log commit sẽ như sau:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-dev-log-after-rebase.jpg)

Bạn nhìn log đó hơi lạ đúng ko, sự thay đổi được mô tả lại trên diagram:   
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-diagram-after-rebase.jpg)

Vậy Git Rebase đã làm gì?  

Bạn sẽ thấy dù ko còn cái commit tự động (bôi hồng) được thêm vào nữa nhưng

-> `git rebase` đã làm: 
- Đưa các commit của nhánh `dev` lên trên đầu, commit của nhánh `main` đẩy xuống dưới.  
- Commit hash id của nhánh `dev` bị thay đổi hết (-> đây là lý do bạn cần push force).  

=> Nếu bạn làm việc trên 1 nhánh riêng biệt của mình bạn, việc thay đổi commit hash id này ko vấn đề gì,  
nhưng nếu bạn làm việc trên 1 nhánh mà có nhiều người cùng làm việc, việc này có thể dẫn đến làm mất code của người khác.  
Bù lại, commit log của nhánh `dev` nhìn sẽ clear hơn cho bạn, ko có commit tự động xen vào giữa. 

Diagram tổng kết ở đây:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diff-rebase-merge-dev-main-log-all.jpg)

Quan điểm của riêng mình: Chỉ dùng `git rebase` trên nhánh riêng của bạn để làm đẹp commit log.  
Bởi `git rebase` ghi đè lịch sử commit nên nếu bạn tôn trọng lịch sử thì đừng nên cố gắng thay đổi nó. Hãy dùng `git merge`.      

Hy vọng bài viết và diagram trên giúp bạn hiểu rõ sự khác biệt ✌

## CREDIT

https://stackoverflow.com/a/66813076/9922066  