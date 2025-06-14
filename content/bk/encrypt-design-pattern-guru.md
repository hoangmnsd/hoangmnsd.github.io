---
title: "Design Pattern notes"
date: 2025-01-02T22:49:25+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [Design-Pattern]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Fast notes trong quá trình mình tìm hiểu về 1 số loại Design Pattern phổ biến"
---

# 1. Design Pattern

## 1.1. Overview

### 1.1.1. Abstract Factory:

    Bạn có 1 nhóm các sản phẩm liên quan đến nhau: Chair, Sofa, CoffeeTable. Mỗi loại đều có 3 phong cách: Modern, Victorian, ArtDeco.
    Bạn ko muốn mix chúng lại vì như thế sai về phong cách (ví dụ: Modern Sofa ko thể đi với Victorian Chair...).

    Bạn cần phải tạo `Chair` interface, tất cả các phong cách Chair đều phải implements cái `Chair` interface. tất cả phong cách của CoffeeTable đều phải implements `CoffeeTable` interface.

    Giờ bạn sẽ tạo Abstract Factory tên là `FurnitureFactory`, là 1 interface chứa hết 3 method (`createChair, createSofa, createCoffeeTable`) để tạo ra 1 nhóm sản phẩm liên quan gồm: Chair, Sofa, CoffeeTable.

    Đối với phong cách, bạn sẽ tạo thêm các factory riêng như `ModernFurnitureFactory` implements cái `FurnitureFactory`. Nó sẽ chỉ tạo ra các `ModernChair, ModernSofa, ModernCoffeeTable`.

    (xem hình để dễ hình dung: https://refactoring.guru/design-patterns/abstract-factory)

### 1.1.2. Adapter aka Wrapper:

    Bạn có 1 app get data từ nhiều source khác nhau (format XML) hiển thị ra chart. Giờ bạn muốn implements 3rd party API nhưng nó lại chỉ có thể làm việc với input JSON data. Bạn ko muốn sửa code của bạn để return JSON. Bạn cũng ko thể làm cho 3rd party API làm việc dc với XML.

    Bạn tạo 1 XML-to-JSON adapter. Mỗi khi code của bạn cần làm việc với 3rd party API, nó sẽ phải đi qua XML-to-JSON adapter.

    xem phần Pseudocode để hiểu đoạn code sau:

    ```sh
    // Somewhere in client code.
    hole = new RoundHole(5)
    rpeg = new RoundPeg(5)
    hole.fits(rpeg) // true

    small_sqpeg = new SquarePeg(5)
    large_sqpeg = new SquarePeg(10)
    hole.fits(small_sqpeg) // this won't compile (incompatible types)

    small_sqpeg_adapter = new SquarePegAdapter(small_sqpeg)
    large_sqpeg_adapter = new SquarePegAdapter(large_sqpeg)
    hole.fits(small_sqpeg_adapter) // true
    hole.fits(large_sqpeg_adapter) // false
    ```

### 1.1.3. Builder:

    Ví dụ khi bạn cần xây dựng 1 đối tượng House. Để xây dựng một ngôi nhà đơn giản, bạn cần xây bốn bức tường và một sàn nhà, lắp đặt một cửa ra vào, gắn một cặp cửa sổ và lắp một mái nhà. Nhưng nếu bạn muốn một ngôi nhà lớn hơn, sáng hơn, có sân sau và những tiện nghi khác (như hệ thống sưởi, ống nước và dây điện)?

    Giải pháp 1 đơn giản nhất là extend cái base House class, tạo 1 loạt các subclass để cover các tổ hợp parameters khác nhau. Như vậy sẽ có 1 số lượng lớn các subclass được tạo ra.

    Giải pháp 2 là ko cần tạo subclass, nhưng phải thêm tất cả các parameters vào class House. Kiểu class House sẽ có rất nhiều parameters làm code xấu đi.
    Trong nhiều case, phần lớn các paramters là ko cần thiết.
    ```s
    house1 = new House(4,2,4, true, null, null, null, null,...)
    house2 = new House(4,2,4, true, true, true, true, true,...)
    ```

    Giải pháp 3 là áp dụng Builder pattern. Bạn tạo 1 class HouseBuilder trong đó chứa các step (buildWall, buildDoors...). Bạn ko cần gọi all steps, mà chỉ gọi các step cần thiết.
    Trường hợp 1 số step như buildWall sẽ khác nhau vì có thể wall xây bằng gỗ, hoặc đá. Bạn có thể tạo ra các class Builder riêng, như class WoodHouseBuilder xây tất cả bằng gỗ, class StoneHouseBuilder xây tất cả bằng đá.

### 1.1.4. Factory Method aka Virtual Constructor:

    Bạn có 1 cái app logistic. App của bạn version đầu chỉ xử lý được giao hàng bằng xe tải truck thôi, Code của bạn hiện đang ở trong 1 cái `Truck` class. Sau 1 thời gian, KH có nhu cầu giao hàng đường biển nữa.

    Code của bạn đang bám chặt logic vào `Truck` class, Nếu add thêm class `Ship` vào sẽ cần nhiều thay đổi.

    Giải pháp là, Bạn tạo 1 class `Logistics`, và 2 subclass `RoadLogistics` và `SeaLogistics`. Chúng đều có method `createTransport`.
    Nhưng method `createTransport` của `RoadLogistics` sẽ return Truck object. Còn method `createTransport` của `SeaLogistics` sẽ return Ship object.

    Bạn sẽ tạo thêm `Ship` class. `Ship` class và `Truck` class đều implements `Transport` interface (đều có method `deliver`).

    Mỗi class Ship hoặc Truck sẽ implements cái `deliver` method theo cách khác nhau. Ví dụ trucks deliver cargo trên đất liền. Ship deliver containers trên biển.


### 1.1.5. Bridge:

    Bạn có 1 app quản lý device và remote của chúng. Device có nhiều method (enable, disable, setVolume, setChannel). Remote có nhiều method (togglePower, volumeDown, volumeUp, channelDown, channelUp).

    Trong 1 app tệ nhất, bạn sẽ có hàng trăm class kết hợp các tổ hợp khác nhau của Device và Remote.

    Áp dụng Bridge pattern, ta sẽ chia lớp Abstraction là `Remote`, lớp Implementation là `Device`.

    Điều quan trọng là trong Abstraction `Remote` bạn sẽ khai báo 1 field để link với Implementation `Device`. Từ đó gọi các method của `Device` tương ứng với các method của `Remote`.

    Nhìn từ phía client, nó sẽ chỉ làm việc với lớp Abstraction mà thôi.

### 1.1.6. Composite aka Object Tree:

    khó hiểu

### 1.1.7. Prototype aka Clone:

    Design Pattern Prototype là một mẫu thiết kế trong lập trình nhằm tạo ra bản sao (nhân bản) của một đối tượng mà không cần phải biết rõ lớp cụ thể của nó. Điều này rất hữu ích khi việc khởi tạo một đối tượng mới tốn kém về tài nguyên hoặc thời gian.

    Ví dụ: Giả sử bạn có một đối tượng "Xe Hơi" với nhiều thuộc tính như màu sắc, kiểu dáng và động cơ. Thay vì tạo mỗi chiếc xe từ đầu, bạn có thể tạo một "xe mẫu" (prototype) và tạo nhiều chiếc xe mới bằng cách sao chép đối tượng này với các thuộc tính khác nhau.

    ```sh
    class CarPrototype:
        def __init__(self, model, color):
            self.model = model
            self.color = color

        def clone(self):
            return CarPrototype(self.model, self.color)

    # Tạo một xe mẫu
    car1 = CarPrototype("Toyota", "Red")

    # Nhân bản xe mẫu để tạo ra xe mới
    car2 = car1.clone()
    car2.color = "Blue"  # Thay đổi màu sắc của xe mới

    print(car1.color)  # Xuất ra: Red
    print(car2.color)  # Xuất ra: Blue
    ```

### 1.1.8. Singleton:

    Design Pattern "Singleton" là một mẫu thiết kế trong lập trình được sử dụng để đảm bảo rằng một lớp chỉ có một thể hiện (instance) duy nhất và cung cấp một điểm truy cập toàn cục đến đó.

    Giải thích ngắn gọn:
    Mục đích: Đảm bảo chỉ có một đối tượng duy nhất được tạo ra từ lớp đó.
    Cách thực hiện: Thường sử dụng phương thức tĩnh (static) để tạo và quản lý thể hiện duy nhất.

    Giả sử bạn có một lớp DatabaseConnection dùng để kết nối đến cơ sở dữ liệu. Bạn chỉ muốn có một thể hiện duy nhất của lớp này trong toàn bộ ứng dụng để tránh xung đột và tiết kiệm tài nguyên.

    Pattern Singleton rất hữu ích khi bạn cần giới hạn số lượng đối tượng của một lớp, chẳng hạn như khi làm việc với tài nguyên hạn chế hoặc để quản lý trạng thái toàn cục trong ứng dụng.

    ```sh
    class DatabaseConnection:
        _instance = None

        def __new__(cls):
            if cls._instance is None:
                cls._instance = super(DatabaseConnection, cls).__new__(cls)
                # Khởi tạo các thuộc tính của kết nối CSDL ở đây
            return cls._instance

    # Sử dụng
    db1 = DatabaseConnection()
    db2 = DatabaseConnection()

    print(db1 is db2)  # Kết quả sẽ là True, vì db1 và db2 là cùng một thể hiện
    ```

### 1.1.9. Decorator aka Wrapper:

    Decorators (pattern thiết kế trang trí) là một pattern thiết kế cấu trúc cho phép thêm chức năng mới vào một đối tượng hiện có mà không làm thay đổi cấu trúc của nó.
    Điều này rất hữu ích để gói ghém chức năng bổ sung một cách linh hoạt và có thể kết hợp nhiều decorator lại với nhau.

    Decorator cho phép bạn mở rộng chức năng của đối tượng mà không cần thay đổi mã nguồn của nó,
    giúp cho việc duy trì và phát triển mã trở nên dễ dàng hơn.

    Cách hoạt động:
        Component: Đối tượng chính mà bạn muốn mở rộng chức năng.
        Decorator: Là lớp cung cấp giao diện giống như component và có thể thêm chức năng mới vào đối tượng.

    Ví dụ 1:
    Giả sử bạn có một lớp Beverage đại diện cho đồ uống, và bạn muốn thêm các tùy chọn khác như thêm sữa và đường mà không làm thay đổi lớp Beverage:

    ```sh
    class Beverage:
        def cost(self):
            return 5  # Giá cơ bản cho đồ uống

    class MilkDecorator:
        def __init__(self, beverage):
            self.beverage = beverage

        def cost(self):
            return self.beverage.cost() + 1  # Thêm phí sữa

    class SugarDecorator:
        def __init__(self, beverage):
            self.beverage = beverage

        def cost(self):
            return self.beverage.cost() + 0.5  # Thêm phí đường

    # Sử dụng
    beverage = Beverage()
    print("Giá đồ uống cơ bản: ", beverage.cost())  # Giá 5

    # Thêm sữa
    beverage_with_milk = MilkDecorator(beverage)
    print("Giá với sữa: ", beverage_with_milk.cost())  # Giá 6

    # Thêm đường
    beverage_with_milk_and_sugar = SugarDecorator(beverage_with_milk)
    print("Giá với sữa và đường: ", beverage_with_milk_and_sugar.cost())  # Giá 6.5
    ```

    Ví dụ 2: Bạn có 1 library dựa trên class Notifier. Nó chỉ có vài field và 1 method `send()`. Method sẽ nhận arguments từ client, gửi email đến 1 list email.
    Nhiều 3rd-party sẽ sử dụng Notifier của bạn. Nhưng rồi theo thời gian, user mong muốn nhiều chức năng hơn. User muốn có thể notify đến cả Facebook, Slack, SMS.
    Rồi User muốn có thể gửi cùng lúc nhiều kênh chứ ko chỉ chọn một.

    Giải pháp: Bạn sẽ để 1 class Notifier chứa behavior đơn giản email. Còn bạn sẽ tạo chuyển tất cả các method notify khác sang thành Decorators.

    ```python
    # Đây là lớp cơ bản chỉ có khả năng gửi thông báo qua email.
    class Notifier:
        def __init__(self, email_list):
            self.email_list = email_list

        def send(self, message):
            print(f"Sending email to {self.email_list}: {message}")

    # Tạo các Decorator
    class SMSDecorator:
        def __init__(self, notifier):
            self.notifier = notifier

        def send(self, message):
            self.notifier.send(message)
            print(f"Sending SMS: {message}")

    class FacebookDecorator:
        def __init__(self, notifier):
            self.notifier = notifier

        def send(self, message):
            self.notifier.send(message)
            print(f"Sending Facebook message: {message}")

    class SlackDecorator:
        def __init__(self, notifier):
            self.notifier = notifier

        def send(self, message):
            self.notifier.send(message)
            print(f"Sending Slack message: {message}")

    # Client code sử dụng
    # Khởi tạo Notifier cơ bản
    notifier = Notifier(["user@example.com"])

    # Thêm các decorator
    sms_notifier = SMSDecorator(notifier)
    sms_and_fb_notifier = FacebookDecorator(sms_notifier)
    sms_and_fb_and_slack_notifier = SlackDecorator(sms_and_fb_notifier)
    fb_notifier = FacebookDecorator(notifier)

    print("Gửi thông báo bằng sms_notifier")
    sms_notifier.send("Critical issue detected!")
    print("\n")

    print("Gửi thông báo bằng sms_and_fb_notifier")
    sms_and_fb_notifier.send("Critical issue detected!")
    print("\n")

    print("Gửi thông báo bằng sms_and_fb_and_slack_notifier")
    sms_and_fb_and_slack_notifier.send("Critical issue detected!")
    print("\n")

    print("Gửi thông báo bằng fb_notifier")
    fb_notifier.send("Critical issue detected!")
    print("\n")
    ```

### 1.1.10. Facade:

    Façade là một mẫu thiết kế (design pattern) trong lập trình nhằm đơn giản hóa interface của một hệ thống phức tạp bằng cách cung cấp một interface đơn giản hơn cho người dùng hoặc các lớp khác trong chương trình. Mẫu thiết kế này giúp ẩn đi những chi tiết phức tạp của các lớp con và chỉ cung cấp những chức năng cần thiết để người dùng có thể dễ dàng tương tác.

### 1.1.11. Flyweight:

    Giả sử bạn đang phát triển một trò chơi và cần tạo ra nhiều đối tượng cho các loại cây. Thay vì tạo một đối tượng mới cho mỗi cây, bạn có thể tạo một đối tượng "Cây" dùng chung cho tất cả các cây cùng loại, và chỉ lưu lại thuộc tính khác nhau như vị trí hoặc kích thước của cây.

    ```py
    class TreeType:
        def __init__(self, name, color):
            self.name = name
            self.color = color

        def draw(self, x, y):
            print(f"Drawing {self.color} {self.name} at ({x}, {y})")

    class TreeFactory:
        _tree_types = {}

        @staticmethod
        def get_tree_type(name, color):
            key = (name, color)
            if key not in TreeFactory._tree_types:
                TreeFactory._tree_types[key] = TreeType(name, color)
            return TreeFactory._tree_types[key]

    # Sử dụng mẫu Flyweight
    forest = []
    forest.append(TreeFactory.get_tree_type("Oak", "Green"))
    forest.append(TreeFactory.get_tree_type("Pine", "Dark Green"))
    forest.append(TreeFactory.get_tree_type("Oak", "Green"))  # Sử dụng lại cùng một đối tượng Oak

    # Vẽ cây
    for idx, tree in enumerate(forest):
        tree.draw(idx * 10, idx * 20)
    ```

    Trong ví dụ trên, mặc dù có nhiều đối tượng cây được tạo ra, chỉ có hai đối tượng thực tế được tạo ra và được sử dụng lại, tiết kiệm bộ nhớ và nâng cao hiệu suất.

    Giả sử bạn gọi hàm `get_tree_type("Oak", "Green")` lần đầu tiên:

    Hàm kiểm tra `_tree_types` và thấy rằng không có key `("Oak", "Green")`, do đó nó tạo ra một đối tượng `TreeType` mới và lưu vào `_tree_types`.

    Nếu bạn gọi lại `get_tree_type("Oak", "Green")` lần thứ hai:

    Hàm sẽ tìm thấy key `("Oak", "Green")` trong `_tree_types`, và trả về đối tượng đã được tạo ra ở lần gọi đầu tiên mà không tạo thêm đối tượng mới.

    Việc sử dụng hàm `get_tree_type` theo cách này giúp tiết kiệm bộ nhớ bằng cách chia sẻ cùng một đối tượng giữa các phần khác nhau của chương trình, thay vì tạo ra nhiều đối tượng giống nhau. Đây chính là cốt lõi của mẫu thiết kế Flyweight.

### 1.1.12. Proxy:

    một mẫu thiết kế cấu trúc, trong đó một đối tượng (proxy) giữ vai trò đại diện cho một đối tượng khác. Mục đích chính của proxy là kiểm soát việc truy cập đến đối tượng thực, có thể là để tối ưu hóa tài nguyên, bảo mật hoặc cung cấp thêm tính năng.

    Giả sử bạn có một hình ảnh rất lớn mà việc tải xuống sẽ tốn nhiều thời gian và băng thông. Bạn có thể tạo một lớp Proxy để đại diện cho hình ảnh đó:

    ```py
    class RealImage:
        def __init__(self, filename):
            self.filename = filename
            self.load_image()

        def load_image(self):
            print(f"Loading {self.filename} from disk...")

        def display(self):
            print(f"Displaying {self.filename}")

    class ProxyImage:
        def __init__(self, filename):
            self.filename = filename
            self.real_image = None

        def display(self):
            if self.real_image is None:
                self.real_image = RealImage(self.filename)
            self.real_image.display()

    # Sử dụng
    image = ProxyImage("big_picture.jpg")
    image.display()  # Tải hình ảnh thực chỉ khi cần thiết
    ```

    Trong ví dụ trên, ProxyImage chỉ tải hình ảnh thực (RealImage) khi phương thức display được gọi lần đầu tiên. Điều này giúp tiết kiệm tài nguyên và cải thiện hiệu suất.

## 1.2. Pseudocode

### 1.2.1. Abstract Factory

source: https://refactoring.guru/design-patterns/abstract-factory

```sh
// The abstract factory interface declares a set of methods that
// return different abstract products. These products are called
// a family and are related by a high-level theme or concept.
// Products of one family are usually able to collaborate among
// themselves. A family of products may have several variants,
// but the products of one variant are incompatible with the
// products of another variant.
interface GUIFactory is
    method createButton():Button
    method createCheckbox():Checkbox


// Concrete factories produce a family of products that belong
// to a single variant. The factory guardicantees that the
// resulting products are compatible. Signatures of the concrete
// factory's methods return an abstract product, while inside
// the method a concrete product is instantiated.
class WinFactory implements GUIFactory is
    method createButton():Button is
        return new WinButton()
    method createCheckbox():Checkbox is
        return new WinCheckbox()

// Each concrete factory has a corresponding product variant.
class MacFactory implements GUIFactory is
    method createButton():Button is
        return new MacButton()
    method createCheckbox():Checkbox is
        return new MacCheckbox()


// Each distinct product of a product family should have a base
// interface. All variants of the product must implement this
// interface.
interface Button is
    method paint()

// Concrete products are created by corresponding concrete
// factories.
class WinButton implements Button is
    method paint() is
        // Render a button in Windows style.

class MacButton implements Button is
    method paint() is
        // Render a button in macOS style.

// Here's the base interface of another product. All products
// can interact with each other, but proper interaction is
// possible only between products of the same concrete variant.
interface Checkbox is
    method paint()

class WinCheckbox implements Checkbox is
    method paint() is
        // Render a checkbox in Windows style.

class MacCheckbox implements Checkbox is
    method paint() is
        // Render a checkbox in macOS style.


// The client code works with factories and products only
// through abstract types: GUIFactory, Button and Checkbox. This
// lets you pass any factory or product subclass to the client
// code without breaking it.
class Application is
    private field factory: GUIFactory
    private field button: Button
    constructor Application(factory: GUIFactory) is
        this.factory = factory
    method createUI() is
        this.button = factory.createButton()
    method paint() is
        button.paint()


// The application picks the factory type depending on the
// current configuration or environment settings and creates it
// at runtime (usually at the initialization stage).
class ApplicationConfigurator is
    method main() is
        config = readApplicationConfigFile()

        if (config.OS == "Windows") then
            factory = new WinFactory()
        else if (config.OS == "Mac") then
            factory = new MacFactory()
        else
            throw new Exception("Error! Unknown operating system.")

        Application app = new Application(factory)
```

### 1.2.2. Adapter aka Wrapper

source: https://refactoring.guru/design-patterns/adapter

```sh
// Say you have two classes with compatible interfaces:
// RoundHole and RoundPeg.
class RoundHole is
    constructor RoundHole(radius) { ... }

    method getRadius() is
        // Return the radius of the hole.

    method fits(peg: RoundPeg) is
        return this.getRadius() >= peg.getRadius()

class RoundPeg is
    constructor RoundPeg(radius) { ... }

    method getRadius() is
        // Return the radius of the peg.


// But there's an incompatible class: SquarePeg.
class SquarePeg is
    constructor SquarePeg(width) { ... }

    method getWidth() is
        // Return the square peg width.


// An adapter class lets you fit square pegs into round holes.
// It extends the RoundPeg class to let the adapter objects act
// as round pegs.
class SquarePegAdapter extends RoundPeg is
    // In reality, the adapter contains an instance of the
    // SquarePeg class.
    private field peg: SquarePeg

    constructor SquarePegAdapter(peg: SquarePeg) is
        this.peg = peg

    method getRadius() is
        // The adapter pretends that it's a round peg with a
        // radius that could fit the square peg that the adapter
        // actually wraps.
        return peg.getWidth() * Math.sqrt(2) / 2


// Somewhere in client code.
hole = new RoundHole(5)
rpeg = new RoundPeg(5)
hole.fits(rpeg) // true

small_sqpeg = new SquarePeg(5)
large_sqpeg = new SquarePeg(10)
hole.fits(small_sqpeg) // this won't compile (incompatible types)

small_sqpeg_adapter = new SquarePegAdapter(small_sqpeg)
large_sqpeg_adapter = new SquarePegAdapter(large_sqpeg)
hole.fits(small_sqpeg_adapter) // true
hole.fits(large_sqpeg_adapter) // false
```


### 1.2.3. Builder

source: https://refactoring.guru/design-patterns/builder

```sh
// Using the Builder pattern makes sense only when your products
// are quite complex and require extensive configuration. The
// following two products are related, although they don't have
// a common interface.
class Car is
    // A car can have a GPS, trip computer and some number of
    // seats. Different models of cars (sports car, SUV,
    // cabriolet) might have different features installed or
    // enabled.

class Manual is
    // Each car should have a user manual that corresponds to
    // the car's configuration and describes all its features.


// The builder interface specifies methods for creating the
// different parts of the product objects.
interface Builder is
    method reset()
    method setSeats(...)
    method setEngine(...)
    method setTripComputer(...)
    method setGPS(...)

// The concrete builder classes follow the builder interface and
// provide specific implementations of the building steps. Your
// program may have several variations of builders, each
// implemented differently.
class CarBuilder implements Builder is
    private field car:Car

    // A fresh builder instance should contain a blank product
    // object which it uses in further assembly.
    constructor CarBuilder() is
        this.reset()

    // The reset method clears the object being built.
    method reset() is
        this.car = new Car()

    // All production steps work with the same product instance.
    method setSeats(...) is
        // Set the number of seats in the car.

    method setEngine(...) is
        // Install a given engine.

    method setTripComputer(...) is
        // Install a trip computer.

    method setGPS(...) is
        // Install a global positioning system.

    // Concrete builders are supposed to provide their own
    // methods for retrieving results. That's because various
    // types of builders may create entirely different products
    // that don't all follow the same interface. Therefore such
    // methods can't be declared in the builder interface (at
    // least not in a statically-typed programming language).
    //
    // Usually, after returning the end result to the client, a
    // builder instance is expected to be ready to start
    // producing another product. That's why it's a usual
    // practice to call the reset method at the end of the
    // `getProduct` method body. However, this behavior isn't
    // mandatory, and you can make your builder wait for an
    // explicit reset call from the client code before disposing
    // of the previous result.
    method getProduct():Car is
        product = this.car
        this.reset()
        return product

// Unlike other creational patterns, builder lets you construct
// products that don't follow the common interface.
class CarManualBuilder implements Builder is
    private field manual:Manual

    constructor CarManualBuilder() is
        this.reset()

    method reset() is
        this.manual = new Manual()

    method setSeats(...) is
        // Document car seat features.

    method setEngine(...) is
        // Add engine instructions.

    method setTripComputer(...) is
        // Add trip computer instructions.

    method setGPS(...) is
        // Add GPS instructions.

    method getProduct():Manual is
        // Return the manual and reset the builder.


// The director is only responsible for executing the building
// steps in a particular sequence. It's helpful when producing
// products according to a specific order or configuration.
// Strictly speaking, the director class is optional, since the
// client can control builders directly.
class Director is
    // The director works with any builder instance that the
    // client code passes to it. This way, the client code may
    // alter the final type of the newly assembled product.
    // The director can construct several product variations
    // using the same building steps.
    method constructSportsCar(builder: Builder) is
        builder.reset()
        builder.setSeats(2)
        builder.setEngine(new SportEngine())
        builder.setTripComputer(true)
        builder.setGPS(true)

    method constructSUV(builder: Builder) is
        // ...


// The client code creates a builder object, passes it to the
// director and then initiates the construction process. The end
// result is retrieved from the builder object.
class Application is

    method makeCar() is
        director = new Director()

        CarBuilder builder = new CarBuilder()
        director.constructSportsCar(builder)
        Car car = builder.getProduct()

        CarManualBuilder builder = new CarManualBuilder()
        director.constructSportsCar(builder)

        // The final product is often retrieved from a builder
        // object since the director isn't aware of and not
        // dependent on concrete builders and products.
        Manual manual = builder.getProduct()
```

### 1.2.4. Factory Method

source: https://refactoring.guru/design-patterns/factory-method

```sh
// The creator class declares the factory method that must
// return an object of a product class. The creator's subclasses
// usually provide the implementation of this method.
class Dialog is
    // The creator may also provide some default implementation
    // of the factory method.
    abstract method createButton():Button

    // Note that, despite its name, the creator's primary
    // responsibility isn't creating products. It usually
    // contains some core business logic that relies on product
    // objects returned by the factory method. Subclasses can
    // indirectly change that business logic by overriding the
    // factory method and returning a different type of product
    // from it.
    method render() is
        // Call the factory method to create a product object.
        Button okButton = createButton()
        // Now use the product.
        okButton.onClick(closeDialog)
        okButton.render()


// Concrete creators override the factory method to change the
// resulting product's type.
class WindowsDialog extends Dialog is
    method createButton():Button is
        return new WindowsButton()

class WebDialog extends Dialog is
    method createButton():Button is
        return new HTMLButton()


// The product interface declares the operations that all
// concrete products must implement.
interface Button is
    method render()
    method onClick(f)

// Concrete products provide various implementations of the
// product interface.
class WindowsButton implements Button is
    method render(a, b) is
        // Render a button in Windows style.
    method onClick(f) is
        // Bind a native OS click event.

class HTMLButton implements Button is
    method render(a, b) is
        // Return an HTML representation of a button.
    method onClick(f) is
        // Bind a web browser click event.


class Application is
    field dialog: Dialog

    // The application picks a creator's type depending on the
    // current configuration or environment settings.
    method initialize() is
        config = readApplicationConfigFile()

        if (config.OS == "Windows") then
            dialog = new WindowsDialog()
        else if (config.OS == "Web") then
            dialog = new WebDialog()
        else
            throw new Exception("Error! Unknown operating system.")

    // The client code works with an instance of a concrete
    // creator, albeit through its base interface. As long as
    // the client keeps working with the creator via the base
    // interface, you can pass it any creator's subclass.
    method main() is
        this.initialize()
        dialog.render()
```

### 1.2.5. Bridge

Python code: https://refactoring.guru/design-patterns/bridge/python/example

```sh
// The "abstraction" defines the interface for the "control"
// part of the two class hierarchies. It maintains a reference
// to an object of the "implementation" hierarchy and delegates
// all of the real work to this object.
class RemoteControl is
    protected field device: Device
    constructor RemoteControl(device: Device) is
        this.device = device
    method togglePower() is
        if (device.isEnabled()) then
            device.disable()
        else
            device.enable()
    method volumeDown() is
        device.setVolume(device.getVolume() - 10)
    method volumeUp() is
        device.setVolume(device.getVolume() + 10)
    method channelDown() is
        device.setChannel(device.getChannel() - 1)
    method channelUp() is
        device.setChannel(device.getChannel() + 1)


// You can extend classes from the abstraction hierarchy
// independently from device classes.
class AdvancedRemoteControl extends RemoteControl is
    method mute() is
        device.setVolume(0)


// The "implementation" interface declares methods common to all
// concrete implementation classes. It doesn't have to match the
// abstraction's interface. In fact, the two interfaces can be
// entirely different. Typically the implementation interface
// provides only primitive operations, while the abstraction
// defines higher-level operations based on those primitives.
interface Device is
    method isEnabled()
    method enable()
    method disable()
    method getVolume()
    method setVolume(percent)
    method getChannel()
    method setChannel(channel)


// All devices follow the same interface.
class Tv implements Device is
    // ...

class Radio implements Device is
    // ...


// Somewhere in client code.
tv = new Tv()
remote = new RemoteControl(tv)
remote.togglePower()

radio = new Radio()
remote = new AdvancedRemoteControl(radio)
```

### 1.2.6. Facade

```sh
// These are some of the classes of a complex 3rd-party video
// conversion framework. We don't control that code, therefore
// can't simplify it.

class VideoFile
// ...

class OggCompressionCodec
// ...

class MPEG4CompressionCodec
// ...

class CodecFactory
// ...

class BitrateReader
// ...

class AudioMixer
// ...


// We create a facade class to hide the framework's complexity
// behind a simple interface. It's a trade-off between
// functionality and simplicity.
class VideoConverter is
    method convert(filename, format):File is
        file = new VideoFile(filename)
        sourceCodec = (new CodecFactory).extract(file)
        if (format == "mp4")
            destinationCodec = new MPEG4CompressionCodec()
        else
            destinationCodec = new OggCompressionCodec()
        buffer = BitrateReader.read(filename, sourceCodec)
        result = BitrateReader.convert(buffer, destinationCodec)
        result = (new AudioMixer()).fix(result)
        return new File(result)

// Application classes don't depend on a billion classes
// provided by the complex framework. Also, if you decide to
// switch frameworks, you only need to rewrite the facade class.
class Application is
    method main() is
        convertor = new VideoConverter()
        mp4 = convertor.convert("funny-cats-video.ogg", "mp4")
        mp4.save()
```
