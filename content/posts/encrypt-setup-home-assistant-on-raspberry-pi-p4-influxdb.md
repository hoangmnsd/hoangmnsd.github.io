---
title: "Setup Home Assistant on Raspberry Pi (Part 4) - InfluxDB"
date: 2022-05-18T23:04:36+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [HomeAssistant,InfluxDB]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Mặc định Home Assistant chỉ lưu Logbook for 10 days, phải làm gì nếu bạn muốn kéo dài retention đó?"
---

Chú ý: 

- Cách làm này recommend dùng để lưu short term data trong Postgresql, Logbook của bạn sẽ hiển thị data tối đa dựa trên config `recorder.purge_keep_days` trong file `hass/config/configuration.yaml`.   
- Để lưu long term data thì recommend dùng InfluxDB để lưu, và dùng Grafana (tự dựng Dashboard) để visualize.  


# 1. Setup Postgresql for short term data

Làm theo bài [này](https://github.com/Burningstone91/smart-home-setup#history-databases):  

Set up Postgresql, sửa `docker-compose.yml` file:  

```yml
homeassistant-db:
    container_name: homeassistant-db
    environment:
      POSTGRES_DB: "<YOUR_DB_NAME>"
      POSTGRES_PASSWORD: "<YOUR_PASSWORD>"
      POSTGRES_USER: "<YOUR_DB_USER>"
    image: "postgres:12.15-alpine3.18"
    ports:
      - "5432:5432"
    restart: always
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /opt/homeassistant-db:/var/lib/postgresql/data
```

Sau khi `docker-compose up -d`, sửa file `hass/config/configuration.yaml`:  

```yml
# Nếu file config chưa có dòng này thì add vào
history:

# chỉ những entities sau được HASS record lại trong db postgresql
recorder:
  db_url: postgresql://<YOUR_DB_USER>:<YOUR_PASSWORD>@127.0.0.1/<YOUR_DB_NAME>
  purge_keep_days: 10
  include:
    entities:
      - automation.bedroom_air_purifier_aqi_over_80_warning_2
      - automation.bedroom_air_purifier_filter_lifetime_warning_2
      - automation.change_light_bulb_color_when_front_door_open_4
      - automation.check_if_any_device_sensor_is_on_then_alert
    entity_globs:
      - alert.*
    domains:
      - person
```

Để list ALL entities dùng để lọc include thì mình dùng cách này [Template Editor Method (easiest, try this first)](https://community.home-assistant.io/t/how-to-reduce-your-database-size-and-extend-the-life-of-your-sd-card/205299#template-editor-method-easiest-try-this-first-1)


# 2. Setup InfluxDB for long term data

## 2.2. Setup influxDB v1

Sửa `docker-compose.yml` file:  

```yml
  influxdb:
    container_name: influxdb
    environment:
      - INFLUXDB_DB=<YOUR_DB_NAME>
      - INFLUXDB_ADMIN_USER=<YOUR_ADMIN_USERNAME>
      - INFLUXDB_ADMIN_PASSWORD=<YOUR_PASSWORD>
      - INFLUXDB_REPORTING_DISABLED=true # https://docs.influxdata.com/influxdb/v1.8/administration/config/#reporting-disabled-false
    image: influxdb:1.8.10
    ports:
      - "8086:8086"
    restart: unless-stopped
    volumes:
      - /opt/influxdb/data:/var/lib/influxdb:rw
      - /etc/localtime:/etc/localtime:ro
```
Tìm hiểu thêm về các biến môi trường ở đây: https://docs.influxdata.com/influxdb/v1.8/administration/config/#reporting-disabled-false

Muốn check retention policy của InfluxDB:  

```
$ docker exec -it <INFLUXDB_CONTAINER_NAME> influx
show retention policies on <YOUR_DB_NAME>
name    duration shardGroupDuration replicaN default
----    -------- ------------------ -------- -------
autogen 0s       168h0m0s           1        true
```

duration 0s nghĩa là đang ko delete data

Giờ muốn sửa duration thành 10d thì:

```
$ docker exec -it influxdb influx
> ALTER RETENTION POLICY "autogen" ON "<YOUR_DB_NAME>" DURATION 10d
> show retention policies on <YOUR_DB_NAME>
name    duration shardGroupDuration replicaN default
----    -------- ------------------ -------- -------
autogen 240h0m0s 168h0m0s           1        true
```

đó, 240h nghĩa là 10d rồi.

Sửa file `hass/config/configuration.yaml`: 

```yml
influxdb:
  host: localhost
  port: 8086
  database: <YOUR_DB_NAME>
  username: <YOUR_ADMIN_USERNAME>
  password: <YOUR_PASSWORD>
  default_measurement: state
  include:
    entities:
      - binary_sensor.front_door_sensor_contact
```

Do có nhiều người kêu sau 1 thời gian thấy Size của InfluxDB to quá, thế nên ng ta khuyên chỉ nên `include` những sensor mà bạn muốn lưu trữ thôi. 

Sau đó add data source trong Grafana: Setting -> Data sources:  
- Query Language: InfluxQL
- HTTP url: http://influxdb:8086 (influxdb là container name trong docker-compose file)
- Auth: disable all
- InfluxDB Details: Database, Username/password, HTTP GET.  
- Save & test 

Test Grafana+InfluxDB, thấy data là OK:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/grafana-example-explorer-influxdb.jpg)

Bây giờ phải tự ngồi mà tạo các Grafana Dashboard cho mình thôi.


## 2.2. Setup influxDB v2 (not recommended)

Không recommend cách này lắm, vì ít tài liệu tham khảo. Dùng Flux Query cũng là 1 ngôn ngữ mới, khó khăn nếu bạn ko thừa thời gian

Sửa `docker-compose.yml` file:  

```yml
influxdb2:
    container_name: influxdb2
    environment:
      - INFLUXDB_DB=<YOUR_DB_NAME> # tự nghĩ ra rồi điền vào đây
      - DOCKER_INFLUXDB_INIT_MODE=setup # phải có cái này thì influxdb mới hiểu các  environment variable bên dưới
      - DOCKER_INFLUXDB_INIT_USERNAME=<YOUR_ADMIN_USERNAME> # tự nghĩ ra rồi điền vào đây
      - DOCKER_INFLUXDB_INIT_PASSWORD=<YOUR_PASSWORD> # tự nghĩ ra rồi điền vào đây
      - DOCKER_INFLUXDB_INIT_ORG=influxdb2-hass-org
      - DOCKER_INFLUXDB_INIT_BUCKET=influxdb2-hass-bucket
      - DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=<DB_TOKEN> # tự nghĩ ra rồi điền vào đây
      - DOCKER_INFLUXDB_INIT_RETENTION=365d # nghĩa là sau sẽ chỉ giữ data trong XXX days
    image: influxdb:2.7.1
    ports:
      - "8086:8086"
    restart: unless-stopped
    volumes:
      - /opt/influxdb2/data:/var/lib/influxdb2:rw
      - /opt/influxdb2/config:/etc/influxdb2
      - /etc/localtime:/etc/localtime:ro
```

Sau đó login vào http://localhost:8086/ để login vào InfluxDB bằng `<YOUR_ADMIN_USERNAME>` và `<YOUR_PASSWORD>`

Nhìn trên URL sẽ thấy dạng `http://localhost:8086/orgs/8d345eaxxxx1234e/load-data/sources` -> copy được `<ORG_ID>` là `8d345eaxxxx1234e`

Sửa file `hass/config/configuration.yaml`: 

```yml
# remember you should create influxdb container first, then put connection info here
influxdb:
  api_version: 2
  ssl: false
  host: localhost
  port: 8086
  token: <DB_TOKEN> # Đưa cái DOCKER_INFLUXDB_INIT_ADMIN_TOKEN trong file docker-compose.yml vào đây 
  organization: <ORG_ID> 
  bucket: influxdb2-hass-bucket # Cần phải đúng tên bucket DOCKER_INFLUXDB_INIT_BUCKET trong file docker-compose.yml 
  exclude:
    entities:
      - automation.bedroom_air_purifier_mode_change_2
      - automation.bedroom_air_purifier_set_fan_mode_on_time
      - fan.air_purifier
      - fan.mi_air_purifier_33h
```

Rồi restart HASS là xong. Check log ko có lỗi connect đến InfluxDB là OK

Vào Grafana add datasource: 

- Under Query Language, select Flux.  
- URL: Your InfluxDB URL.(http://influxdb2:8086)  
- Access: Server (default)  
- Auth: tắt hết các method, bao gồm cả Basic auth  
- Custom HTTP Headers: Điền Header: Authorization, Value: `Token <DB_TOKEN>`. Chú ý có space giữa Token và DB_TOKEN  
- Organization Name: your organization name  
- Token: your InfluxDB token  
- Default bucket: your InfluxDB bucket  
- HTTP Method: Select GET or POST  

Save & test, make sure là get buckets thành công:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/grafana-datasource-influxdb.jpg)

Vào Explorer của Grafana, query thử xem OK chưa:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/grafana-datasource-influxdb-explorer.jpg)

Nên vào Grafana Setting -> Plugins -> Install 1 plugin tên là Discrete của Natel, Plugin này sẽ giúp bạn show History của Sensor gần giống như trên HomeAssistant

Trên Grafana, querry sensor từ influxDB thì mình hay dùng querry này:  

```sh
SELECT max("value") FROM "state" WHERE ("entity_id" = 'motion_sensor_01_occupancy') AND $timeFilter GROUP BY time($__interval) fill(0)
```

Cùng 1 câu querry đó, trong InfluxDB CLi thì xóa cái $timeFiller đi:  

```sh
SELECT max("value") FROM "state" WHERE ("entity_id" = 'motion_sensor_01_occupancy') GROUP BY time($__interval) fill(0)
```

Như vậy là có thể lấy dược state on/off của Sensor giống như HASS rồi verify xem Grafana hiển thị có đúng ko.  

## 2.3 Troubleshoot

### Với InfluxDB v1: 

Đôi khi mình thấy data show trên Grafana ko chuẩn lắm, ví dụ như front door tại sao có thể mở tận 3 tiếng liền khi ko có ai ở nhà. Dẫn đến chúng ta cần debug: chọc thằng vào DB của InfluxDB để query data:

```

$ docker exec -it hass-influxdb influx

Connected to http://localhost:8086 version 1.8.10
InfluxDB shell version: 1.8.10
> use homeassistant

> SELECT state FROM "state" WHERE ("entity_id" = 'front_door_sensor_contact')
name: state
time                state
----                -----
1691680116384444000 off
1691683667429836000 off
1691683668948214000 off
1691683987598154000 off
1691683987607464000 off
1691704750411597000 off
1691704750423319000 off
1691712860715323000 off
1691712860717387000 on
1691712865313523000 on
1691712865314533000 off
1691716302588351000 off
1691716302590925000 on

# Để data dễ nhìn Timestamp hơn:

> precision rfc3339

> SELECT state FROM "state" WHERE ("entity_id" = 'front_door_sensor_contact')
name: state
time                        state
----                        -----
2023-08-10T15:08:36.384444Z off
2023-08-10T16:07:47.429836Z off
2023-08-10T16:07:48.948214Z off
2023-08-10T16:13:07.598154Z off
2023-08-10T16:13:07.607464Z off
2023-08-10T21:59:10.411597Z off
2023-08-10T21:59:10.423319Z off
2023-08-11T00:14:20.715323Z off

```



### Với InfluxDB v2: 

Chú ý lần đầu tiên run `docker-compose up -d` thì ko vấn đề gì, nhưng nếu sửa environment rồi run lại thì sẽ thấy ko apply thay đổi vì influxdb sẽ check trong folder `/opt/influxdb2/data` mà còn data (cụ thể là file bolt) thì sẽ ko setup lại (nó nghĩ là đã dc initial setup rồi)

Check log Nếu bị lỗi này:  

```
docker logs influxdb2
{
  "bolt-path": "/var/lib/influxdb2/influxd.bolt",
  "engine-path": "/var/lib/influxdb2/engine",
  "http-bind-address": ":9999",
  "nats-port": 4222
}
2023-08-09T13:57:16.640601764Z  info    booting influxd server in the background        {"system": "docker"}
ts=2023-08-09T13:57:16.941838Z lvl=info msg="Welcome to InfluxDB" log_id=0jYeFA3G000 version=v2.7.1 commit=407fa622e9 build_date=2023-04-28T13:24:42Z log_level=info
ts=2023-08-09T13:57:16.941928Z lvl=warn msg="nats-port argument is deprecated and unused" log_id=0jYeFA3G000
ts=2023-08-09T13:57:16.963350Z lvl=info msg="Resources opened" log_id=0jYeFA3G000 service=bolt path=/var/lib/influxdb2/influxd.bolt
ts=2023-08-09T13:57:16.963831Z lvl=info msg="Resources opened" log_id=0jYeFA3G000 service=sqlite path=/var/lib/influxdb2/influxd.sqlite
ts=2023-08-09T13:57:16.966581Z lvl=info msg="Bringing up metadata migrations" log_id=0jYeFA3G000 service="KV migrations" migration_count=20
ts=2023-08-09T13:57:17.324603Z lvl=info msg="Bringing up metadata migrations" log_id=0jYeFA3G000 service="SQL migrations" migration_count=8
ts=2023-08-09T13:57:17.594501Z lvl=info msg="Using data dir" log_id=0jYeFA3G000 service=storage-engine service=store path=/var/lib/influxdb2/engine/data
ts=2023-08-09T13:57:17.594791Z lvl=info msg="Compaction settings" log_id=0jYeFA3G000 service=storage-engine service=store max_concurrent_compactions=2 throughput_bytes__per_second_burst=50331648
ts=2023-08-09T13:57:17.594835Z lvl=info msg="Open store (start)" log_id=0jYeFA3G000 service=storage-engine service=store op_name=tsdb_open op_event=start
ts=2023-08-09T13:57:17.595001Z lvl=info msg="Open store (end)" log_id=0jYeFA3G000 service=storage-engine service=store op_name=tsdb_open op_event=end op_elapsed=0.171ms
ts=2023-08-09T13:57:17.595107Z lvl=info msg="Starting retention policy enforcement service" log_id=0jYeFA3G000 service=retention check_interval=30m
ts=2023-08-09T13:57:17.595150Z lvl=info msg="Starting precreation service" log_id=0jYeFA3G000 service=shard-precreation check_interval=10m advance_period=30m
ts=2023-08-09T13:57:17.597155Z lvl=info msg="Starting query controller" log_id=0jYeFA3G000 service=storage-reads concurrency_quota=1024 initial_memory_bytes_quota_per_qs_quota_per_query=9223372036854775807 max_memory_bytes=0 queue_size=1024
ts=2023-08-09T13:57:17.604682Z lvl=info msg="Configuring InfluxQL statement executor (zeros indicate unlimited)." log_id=0jYeFA3G000 max_select_point=0 max_select_serie
ts=2023-08-09T13:57:17.619106Z lvl=info msg=Starting log_id=0jYeFA3G000 service=telemetry interval=8h
ts=2023-08-09T13:57:17.621965Z lvl=info msg=Listening log_id=0jYeFA3G000 service=tcp-listener transport=http addr=:9999 port=9999
2023-08-09T13:57:17.648759810Z  info    pinging influxd...      {"system": "docker", "ping_attempt": "0"}
2023-08-09T13:57:17.671015903Z  info    got response from influxd, proceeding   {"system": "docker", "total_pings": "1"}
Error: config name "default" already exists
2023-08-09T13:57:17.695209237Z  warn    cleaning bolt and engine files to prevent conflicts on retry    {"system": "docker", "bolt_path": "/var/lib/influxdb2/influxd.bodb2/engine"}
```

Lý do là `Error: config name "default" already exists`, cần xóa hết data đi:

```sh
cd /opt/influxdb2
rm -rf data config
```

Check log như này là OK:  

```
ts=2023-08-09T14:18:32.861007Z lvl=info msg="Configuring InfluxQL statement executor (zeros indicate unlimited)." log_id=0jYfT20W000 max_select_point=0 max_select_series=0 max_select_buckets=0
ts=2023-08-09T14:18:32.879062Z lvl=info msg=Starting log_id=0jYfT20W000 service=telemetry interval=8h
ts=2023-08-09T14:18:32.880396Z lvl=info msg=Listening log_id=0jYfT20W000 service=tcp-listener transport=http addr=:8086 port=8086
```

check size của các containers:

```sh
$ docker ps -s
CONTAINER ID   IMAGE                                            COMMAND                  CREATED          STATUS          PORTS                                                                                  NAMES                      SIZE
73f66b17a9e4   postgres:12.15-alpine3.18                        "docker-entrypoint.s…"   11 minutes ago   Up 11 minutes   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp                                              homeassistant-db           63B (virtual 236MB)
a0710a5cdfbb   grafana/grafana:8.5.5                            "/run.sh"                23 hours ago     Up 23 hours     0.0.0.0:3000->3000/tcp, :::3000->3000/tcp                                              grafana                    60.6kB (virtual 270MB)
5b1a38f94a4b   prom/prometheus:v2.36.0                          "/bin/prometheus --c…"   23 hours ago     Up 23 hours     0.0.0.0:9090->9090/tcp, :::9090->9090/tcp                                              prometheus                 0B (virtual 207MB)
0fa70f4fc8c0   prom/node-exporter:v1.3.1                        "/bin/node_exporter"     23 hours ago     Up 23 hours     9100/tcp                                                                               monitoring_node_exporter   0B (virtual 20.6MB)
f0af7434611c   lscr.io/linuxserver/wireguard:1.0.20210914       "/init"                  27 hours ago     Up 23 hours     0.0.0.0:51820->51820/udp, :::51820->51820/udp                                          wireguard                  22.9kB (virtual 168MB)
4194afb00cbc   lscr.io/linuxserver/swag:1.30.0                  "/init"                  31 hours ago     Up 23 hours     80/tcp, 0.0.0.0:443->443/tcp, :::443->443/tcp                                          swag                       12.5MB (virtual 407MB)
9d657cd96e8c   koenkk/zigbee2mqtt:1.25.0                        "docker-entrypoint.s…"   31 hours ago     Up 23 hours     0.0.0.0:8080->8080/tcp, :::8080->8080/tcp                                              zigbee2mqtt                0B (virtual 149MB)
9749cc78b65e   ghcr.io/home-assistant/home-assistant:2022.9.0   "/init"                  31 hours ago     Up 23 hours                                                                                            homeassistant              1.77MB (virtual 1.43GB)
0457dc609f37   eclipse-mosquitto:2.0.14                         "/docker-entrypoint.…"   31 hours ago     Up 23 hours     0.0.0.0:1883->1883/tcp, :::1883->1883/tcp, 0.0.0.0:9001->9001/tcp, :::9001->9001/tcp   mosquitto                  0B (virtual 11.5MB)
0f0c0ee73850   lscr.io/linuxserver/duckdns:68a3222a-ls97        "/init"                  31 hours ago     Up 23 hours                                                                                            duckdns                    12.1kB (virtual 32.3MB)
3c13684c78ac   portainer/portainer-ce:2.13.1                    "/portainer"             32 hours ago     Up 23 hours     8000/tcp, 9443/tcp, 0.0.0.0:9000->9000/tcp, :::9000->9000/tcp                          portainer                  0B (virtual 265MB)

$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        59G  9.4G   47G  17% /
devtmpfs        3.6G     0  3.6G   0% /dev
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           1.6G  2.0M  1.6G   1% /run
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
/dev/mmcblk0p1  255M   31M  225M  13% /boot
tmpfs           782M     0  782M   0% /run/user/1000
```

# CREDIT

Lưu sensor data long-term: https://community.home-assistant.io/t/how-do-people-store-and-use-historical-sensor-data-long-term/288692/8

Practice của mọi người: dùng MariaDB/Postgres để giữ data short term, dùng influxDB và grafana để cho long-term. 

Có 1 guilde ở đây Postgresql for short term data, and influxDB for long term:  
https://github.com/Burningstone91/smart-home-setup#history-databases

Và đây: https://www.paolotagliaferri.com/home-assistant-data-persistence-and-visualization-with-grafana-and-influxdb/

1 bài về cách reduce Size cho db short-term (mariaDB) khi run trên Pi + SD Card, tăng tuổi thọ SD card: https://community.home-assistant.io/t/how-to-reduce-your-database-size-and-extend-the-life-of-your-sd-card/205299/11

Trong bài trên có người khuyên nên dùng thẻ SD card này: SanDisk Extreme 64 GB microSDXC A2 App Performance:   
(https://community.home-assistant.io/t/how-to-reduce-your-database-size-and-extend-the-life-of-your-sd-card/205299/66?u=super318)  
(https://cyan-automation.medium.com/best-sd-card-for-home-assistant-raspberry-pi-62df0674c405)  

So sánh Prometheus vs InfluxDB: https://logz.io/blog/prometheus-influxdb/

So sánh InfluxDB và VictoriaMetrics, TimeScaleDB: VictoriaMetric có vẻ mới hơn, performance tốt hơn, nhưng ít người dùng hơn.

Cũng có người nói nên dùng TimeScaleDB hơn: https://community.home-assistant.io/t/how-to-reduce-your-database-size-and-extend-the-life-of-your-sd-card/205299/90?u=super318

Hướng dẫn install influxDB + grafana trong HASS: https://www.youtube.com/watch?v=eJ-XE2tsD4U&ab_channel=EverythingSmartHome

Khuyên nên tìm cách manage DB trong HASS vì HA hiện đang ghi lại every event. Nên dùng Recorder của HASS để include/exclude các event: https://community.home-assistant.io/t/recommendation-sd-card-that-wont-die-in-a-few-months/383944/4?u=super318

Hướng dẫn dùng MariaDB và set HASS Recorder, họ cũng khuyên ko dùng với SD card mà dùng SSD:  
https://www.youtube.com/watch?v=FbFyqQ3He7M&ab_channel=EverythingSmartHome  

Có người khuyên dùng A1/A2 sdcard: If you use an A1 or A2 sd card, this shouldn't be that much of a problem anyway. :)

Update recorder để có thời gian dài hơn giữ data: 32 days:  
https://community.home-assistant.io/t/best-choice-for-keeping-a-longer-history-for-sensors/86785/12?u=super318 

Grafana + InfluxDB setup: https://medium.com/@nanditasahu031/integration-of-influxdb2-with-grafana-28b4aebb3368

https://stackoverflow.com/questions/45171907/influxdb-how-to-update-duration-of-an-existing-database