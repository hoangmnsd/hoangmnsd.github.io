---
title: "Grafana Loki and Promtail for Log Aggregation (Logging)"
date: 2023-04-14T22:49:25+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Loki,Grafana,Promtail]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Loki của GrafanaLabs được đánh giá là 1 giải pháp để tổng hợp log dễ vận hành và giúp giảm chi phí hơn nhiều khi so sánh với EFK hay ELK"
---

Khi bạn phải quản lý log trên nhiều VM khác nhau, thậm chí là quản lý cả log trong các docker container chạy trên các VM đó, thì việc theo dõi log sẽ gặp nhiều khó khăn. Chẳng lẽ cứ SSH vào từng VM rồi `tail` từng file hay sao? 

Điều này dẫn đến các giải pháp logging (log aggregation) ra đời: ELK, EFK, nay mình giới thiệu 1 trending tool là Loki của Grafana

> Loki: Loki is a open source log aggregation tool developed by Grafana labs. It is inspired by Prometheus and is designed to be cost-effective and easy to operate.

"Grafana Loki Promtail" được đánh giá là 1 giải pháp để tổng hợp log dễ vận hành và giúp giảm chi phí hơn nhiều khi so sánh với EFK hay ELK

Về cơ bản kiến trúc của Loki sẽ như này: ([tham khảo](https://grafana.com/docs/loki/latest/fundamentals/architecture/deployment-modes/))

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/loki-grafana-promtail-read-write-diagram.jpg)

Bài này thì mình sẽ demo trên 2 VM thôi, thì kiến trúc sẽ như này: (ảnh)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/loki-grafana-promtail-demo-diagram.jpg)

Việc tạo 2 vm như thế nào thì mình ko để cập ở đây vì ko liên quan, miễn là giữa 2 vm đó có thể kết nối internal network đến nhau (trong cùng 1 subnet chẳng hạn)

Clone source từ repo này về nhé: https://github.com/hoangmnsd/loki-grafana-promtail

Trong repo này mình chia thành 2 folder, mỗi folder tương ứng với 1 vm. Trong mỗi vm có cài các application để demo việc tổng hợp log.  

```sh
loki-grafana-promtail
|
├── vm1
│   ├── 1-loki
│   │   └── docker-compose.yml
│   ├── 2-grafana
│   │   ├── config
│   │   │   └── grafana-datasources.yml
│   │   └── docker-compose.yml
│   ├── 3-nginx
│   │   └── docker-compose.yml
│   ├── 4-promtail
│   │   ├── config
│   │   │   └── promtail.yml
│   │   └── docker-compose.yml
│   ├── 5-navidrome
│   │   ├── data
│   │   ├── docker-compose.yml
│   │   └── music
│   │       └── XuanThi-HaAnhTuan-6803648.mp3
│   └── 6-crontab-bashlog
│       ├── demo-java-log4j.sh
│       └── demo-json-log.sh
└── vm2
    ├── 1-nginx
    │   └── docker-compose.yml
    └── 2-promtail
        ├── config
        │   └── promtail.yml
        └── docker-compose.yml
```
# 1. Setup on vm1

## 1.1. Setup loki and grafana

Đầu tiên chúng ta sẽ setup các component cần thiết trên vm1:  

```sh
cd /loki-grafana-promtail/vm1/1-loki
docker-compose up -d

cd /loki-grafana-promtail/vm1/2-grafana
docker-compose up -d
```

```
$ docker ps
CONTAINER ID   IMAGE                   COMMAND                  CREATED          STATUS          PORTS                                       NAMES
6139415b40e5   grafana/grafana:9.3.6   "/run.sh"                4 seconds ago    Up 3 seconds    0.0.0.0:3000->3000/tcp, :::3000->3000/tcp   grafana
3955b35fcbc2   grafana/loki:2.7.4      "/usr/bin/loki -conf…"   12 seconds ago   Up 10 seconds   0.0.0.0:3100->3100/tcp, :::3100->3100/tcp   loki
```

Tại thời điểm này Loki đã hoạt động bạn có thể truy cập vào đây để xem http://vm1_ip:3000 grafana show những gì. Tuy nhiên vì chúng ta chưa setup promtail nên sẽ chưa có log gì để xem cả

Check Grafana đã kết nối được đến Datasource của Loki là OK (ảnh):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/grafana-loki-ds.jpg)

## 1.2. Setup a test application (nginx)

Cài 1 app bình thường để xuất log, app này chạy trên docker-compose. 

Đọc file `3-nginx/docker-compose.yml`, sẽ thấy mình đang gắn label cho container:

```
~~
labels:
  logging: "promtail"
  host: "vm1"
  app: "nginx"
~~
```

- label `logging=promtail` là để sau này promtail sẽ chỉ get log từ các container có label này thôi.  
- label `host=vm1` là để sau này ta có thể phân biệt được app nào được chạy trên vm nào (trường hợp có nhiều vm).   
- label `app=nginx` là để mình phân biệt sau này, các app khác nhau sẽ có cách cào log khác nhau.  

```sh
cd /loki-grafana-promtail/vm1/3-nginx
docker-compose up -d
```

## 1.3. Setup promtail

Promtail sẽ có nhiệm vụ đi cào log và gửi về cho Loki lưu trữ.  

Ở đây hãy **xóa toàn bộ** nội dung file `vm1/4-promtail/config/promtail.yml` và paste đoạn code sau vào:  

```yml
# https://grafana.com/docs/loki/latest/clients/promtail/configuration/
# https://docs.docker.com/engine/api/v1.41/#operation/ContainerList
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
- url: http://loki:3100/loki/api/v1/push

scrape_configs:
- job_name: scrape_container_nginx_log
  docker_sd_configs:
  - host: unix:///var/run/docker.sock
    refresh_interval: 5s
    # only scrape container that have label logging=promtail and app=xxx
    filters:
    - name: label
      values: ["logging=promtail", "app=nginx"]
  relabel_configs:
  - source_labels: ['__meta_docker_container_name']
    regex: '/(.*)'
    target_label: 'container'
  # you can relabel a custom label such as `host` was attached to container
  - source_labels: ['__meta_docker_container_label_host']
    target_label: 'host'
```

Giải thích: 
- Đoạn `filter` cho thấy mình chỉ lấy log từ những container có label nhất định.
- `relabel_configs` là mình sẽ lấy các label internal của container ra, chuyển nó thành 1 cái ngắn gọn hơn để hiển thị trên Grafana(ví dụ như `container`)

File `vm1/4-promtail/docker-compose.yml` bạn sẽ thấy chúng ta cần mount để promtail có thể lấy được log của Docker container:  

```
~~~
- /var/lib/docker/containers:/var/lib/docker/containers:ro
- /var/run/docker.sock:/var/run/docker.sock
~~~
```

```sh
cd /vm1/4-promtail/
docker-compose up -d
```

Check log của promtail không có lỗi gì là OK:  
```
$ docker logs promtail

Creating promtail ... done
~/vm1/4-promtail$ docker logs promtail
level=info ts=2023-04-27T10:25:14.599539383Z caller=promtail.go:123 msg="Reloading configuration file" md5sum=e25bf1833dfb7c505c646df4988f46b3
level=info ts=2023-04-27T10:25:14.608231512Z caller=server.go:323 http=[::]:9080 grpc=[::]:37915 msg="server listening on addresses"
level=info ts=2023-04-27T10:25:14.617268149Z caller=main.go:171 msg="Starting Promtail" version="(version=2.7.4, branch=HEAD, revision=98421b0c0)"
level=warn ts=2023-04-27T10:25:14.617389253Z caller=promtail.go:220 msg="enable watchConfig"
```

Vào Grafana xem lấy log như nào: (ảnh)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/loki-explore-nginx-first.jpg)

# 2. Setup on vm2

## 2.1. Setup a test application (nginx)

Cài 1 app bình thường để xuất log, app này chạy trên docker-compose. 

Đọc file `1-nginx/docker-compose.yml`, sẽ thấy mình đang gắn label cho container:

```
~~
labels:
  logging: "promtail"
  host: "vm2"
  app: "nginx"
~~
```

- label `logging=promtail` là để sau này promtail sẽ chỉ get log từ các container có label này thôi.  
- label `host=vm2` là để sau này ta có thể phân biệt được app nào được chạy trên vm nào (trường hợp có nhiều vm).  
- label `app=nginx` là để mình phân biệt sau này, các app khác nhau sẽ có cách cào log khác nhau.  

```sh
cd /loki-grafana-promtail/vm2/1-nginx
docker-compose up -d
```

## 2.2. Setup promtail

Cần sửa file `loki-grafana-promtail/vm2/2-promtail/config/promtail.yml` đoạn `LOKI_IP_ADDRESS` nhé:  

```
clients:
- url: http://LOKI_IP_ADDRESS:3100/loki/api/v1/push
```

sau khi sửa thì: 

```sh
cd /loki-grafana-promtail/vm2/2-promtail
docker-compose up -d
```

Nếu log có lỗi này nghĩa là Promtail chưa connect được đến loki:  

```
$ docker logs promtail
level=info ts=2023-04-27T10:40:30.742644313Z caller=promtail.go:123 msg="Reloading configuration file" md5sum=e25bf1833dfb7c505c646df4988f46b3
level=info ts=2023-04-27T10:40:30.743478522Z caller=server.go:323 http=[::]:9080 grpc=[::]:42771 msg="server listening on addresses"
level=info ts=2023-04-27T10:40:30.743667824Z caller=main.go:171 msg="Starting Promtail" version="(version=2.7.4, branch=HEAD, revision=98421b0c0)"
level=warn ts=2023-04-27T10:40:30.744724635Z caller=promtail.go:220 msg="enable watchConfig"
level=info ts=2023-04-27T10:40:35.744073877Z caller=target_group.go:95 msg="added Docker target" containerID=832a55cf1cc500d1fb679f859a6be737f5ec9a23fb750ecaa4202b17bde188a2
level=warn ts=2023-04-27T10:40:36.87174111Z caller=client.go:379 component=client host=loki:3100 msg="error sending batch, will retry" status=-1 error="Post \"http://loki:3100/loki/api/v1/push\": dial tcp: lookup loki on 127.0.0.11:53: server misbehaving"
```

Hãy sửa lại đúng IP của Loki và run lại:  

```sh
cd /loki-grafana-promtail/vm2/2-promtail
docker-compose down
docker-compose up -d
```

Giờ có thể chọn các host khác nhau trong filter để xem log trên từng app:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/loki-explore-nginx-filter-host.jpg)

# 3. Focus on Scrape Config

## 3.1. logfmt

Nãy giờ chúng ta đã setup xong và hiểu được làm sao để đánh label và filter log 

Giờ sẽ tập trung vào 1 chức năng chính của promtail đó là parsing, transform log

Promtail có 1 khái niệm là `pipeline_stages`, bao gồm nhiều stage để chúng ta thực hiện các thao tác với từng line log

Giờ ta sẽ tạo 1 application (tên `navidrome`) mà nó sẽ output ra log dưới 1 dạng phổ biến kiểu như này:  

```
time="2023-04-25T09:20:23Z" level=info msg="goose: no migrations to run. current version: 20211105162746\n"
```

Mục đích là ta sẽ extract các level của từng line log vào 1 label tên là `level`

khi có thể filter theo level log thì sẽ dễ nhìn và nhanh chóng hơn trong việc debug.

Chú ý file `vm1/5-navidrome/docker-compose.yml` có đoạn: 

```
    labels:
      logging: "promtail"
      host: "vm1"
      app: "navidrome"
```

```sh
cd vm1/5-navidrome
docker-compose up -d
```

```
$docker logs navidrome

 _   _             _     _
| \ | |           (_)   | |
|  \| | __ ___   ___  __| |_ __ ___  _ __ ___   ___
| . ` |/ _` \ \ / / |/ _` | '__/ _ \| '_ ` _ \ / _ \
| |\  | (_| |\ V /| | (_| | | | (_) | | | | | |  __/
\_| \_/\__,_| \_/ |_|\__,_|_|  \___/|_| |_| |_|\___|
                          Version: 0.47.5 (86fe1e3b)

time="2023-04-28T07:26:44Z" level=info msg="goose: no migrations to run. current version: 20211105162746\n"
time="2023-04-28T07:26:44Z" level=info msg="Creating Image cache" maxSize="100 MB" path=/data/cache/images
time="2023-04-28T07:26:44Z" level=info msg="Finished initializing cache" cache=Image elapsedTime=4.2ms maxSize=100MB
time="2023-04-28T07:26:44Z" level=info msg="Configuring Media Folder" name="Music Library" path=/music
time="2023-04-28T07:26:44Z" level=info msg="Starting scheduler"
time="2023-04-28T07:26:44Z" level=info msg="Scheduling periodic scan" schedule="@every 1h"
time="2023-04-28T07:26:44Z" level=info msg="Setting Session Timeout" value=24h
time="2023-04-28T07:26:44Z" level=info msg="Login rate limit set" requestLimit=5 windowLength=20s
time="2023-04-28T07:26:44Z" level=info msg="Found ffmpeg" path=/usr/bin/ffmpeg
time="2023-04-28T07:26:44Z" level=info msg="Spotify integration is not enabled: missing ID/Secret"
time="2023-04-28T07:26:44Z" level=info msg="Mounting Native API routes" path=/api
time="2023-04-28T07:26:44Z" level=error msg="Agent not available. Check configuration" name=spotify

```

Giờ sẽ update `/vm1/4-promtail/config/promtail.yml` để nó có thể cào log của app `navidrome` này, sửa phần `scrape_configs`:  

```yml
....
scrape_configs:

- job_name: scrape_container_navidrome_log
  docker_sd_configs:
  - host: unix:///var/run/docker.sock
    refresh_interval: 5s
    # only scrape container that have label logging=promtail and app=xxx
    filters:
    - name: label
      values: ["logging=promtail", "app=navidrome"]
  relabel_configs:
  - source_labels: ['__meta_docker_container_name']
    regex: '/(.*)'
    target_label: 'container'
  # you can relabel a custom label such as `host` was attached to container
  - source_labels: ['__meta_docker_container_label_host']
    target_label: 'host'
  pipeline_stages:
  # because I know the log will be in logfmt format,...Ex: time="2023-04-25T09:20:23Z" level=info msg="goose: no migrations to run. current version: 20211105162746\n"
  # so I use logfmt stage here to extract level label
  - logfmt:
      mapping:
        timestamp: time
        level:
        msg:
  - labels:
      level:
```

```sh
cd /vm1/4-promtail/
docker-compose down
docker-compose up -d
```

Nhìn ảnh này có thể thấy được là các label level `error, info, warning` đã được hiển thì trên chart. Giúp chúng ta dễ dàng hơn trong việc phán đoán tình huống bất thường. 

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/loki-navidrome-level-label.jpg)

Bây giờ chúng ta thấy log đang ở format logfmt là kiểu này:  

```
time="2023-04-28T07:26:46Z" level=info msg="Finished processing changed folder" deleted=0 dir=/music elapsed=2.5ms updated=0
```

Sẽ có 1 số người thấy log này là ổn áp rồi, nhưng 1 số người sẽ muốn log được in ra dưới dạng JSON cơ? thì Promtail cũng có thể thỏa mãn họ. 

Bằng cách sửa file `/vm1/4-promtail/config/promtail.yml` như sau, thêm vào `scrape_configs`:  

```yml
....
scrape_configs:

- job_name: scrape_container_navidrome_log
  docker_sd_configs:
  - host: unix:///var/run/docker.sock
    refresh_interval: 5s
    # only scrape container that have label logging=promtail and app=xxx
    filters:
    - name: label
      values: ["logging=promtail", "app=navidrome"]
  relabel_configs:
  - source_labels: ['__meta_docker_container_name']
    regex: '/(.*)'
    target_label: 'container'
  # you can relabel a custom label such as `host` was attached to container
  - source_labels: ['__meta_docker_container_label_host']
    target_label: 'host'
  pipeline_stages:
  # because I know the log will be in logfmt format,...Ex: time="2023-04-25T09:20:23Z" level=info msg="goose: no migrations to run. current version: 20211105162746\n"
  # so I use logfmt stage here to extract level label
  - logfmt:
      mapping:
        timestamp: time
        level:
        msg:
  - labels:
      level:
  # (OPTIONAL: below I try to re format output on Grafana to json format)
  # I create a template for output displayed on Grafana
  - template:
      source: new_key
      template: '{"level": "{{ .level }}", "msg":"{{ .msg }}"}'
  # I use the template which just created above
  - output:
      source: new_key
```

```sh
cd /vm1/4-promtail/
docker-compose down
docker-compose up -d

# Step này để clean data trong loki, tránh trường hợp duplicate log trong loki
cd /vm1/1-loki/
docker-compose down
docker-compose up -d
```

Giờ có thể thấy log của `navidrome` đã xuất hiện dưới dạng json:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/loki-navidrome-level-label-json.jpg)


## 3.2. Java log4j

Nếu bạn làm việc với JAVA application thì sẽ thấy là log ERROR của nó sẽ có dạng multiline như này:  

```
[2023-04-28 08:20:08,525 1-thread-1 ERROR           o.o.p.s.u.Log4j] task (AHAHA) task has terminated with an error
Failed to execute task: YOUR process execution has failed with exit code 1
javax.script.ScriptException: NANO process execution has failed with exit code 1
        at ASD.EEEE.PythonScriptEngine.eval(WWHAT.java:223)
        at ASD.EEE.PythonScriptEngine.eval(OKOK.java:318)
        at javax.script.DESS.eval(NONONO.java:249)
        at org.QS.AAA.scripting.Script.execute(Script.java:451)
Caused by: org.ow2.AAA.scripting.HEHEH: JAVA process execution has failed with exit code 1
javax.script.ScriptException: JAVA process execution has failed with exit code 1
        at ASD.EEE.JAVA.eval(JAVA.java:223)
        ... 3 more
[2023-04-28 08:21:02,992 Thread-1 INFO  o.c.p.v.a.Authenticate] Log4j someone is going to connect
[2023-04-28 08:21:03,995 Thread-2 INFO  o.c.p.v.a.HOHOHOHOHO] Log4j User logging
[2023-04-28 08:21:04,133 Thread-3 INFO  o.c.p.v.a.HEHEHEHE] Log4j I am trying to connect
[2023-04-28 08:21:05,819 405322-237 INFO             o.d.Mapper] Log4j Initializing a new instance mapper.
[2023-04-28 08:21:06,152 Thread-4 INFO  o.a.v.s.c.HEHEHA] Log4j Multiline here::
```

Khi lên Grafana nó sẽ kiểu này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/loki-log4j-1.jpg)

Sẽ rất khó nhìn và khó thống kê nếu các raw log cứ thế show lên dashboard. 

Vì vậy Phần này sẽ tạo 1 crontab output ra log y như 1 Java app dùng log4j. Sau đó dùng Promtail để parsing và transforming raw code đó cho dễ nhìn, dễ sử dụng.

Sử dụng file `/vm1/6-crontab-bashlog/demo-java-log4j.sh`, đặt vào folder tùy ý, tạo crontab mỗi phút run shell 1 lần ra path sau: `/opt/devops/logs/demo-java-log4j.log`

Update Promtail config `/vm1/4-promtail/config/promtail.yml` như sau, thêm vào `scrape_configs`:  

```yml
....
scrape_configs:

- job_name: scrap_log4j_log
  static_configs:
  - targets:
    - localhost
    labels:
      host: vm1
      job: demo-java-log4j
      __path__: /opt/devops/logs/demo-java-log4j.log
  pipeline_stages:
  - match:
      # process only lines that have label job=demo-java-log4j. This may not help here, but may helps in Kubernetes
      selector: '{job="demo-java-log4j"}'
      stages:
      # first: merge multiline to one line, ex: ERROR log will have multiline
      - multiline:
          # this is regex for the first line
          firstline: '^.*\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2},\d{3}'
          max_wait_time: 3s
      # next, if above line have these words, ex: line contains INFO, -> label that line with level=INFO
      - regex:
          expression: "(?P<level>(INFO|WARN|ERROR|DEBUG))(.*)"
      # then, I label that line by level value
      - labels:
          level:
```

Có thể thấy cái quan trọng là regex cần phải match được format của line đầu tiên (firstline)

```sh
cd /vm1/4-promtail/
docker-compose down
docker-compose up -d

# Step này để clean data trong loki, tránh trường hợp duplicate log trong loki
cd /vm1/1-loki/
docker-compose down
docker-compose up -d
```

Nhìn ảnh này ta có thể thấy các log ERROR được gộp vào 1 line rất dễ nhìn, đồng thời level ERROR cũng được đưa vào label, nên nhìn trên chart rất tiện

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/loki-level-label-log4j.jpg)


## 3.3. Json log

Với 1 số appication sẽ output ra log dưới dạng Json:  

```
{"timestamp":"2023-04-28T08:47:06.840+02:00","version":3,"message":"This is a debug message","logger_name":"com.github.pnowy.spring.api.ApiApplication","thread_name":"something","level":"DEBUG","level_value":40000}
{"timestamp":"2023-04-28T08:47:07.840+02:00","version":3,"message":"Warning this should be noticed","logger_name":"com.github.pnowy.spring.api.ApiApplication","thread_name":"oh","level":"WARN","level_value":40000}
{"timestamp":"2023-04-28T08:47:08.840+02:00","version":3,"message":"ERROR message goes here: Something wrong with your application","logger_name":"com.github.pnowy.spring.api.ApiApplication","thread_name":"someone","level":"ERROR","level_value":50000}
{"timestamp":"2023-04-28T08:48:01.840+02:00","version":1,"message":"Started ApiApplication in 1.431 seconds (JVM running for 6.824)","logger_name":"com.github.pnowy.spring.api.ApiApplication","thread_name":"main","level":"INFO","level_value":20000}
{"timestamp":"2023-04-28T08:48:02.840+02:00","version":2,"message":"Started ApiApplication in xxx seconds (JVM running for 6.824)","logger_name":"com.github.pnowy.spring.api.ApiApplication","thread_name":"main","level":"INFO","level_value":20000}
{"timestamp":"2023-04-28T08:48:03.840+02:00","version":3,"message":"Started ApiApplication in yyy seconds (JVM running for 6.824)","logger_name":"com.github.pnowy.spring.api.ApiApplication","thread_name":"main","level":"INFO","level_value":10000}
{"timestamp":"2023-04-28T08:48:04.840+02:00","version":3,"message":"Started ApiApplication in yyy seconds (JVM running for 6.824)","logger_name":"com.github.pnowy.spring.api.ApiApplication","thread_name":"main","level":"INFO","level_value":20000}
{"timestamp":"2023-04-28T08:48:05.840+02:00","version":3,"message":"Started ApiApplication in yyy seconds (JVM running for 6.824)","logger_name":"com.github.pnowy.spring.api.ApiApplication","thread_name":"main","level":"INFO","level_value":30000}
{"timestamp":"2023-04-28T08:48:06.840+02:00","version":3,"message":"This is a debug message","logger_name":"com.github.pnowy.spring.api.ApiApplication","thread_name":"something","level":"DEBUG","level_value":40000}
```

Tuy nhiên có thể thấy log Json dạng này lại cung cấp quá nhiều thông tin, dẫn đến hoa hết cả mắt trên Grafana. 😵

Giờ chúng ta muốn reformat lại các line log đó, thành dạng logfmt

Sử dụng file `/vm1/6-crontab-bashlog/demo-json-log.sh`, đặt vào folder tùy ý, tạo crontab mỗi phút run shell 1 lần ra path sau: `/opt/devops/logs/demo-json-log.log`

Update Promtail config `/vm1/4-promtail/config/promtail.yml` như sau, thêm phần sau vào `scrape_configs`:  

```yml
....
scrape_configs:

# # https://stackoverflow.com/a/62228397
- job_name: scrape_json_log
  static_configs:
  - targets:
    - localhost
    labels:
      host: vm1
      job: demo-json-log
      __path__: /opt/devops/logs/demo-json-log.log
  pipeline_stages:
  # because I know the log will be in json format,...
  # so I use json stage here to extract value from json to some key: level/msg/timestamp...
  - json:
      expressions:
        msg: message
        level: level
        timestamp: timestamp
        logger_name: logger_name
        thread_name: thread_name
  # then, I label that line by level value
  - labels:
      level:
  # I create a template for output displayed on Grafana
  - template:
      source: new_key
      template: 'level={{ .level }} logger={{ .logger_name }} threadName={{ .thread_name }} | {{ .msg }}'
  # I use the template which just created above
  - output:
      source: new_key
```

```sh
cd /vm1/4-promtail/
docker-compose down
docker-compose up -d

# Step này để clean data trong loki, tránh trường hợp duplicate log trong loki
cd /vm1/1-loki/
docker-compose down
docker-compose up -d
```

Nhìn hình sau có thể thấy các line đã nhìn gọn hơn, các thứ ko cần thiết sẽ ko hiển thị ra:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/loki-level-label-json.jpg)


# 4. Advanced setup 

Trong môi trường production có thể bạn sẽ cần các setup kiểu như này: 
- Loki được tách ra các node với nhiệm vụ read/write riêng biệt. ([source](https://grafana.com/docs/loki/latest/fundamentals/architecture/deployment-modes/))
- Loki sẽ store index+chunk trên các Cloud storage service như AWS S3, AWS DynamoDB, Azure storage account,...

# CREDIT

https://blog.ruanbekker.com/blog/2022/11/18/logging-with-docker-promtail-and-grafana-loki/  
https://rtfm.co.ua/en/grafana-labs-loki-logs-collector-and-monitoring-system/  
https://rtfm.co.ua/en/grafana-labs-loki-distributed-system-labels-and-filters/  
https://rtfm.co.ua/en/grafana-labs-loki-using-aws-s3-as-a-data-storage-and-aws-dynamodb-for-indexes/  
https://www.baeldung.com/ops/grafana-loki  

So sánh Loki vs ElasticSearch: https://signoz.io/blog/loki-vs-elasticsearch/

Docs chính thức:  
https://github.com/grafana/loki  
https://grafana.com/docs/loki/latest/clients/promtail/logrotation/  
https://grafana.com/docs/loki/latest/installation/docker/  

Microservice deployment modes:  
https://grafana.com/docs/loki/latest/fundamentals/architecture/deployment-modes/  

Advanced:   
Setup Loki sử dụng AWS DynamoDB và AWS S3 để lưu index và chunk [here](https://grafana.com/docs/loki/latest/operations/storage/)

