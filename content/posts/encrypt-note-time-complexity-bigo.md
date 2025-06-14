---
title: "Notes About Time Complexity"
date: 2023-11-06T15:54:05+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [Algorithm,TimeComplexity]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "This is just my notes about time complexity"
---

# Story

Trong khi tham gia các buổi phỏng vấn thì các bạn sẽ có thể bị hỏi về cách tính độ phức tạp thuật toán để tối ưu code (Với mình là 1 lần).  
Mặc dù đã học ở Đại học rồi nhưng đến lúc phỏng vấn mình lại chẳng thế nhớ ra để mà trả lời.

Trong thực tế thì việc `tính độ phức tạp của thuật toán` rất quan trọng nhưng thường bị bỏ qua vì "Deadline gấp quá, code chạy được là ngon rồi, tối ưu thì sau này sẽ làm". Nhưng kết quả là chả bao giờ chúng ta làm cho đến khi thấy "Sao hệ thống thực sự chạy chậm thế nhỉ, có lẽ phải xem lại code thôi".  

Bài này mình chỉ note lại các điểm chú ý để sau này mình sẽ ôn lại nhanh hơn.  

Việc tính toán độ phức tạp của thuật toán nói phức tạp thì cũng rất phức tạp, nhưng nếu muốn nó đơn giản thì cũng khá đơn giản (sau khi bạn hiểu được mấu chốt vấn đề)  

Về cơ bản, đáp án của việc tính toán độ phức tạp sẽ nằm trong số sau:
- O(1)
- O(logn)  # Tiếng Anh đọc là `O logarithmic` hoặc `O log n`
- O(n)
- O(nlogn) # Tiếng Anh đọc là `O linearithmic` hoặc `O n log n`
- O(n^2)   # Tiếng Việt đọc là `O-nờ-mũ-2`. Tiếng Anh đọc là `O n squared`
- O(2^n)   # Tiếng Anh đọc là `O exponential`
- O(n!)    # Tiếng Việt đọc là `O-nờ-giai-thừa`. Tiếng Anh đọc là `O factorial`

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/big-o-complexity-chart.jpg)

Ảnh trên sắp xếp các độ phức tạp theo mức độ. Ví dụ đoạn code mà bạn viết có độ phức tạp là O(n^2) có nghĩa là "Bạn code tệ quá, nó sẽ chạy chậm đấy, cần phải sửa code đi"

Mấu chốt của Cách tính độ phức tạp của 1 đoạn code thì hãy xem đoạn code đó có bao nhiêu vòng lặp. Càng có nhiều vòng lặp lồng nhau thì càng phức tạp.

Có nhiều thuật toán Sort khác nhau nhưng độ phức tạp tốt nhất có thể là O(nlogn) mà thôi. Chẳng có thuật toán sort nào có độ phức tạp bé hơn O(nlogn) nữa cả.

Thuật toán search `Binary Search` (Tìm kiếm nhị phân) có độ phức tạp là O(logn) nhưng chỉ với điều kiện là mảng đã sorted (đã được sắp xếp).  
Nếu mảng chưa được sắp xếp (unsort) thì bạn phải sắp xếp trước, và khi đó độ phức tạp của việc tìm kiếm số từ 1 mảng chưa sắp xếp sẽ là O(nlogn).   


# Ví dụ

## Ví dụ 1

```
s = 0;

for (i=0; i<=n;i++){
  p =1;
  for (j=1;j<=i;j++)
    p=p * x / j;
  s = s+p;
}
```
=> 2 vòng lặp lồng nhau, không cần nói nhiều độ phức tạp sẽ là `O(n^2)` - rất phức tạp

## Ví dụ 2

```
s = 1; p = 1;
for (i=1;i<=n;i++) {
  p = p * x / i;
  s = s + p;
}
```
=> chỉ có 1 vòng lặp, độ phức tạp sẽ là `O(n)`

## Ví dụ 3

```
s=n*(n-1) /2;
```
=> Chả có vòng lặp, chỉ 1 dòng code. Độ phức tạp là `O(1)`

## Ví dụ 4
```
s=0;
for (i= 1;i<=n;i++)
  s=s+i;
```
=> chỉ có 1 vòng lặp, độ phức tạp sẽ là `O(n)`

## Ví dụ 5

```
for (i= 1;i<=n;i++)
  for (j= 1;j<=n;j++)
    //Lệnh
```
=> 2 vòng lặp lồng nhau, cùng loop n phần tử, độ phức tạp sẽ là `O(n^2)`

## Ví dụ 6

```
for (i= 1;i<=n;i++)
  for (j= 1;j<=m;j++)
    //Lệnh
```
=> 2 vòng lặp lồng nhau, độ phức tạp sẽ là `O(n*m)`. (O của n nhân m)

## Ví dụ 7

```
for (i= 1;i<=n;i++)
  //lệnh 1
for (j= 1;j<=m;j++)
  //lệnh 2
```
=> 2 vòng lặp nối tiếp nhau, độ phức tạp sẽ là `O(max(m,n))`. Nghĩa là sẽ lấy giá trị lớn nhất giữa m và n để làm độ phức tạp.

## Ví dụ 8

```
for (i= 1;i<=n;i++)
    for (j= 1;j<=m;j++)
        for (k= 1;k<=x;k++)
            //lệnh
        for (h= 1;h<=y;h++)
            //lệnh
```
=> Rất nhiều vòng lặp lồng nhau. Độ phức tạp sẽ là `O(n*m*max(x,y))`. O của n nhân m nhân max giữa x & y

## Ví dụ O(logn)

Đến đây chúng ta vẫn chưa thấy xuất hiện O(logn) và O(nlogn) nhỉ?

> O(log n) means that the running time grows in proportion to the logarithm of the input size, meaning that the run time barely increases as you exponentially increase the input.  

Có nghĩa là O(log n) sẽ tăng theo hàm logarit của đầu vào.  
Nếu bạn dùng máy tính để tính thì logarit của 10000: log(10000) = 4. Nghĩa là..  
Nếu n = 10,000  thì độ phức tạp sẽ là log(10000) = 4.  
Nếu n = 100,000 thì độ phức tạp sẽ là log(100000) = 5, con số này là rất nhỏ so với input đầu vào là 10,000 hay 100,000.  

Và thực tế, chỉ cần bạn áp dụng được thuật toán mà có độ phức tạp O(log n) hoặc O(n log n) đã là rất tốt rồi.

Ví dụ về O(logn) là thuật toán Binary Search: Bạn mở quyền từ điển ra và cần tìm từ `senior`. Bạn sẽ ko lật từng trang 1 từ đầu. Bạn sẽ mở giữa quyển sách ra. Bạn xem trang bạn đang nhìn là ký tự trước hay sau ký tự `s`. Nếu là ký tự `o` chẳng hạn, thì vì `o nằm trước s trong bảng alphabet` Bạn sẽ loại bỏ được 1 nửa quyền bên tay trái. Cứ tiếp tục như vậy với 1 nửa quyền còn lại. Đó chính là ý tưởng của thuật toán Binary Search có độ phức tạp log(n). Giúp giảm đi 1 lượng đáng kể số lần duyệt trang.  

```python
def countOperations(n):
  operations = 0
  i = 1
  while (i < n):
    i = i * 2
    operations++
  return operations

countOperations(2000) # = 11
countOperations(4000) # = 12
```
=> Chỉ có 1 vòng lặp. Nếu bạn tính ra độ phức tạp = O(n) thì bạn đã sai.
Đoạn code trên trả về số lần thực hiện phép toán (operations) mỗi khi ta nhân đôi i=1 lên. Kết quả là nếu n = 2000, vòng lặp sẽ chạy 11 lần. Nếu n = 4000 thì vòng lặp sẽ chạy 12 lần. Con số quá nhỏ so với 2000 hay 4000.

## Ví dụ O(nlogn)

Về O(nlogn) thì bài này mình ko có ví dụ cụ thể nào. Nhưng về cơ bản thì mình nghĩ đến 1 ví dụ : Sự kết hợp của 2 vòng lặp lồng nhau. Vòng lặp 1 là lặp n lần. Lồng trong nó là vòng lặp chỉ chạy log(n) lần.

Ví dụ của O(nlogn) là thuật toán Quick Sort - Bạn có thể tìm hiểu thêm trên Google. 

# CREDIT

https://kcntt.duytan.edu.vn/Home/ArticleDetail/vn/168/2006/xac-dinh-do-phuc-tap-thuat-toan

https://www.linkedin.com/pulse/big-o-notation-simple-explanation-examples-pamela-lovett/

https://stackoverflow.com/questions/1592649/examples-of-algorithms-which-has-o1-on-log-n-and-olog-n-complexities

https://stackoverflow.com/questions/15911943/time-complexity-of-binary-search-for-an-unsorted-array

