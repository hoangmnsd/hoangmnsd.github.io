---
title: "Python: Walrus operator, lambda, arrow, class, (non)keyword arguments"
date: 2023-01-20T23:09:57+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [Python,Notes]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bài này note lại những thứ khá phổ biến trong Python nhưng mình ít dùng/để ý đến nó."
---

Bài này note lại những thứ khá phổ biến trong Python nhưng mình ít dùng/để ý đến nó.

Với mình thì công việc DevOps cũng có làm việc với Python scripting nhưng ở level rất basic thôi. Những thứ này đúng là có 1 chút lạ lẫm. 

# 1. Walrus Operator

Toán tử `:=` trong python được gọi là "Walrus Operator", được giới thiệu từ Python3.8. Giúp làm code ngắn gọn hơn.

**Ví dụ 1**: Nếu 1 function tên là `func()` chạy rất lâu, tốn nhiều thời gian,  
bạn ko nên chạy lại function đó nhiều lần 1 cách ko cần thiết,  
mà nên gán kết quả của nó vào 1 biến, rồi sử dụng lại khi cần thiết. 

```sh
# ---------------------
# SLOWER
# "func" called 3 times
result = [func(x), func(x)**2, func(x)**3] # -----> Bạn đang chạy lại func(x) 3 lần trong 1 dòng code

# ---------------------
# FASTER
# Reuse result of "func" without splitting the code into multiple lines
result = [y := func(x), y**2, y**3]  # -----> Bạn gán kết quả của func(x) cho y, rồi lấy kết quả đó sử dụng lại trong y**2, y**3
```

**Ví dụ 2**: Bạn cần dùng regex để tìm kiếm 2 partern trong 1 list. Thay vì if-else lồng nhau hết partern này đến partern khác.  
Bạn nên gán giá trị regex vào biến `m` kết hợp với `or`.    
Tránh việc tạo các vòng loop if-else lồng nhau sẽ khó đọc.


```sh
import re

tests = ["Something to match", "Second one is present"]

pattern1 = r"^.*(thing).*"
pattern2 = r"^.*(present).*"

# ---------------------
# LONGER
for test in tests:
    m = re.match(pattern1, test)
    if m:
        print(f"Matched the 1st pattern: {m.group(1)}")
    else:
        m = re.match(pattern2, test)
        if m:
            print(f"Matched the 2nd pattern: {m.group(1)}")

# Matched the 1st pattern: thing
# Matched the 2nd pattern: present

# ---------------------
# CLEANER
for test in tests:
    if m := (re.match(pattern1, test) or re.match(pattern2, test)):
        print(f"Matched: '{m.group(1)}'")
        # Matched: 'thing'
        # Matched: 'present'
```

**Ví dụ 3**: Bạn sử dụng biến `today` để nhận giá trị của hàm `datetime.today()`, sau đó sử dụng lại trong cùng line đó.  
Mà ko cần phải run hàm `datetime.today()` 2 lần.

```sh
from datetime import datetime

print(f"Today is: {(today:=datetime.today()):%Y-%m-%d}, which is {today:%A}")
# Today is: 2022-07-01, which is Friday
```


# 2. Lambda function

Đây là 1 function khá thông dụng khi đọc code Python ở trên mạng.

Mục đích của nó là để khai báo hàm mà ko cần define bằng `def`. Người ta gọi lambda function là hàm ẩn danh (anonymous function)

Thường chúng ta sử dụng lambda function với các hàm chỉ cần một dòng lệnh. 

```sh
# ---------------------
# LONG
def doubler(x):
    return x*2

print(doubler(4))
# Prints 8

# ---------------------
# SHORT
doubler = lambda x: x*2

print(doubler(5))
# Prints 10
```

Nhiều tham số:  

```sh
mul = lambda x, y: x*y
print(mul(5, 10))
# Prints 50
```

Mặc dù vậy Lambda bị đánh giá là khiến việc debug/maintenance trở nên khó khăn hơn

# 3. Arrow ->

Đôi khi đọc code Python3 bạn còn thấy ký tự mũi tên `->` khi define function

Ký hiệu này chỉ đơn giản là giúp code của bạn dễ đọc hơn mà thôi, nó ko ảnh hưởng gì đến logic của code cả.

Kiểu như thay vì viết comment `# hàm này tính vận tốc` thì bạn viết:  

```sh
def velocity(s, t) -> 'hàm này tính vận tốc':
 return s / t
```

Đơn giản thế thôi. Khi print `velocity.__annotations__` bạn sẽ thấy:  

```
{'return': 'hàm này tính vận tốc'}
```

Người ta cũng hay viết kiểu thế này:  

```sh
def velocity(s: 'dùng đơn vị kilomet', t: 'dùng đơn vị giờ') -> 'hàm này tính vận tốc':
 return s / t
```

Viết như vậy là để người đọc hiểu rằng hãy input giá trị kilomet cho `s`, giá trị giờ cho `t` 

Khi print `velocity.__annotations__` bạn sẽ thấy:  

```
{'return': 'hàm này tính vận tốc', 's': 'dùng đơn vị kilomet', 't': 'dùng đơn vị giờ'}
```


# 4. Class in Python

Có thể coi `class` trong Python như 1 blueprint của objects. Như là prototype của 1 chiếc xe máy.

Ta có thể tạo ra nhiều chiếc xe khác nhau từ 1 prototype, mỗi chiếc xe là 1 object.

Trong 1 class thì có thể có nhiều function, các function đó gọi là `method` của class.


```sh
# create a class
class Room:
    length = 0.0 # <-------------------- Đây là các attribute của Class
    breadth = 0.0
    
    # method to calculate area
    def calculate_area(self): # <---------------- Đây gọi là Method
        print("Area of Room =", self.length * self.breadth)

# create object of Room class
study_room = Room()

# assign values to all the attributes 
study_room.length = 42.5
study_room.breadth = 30.8

# access method inside class
study_room.calculate_area()
```

Output:  

```
Area of Room = 1309.0
```

## 4.1. Constructor __init__

`__init__` method là 1 hàm đặc biệt trong Class của Python, nó giống với khái niệm `constructor` trong Java hay C++.

Constructors được dùng để khởi tạo giá trị cho object. 

`__init__` sẽ được gọi bất cứ khi nào 1 object mới được khởi tạo.  

Nếu ko dùng constructor bạn sẽ viết code thế này để tạo giá trị cho attribute `name` trong class Bike:  

```sh
class Bike:
    name = ""
...
# create object
bike1 = Bike()
```

Nếu dùng constructor:  

```sh
class Bike:

    # constructor function    
    def __init__(self, name = ""):
        self.name = name

bike1 = Bike()
```

## 4.2. Kế thừa, đa kế thừa

Vì Python cũng là 1 ngôn ngữ OOP nên nó có đầy đủ các thuộc tính của OOP language. Ví dụ tính kế thừa (Inheritance)

**Kế thừa**: Trong ví dụ sau, class `Dog` kế thừa class `Animal`, thay đổi giá trị của thuộc tính `leg`, viết lại method `eat()` và thêm method mới là `run()`  

```sh
class Animal:
   legs = '0'

   def __init__(self):
      pass

   def whoAmI(self):
      print ("Animal")
 
   def eat(self):
      print ("Eating")
 
 
class Dog(Animal):
   def __init__(self):
      Animal.__init__(self)
      print ("Dog created")
      self.legs = '4';
 
   def whoAmI(self):
      print ("Dog go go")
 
   def eat(self):
      print ("eat eat eat .....")

   def run(self):
      print ("legs: " + self.legs + " run run run .....")
 
 
d = Dog()
d.whoAmI()
d.eat()
d.run()
```

**Đa kế thừa**: trong ví dụ sau, class Dog kế thừa từ 2 class cha `Animal, Entity`

```sh
class Animal:
   legs = '0'

   def __init__(self):
      pass

   def whoAmI(self):
      print ("Animal")
 
   def eat(self):
      print ("Eating")

class Entity:
   def __init__(self):
      pass

   def weight(self):
      print 'weight 88';
 
class Dog(Entity, Animal):
   def __init__(self):
      Animal.__init__(self)
      Entity.__init__(self)
      print ("Dog created")
      self.legs = '4';
 
   def whoAmI(self):
      print ("Dog go go")
 
   def eat(self):
      print ("eat eat eat .....")

   def run(self):
      print ("legs: " + self.legs + " run run run .....")
 
 
d = Dog()
d.whoAmI()
d.eat()
d.run()
d.weight()
```


# 5. *args and **kwargs

- Ví dụ với `*args` (Non Keyword Arguments):  

```sh
def myCountries(*args):
  for item in args:
    print(item)

myCountries('US', 'Cuba') # <------------------ bạn truyền vào bất cứ thứ gì, *args sẽ convert chúng thành 1 tuple, rồi bạn in ra tuple đó

# Output: 
# US
# Cuba
```

`*args` luôn convert giá trị sang kiểu tuple `('US', 'Cuba')`

Bạn cũng có thể viết thế này `*data`. Miễn là 1 dấu * ở trước, mọi người sẽ hiểu đó là `non-keywork argument`, kiểu tuple:  

```sh
def myCountries(*data):
  for item in data:
    print(item)
```


- Ví dụ với `**kwargs` (Keyword Arguments):  

```sh
def intro(**kwargs):
  for key,value in kwargs.items():
    print(key, ": ", value)

intro(Firstname="Sita", Lastname="Sharma", Age=22)

# Output: 
# Firstname: Sita
# Lastname: Sharma
# Age: 22
```

`**kwargs` dùng khi bạn muốn pass argument kiểu dictionary gồm key,value vào function. Vì lý do đó mà họ gọi nó là `keywork argument`

Bạn cũng có thể viết thế này `**data`. Miễn là 2 dấu ** ở trước, mọi người sẽ hiểu đó là `keywork argument`, kiểu dictionary: 

```sh
def intro(**data):
    for key,value in data.items():
    print(key, ": ", value)

intro(Firstname="Sita", Lastname="Sharma", Age=22)

# Output: 
# Firstname: Sita
# Lastname: Sharma
# Age: 22
```

# 6. Function name with underscore

khi đọc code Python bạn cũng sẽ thấy được nhiều function/variable có dấu gạch dưới như này __

```
class Foo:
    __name = "Foo"

    def __getName(self):
        print(self.__name)

    def get(self):
        self.__getName()
```

với 1 dấu gạch dưới _, chúng ta ngầm hiểu rằng biến/hàm đó là `protected` - nghĩa là chỉ class đó và các class con **nên** có quyền truy cập

với 2 dấu gạch dưới __, chúng ta ngầm hiểu rằng biến/hàm đó là `private` - nghĩa là chỉ class đó **nên** có quyền truy cập

Tại sao lại bôi đậm chữ **nên**, đó là vì: Đây là các quy tắc ngầm. Nếu bạn vẫn cố sử dụng thì cũng sẽ ko có lỗi nào từ trình biên dịch Python quăng ra cả.

Quy tắc này giúp code của bạn tường minh hơn cho người đọc. Nhưng người ko hiểu sẽ đặt câu hỏi vì sao phải đặt tên kiểu như vậy? (khiến họ bối rối hơn)



# CREDIT

https://martinheinz.dev/blog/79  
https://www.programiz.com/python-programming/class  
https://www.youtube.com/watch?v=6eyOQyG6FpE&ab_channel=PythonforEconometrics  
https://www.youtube.com/watch?v=328QCyHrXYA&ab_channel=PythonforEconometrics  
https://www.programiz.com/python-programming/args-and-kwargs  
https://viblo.asia/p/oop-voi-python-E375zQGblGW  
