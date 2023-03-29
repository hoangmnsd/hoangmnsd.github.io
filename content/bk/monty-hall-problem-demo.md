---
title: "Monty Hall Problem Demo"
date: 2021-12-24T22:53:49+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Non-Tech]
#tags: [Notes]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Tìm hiểu về Monty Hall problem giúp bạn thấy được sức mạnh của Xác suất thống kê."
---

## Vấn đề

Tìm hiểu về [Monty Hall problem](https://en.wikipedia.org/wiki/Monty_Hall_problem) giúp bạn thấy được sức mạnh của Xác suất thống kê.  

Monty Hall problem nói về 1 trò chơi như sau:  
- Monty đưa cho bạn 3 cánh cửa (A,B,C), đằng sau đó là 2 con dê và 1 cái ô tô.    
- Bạn chọn 1 cửa (giả sử là A). Bạn nghĩ rằng sau cánh cửa đó là cái ô tô.  
- Monty kiểm tra 2 cánh cửa còn lại (B,C), và mở 1 cánh cửa có con dê.  
- Câu hỏi là bạn vẫn chọn cánh cửa A như ban đầu, hay đổi sang 1 cánh cửa khác? Xác suất có khác nhau ko?

...  

Câu trả lời có thể sẽ làm 1 số người ngạc nhiên là xác suất ko phải là 50-50. Nếu bạn đổi sang 1 cánh cửa khác. Xác suất bạn chọn đúng cửa có ô tô là 66 % 

## Nghe chuyên gia giải thích

Chuyên gia giải thích rằng:  

Nếu bạn chọn cánh cửa A từ đầu, bạn có 1/3 cơ hội đúng.  
Nhưng nếu bạn giữ nguyên lựa chọn đó sau khi Monty loại trừ 1 cánh cửa sai, bạn sẽ ko thể cải thiện xác suất của mình.  
Khi Monty chưa loại trừ, xác suất của 2 cánh cửa còn lại (B,C) là 2/3.  
Monty kiểm tra chúng và bỏ 1 cánh cửa sai (giả sử B), thì cánh cửa còn lại (C) sẽ có xác suất là 2/3.  
Khi đó việc đổi sang C sẽ giúp bạn tăng xác suất từ 1/3 lên 2/3.  

Bạn hiểu chưa?

Dưới 1 góc nhìn khác:  

- Giả sử có 100 cánh cửa thay vì 3.  
- Bạn chọn 1.  
- Monty kiểm tra 99 cánh cửa còn lại, ông ấy mở 98 cánh cửa có dê và chỉ để lại 1 cửa.  
- Bạn vẫn giữ lựa chọn ban đầu (với cơ hội 1/100) hay là chuyển sang cánh cửa còn lại (cái mà đã được lọc ra trong 99 cái) ?

Đến đây có lẽ bạn đã hiểu rõ hơn. Hành động lọc của Monty đã giúp bạn. Ông ấy cho bạn chọn giữa "lựa chọn hoàn toàn ngẫu nhiên và "lựa chọn sau 1 lần chọn lọc".  
Lựa chọn sau 1 lần lọc rõ ràng tốt hơn. 

## Vậy khi nào xác suất lựa chọn là 50-50 ?

Đó là khi bạn không hề có thông tin về hành động của Monty.  

Tưởng tượng rằng:  
- Monty đưa cho bạn 3 cánh cửa (A,B,C), đằng sau đó là 2 con dê và 1 cái ô tô.    
- Bạn chọn 1 cửa (giả sử là A). Bạn nghĩ rằng sau cánh cửa đó là cái ô tô.  
- Monty kiểm tra 2 cánh cửa còn lại (B,C), và mở 1 cánh cửa có con dê. 
- **Đúng lúc này** 1 người bạn của bạn đi đến, nhìn thấy 2 cánh cửa và ko biết Monty vừa làm gì. Anh ta phải chọn 1, xác suất của anh ta chọn đúng là 50 %. Nhưng xác suất nếu bạn đổi cánh cửa sang C lại là 66 %

=> Kết luận là: Thông tin sẽ ảnh hưởng rất nhiều đến xác suất của lựa chọn

## Demo

Khi bạn vẫn phân vân ko hiểu về bài toán và lời giải trên, cách đơn giản nhất để chứng minh là thực nghiệm. 

Hãy dùng 1 đoạn code python để thực nghiệm xem xác suất có đúng là tăng lên ko?

```python monty-hall-demo.py
#!/usr/bin/env python

"""
an demostration of Monty Hall problem
"""

import random
import sys

def main():
  COUNT = int(sys.argv[1])
  success_count_of_switch = 0
  success_count_not_switch = 0
  time_count = 0
  while(time_count < COUNT):
    # DOOR
    DOOR = ["A", "B", "C"]
    # only one DOOR cover the CAR
    result = random.choice(DOOR)
    print("")
    print("hidden result is: ", result)

    # player make a first choice
    my_first_choice = random.choice(DOOR)
    print("my first choice is: ", my_first_choice)

    # round 1, reveal a DOOR that cover a goat
    reveal1 = random.choice(DOOR)
    # make sure that reveal is not the door cover a car and not my_first_choice
    while((reveal1 == result) or (reveal1 == my_first_choice)):
      reveal1 = random.choice(DOOR)
    print("first reveal: ", reveal1)
    # now DOOR will be subjected 
    DOOR.remove(reveal1)

    # player must switch the choice
    my_second_choice = random.choice(DOOR)
    # make sure that player switch to another DOOR
    while(my_second_choice == my_first_choice):
      my_second_choice = random.choice(DOOR)
    print("my second choice is: ", my_second_choice)

    if (my_second_choice == result):
      print("Switch is CORRECT decision!")
      success_count_of_switch += 1
    elif (my_first_choice == result):
      print("Switch is wrong decision!")
      success_count_not_switch += 1

    time_count += 1

  print("Success percentage of second choice: %d / %d" % (success_count_of_switch, time_count))
  print("Success percentage of first choice : %d / %d" % (success_count_not_switch, time_count))

if __name__ == '__main__':
    main()
```

Run khoảng 1000 lần, bạn sẽ thấy xác suất khá chính xác:  
```
$ python3 monty-hall-demo.py 1000
Success percentage of second choice: 665 / 1000
Success percentage of first choice : 335 / 1000
```

## Đi xa hơn 1 chút

Hãy nghĩ về 1 hoàn cảnh có thể khác: 
- Bạn chơi "Ai Là Triệu Phú"  
- Bạn ko biết gì, ko có bất cứ 1 thông tin gì để phân vân, Nhưng bạn chọn sẽ nói với MC là bạn nghiêng về đáp án A.   
- Bạn dùng sự trợ giúp 50-50  
- Tại đây giả sử họ bỏ đi 2 đáp án sai và giữ lại đáp án A.    
- Giờ bạn có nên đổi sự lựa chọn sang đáp án còn lại ko?  

Hãy thực nghiệm với 1 đoạn code (sửa đoạn code trên 1 chút):  
```python
#!/usr/bin/env python

"""
an demostration of Monty Hall problem
"""

import random
import sys

def main():
  COUNT = int(sys.argv[1])
  success_count_of_switch = 0
  success_count_not_switch = 0
  time_count = 0
  while(time_count < COUNT):
    # DOOR
    DOOR = ["A", "B", "C", "D"]
    # only one DOOR cover the CAR
    result = random.choice(DOOR)
    print("")
    print("hidden result is: ", result)

    # player make a first choice
    my_first_choice = random.choice(DOOR)
    print("my first choice is: ", my_first_choice)

    # round 1, reveal a DOOR that cover a goat
    reveal1 = random.choice(DOOR)
    # make sure that reveal is not the door cover a car and not my_first_choice
    while((reveal1 == result) or (reveal1 == my_first_choice)):
      reveal1 = random.choice(DOOR)
    print("first reveal: ", reveal1)
    # now DOOR will be subjected 
    DOOR.remove(reveal1)

    # round 2, reveal a DOOR that cover a goat
    reveal2 = random.choice(DOOR)
    # make sure that reveal is not the door cover a car and not my_first_choice
    while((reveal2 == result) or (reveal2 == my_first_choice)):
      reveal2 = random.choice(DOOR)
    print("second reveal: ", reveal2)
    # now DOOR will be subjected 
    DOOR.remove(reveal2)

    # player must switch the choice
    my_second_choice = random.choice(DOOR)
    # make sure that player switch to another DOOR
    while(my_second_choice == my_first_choice):
      my_second_choice = random.choice(DOOR)
    print("my second choice is: ", my_second_choice)

    if (my_second_choice == result):
      print("Switch is CORRECT decision!")
      success_count_of_switch += 1
    elif (my_first_choice == result):
      print("Switch is wrong decision!")
      success_count_not_switch += 1

    time_count += 1

  print("Success percentage of second choice: %d / %d" % (success_count_of_switch, time_count))
  print("Success percentage of first choice : %d / %d" % (success_count_not_switch, time_count))

if __name__ == '__main__':
    main()
```

Kết quả là:  
```
$ python3 monty-hall-demo.py 1000
Success percentage of second choice: 754 / 1000
Success percentage of first choice : 246 / 1000
```
Việc đổi lựa chọn rõ ràng đem lại khả năng đúng cao hơn.

Nhưng hãy chú ý rằng đấy là trường hợp chúng ta đang giả sử: "giả sử họ bỏ đi 2 đáp án sai và giữ lại đáp án A."

Trong thực tế MC sẽ ko nói rằng MC sẽ giữ lại đáp án A, nhiều khi họ bỏ nó luôn. 

Lúc ấy đoạn code nên thay đổi: 
```python
#!/usr/bin/env python

"""
an demostration of Monty Hall problem
"""

import random
import sys

def main():
  COUNT = int(sys.argv[1])
  success_count_of_switch = 0
  success_count_not_switch = 0
  time_count = 0
  while(time_count < COUNT):
    # DOOR
    DOOR = ["A", "B", "C", "D"]
    # only one DOOR cover the CAR
    result = random.choice(DOOR)
    print("")
    print("hidden result is: ", result)

    # player make a first choice
    my_first_choice = random.choice(DOOR)
    print("my first choice is: ", my_first_choice)

    # round 1, reveal a DOOR that cover a goat
    reveal1 = random.choice(DOOR)
    # make sure that reveal is not the door cover a car
    while(reveal1 == result):
      reveal1 = random.choice(DOOR)
    print("first reveal: ", reveal1)
    # now DOOR will be subjected 
    DOOR.remove(reveal1)

    # round 2, reveal a DOOR that cover a goat
    reveal2 = random.choice(DOOR)
    # make sure that reveal is not the door cover a car
    while(reveal2 == result):
      reveal2 = random.choice(DOOR)
    print("second reveal: ", reveal2)
    # now DOOR will be subjected 
    DOOR.remove(reveal2)

    # player must switch the choice
    my_second_choice = random.choice(DOOR)
    # make sure that player switch to another DOOR
    while(my_second_choice == my_first_choice):
      my_second_choice = random.choice(DOOR)
    print("my second choice is: ", my_second_choice)

    if (my_second_choice == result):
      print("Switch is CORRECT decision!")
      success_count_of_switch += 1
    elif (my_first_choice == result):
      print("Switch is wrong decision!")
      success_count_not_switch += 1

    time_count += 1

  print("Success percentage of second choice: %d / %d" % (success_count_of_switch, time_count))
  print("Success percentage of first choice : %d / %d" % (success_count_not_switch, time_count))

if __name__ == '__main__':
    main()
```

Lúc này lần lựa chọn thứ 2 của bạn có xác suất là 50 % 
```
Success percentage of second choice: 509 / 1000
Success percentage of first choice : 250 / 1000
```

Hãy tự nghĩ ra thêm khả năng và thực nghiệm để xem kết quả nhé !

Vậy là bạn có thể thấy sức mạnh của Xác suất thống kê giúp bạn đỡ tốn công thực nghiệm rất nhiều.  
Thay vì phải viết code để tìm hiểu như mình, bạn chỉ cần làm vài phép tính Xác suất là có thể tìm ra lời giải rất nhanh...  
Thế nên hãy nghiêm túc khi học nhé 🤣

## CREDIT

https://betterexplained.com/articles/understanding-the-monty-hall-problem/

