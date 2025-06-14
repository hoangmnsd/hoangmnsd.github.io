---
title: "Performance Tests with Locust"
date: 2022-09-29T00:07:17+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Locust,Test]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "1 vài demo nho nhỏ với Locus để làm performance test"
---

# 1. Giải thích các khái niệm 1 cách ngắn gọn

**Performance test** ko phải là 1 kiểu test cụ thể nào, nó là 1 khái niệm chung cho tất cả các kiểu test nhằm validate performance và xác định performance issues.

**Load test** là 1 kiểu test để validate xem application của bạn có thỏa mãn các goals đã đc define từ trước hay ko? Khi xây dựng app thì bạn phải define rằng app này sẽ cho phép bao nhiêu CCU? Nếu bạn define 50 CCU thì Load test chỉ cần đạt được 50 CCU là OK.

**Stress test** là 1 kiểu test để xác định behavior của application là như nào nếu nó phải chịu 1 lượng traffic lớn hơn nhiều so với expectation. Ví dụ nếu app của bạn define CCU là 50 thì Stress test với 500 CCU thì App của bạn sẽ như nào? (throttle? crash? restart?)

**Volume test** là 1 kiểu test được dùng trong 2 case:
- Xác định performance của app khi phải chịu các khối lượng data khác nhau đi vào Database  
- Tính toán khả năng của app với 1 khối lượng lớn data (ví dụ như import large volume data from file to DB...)

**Endurance test** là 1 kiểu test để tìm ra các issue mà chỉ có thể xảy ra khi app đã chạy 1 thời gian dài, nói chung là những case mà khó có thể phát hiện bug nếu thời gian test ngắn.

# 2. Locust (Basic)

## 2.1. Basic step

Install:  
```sh
$ python --version
Python 3.9.2

$ pip3 install locust
# wait till all done

$ locust -V
locust 2.12.1
```

Quick start:  
tạo 1 file `locustfile.py`:  
```python
from locust import HttpUser, task
            
class User(HttpUser):
    @task
    def mainPage(self):
        self.client.get("/")
```

thế thôi, run command `locust`:  
```
$ locust
[2022-09-30 23:29:17,172] raspian-rpi/WARNING/locust.main: System open file limit '1024' is below minimum setting '10000'.
It's not high enough for load testing, and the OS didn't allow locust to increase it by itself.
See https://github.com/locustio/locust/wiki/Installation#increasing-maximum-number-of-open-files-limit for more info.
[2022-09-30 23:29:17,173] raspian-rpi/INFO/locust.main: Starting web interface at http://0.0.0.0:8089 (accepting connections from all network interfaces)
[2022-09-30 23:29:17,205] raspian-rpi/INFO/locust.main: Starting Locust 2.12.1
```
Giờ bạn có thể truy cập vào địa chỉ `127.0.0.1:8089` để xem giao diện Locust:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-init-dashboard.jpg)

Điền 1 số thông tin vào giao diện như này rồi ấn Start:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-test-basic-1.jpg)

màn hình chờ trong lúc script đang chạy:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-test-basic-1-wait.jpg)

Ấn Stop và xem kết quả: 
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-test-basic-1-stopped.jpg)

Ấn vào tab Chart để xem:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-test-basic-1-charts.jpg)

Chart `Total RPS` đúng như tên gọi, chưa biết cách tăng lên như nào?  
Chart `Response times`:  
- có `Median Response Time` là respone time trung bình của 50% số request  
- có `95% percentile`: là respone time trung bình của 95% số request    
Chart `Number of users`: số lượng user theo thời gian  

Ấn vào tab Download Data sẽ download dc report dưới dạng html:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-test-basic-1-report.jpg)

Khá hay đấy chứ

Tuy nhiên mình sẽ tìm cách để làm hết dưới dạng câu lệnh vào lưu lại report 1 cách tự động sau khi test xong.  


## 2.2. Distributed mode with docker-compose

Chạy ở mode này sẽ tạo ra các container cho master và worker, làm tăng performance của Locust lên

Chúng ta sẽ chuẩn bị folder structure đơn giản như này:  
tạo folder `/opt/devops/locust` trước nhé  
```
/opt/devops/locust $ tree .
.
├── docker-compose.yml
├── html-report/
├── locustfile.py
├── master.conf

```

File `docker-compose.yml` file:  
```yml
version: '3'

services:
  master:
    image: locustio/locust
    ports:
     - "8089:8089"
    volumes:
      - /opt/devops/locust:/mnt/locust
    command: -f /mnt/locust/locustfile.py --config=/mnt/locust/master.conf
  
  worker:
    image: locustio/locust
    volumes:
      - /opt/devops/locust:/mnt/locust
    command: -f /mnt/locust/locustfile.py --worker --master-host master
```
File `locustfile.py`:
```python
from locust import HttpUser, task
            
class User(HttpUser):
    @task
    def mainPage(self):
        self.client.get("/")
```

File `master.conf`:
```
# master.conf in current directory
locustfile = ./locustfile.py
headless = true
master = true
expect-workers = 3
host = http://192.168.1.128:3000 # this is the site you want to test
users = 80
spawn-rate = 2
run-time = 2m
html = /mnt/locust/html-report/report.html
```
https://docs.locust.io/en/2.12.1/configuration.html#configuration-file

- `users = 200`: tổng số user  
- `spawn-rate = 10`: là số user per second  
Ex: `users = 200, spawn-rate = 10`=> mỗi giây sẽ tăng lên 10 user, dần dần đến max là 200 user  

- `run-time = 2m`: thời gian chạy file test locust 2 minutes  
- `headless = true`: sẽ ko có giao diện UI để vào xem trực tiếp trên port 8089  
- `master = true`: sẽ run ở mode distributed mode ( bao gồm master và các worker)  

Run docker-compose:  
Do mình đang set trong `master.conf` là `expect-workers = 3` nên mình sẽ run command `scale worker=3`
```sh
cd /opt/devops/locust
docker-compose up --scale worker=3
```
Docker sẽ tạo ra 1 container cho master và 3 container cho worker để run test

Sau khi chạy xong, vào xem `report.html` trên chrome thôi

## 2.3. Xác định CCU

Nếu bạn muốn xem web app của mình có thể handle đc bao nhiêu CCU thì cứ tăng dần số users lên thôi

Hãy tham khảo link này: https://github.com/locustio/locust/wiki/FAQ#increase-my-request-raterps
Nó nói rằng: Nếu Chart Response times tăng lên bất ngờ khi bạn tăng số users lên thì có thể app của bạn đã đạt giới hạn rồi. 

Ví dụ con số trung bình Response Times mà bạn chấp nhận được là 2000ms (2s) chẳng hạn. Như bài này (https://medium.com/swlh/load-testing-with-locust-3e74349f9cbf) họ nói rằng: 
> In 2020, the average Time-To-First-Byte (TTFB) speed was found to be 1.28 seconds (1280ms) on desktop and 2.59 seconds (1590ms) on mobile. However, Google’s best practice is to achieve a time under 200ms.

Thì bạn phải tăng số user dần dần lên. Cho đến khi chỉ số Response Times vượt quá 2000ms thì có nghĩa đó là ngưỡng giới hạn của website rồi.  

Ví dụ tình huống này khi số lượng user=88 thì 95% request mất 1,9s để finish (nhỏ hơn expected):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-test-charts-rt-1.jpg)

Còn khi user=98 thì 95% request mất 2,8s để finish (lớn hơn expected):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-test-charts-rt-2.jpg)

Đó là khi mình xác định được website của mình chỉ chấp nhận khoảng ~80 user với Average size là 28101 bytes mà thôi, khi đó Response Times sẽ không vượt quá 2000ms (2s)

## 2.4. Request per second (RPS)

Chắc hẳn khi làm bạn sẽ muốn tăng số lượng RPS lên, hoặc xác định bao nhiêu RPS là max.  
Nhưng Locust được thiết kế để trả lời câu hỏi: `How many concurrent users can my application support?` (source: https://stackoverflow.com/a/27716019/9922066)  

> In many cases it's much more relevant to be able to say "our system can handle X number of simultaneous users", than "our system kan handle Y requests/second". Even though it's often quite easy to determine Y as well, by just simulating more users until the system that is being tested can no longer handle the load.  
(source: https://github.com/locustio/locust/issues/646#issuecomment-360405844)


Mặc dù vậy theo link này thì vẫn có 1 cách: https://stackoverflow.com/a/70935620/9922066

Đó là sửa file `locustfile.py`:  
```python
from locust import HttpUser, task, constant_throughput
            
class User(HttpUser):
    wait_time = constant_throughput(1)
    @task
    def mainPage(self):
        self.client.get("/")

```
hoặc:  
```python
from locust import HttpUser, task, constant_pacing
            
class User(HttpUser):
    wait_time = constant_pacing(1)
    @task
    def mainPage(self):
        self.client.get("/")
```

Khi mình set: 
```
users = 2
spawn-rate = 2
```
thì sẽ có chính xác 2 RPS trong chart:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-test-charts-rps-1.jpg)

Khi mình set:
```
users = 50
spawn-rate = 2
```
thì sẽ có khoảng 48 RPS trong chart:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-test-charts-rps-50.jpg)

Khi mình set:
```
users = 80
spawn-rate = 10
```
thì sẽ có khoảng 70 RPS trong chart:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-test-charts-rps-80.jpg)

Khi mình set:
```
users = 200
spawn-rate = 10
```
thì vẫn sẽ có khoảng 70 RPS trong chart:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-test-charts-rps-200.jpg)

Điều này chứng tỏ 70 RPS là giới hạn của chúng ta rồi (kết quả này khá match với CCU mà mình đã xác định trong phần `2.3`)


## 2.5. Troubeshooting

Tuy nhiên giờ có 1 vấn đề, bạn biết RPS rồi CCU rồi, nhưng lại ko chắc đây là giới hạn của Web server hay của Locust server?

1 số người từng gặp phải các vấn đề tương tự, họ run Locust trên những VPS rất mạnh, nhưng RPS ko vượt quá 300 (trong khi họ expect là 3000 RPS): https://github.com/locustio/locust/issues/710

Điều này phụ thuộc vào khá nhiều thứ: 
- CPU/Memory/network bandwidth on Web server  
- CPU/Memory/network bandwidth on Locust server  
- Application code  

Khi điều đó xảy ra, nếu ko thể debug trên log của Web server thì hãy dùng `htop` để theo dõi CPU/Memory trên cả Locust server và Web server, Khi run test chúng nên thường xuyên chạy ở mức 70-80% CPU, Memory mà thôi  

Giờ mình sẽ thử tạo 1 static site trên AWS S3. Điều này sẽ đảm bảo rằng sẽ ko có vấn đề gì ở phía Web server (vì AWS S3 nổi tiếng về việc có thể serve được rất nhiều RPS) 
https://aws.amazon.com/premiumsupport/knowledge-center/s3-request-limit-avoid-throttling/  
https://www.netdepot.com/blog/8-top-amazon-s3-performance-tips  

Khi đó, nếu Locust script test 1 website trên S3 mà chỉ có RPS khoảng 100 thì chứng tỏ Locust server của mình đã đạt giới hạn của nó.  

Mình test với:  
```
users = 100
spawn-rate = 5
run-time = 2m
```
Kết quả khá ấn tượng khi RPS lên 333, Response time của 95% là 250 ms thôi. Ngoài ra có 5 request lỗi.    
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-test-charts-s3-static-100u.jpg)  

Giờ mình test với:  
```
users = 500
spawn-rate = 50
run-time = 2m
```
Kết quả là RPS đạt khoảng 398, Response time của 95% là 1700 ms. Có 22 request lỗi.  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-test-charts-s3-static-500u.jpg)

Như vậy mình có thể kết luận rằng Locust server của mình chỉ có thể generate ra khoảng 300-400 RPS với CCU khoảng 300-400 mà thôi. Tất nhiên bài test này có phần ko công bằng với lần test trước vì lần này S3 static site của mình có Average size chỉ khoảng 837 bytes (ít hơn nhiều so với lần trước là 28101 bytes)

# 3. Locust (Advanced)

## 3.1. Communicate across Locust Nodes

Bài toán mình tự đặt ra:  
- Mình có 1 admin account và 4 test account.  
- Admin account sẽ sử dụng để lấy token đúng 1 lần trên Master node, phải chia sẻ token đó cho các Worker node còn lại dùng.  
- Test account sẽ phải login đúng 1 lần trên các Worker (Worker nào thì ko cần quan tâm). Có 4 test account thì trong final report phải có 4 login request. Nói chung 1 test account ko được login 2 lần.  

Mình sẽ sử dụng Navidrome để giả lập 1 website để test.  

Working dir sẽ kiểu như này:  
```
.
├── locust
│   ├── docker-compose.yml
│   ├── html-report
│   │   └── report.html
│   ├── locustfile.py
│   └── master.conf
└── navidrome
    ├── data
    ├── docker-compose.yml
    └── music
        └── Nhu Vay Nhe Cover - Tu Na.mp3
```

Clone repo sau về: `https://github.com/hoangmnsd/locust-lab`, trong đó có sẵn cấu trúc folder rồi.  

### 3.1.1. Setup Navidrome 

Bạn sẽ thấy trong repo `https://github.com/hoangmnsd/locust-lab` như sau:  
- tạo sẵn 2 folder `navidrome/data` và `navidrome/music`, trong đó cho 1 file mp3 bài hát bất kỳ vào folder music.  
- tạo file `navidrome/docker-compose.yml`, chú ý rằng mình tạo 1 network bridge `common-nw` để sau này có thể communicate giữa 2 `docker-compose.yml` file khác nhau:  

```yml
version: '3'

services:
  navidrome:
    container_name: navidrome
    image: deluan/navidrome:latest
    ports:
      - "4533:4533"
    environment:
      # Optional: put your config options customization here. Examples:
      ND_SCANSCHEDULE: 1h
      ND_LOGLEVEL: info
      ND_BASEURL: ""
    volumes:
      - "../navidrome/data:/data"
      - "../navidrome/music:/music:ro"
    networks:
      - common-nw
networks:
  common-nw:
    driver: bridge
```

- Run command:  
```sh
cd navidrome/
docker-compose up -d
```

Giờ hãy truy cập vào địa chỉ ip của Server mà bạn cài Navidrome: `http://<IP-ADDRESS>:4533`

Tạo admin account và test account:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/navidrome-test-user-loc.jpg)

Giả sử user/password lần lượt là:   
- admin/admin  
- test1/test1  
- test2/test2  
- test3/test3  
- test4/test4  

### 3.1.2. Setup Locust
Trong repo `https://github.com/hoangmnsd/locust-lab`:  
- tạo sẵn folder `locust/html-report` để sau này chứa file report  
- tạo sẵn file `locust/docker-compose.yml`, chú ý mình đã liên kết với navidrome bằng cách sử dụng external network, điều này cho phép locust sẽ hiểu khi bạn define gọi đến host `http://navidrome:4533`:   

```
version: '3'

services:
  master:
    image: locustio/locust
    ports:
     - "8089:8089"
    volumes:
      - .:/mnt/locust
    command: -f /mnt/locust/locustfile.py --config=/mnt/locust/master.conf
    networks:
      - navidrome_common-nw

  worker:
    image: locustio/locust
    volumes:
      - .:/mnt/locust
    command: -f /mnt/locust/locustfile.py --worker --master-host master
    networks:
      - navidrome_common-nw

networks:
  navidrome_common-nw:
    external: true
```

- tạo sẵn file `locust/master.conf`, chú ý chỗ host mình đang trỏ đến hostname của container service `http://navidrome:4533`, điều này hạn chế lỗi `Failed to establish a new connection: [Errno 111] Connection refused')) or [Errno 113] No route to host` khi bạn dùng `localhost:4533`, `127.0.0.1:4533`:  

```
# master.conf in current directory
locustfile = ./locustfile.py
headless = true
master = true
expect-workers = 2
host = http://navidrome:4533
users = 50
spawn-rate = 5
run-time = 1m
html = /mnt/locust/html-report/report.html
```

=> file này đang setting số worker = 2 và lượng user giả lập là 50. Cần phân biệt rõ, 50 user này ko phải là số account tạo ra đâu nhé. 50 users này giống như 50 tab khác nhau được bật lên, thực hiện riêng các sequence of task trong `locustfile.py`

- tạo sẵn file `locust/locustfile.py`, đây là file quan trọng mà mình muốn giải thích trong phần sau

### 3.1.3. Run script and explain the log

```sh
cd locust
docker-compose up --scale worker=2
```

Đảm bảo rằng script `locust/locustfile.py` chạy ko có lỗi gì, bạn có thể download `report.html` về và mở trên chrome để xem:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/locust-test-adv-1-report.jpg)

Giải thích script `locust/locustfile.py`:    

- decorate `@events.init.add_listener` sẽ giúp `on_locust_init` run đầu tiên trên các node và chỉ run 1 lần. Nếu đang run trên Worker, ta sẽ đăng ký (register) message rằng nếu nhận được message type `test_users` thì hãy run hàm `setup_test_users`, còn nếu nhận được message type `unique_token` thì run hàm `setup_unique_token`. Nếu đang run trên Master ta sẽ đăng ký message rằng nếu nhận được message `acknowledge_users` thì hãy run hàm `on_acknowledge`.


- Sau đó hàm có decorate `@events.test_start.add_listener` sẽ run để lấy admin token nếu đang là Master node. Tiếp, nó chia đều các test account cho từng Worker (chỗ này cộng trừ nhân chia hơi rối bạn nên đọc kỹ). Cuối cùng nó gửi data (các account và token) tới từng Worker bằng hàm `environment.runner.send_message`. Đây chính là chiều giao tiếp từ Master đến Workers.  


- Tiếp theo, hàm `setup_test_users` và `setup_unique_token` sẽ được run. Chỗ hàm `setup_test_users` bạn sẽ thấy khi nhận được list account của mình xong, Worker sẽ run hàm `environment.runner.send_message` để gửi tới Master lời cảm ơn của mình. Khi Master nhận được nó sẽ in ra lời cảm ơn của Worker. Đây chính là chiều giao tiếp từ Worker đến Master.


- Cuộc nói chuyện kết thúc và hàm `on_start(self)` sẽ mở đầu cho chuỗi sequence of tasks. Nó lấy token ra từ list `token_shared` gán vào 1 biến `global token` để các task khác có thể sử dụng.  Sau đó, nó `pop()` dần dần từng account trong list `testuser_filtered` ra để login. Điều kiện `if len(testuser_filtered) > 0:` sẽ đảm bảo rằng script sẽ ko `pop from empty list`, như vậy mặc dù hàm `on_start(self)` run nhiều lần nhưng mỗi test account chỉ login 1 lần mà thôi. 


- Hàm `getAllSongs`, chú ý chỗ `response.failure("getAllSongs: Got wrong response")`, là 1 ví dụ nếu bạn muốn kiểm tra response trả về.


- Hàm `getAllAlbums` chỗ `elif response.elapsed.total_seconds() > 0.04:`, là 1 ví dụ nếu bạn muốn assert response time phải ở mức nào đó. 


- Hàm `createDeletePlaylist` chỗ `name="/api/playlist/[id]"`, là 1 ví dụ để bạn nhóm các request lại trong Final Report, tránh việc làm rối report bởi quá nhiều request cùng loại.  

- Trong document của Locust có nói về recommended structure folder như sau: https://docs.locust.io/en/stable/writing-a-locustfile.html#how-to-structure-your-test-code  

LOG khá dài nhưng mình chỉ lấy phần đầu thôi, xem log này cùng với đọc code sẽ hiểu được thứ tự các hàm được gọi trong Locust:    

```
 $ docker-compose up --scale worker=2
[+] Running 3/0
 ⠿ Container locust-worker-1  Created                                                                                                              0.0s
 ⠿ Container locust-worker-2  Created                                                                                                              0.0s
 ⠿ Container locust-master-1  Created                                                                                                              0.0s
Attaching to locust-master-1, locust-worker-1, locust-worker-2
locust-master-1  | Initializing locust message types and listeners
locust-master-1  | [2022-10-15 08:14:43,657] 6335de046f29/INFO/root: Waiting for workers to be ready, 0 of 2 connected
locust-master-1  | Type     Name                                                                          # reqs      # fails |    Avg     Min     Max    Med |   req/s  failures/s
locust-master-1  | --------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
locust-master-1  | --------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
locust-master-1  |          Aggregated                                                                         0     0(0.00%) |      0       0       0      0 |    0.00        0.00
locust-master-1  |
locust-master-1  | [2022-10-15 08:14:43,666] 6335de046f29/INFO/locust.runners: Worker 5201f3c32fcb_57d185c2045540ffbeeae3fc9d30e1ed (index 0) reported as ready. 1 workers connected.
locust-worker-2  | Initializing locust message types and listeners
locust-worker-2  | [2022-10-15 08:14:43,668] 5201f3c32fcb/INFO/locust.main: Starting Locust 2.12.1
locust-master-1  | [2022-10-15 08:14:43,911] 6335de046f29/INFO/locust.runners: Worker 29adedeb6842_18225c26a017418e85458e5356309bba (index 1) reported as ready. 2 workers connected.
locust-worker-1  | Initializing locust message types and listeners
locust-worker-1  | [2022-10-15 08:14:43,913] 29adedeb6842/INFO/locust.main: Starting Locust 2.12.1
locust-master-1  | [2022-10-15 08:14:44,659] 6335de046f29/INFO/locust.main: Run time limit set to 60 seconds
locust-master-1  | [2022-10-15 08:14:44,660] 6335de046f29/INFO/locust.main: Starting Locust 2.12.1
locust-master-1  | [2022-10-15 08:14:44,661] 6335de046f29/INFO/locust.runners: Sending spawn jobs of 50 users at 5.00 spawn rate to 2 ready workers
locust-master-1  | MASTER say - Trying to get token on this node
locust-master-1  | MASTER say - Number of user to be divided between each worker is 2
locust-master-1  | sending this data [{'account': ('test1', 'test1')}, {'account': ('test2', 'test2')}] to this 5201f3c32fcb_57d185c2045540ffbeeae3fc9d30e1ed
locust-master-1  | sending this token [{'admin_token': 'eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w'}] to this 5201f3c32fcb_57d185c2045540ffbeeae3fc9d30e1ed
locust-master-1  | sending this data [{'account': ('test3', 'test3')}, {'account': ('test4', 'test4')}] to this 29adedeb6842_18225c26a017418e85458e5356309bba
locust-worker-2  | Worker say - setup_test_users - msg.data:  [{'account': ['test1', 'test1']}, {'account': ['test2', 'test2']}]
locust-worker-2  | Worker say - Here is accounts I received: [['test1', 'test1'], ['test2', 'test2']]
locust-master-1  | sending this token [{'admin_token': 'eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w'}] to this 29adedeb6842_18225c26a017418e85458e5356309bba
locust-worker-2  | Worker say - setup_unique_token - msg.data:  [{'admin_token': 'eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w'}]
locust-worker-2  | Worker say - Here is token I received: ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-worker-1  | Worker say - setup_test_users - msg.data:  [{'account': ['test3', 'test3']}, {'account': ['test4', 'test4']}]
locust-worker-1  | Worker say - Here is accounts I received: [['test3', 'test3'], ['test4', 'test4']]
locust-master-1  | MASTER say - Here is message from Woker: Thanks for the 2 users!
locust-worker-1  | Worker say - setup_unique_token - msg.data:  [{'admin_token': 'eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w'}]
locust-worker-1  | Worker say - Here is token I received: ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-master-1  | MASTER say - Here is message from Woker: Thanks for the 2 users!
locust-worker-2  | on_start running - testuser_filtered =  [['test1', 'test1'], ['test2', 'test2']]
locust-worker-2  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-worker-1  | on_start running - testuser_filtered =  [['test3', 'test3'], ['test4', 'test4']]
locust-worker-1  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-worker-2  | on_start running - testuser_filtered =  [['test1', 'test1']]
locust-worker-2  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-worker-1  | on_start running - testuser_filtered =  [['test3', 'test3']]
locust-worker-1  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-worker-1  | on_start running - testuser_filtered =  []
locust-worker-1  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-master-1  | Type     Name                                                                          # reqs      # fails |    Avg     Min     Max    Med |   req/s  failures/s
locust-master-1  | --------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
locust-master-1  | --------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
locust-master-1  |          Aggregated                                                                         0     0(0.00%) |      0       0       0      0 |    0.00        0.00
locust-master-1  |
locust-worker-1  | on_start running - testuser_filtered =  []
locust-worker-1  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-worker-2  | on_start running - testuser_filtered =  []
locust-worker-2  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-worker-1  | on_start running - testuser_filtered =  []
locust-worker-1  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-worker-2  | on_start running - testuser_filtered =  []
locust-worker-2  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-worker-2  | on_start running - testuser_filtered =  []
locust-worker-2  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-worker-2  | on_start running - testuser_filtered =  []
locust-worker-2  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-worker-2  | on_start running - testuser_filtered =  []
locust-worker-2  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-worker-1  | on_start running - testuser_filtered =  []
locust-worker-1  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-worker-1  | on_start running - testuser_filtered =  []
locust-worker-1  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-worker-1  | on_start running - testuser_filtered =  []
locust-worker-1  | on_start running - token_shared =  ['eyJhbGciOiJIUzI1NiIsIngyZDBjYjFhLThjMzctNylKjgAeTigH7fitH0w']
locust-master-1  | Type     Name                                                                          # reqs      # fails |    Avg     Min     Max    Med |   req/s  failures/s
locust-master-1  | --------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
locust-master-1  | GET      /                                                                                 10     0(0.00%) |     33      19      74     30 |    0.00        0.00
locust-master-1  | GET      /api/song?_end=15&_order=ASC&_sort=title&_start=0                                  1     0(0.00%) |     18      18      18     18 |    0.00        0.00
locust-master-1  | POST     /auth/login                                                                        4     0(0.00%) |     60      56      63     60 |    0.00        0.00
locust-master-1  | --------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
locust-master-1  |          Aggregated                                                                        15     0(0.00%) |     40      18      74     37 |    0.00        0.00
locust-master-1  |
locust-worker-1  | on_start running - testuser_filtered =  []
```

## 3.2. Setup Distributed Locust system on Azure

Chúng ta sẽ dựng môi trường trên hệ thống Azure ACI:  
https://github.com/hoangmnsd/locust-lab/blob/master/locust-az-aci-structure.jpg  

Điểm mạnh của hệ thống này là bạn có thể scale Worker lên số lượng rất nhiều, miễn là bạn có đủ tiền 😂

Đầu tiên là tạo 1 resource group: `locust-rg`

Sửa file `azure/azuredeploy.parameters.json`:  
```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "instances": {
        "value": 1
      },
      "prefix": {
        "value": "hahihohe"
      }
    }
  }
```
Nếu cần số lượng Worker là 5 thì sửa value của `instances` thành 5

Open Cloudshell to run these commands:

```sh
export resourceGroup=locust-rg

cd locust-lab/
templateFile="azure/azuredeploy.json"
paramsFile="azure/azuredeploy.parameters.json"
az deployment group create --name "locust" --resource-group $resourceGroup --template-file $templateFile --parameters $paramsFile
```

Go to Storage Account -> `File Shares` tab -> `scripts` -> upload files:
- master.conf (lấy từ `locust-lab/locust/master.conf`)  
- locustfile.py (lấy từ `locust-lab/locust/locustfile.py`)   
- create directory `html-report`  

Edit file tương ứng:
- Click vào `...` tương ứng mỗi file nếu cần.  
- File `master.conf`: 
  + sửa `expect-workers` tùy theo số lượng instances trong `azure/azuredeploy.parameters.json` hiện có  
  + sửa `host` trỏ đến navidrome webapp target mà bạn đã build  

Restart containers:  
```sh
az container restart --name hmmnsd1-master --resource-group $resourceGroup && \
az container restart --name hmmnsd1-worker-0 --resource-group $resourceGroup
```
Hoặc trong Output của ARM sau khi deploy xong sẽ có command để restart containers

Sau khi restart xong chờ Container run test xong thì report sẽ xuất ra folder html-report trong Storage account. Download file đó về mở trong Chrome là xem được.  

Có thể có 1 cách khác là deploy trên K8s, xuất report ra CSV file, đẩy vào Prometheus bằng 1 tool (LocustExporter)[https://github.com/ContainerSolutions/locust_exporter], rồi hiển thị trên Grafana.

Xong rồi thì có thể xóa Resource Group đi được rồi.  

Chú ý về giá của ACI và Storage account: https://azure.microsoft.com/en-us/pricing/details/container-instances/

# CREDIT

Rakesh's comment on: https://www.softwaretestinghelp.com/what-is-performance-testing-load-testing-stress-testing/  
https://docs.locust.io/en/1.5.2/   
https://github.com/tavishigupta/locust-blog/tree/master/deployment  
https://github.com/locustio/locust/wiki/FAQ#increase-my-request-raterps  
https://medium.com/swlh/load-testing-with-locust-3e74349f9cbf   
https://docs.locust.io/en/stable/api.html#locust.wait_time.constant_throughput  
https://github.com/locustio/locust/issues/646#issuecomment-360405844  
https://www.blazemeter.com/blog/locust-python  
https://www.blazemeter.com/blog/locust-multiple-users  
https://github.com/locustio/locust/wiki/Installation#increasing-maximum-number-of-open-files-limit  
https://stackoverflow.com/questions/71470516/how-do-i-set-a-specify-rps-in-locust-like-500-requests-per-seconds  
https://docs.aws.amazon.com/AmazonS3/latest/userguide/optimizing-performance.html  
https://docs.locust.io/en/stable/writing-a-locustfile.html#how-to-structure-your-test-code  
1 số example script của cộng đồng đóng góp: https://github.com/locustio/locust/blob/master/examples  
https://docs.locust.io/en/stable/running-distributed.html#communicating-across-nodes  
https://github.com/locustio/locust/blob/master/examples/test_data_management.py  
https://github.com/locustio/locust/blob/master/examples/custom_messages.py  
https://stackoverflow.com/questions/38088279/communication-between-multiple-docker-compose-projects  
1 bài khá hay về Locust trên k8s, sử dụng distributed mode, giải thích cơ chế share msg between workers, ví dụ về use-case cần dùng nó, có thể kết hợp locust exporter để export report csv ra prometheus rồi show trên grafana:   
https://medium.com/dkatalis/distributed-load-testing-on-k8s-using-locust-6ee4ed6c7ca