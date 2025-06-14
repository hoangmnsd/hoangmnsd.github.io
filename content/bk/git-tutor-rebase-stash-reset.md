---
title: "Amateur tutor Git commands (rebase interactive, stash, reset)"
date: 2021-11-05T23:43:28+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Git]
comments: false
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Khi sử dụng Git dần dần trở nên thường xuyên thì việc hiểu về các câu lệnh nâng cao của nó càng trở nên cần thiết. "
---

Khi sử dụng Git dần dần trở nên thường xuyên thì việc hiểu về các câu lệnh nâng cao của nó càng trở nên cần thiết.  

Sử dụng nhiều thì dẫn đến commit nhiều, commit nhiều thì việc commit sai file, commit sai message là chuyện dễ hiểu.  
Từ đó dẫn đến nhu cầu sửa lại commit message, commit sai muốn revert lại commit trước đó, gộp các commit lại cho dễ nhìn, cho trace log trong tương lai, 
và ... nhìn log commit cho đẹp.  
Đó là lúc bạn cần tìm hiểu nhiều hơn về các câu lệnh của Git.  

1 số Git command hay sử dụng nhất là: 
- git clone, git add, git commit, git remote set-url, git pull, git push, git merge, ...  

Bài này nói về `git rebase interactive`, `git stash`, `git reset`.  

## 1. Git Rebase interactive

Cần chú ý rằng không nên sử dụng `git rebase` trên nhánh master, vì nó dẫn đến khả năng bạn sẽ làm mất code của người khác.  
Chỉ nên dùng trên nhánh feature của bạn mà chỉ có bạn đang làm việc, hoặc bạn biết chắc mất code của người khác cũng ko vấn đề.  

### 1.1. Ví dụ 1 

Bắt đầu với ví dụ như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_commit_all_1.jpg)
Mình đang trên nhánh `testing`. Đã edit file README.md 6 lần. Lần gần nhất là "edit readme 6".  
Mỗi lần edit mình add thêm 1 số vào file README.md. Sau 6 lần thì nội dung nó là:  
```README.md
hello 1 2 3 4 5 6
```

run command sau:
```sh
git rebase -i HEAD~6
```
đây là hình ảnh màn hình editor của `git rebase -i HEAD~6`  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_rebase_HEAD_6.jpg)

giờ mình muốn gộp 2 commit "edit readme 5" và "edit readme 4" lại, chỉ giữ cái "edit readme 4" thôi.  

trong màn hình editor của `git rebase`, thay chữ `pick` của commit 5 thành `s` (viết tắt của `squash`)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_rebase_HEAD_6_squash.jpg)  
chữ `s` này có nghĩa bạn vẫn dùng commit này nhưng gộp nó vào commit trước đó (commit 4)
sau đó Ctr+X, Yes để save editor lại  


ngay sau đó 1 editor mới được bật lên:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_rebase_HEAD_6_squash_2.jpg)  
ở đây bạn chỉ muốn giữ commit message "edit readme 4" thôi đúng ko, hãy add `#` vào trước "edit readme 5" để ignore nó:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_rebase_HEAD_6_squash_commentout.jpg)  
sau đó Ctr+X, Yes để save editor lại  
màn hình như sau là ok.  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_rebase_success.jpg)  

đến đây chưa xong, bạn cần push các thay đổi vừa xong lên remote branch để check:  
```sh
git push origin testing -f
```

lên Git repository xem log commit:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_commit_all_after.jpg)  
nội dung của commit 4 đã bao gồm cả thay đổi của commit 5.  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_commit_all_after_commit4.jpg)  
như vậy là đúng ý chúng ta rồi.

### 1.2. Ví dụ 2

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_commit_all_after_hl.jpg)  
Giờ bạn muốn gộp 3 commit bôi vàng lại, và commit message mới sẽ là 'hello 123' thì sao?  
```sh
git rebase -i HEAD~5
```
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_rebase_HEAD_5_squash.jpg)  
trong màn hình editor của `git rebase`, thay chữ `pick` của commit 3 và commit 2 thành `s` (viết tắt của `squash`)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_rebase_HEAD_5_squash_123.jpg)   
sau đó Ctr+X, Yes để save editor lại  
ngay sau đó 1 editor mới được bật lên:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_rebase_HEAD_5_squash_123_editor.jpg)  

Hãy comment out 2 commit message "edit readme 2" và "edit readme 3", sửa "edit readme 1" thành "hello 123" như ý muốn ban đầu
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_rebase_HEAD_5_squash_editor_hello123.jpg)  
sau đó Ctr+X, Yes để save editor lại  

đến đây chưa xong, bạn cần push các thay đổi vừa xong lên remote branch để check:  
```sh
git push origin testing -f
```
lên Git repository xem log commit:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_commit_all_after_merge123.jpg)   
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_commit_all_after_commit_hello123.jpg)  
như vậy là đã đúng ý chúng ta rồi 😍

Git rebase interactive có nhiều option như `squash, edit, reword, fixup` nếu bạn để ý màn hình editor của Git rebase. 

> "reword" allows you to change ONLY the commit message, NOT the commit contents.  

> "edit" allows you to change BOTH commit contents AND commit message. By replacing the command "pick" with the command "edit", you can tell git rebase to stop after applying that commit, so that you can edit the files and/or the commit message, amend the commit, and continue rebasing.  


Nhưng theo mình chỉ cần biết `squash` là đủ 😂

## 2. Git stash 

Tưởng tượng bạn đang phát triển trên 1 branch `testing`, nhưng sếp bắt fix bug trên 1 nhánh khác (master) nên bạn phải nhảy qua nhánh `master` đó để fix.  
Nhưng muốn checkout master thì cần phải commit các thay đổi hiện tại đã...   
Nhưng bạn chưa muốn commit các code dở dang lên branch `testing` luôn 
(vì nó sẽ xấu commit log, nó sẽ push những sensitve info lên, nó sẽ trigger pipeline ko cần thiết, ... etc) 

-> Đây là lúc bạn muốn dùng `git stash`  

giả sử file README.md của bạn ở nhánh `testing` như sau:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_stash_1.jpg)  

bạn muốn save lại session làm việc hiện tại, run command sau:  
```sh
git stash save --include-untracked doing crazy things
```
command trên có nghĩa là bạn save session hiện tại với message là "doing crazy things"

mọi thứ sẽ clean đi, quay trở về nhánh `testing` ban đầu.

giờ bạn có thể dễ dàng checkout nhánh master để fix bug cho sếp.  

Sau khi fix xong bạn quay trở lại nhánh `testing`, lôi những đoạn code dở dang ra và tiếp tục...
```sh
$ git stash list
stash@{0}: On testing: doing crazy things
```

Bạn lôi code dở dang bằng command sau:   
```sh
git stash pop stash@{0}
```
Tuyệt vời, lại tiếp tục công việc thôi! 🥱

Mặc dù `git stash` còn có 1 số option như:  
`git stash apply`, `git stash drop`, `git stash clear`, `git stash show`

Nhưng mình nghĩ chỉ cần biết 3 cái là đủ rồi 😂:   
- `git stash save --include-untracked what-you-are-doing-message`, 
- `git stash pop`, 
- `git stash list` 


## 3. Git reset

Giả sử bạn đang bạn đang ở trên nhánh `feature/A`, bạn đã thực hiện nhiều commit như sau:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_reset_all_commit.jpg)

nhưng bạn phát hiện ra là bạn đã lỡ tay commit nhiều cái linh tinh quá, pipeline chạy lỗi tùm lum rồi, bạn muốn quay lại commit "edit readme 3", xóa hết 3 commit mới nhất đi. Làm sao nhỉ?  

Như này, đầu tiên check git log để lấy commit_id:  
```sh
git log --decorate --oneline
```
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_log_decorate_1line.jpg)

Bạn muốn quay lại commit "edit readme 3" thì commit_id chính là `543a35a`  
Giờ run command `git reset --hard <commit_id>`:  
```sh
git reset --hard 543a35a
HEAD is now at 543a35a edit readme 3
```

Giờ file README.md ở local của bạn đã trở về thời điểm commit "edit readme 3"  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_reset_hard_commit_id.jpg)

Nhưng chưa đủ, bạn cần push thay đổi ở local lên remote Git nữa   
```sh
# force clean, remove all object and sub directories
git clean -f -d

# download all object and refs from all remotes to local
git fetch --all

# git push to only branch feature/A, set it upstream
git push -u origin +feature/A
```
Xác nhận ko có lỗi gì khi run các command trên, quay lại xem log git commit trên remote thôi.  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/git_tutor_commit_all_after_reset.jpg)

Vậy là đúng ý chúng ta rồi, tiếp tục edit code cho cẩn thận rồi hãy commit lên nhé

## 4. Pull code từ 1 repository khác giữ nguyên history commit

https://stackoverflow.com/a/46289324/9922066

Giả sử bạn có 1 repo A. Bạn muốn archive repo A và chuyển hết code sang repo B. Giữ nguyên history commit. 

-> Tạo repo B, giả sử branch mặc định là master.  
-> Bạn tạo branch mới (`develop`) trên repo B mà ko có content gì cả bằng cách:  
```sh
git checkout --orphan develop
git reset --hard
git pull [REPO_A_URL] [REPO_A_BRANCH]
```
Như vậy repo B (branch `develop`) đã có tất cả history commit của repo A (branch `REPO_A_BRANCH`)

## 5. Delete all commit history

https://stackoverflow.com/questions/13716658/how-to-delete-all-commit-history-in-github

Giả sử bạn muốn xóa hết commit history thì làm như các command sau:  

```sh
# Create new empty branch
git checkout --orphan latest_branch

# Add all the files
git add -A

# Commit the changes
git commit -am "commit message"

# Delete the branch
git branch -D master

# Rename the current branch to master
git branch -m master

# Finally, force update your repository
git push -f origin master
```


## CREDIT

https://thoughtbot.com/blog/git-interactive-rebase-squash-amend-rewriting-history  
https://kipalog.com/posts/Viet-lai-lich-su-cua-git-bang-cach-su-dung-interactive-rebase  
https://git-scm.com/docs/git-push  
https://git-scm.com/docs/git-fetch  
https://git-scm.com/docs/git-clean  
https://stackoverflow.com/a/46289324/9922066  