---
title: "Ship Log to Grafana Loki using Promtail"
date: 2025-01-02T00:07:17+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Logging,Grafana,Loki,Promtail]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Mình có nhu cầu query log trên Grafana để giảm chi phí..."
---


## Story 

Câu chuyện là mình có 1 app chạy trên AWS Lambda. Hàng ngày throw log ra AWS Cloudwatch Log.

Mình có nhu cầu query log để marketing, thế nên thường xuyên dùng chức năng Log Insight của Cloudwatch.

Tuy nhiên thì giá của Log Insight khá là căng. Họ sẽ free 5GB query đầu tiên, sau đó [tính phí](https://aws.amazon.com/cloudwatch/pricing/): 

> First 5GB per month of log data scanned by CloudWatch Logs Insights queries is free. Query (Logs Insights) $0.005 per GB of data scanned

Vậy nên mình cần có giải pháp để có thể query log 1 cách thoải mái.

Solution: Hàng tuần hoặc hàng tháng sẽ Export log từ Cloudwatch log ra S3. Download từ S3 về local. Ship log từ local lên Grafana Loki bằng Promtail. Còn real-time thì query trên cloudwatch sẽ chỉ query log trong vòng 1 tuần / vài ngày thôi. Đồng thời sửa app để giảm size của log (như vậy sẽ giảm được size scanned)

giải pháp này có nhược điểm là ko real-time được vì trung bình vài tuần (hoặc 1 tháng) mình mới lấy log từ Cloudwatch về local.

Hiện cũng chưa làm tự động việc lấy log về local (toàn làm bằng tay) nên cũng ko linh hoạt lắm.

Việc lấy log từ Cloud về local thì đơn giản, nhưng hiển thị nó lên Grafana để query theo timestamp thì mất vài ngày mới giải quyết được.

Chủ yếu là cần phải hiểu và tương tác tốt với Promtail configuration.

## Steps

Export log from Cloudwatch Log to S3 bucket:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/loki-grafana-promtail-export-cw-log-to-s3.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/loki-grafana-promtail-export-cw-log-to-s3-ok.jpg)

Dùng aws cli, download log từ s3 về local folder `result`:

```sh
aws s3 cp s3://S3_BUCKET_NAME/cloudwatchlog-20241101-to-20241231/ ./result/ --recursive
```

zip `result` sub-folder:

```sh
$ cd ./result/

$ ll
total 4480
drwxr-xr-x 1 hoangmnsd hoangmnsd    4096 Jan  4 14:09 ./
drwxr-xr-x 1 hoangmnsd hoangmnsd    4096 Jan  4 13:58 ../
-rw-r--r-- 1 hoangmnsd hoangmnsd      27 Jan  4 13:51 aws-logs-write-test
drwxr-xr-x 1 hoangmnsd hoangmnsd    4096 Jan  4 13:57 d36fc1f0-a466-47fe-b375-d70ee97ff05d/

$ zip   -r   cloudwatchlog-20241101-to-20241231.zip      d36fc1f0-a466-47fe-b375-d70ee97ff05d/
```

Upload file `.zip` to Loki Promtail Server. Unzip it under:  
`/opt/devops/grafana-visualize-cloudwatchlog/cloudwatchlog/cloudwatchlog-20241101-to-20241231/`

Run `unzip_then_delete.sh` to: unzip `.gz` files and delete `.gz` files:

```sh
bash unzip_then_delete.sh ./cloudwatchlog-20241101-to-20241231/
```

Now, all text file is unzipped.

Mình sẽ dựng Grafana Loki Promtail bằng `docker-compose.yml`. Mount volume chứa log Cloudwatch vào promtail để nó scrape:

Đây là sample directory tree:

```s
grafana-visualize-cloudwatchlog$ tree .
.
├── cloudwatchlog
│   ├── cloudwatchlog-to-20241031
│   │   └── 6058708e-f3f5-44d8-ab90-529fff5eafc7
│   │       └── 2024-11-31-[$LATEST]fbc4eeb6878043f48fabd74927eab187
│   │           ├── 000000-A
│   │           ├── 000000-B
│   │           └── 000000-C
│   ├── cloudwatchlog-to-20241031.zip
│   └── unzip_then_delete.sh
├── docker-compose.yml
├── grafana
│   └── config
│       └── grafana-datasources.yml
├── loki
│   └── config
│       └── loki-config.yaml
├── promtail
│   └── config
│       └── promtail.yml
├── promtail-linux-arm64
├── promtail-linux-arm64.zip
└── test.log
```

File `docker-compose.yml`:

```yml
version: '3.8'

services:
  loki:
    image: grafana/loki:3.2.1
    container_name: loki
    ports:
    - 3100:3100
    command: -config.file=/mnt/config/loki-config.yaml
    volumes:
    - ./loki/config/loki-config.yaml:/mnt/config/loki-config.yaml
    networks:
    - logging-nw

  grafana:
    image: grafana/grafana:11.4.0
    container_name: grafana
    ports:
    - 3000:3000
    volumes:
    - ./grafana/config/grafana-datasources.yml:/etc/grafana/provisioning/datasources/datasources.yaml
    environment:
    - GF_AUTH_ANONYMOUS_ENABLED=true
    - GF_AUTH_ANONYMOUS_ORG_ROLE=Admin
    - GF_AUTH_DISABLE_LOGIN_FORM=true
    networks:
    - logging-nw

  promtail:
    image:  grafana/promtail:3.2.1
    container_name: promtail
    volumes:
    - ./promtail/config/promtail.yml:/etc/promtail/config.yml
    - /var/lib/docker/containers:/var/lib/docker/containers:ro
    - /var/run/docker.sock:/var/run/docker.sock
    - /opt/devops/grafana-visualize-cloudwatchlog/cloudwatchlog/:/opt/devops/grafana-visualize-cloudwatchlog/cloudwatchlog/
    command: -config.file=/etc/promtail/config.yml
    networks:
    - logging-nw

networks:
  logging-nw:
    name: logging-nw
    driver: bridge
```

File `grafana-datasources.yml`:

```yml
apiVersion: 1

datasources:
- name: Loki
  type: loki
  access: proxy
  url: http://loki:3100
  version: 1
  editable: false
  isDefault: true
```

File `loki-config.yaml`:

```yml
limits_config:
  max_streams_per_user: 1000000
  reject_old_samples: false
  reject_old_samples_max_age: 52w
  max_query_lookback: 52w
  max_query_length: 52w
  max_streams_per_user: 0
  max_global_streams_per_user: 0

auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  instance_addr: 127.0.0.1
  path_prefix: /tmp/loki
  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks
      rules_directory: /tmp/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 100

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://localhost:9093

ingester:
  chunk_idle_period: 4320h
  max_chunk_age: 4320h
```

File `promtail.yml`:

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

- job_name: scrap_sayan_cw_log
  static_configs:
  - targets:
    - localhost
    labels:
      job: scrap_sayan_cw_log
      __path__: /opt/devops/grafana-visualize-cloudwatchlog/cloudwatchlog/cloudwatchlog-to-20241031/6058708e-f3f5-44d8-ab90-529fff5eafc7/*/*

  pipeline_stages:
    - match:
        selector: '{job="scrap_sayan_cw_log"}'
        stages:
        - multiline:
            firstline: '^.*\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}'
            max_wait_time: 3s
        # - regex: # OPTIONAL: CHO VÀO ĐỂ TEST
        #     expression: "(?P<level>(INFO|WARN|ERROR|DEBUG|START))(.*)"
        # - labels: # OPTIONAL: CHO VÀO ĐỂ TEST
        #     level:
        - regex:
            expression: "^(?s)(?P<extractedtimestamp>\\S+?) "
        # - labels:# OPTIONAL: CHO VÀO ĐỂ TEST
        #     extractedtimestamp:
        - template:
            source: extractedtimestamp
            template: '{{ Replace .Value "Z" "" 1 }}000000+00:00'
        - timestamp:
            source: extractedtimestamp
            format: RFC3339Nano
```

Trong quá trình làm thì file mình phải sửa đi sửa lại nhiều nhất là `promtail.yml`. Vì troubleshoot Pipeline stages rất khó khăn.

Đọc tài liệu [troubleshooting](https://grafana.com/docs/loki/latest/send-data/promtail/troubleshooting/)

Để dễ dàng troubleshoot thì bạn nên dùng tool promtail binary [download ở đây](https://github.com/grafana/loki/releases/) về. 

Sau đó tạo 1 file `test.log` đơn giản 1 dòng để test dry-run:

File `test.log` mang format của Cloudwatch log, timestamp sẽ có dạng `2024-10-31T13:43:59.810Z`:
```
2024-10-31T13:43:59.810Z 2024-10-31 13:43:59,810 INFO TMP_ALLOWED_CHAT_ID_DATA_CORRECT is: /tmp/allowed_6842370411.json
```

Hiện tại là năm 2025-01-02, nếu như mình ko có stage `timestamp` trong `promtail.yml` thì khi lên Grafana sẽ chỉ có thể query theo timestamp thời điểm file `test.log` được Promtail gửi cho Loki (tức là đâu đó 2025-01-02).

Nhưng nếu scrape đúng cách, timestamp sẽ được extract từ log line, rồi format lại, rồi gửi cho Loki để visuallize đúng trên Grafana.

Run dry-run. Cần chú ý tất cả các `stage` đều phải có kết quả như ý:

```sh
/grafana-visualize-cloudwatchlog$ cat test.log | ./promtail-linux-arm64 --stdin --dry-run --inspect -config.file ./promtail/config/promtail.yml
Clients configured:
----------------------
url: http://loki:3100/loki/api/v1/push
batchwait: 1s
batchsize: 1048576
follow_redirects: true
enable_http2: true
backoff_config:
  min_period: 500ms
  max_period: 5m0s
  max_retries: 10
timeout: 10s
tenant_id: ""
drop_rate_limited_batches: false

[inspect: regex stage]:
{stages.Entry}.Extracted["level"]:
        +: INFO
[inspect: labels stage]:
{stages.Entry}.Entry.Labels:
        -: {__path__="/opt/devops/grafana-visualize-cloudwatchlog/cloudwatchlog/cloudwatchlog-to-20241031/6058708e-f3f5-44d8-ab90-529fff5eafc7/*/*", job="scrap_sayan_cw_log"}
        +: {__path__="/opt/devops/grafana-visualize-cloudwatchlog/cloudwatchlog/cloudwatchlog-to-20241031/6058708e-f3f5-44d8-ab90-529fff5eafc7/*/*", job="scrap_sayan_cw_log", level="INFO"}
[inspect: regex stage]:
{stages.Entry}.Extracted["extractedtimestamp"]:
        +: 2024-10-31T13:43:59.810Z
[inspect: labels stage]:
{stages.Entry}.Entry.Labels:
        -: {__path__="/opt/devops/grafana-visualize-cloudwatchlog/cloudwatchlog/cloudwatchlog-to-20241031/6058708e-f3f5-44d8-ab90-529fff5eafc7/*/*", job="scrap_sayan_cw_log", level="INFO"}
        +: {__path__="/opt/devops/grafana-visualize-cloudwatchlog/cloudwatchlog/cloudwatchlog-to-20241031/6058708e-f3f5-44d8-ab90-529fff5eafc7/*/*", extractedtimestamp="2024-10-31T13:43:59.810Z", job="scrap_sayan_cw_log", level="INFO"}
[inspect: template stage]:
{stages.Entry}.Extracted["extractedtimestamp"].(string):
        -: 2024-10-31T13:43:59.810Z
        +: 2024-10-31T13:43:59.810000000+00:00
[inspect: timestamp stage]:
{stages.Entry}.Entry.Entry.Timestamp:
        -: 2025-01-03 16:23:31.34711029 +0000 UTC
        +: 2024-10-31 13:43:59.81 +0000 UTC
2024-10-31T13:43:59.81+0000     {__path__="/opt/devops/grafana-visualize-cloudwatchlog/cloudwatchlog/cloudwatchlog-to-20241031/6058708e-f3f5-44d8-ab90-529fff5eafc7/*/*", extractedtimestamp="2024-10-31T13:43:59.810Z", job="scrap_sayan_cw_log", level="INFO"}   2024-10-31T13:43:59.810Z 2024-10-31 13:43:59,810 INFO TMP_ALLOWED_CHAT_ID_DATA_CORRECT is: /tmp/allowed_6842370411.json
```

Khi query trên Grafana dashboard sẽ được như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/grafana-loki-promtail-query.jpg)

Bạn sẽ có thể query theo time range của timestamp có trong log file chứ ko phải timestamp của Grafana.

## Troubleshoot

### Promtail dry-run trong container không works

Không nên dùng tool `promtail` trong container để chạy dry-run vì có thể bị lỗi Port 9080 `9080: bind: address already in use`.

```s
# promtail --stdin --dry-run --inspect -config.file /etc/promtail/config.yml
Clients configured:
----------------------
url: http://loki:3100/loki/api/v1/push
batchwait: 1s
batchsize: 1048576
follow_redirects: true
enable_http2: true
backoff_config:
  min_period: 500ms
  max_period: 5m0s
  max_retries: 10
timeout: 10s
tenant_id: ""
drop_rate_limited_batches: false

level=info ts=2025-01-03T16:27:38.185284458Z caller=promtail.go:133 msg="Reloading configuration file" md5sum=5f3cb293a471701dfe99953a442b1472
level=error ts=2025-01-03T16:27:38.190399294Z caller=main.go:169 msg="error creating promtail" error="error creating loki server: listen tcp :9080: bind: address already in use"
```

Solution là download promtail binary về chạy dry-run


### Query ngay sau khi docker-compose up ko có data

Có 1 vấn đề là sau khi `docker-compose up -d` thì mất rất lâu mới query được data. Cảm giác như loki load data từ promtail CHẬM và mất thời gian. Nó cứ trả về như này `No logs volume available`:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/grafana-loki-promtail-query-not-ok.jpg)

Query Loki bằng HTTP request cũng ko có data:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/loki-grafana-promtail-query-http-not-found.jpg)

Mãi nửa tiếng sau mới search đc data. ko biết vì lý do gì khiến Loki chậm trả về data? 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/loki-grafana-promtail-query-http-found-data.jpg)

Solution là đọc link này: https://grafana.com/docs/loki/latest/configure/#ingester

Sửa config của loki:
```yml
ingester:
  chunk_idle_period: 4320h
  max_chunk_age: 4320h
```
-> thì sẽ search được data ngay lập tức

Nếu đọc cái này: https://grafana.com/docs/loki/latest/configure/#querier. Sửa query_ingesters_within = 0 thì vẫn ko fix được issue nhé.

### Promtail 429 Maximum active stream limit exceeded

Khi load hàng ngàn file log vào Promtail khả năng sẽ bị dính lỗi:

```s
$ docker logs -f promtail

level=warn ts=2021-03-05T09:03:14.685601189Z caller=client.go:322 component=client host=MyMonitoringDomain:3100 msg="error sending batch, will retry" status=429 error="server returned HTTP status 429 Too Many Requests (429): Maximum active stream limit exceeded, reduce the number of active streams (reduce labels or reduce label values), or contact your Loki administrator to see if the limit can be increased
```

Lỗi này là do có quá nhiều labels được tạo ra. 

Cách 1 là giảm lượng labels xuống:

Cần sửa file `promtail.yml`, mình sẽ bỏ phần đánh label `extractedtimestamp` đi:

```yml
...

  pipeline_stages:
    - match:
        selector: '{job="scrap_sayan_cw_log"}'
        stages:
        - multiline:
            firstline: '^.*\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}'
            max_wait_time: 3s
        - regex:
            expression: "^(?s)(?P<extractedtimestamp>\\S+?) "
        # - labels:
        #     extractedtimestamp:
        - template:
            source: extractedtimestamp
            template: '{{ Replace .Value "Z" "" 1 }}000000+00:00' # because I want to convert it to RFC3339Nano format. From 2024-10-31T13:43:59.810Z to 2024-10-31T13:43:59.810000000+00:00
        - timestamp:
            source: extractedtimestamp
            format: RFC3339Nano
```
Thì sẽ ko còn lỗi nữa. 

Cách 2 là disable limit của active stream, nhưng nếu chỉ làm cách này thì sẽ ảnh hưởng đến performance của Loki (Nên kết hợp với giảm label cách 1), Sửa file `loki-config.yaml`:

```yml
limits_config:
  max_streams_per_user: 0
  max_global_streams_per_user: 0
```

nguồn: https://grafana.com/docs/loki/v3.2.x/configure/#limits_config

## REFERENCES

https://grafana.com/docs/loki/latest/send-data/promtail/stages/timestamp/

https://community.grafana.com/t/parsing-timestamp-from-logline-with-promtail-and-sending-to-loki/85381/4

https://grafana.com/docs/loki/latest/send-data/promtail/troubleshooting/

https://grafana.com/docs/loki/latest/setup/install/local/#install-using-apt-or-rpm-package-manager