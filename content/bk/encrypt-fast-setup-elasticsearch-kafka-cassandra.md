---
title: "Fast setup ElasticSearch Kafka Cassandra"
date: 2024-07-04T21:50:50+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [ElasticSearch,Kafka,Cassandra,Docker]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Dùng Docker setup các tool để test"
---


Quá trình làm việc có thể bạn sẽ cần dựng môi trường thật nhanh để test các tính năng

Dưới đây là script để setup ElasticSearch, Cassandra, Kafka+Zookeeper nhanh bằng Docker Compose

# 1. Fast setup

## 1.1. Install Docker, Docker Compose in Ubuntu 20

```sh
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce -y
sudo systemctl status docker
sudo usermod -aG docker ${USER}
exit
login again

sudo curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
sudo systemctl enable docker

wget https://bootstrap.pypa.io/get-pip.py
sudo python3 get-pip.py
pip install requests==2.31 docker==6.1.3 docker-compose==1.29.2
pip show docker-compose docker
```

## 1.2. Setup ElasticSearch single node by Docker compose

Tạo trước `/datadrive/elasticsearch/data`

File `docker-compose-es.yml`:

```yml
version: "3.4"

services:
  elasticsearch:
    image: elasticsearch:7.3.2
    container_name: elasticsearch
    restart: always
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    environment:
      discovery.type: single-node
      xpack.security.enabled: "false"
      bootstrap.memory_lock: "true"
      TAKE_FILE_OWNERSHIP: "true"
    ports:
      - 9200:9200
      - 9300:9300
    volumes:
      - /opt/test/datadrive/elasticsearch/data:/usr/share/elasticsearch/data
```

```sh
docker-compose -f docker-compose-es.yml up -d
```

Test connection:

```sh
# List all index/alias ElasticSearch
curl -XGET http://localhost:9200/_cat/indices?v
curl -XGET http://localhost:9200/_cat/aliases?v
```


## 1.3. Setup Kafka single node by Docker compose

Tạo trước folder `/datadrive/zookeeper`, `/datadrive/kafka`

File `docker-compose-kafka.yml`, thay `<VM_HOST_IP_ADDRESS>` bằng IP của Host:

```yml
version: '2.1'

services:
  zookeeper:
    image: wurstmeister/zookeeper
    hostname: zookeeper
    container_name: zookeeper
    restart: always
    ports:
      - "2181:2181"
    environment:
        ZOO_MY_ID: 1
        ZOO_PORT: 2181
        ZOO_SERVERS: server.1=zookeeper:2888:3888
    volumes:
      - /datadrive/zookeeper/data:/data
      - /datadrive/zookeeper/datalog:/datalog

  kafka:
      image: wurstmeister/kafka
      hostname: kafka
      container_name: kafka
      restart: always
      ports:
        - "9092:9092"
      environment:
        HOSTNAME_COMMAND: "docker info | grep ^Name: | cut -d' ' -f 2"
        KAFKA_ADVERTISED_LISTENERS: "PLAINTEXT://<VM_HOST_IP_ADDRESS>:9092"
        KAFKA_ZOOKEEPER_CONNECT: "zookeeper:2181"
        KAFKA_ADVERTISED_HOST_NAME: 172.19.0.1
        KAFKA_BROKER_ID: 1
        KAFKA_LOG4J_LOGGERS: "kafka.controller=INFO,kafka.producer.async.DefaultEventHandler=INFO,state.change.logger=INFO"
        KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      volumes:
        - /datadrive/kafka/data:/var/lib/kafka/data
      depends_on:
        - zookeeper
```

```sh
docker-compose -f docker-compose-kafka.yml up -d
```

test connection từ VM khác, lấy số lượng topic, consummer:

```sh
$ sudo apt-get install kafkacat
$ kafkacat --help
$ kafkacat -L -b <VM_HOST_IP_ADDRESS>:9092
# Sẽ trả về meta data của Kafka host

```

## 1.4. Setup Cassandra single node by Docker compose

Tạo folder và set `chown,chmod 777 -R` cho tất cả folder trong `/datadrive/cassandra and /datadrive/datastax-studio`

```sh
mkdir -p /datadrive/cassandra/config/ /datadrive/cassandra/data/ /datadrive/cassandra/dsefs/ /datadrive/cassandra/log/ /datadrive/cassandra/spark/
```

File `docker-compose-dse.yml`:

```yml
version: '2'
services:
  seed_node:
    image: "datastax/dse-server:6.8.37"
    container_name: datastax_seed_node
    restart: unless-stopped
    ports:
      - 9042:9042
    environment:
      - DS_LICENSE=accept
      - DC=Cassandra
      - START_RPC=true
    links:
      - opscenter
    # Allow DSE to lock memory with mlock
    cap_add:
    - IPC_LOCK
    ulimits:
      memlock: -1
    volumes:
      - /datadrive/cassandra/data:/var/lib/cassandra:z
      - /datadrive/cassandra/spark:/var/lib/spark:z
      - /datadrive/cassandra/dsefs:/var/lib/dsefs:z
      - /datadrive/cassandra/log/cassandra:/var/log/cassandra:z
      - /datadrive/cassandra/log/spark:/var/log/spark:z
      - /datadrive/cassandra/config:/config:z

  node:
    image: "datastax/dse-server:6.8.37"
    container_name: datastax_node
    restart: unless-stopped
    environment:
      - DS_LICENSE=accept
      - SEEDS=seed_node
      - DC=Cassandra
      - START_RPC=true
    links:
      - seed_node
      - opscenter
    # Allow DSE to lock memory with mlock
    cap_add:
    - IPC_LOCK
    ulimits:
      memlock: -1
    volumes:
      - /datadrive/cassandra/data:/var/lib/cassandra:z
      - /datadrive/cassandra/spark:/var/lib/spark:z
      - /datadrive/cassandra/dsefs:/var/lib/dsefs:z
      - /datadrive/cassandra/log/cassandra:/var/log/cassandra:z
      - /datadrive/cassandra/log/spark:/var/log/spark:z
      - /datadrive/cassandra/config:/config:z

  opscenter:
    image: "datastax/dse-opscenter:6.8.37"
    container_name: datastax_opscenter
    restart: unless-stopped
    ports:
      - 8888:8888
    environment:
      - DS_LICENSE=accept

```

1-Node Setup with OpsCenter:

```sh
docker-compose -f docker-compose-dse.yml up -d --scale node=0
```

Test connection đến Opscenter:

```sh
# Lấy IP của Cluster:
$ docker inspect datastax_seed_node | grep '"IPAddress":'
            "IPAddress": "",
                    "IPAddress": "192.168.16.3",
```

Dùng Putty Port forwarding để vào giao diện Opscenter: port 8888
Chọn "Manage existing cluster" -> enter 192.168.16.3, Chọn "Install agents manually"

Test connection từ VM khác:

```sh
CQLSH_HOST=<HOST_IP>
CQLSH_PORT=9042
USER=cas
PASSWORD=cas
keyspace=test
# -> Sẽ lỗi nếu cassandra ko có SSL
cqlsh --ssl "$CQLSH_HOST" "$CQLSH_PORT" -u "$USER" -p "$PASSWORD" -e "DROP KEYSPACE IF EXISTS $keyspace ;"
# -> OK
cqlsh "$CQLSH_HOST" "$CQLSH_PORT" -u "$USER" -p "$PASSWORD" -e "DROP KEYSPACE IF EXISTS $keyspace ;"
```

# 2. ElasticSearch cheatsheet

ElasticSearch có khái niệm về index và alias. Thông thường bạn sẽ lưu data trong index. Mỗi index được đánh 1 alias. Nhưng 1 alias có thể trỏ đến nhiều index.

Còn service thì lấy data từ alias thôi.

## 2.1. List all index/alias ElasticSearch

```sh
curl -XGET http://localhost:9200/_cat/indices?v
curl -XGET http://localhost:9200/_cat/aliases?v
```

## 2.2. Set tăng index.mapping.total_fields.limit cho index conf

```sh
curl -s -XPUT http://localhost:9200/conf/_settings  -H 'Content-Type: application/json' -d '{"index.mapping.total_fields.limit": 2000}'
```

Set max result window ElasticSearch

```sh
curl -H 'Content-Type: application/json' -XPUT http://localhost:9200/_settings -d'
{
    "index" : {
        "max_result_window" : 100000
    }
}'


curl -H 'Content-Type: application/json' -XPUT http://localhost:9200/yourindex-*/_settings -d'
{
    "index" : {
        "max_result_window" : 100000
    }
}'

curl -H 'Content-Type: application/json' -XPUT http://localhost:9200/myindex-*/_settings -d'
{
    "index" : {
        "max_result_window" : 150000
    }
}'
```

## 2.3. Get index template

```sh
INDEX_NAME=test2024
curl -X GET "localhost:9200/_template/${INDEX_NAME}*?pretty"
```

## 2.4. Put/import index template from file

```sh
INDEX_NAME=test2024
# Create index
curl -s -X PUT http://localhost:9200/$INDEX_NAME
# import template
TEMPLATE_FILE_PATH="./YOUR_TEMPLATE.json"
curl -H 'Content-Type: application/json' -XPUT localhost:9200/_template/$INDEX_NAME -d@$TEMPLATE_FILE_PATH
```

## 2.5. Put data to index

```sh
$ curl -H "Content-Type: application/json" -XPOST "http://localhost:9200/$INDEX_NAME/abc/def" -d "{ \"field\" : \"hoangmnsd\"}"
{"_index":"hoang-20240717","_type":"abc","_id":"def","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":0,"_primary_term":1}
```

## 2.6. Get Nodename info

```sh
curl -XGET http://localhost:9200/_cat/nodes?v
```

## 2.7. Select an index from ElasticSearch

```sh
curl -XPUT http://localhost:9200/$INDEX_NAME?pretty
```

## 2.8. Get all data from index `test`

```sh
curl -XGET 'localhost:9200/test/_search?pretty'
```

## 2.9. Create index

```sh
curl -s -X PUT http://localhost:9200/$INDEX_NAME
```

## 2.10. Re-index

Re-index từ `test2024` thành `test2024-20240717` (Nó sẽ tạo 1 index với tên mới `test2024-20240717`, index cũ `test2024` vẫn còn đó, data dc copy sang)

```sh
INDEX_NAME=test2024
DATE=20240717
curl -X POST http://localhost:9200/_reindex -H 'Content-Type: application/json' -d '{"source":{"index":"$INDEX_NAME"},"dest":{"index":"$INDEX_NAME-$DATE"}}'
```

## 2.11. Delete index

```sh
curl -XDELETE http://localhost:9200/$INDEX_NAME
```

## 2.12. Create alias for an index

```sh
curl -s -X POST http://localhost:9200/_aliases -H 'Content-Type: application/json' -d '{"actions":[{"add":{"index": "$INDEX_NAME-$DATE","alias":"$INDEX_NAME"}}]}'

example:
curl -s -X POST http://localhost:9200/_aliases -H 'Content-Type: application/json' -d '{"actions":[{"add":{"index": "test2024-20210701","alias":"test2024"}}]}'
```

## 2.13. Update replica of index

```sh
curl -X PUT "localhost:9200/$INDEX_NAME/_settings?pretty" -H 'Content-Type: application/json' -d'
{
  "index" : {
    "number_of_replicas" : 2
  }
}'
```

## 2.14. Delete all docs/data of an index

```sh
export INDEX_NAME=test

curl -X POST "localhost:9200/$INDEX_NAME/_doc/_delete_by_query?conflicts=proceed" -H 'Content-Type: application/json' -d'
{
 "query": {
 "match_all": {}
 }
}'
```

## 2.15. Get all shards of ElastichSearch / index

```sh
curl -X GET "localhost:9200/_cat/shards"
curl -X GET "localhost:9200/_cat/shards/$INDEX_NAME"
```

# 3. ElasticSearch - Move data from an index to another index

Trong khi làm việc, có thể bạn sẽ gặp trường hợp cần phải xóa index và tạo lại nó với tên mới. Rủi rõ mất hết document trong index.

Bạn có thể backup data trong index `A` sang index `A-2024`. Rồi đánh alias `A` cho index mới `A-2024`.

Hàm reindex chính là sinh ra để làm việc này.

Giờ có thể xóa index A được rồi.


# 4. ElasticSearch - Enable private SSL/TLS

Làm theo cái này: https://discuss.elastic.co/t/curl-against-an-encrypted-elasticsearch-instance-with-certificate-verification/251503

Đầu tiên chúng ta cứ tạo ElasticSearch ko enable SSL giống như mục 1.

## 4.1. Generate cert .crt (localhost) từ ElasticSearch container chưa enable ssl

Ta sẽ SSH vào docker container của ES để generate certs bằng `/bin/elasticsearch-certutil`

```sh
$ docker exec -it  elasticsearch /bin/bash

[root@1a25fadbe4c2 elasticsearch]# ll
total 556
-rw-r--r--  1 elasticsearch root  13675 Sep  6  2019 LICENSE.txt
-rw-r--r--  1 elasticsearch root 502598 Sep  6  2019 NOTICE.txt
-rw-r--r--  1 elasticsearch root   8500 Sep  6  2019 README.textile
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 bin
drwxrwxr-x  1 elasticsearch root   4096 Jul 18 14:38 config
drwxr-xr-x  3 elasticsearch root   4096 Jul 18 14:38 data
drwxr-xr-x  1 elasticsearch root   4096 Sep  6  2019 jdk
drwxr-xr-x  3 elasticsearch root   4096 Sep  6  2019 lib
drwxrwxr-x  1 elasticsearch root   4096 Jul 18 14:38 logs
drwxr-xr-x 33 elasticsearch root   4096 Sep  6  2019 modules
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 plugins

```
ở trong container ES, tạo file `instance.yml`:

```yml
instances:
  name: 'node'
  dns: ['localhost']
  ip: ['127.0.0.1']
```

Run command: `bin/elasticsearch-certutil cert --keep-ca-key ca --pem --in instance.yml --out certs.zip`

```s
[root@1a25fadbe4c2 elasticsearch]# ll
total 560
-rw-r--r--  1 elasticsearch root  13675 Sep  6  2019 LICENSE.txt
-rw-r--r--  1 elasticsearch root 502598 Sep  6  2019 NOTICE.txt
-rw-r--r--  1 elasticsearch root   8500 Sep  6  2019 README.textile
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 bin
drwxrwxr-x  1 elasticsearch root   4096 Jul 18 14:38 config
drwxr-xr-x  3 elasticsearch root   4096 Jul 18 14:38 data
-rw-r--r--  1 root          root     67 Jul 18 14:41 instance.yml
drwxr-xr-x  1 elasticsearch root   4096 Sep  6  2019 jdk
drwxr-xr-x  3 elasticsearch root   4096 Sep  6  2019 lib
drwxrwxr-x  1 elasticsearch root   4096 Jul 18 14:38 logs
drwxr-xr-x 33 elasticsearch root   4096 Sep  6  2019 modules
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 plugins

[root@1a25fadbe4c2 elasticsearch]# bin/elasticsearch-certutil cert --keep-ca-key ca --pem --in instance.yml --out certs.zip
WARNING: An illegal reflective access operation has occurred
WARNING: Illegal reflective access by org.bouncycastle.jcajce.provider.drbg.DRBG (file:/usr/share/elasticsearch/lib/tools/security-cli/bcprov-jdk15on-1.61.jar) to constructor sun.security.provider.Sun()
WARNING: Please consider reporting this to the maintainers of org.bouncycastle.jcajce.provider.drbg.DRBG
WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
WARNING: All illegal access operations will be denied in a future release
This tool assists you in the generation of X.509 certificates and certificate
signing requests for use with SSL/TLS in the Elastic stack.

The 'cert' mode generates X.509 certificate and private keys.
    * By default, this generates a single certificate and key for use
       on a single instance.
    * The '-multiple' option will prompt you to enter details for multiple
       instances and will generate a certificate and key for each one
    * The '-in' option allows for the certificate generation to be automated by describing
       the details of each instance in a YAML file

    * An instance is any piece of the Elastic Stack that requires a SSL certificate.
      Depending on your configuration, Elasticsearch, Logstash, Kibana, and Beats
      may all require a certificate and private key.
    * The minimum required value for each instance is a name. This can simply be the
      hostname, which will be used as the Common Name of the certificate. A full
      distinguished name may also be used.
    * A filename value may be required for each instance. This is necessary when the
      name would result in an invalid file or directory name. The name provided here
      is used as the directory name (within the zip) and the prefix for the key and
      certificate files. The filename is required if you are prompted and the name
      is not displayed in the prompt.
    * IP addresses and DNS names are optional. Multiple values can be specified as a
      comma separated string. If no IP addresses or DNS names are provided, you may
      disable hostname verification in your SSL configuration.

    * All certificates generated by this tool will be signed by a certificate authority (CA).
    * The tool can automatically generate a new CA for you, or you can provide your own with the
         -ca or -ca-cert command line options.

By default the 'cert' mode produces a single PKCS#12 output file which holds:
    * The instance certificate
    * The private key for the instance certificate
    * The CA certificate

If you specify any of the following options:
    * -pem (PEM formatted output)
    * -keep-ca-key (retain generated CA key)
    * -multiple (generate multiple certificates)
    * -in (generate certificates from an input file)
then the output will be be a zip file containing individual certificate/key files


Certificates written to /usr/share/elasticsearch/certs.zip

This file should be properly secured as it contains the private key for
your instance and for the certificate authority.

After unzipping the file, there will be a directory for each instance.
Each instance has a certificate and private key.
For each Elastic product that you wish to configure, you should copy
the certificate, key, and CA certificate to the relevant configuration directory
and then follow the SSL configuration instructions in the product guide.

For client applications, you may only need to copy the CA certificate and
configure the client to trust this certificate.


[root@1a25fadbe4c2 elasticsearch]# ll
total 568
-rw-r--r--  1 elasticsearch root  13675 Sep  6  2019 LICENSE.txt
-rw-r--r--  1 elasticsearch root 502598 Sep  6  2019 NOTICE.txt
-rw-r--r--  1 elasticsearch root   8500 Sep  6  2019 README.textile
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 bin
-rw-------  1 root          root   5024 Jul 18 14:42 certs.zip
drwxrwxr-x  1 elasticsearch root   4096 Jul 18 14:38 config
drwxr-xr-x  3 elasticsearch root   4096 Jul 18 14:38 data
-rw-r--r--  1 root          root     67 Jul 18 14:41 instance.yml
drwxr-xr-x  1 elasticsearch root   4096 Sep  6  2019 jdk
drwxr-xr-x  3 elasticsearch root   4096 Sep  6  2019 lib
drwxrwxr-x  1 elasticsearch root   4096 Jul 18 14:38 logs
drwxr-xr-x 33 elasticsearch root   4096 Sep  6  2019 modules
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 plugins
```

Kết quả chính là file `certs.zip`. Giờ exit khỏi container ES.

Cấu trúc thư mục bên ngoài container của mình:

```
/opt/test/datadrive$ tree .
.
├── docker-compose-es.yml
├── elasticsearch/
│   ├── data/
│   └── es-certs/
│       └── unzip-certs/
└── instance.yml # file này mình dùng để backup, nội dung giống y hệt file `instance.yml` trong container

```

Giờ copy file zip từ container ra ngoài host.

```sh
# ở ngoài Host, mình sẽ copy certs.zip vào folder `/opt/test/datadrive/elasticsearch/es-certs/unzip-certs`
$ cd /opt/test/datadrive/elasticsearch/es-certs/unzip-certs

$ docker cp elasticsearch:/usr/share/elasticsearch/certs.zip .

$ unzip certs.zip
Archive:  certs.zip
   creating: ca/
  inflating: ca/ca.crt
  inflating: ca/ca.key
   creating: node/
  inflating: node/node.crt
  inflating: node/node.key
```

## 4.2. Enable ElasticSearch SSL dùng file .crt (localhost)

Giờ cấu trúc thư mục đã có thêm các file certs vừa được unzip:

```s
/opt/test/datadrive$ tree .
.
├── docker-compose-es.yml
├── elasticsearch/
│   ├── data/
│   └── es-certs/
│       └── unzip-certs/
│           ├── ca/
│           │   ├── ca.crt
│           │   └── ca.key
│           ├── certs.zip
│           └── node/
│               ├── node.crt
│               └── node.key
└── instance.yml
```

Giờ sửa file docker-compose để enable SSL cho ES sử dụng các file cert mới có được:

```yml
version: "3.4"

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.3.2
    container_name: elasticsearch
    restart: always
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    environment:
      discovery.type: single-node
      bootstrap.memory_lock: "true"
      TAKE_FILE_OWNERSHIP: "true"
      ELASTIC_PASSWORD: "12345678"
      xpack.license.self_generated.type: trial
      # xpack.security.enabled: "false"
      xpack.security.enabled: "true"
      xpack.security.transport.ssl.enabled: "true"
      xpack.security.http.ssl.enabled: "true"
      xpack.security.http.ssl.key: /usr/share/elasticsearch/config/certs/node.key
      xpack.security.http.ssl.certificate: /usr/share/elasticsearch/config/certs/node.crt
      xpack.security.http.ssl.certificate_authorities: /usr/share/elasticsearch/config/certs/ca.crt
      xpack.security.transport.ssl.key: /usr/share/elasticsearch/config/certs/node.key
      xpack.security.transport.ssl.certificate: /usr/share/elasticsearch/config/certs/node.crt
      xpack.security.transport.ssl.certificate_authorities: /usr/share/elasticsearch/config/certs/ca.crt
    ports:
      - 9200:9200
      - 9300:9300
    volumes:
      - /opt/test/datadrive/elasticsearch/data:/usr/share/elasticsearch/data
      - /opt/test/datadrive/elasticsearch/es-certs/unzip-certs/node/node.key:/usr/share/elasticsearch/config/certs/node.key
      - /opt/test/datadrive/elasticsearch/es-certs/unzip-certs/node/node.crt:/usr/share/elasticsearch/config/certs/node.crt
      - /opt/test/datadrive/elasticsearch/es-certs/unzip-certs/ca/ca.crt:/usr/share/elasticsearch/config/certs/ca.crt
```

```sh
$ docker-compose -f docker-compose-es.yml up -d

# check logs OK
$ docker logs -f elasticsearch

{"type": "server", "timestamp": "2024-07-18T14:53:46,685+0000", "level": "INFO", "component": "o.e.g.GatewayService", "cluster.name": "docker-cluster", "node.name": "bf0a8af96f80", "cluster.uuid": "NXTZ-ENOQM6OQkrfYO_udA", "node.id": "M7MchhXcR4G0-rNUFgbkpA",  "message": "recovered [1] indices into cluster_state"  }
{"type": "server", "timestamp": "2024-07-18T14:53:47,594+0000", "level": "INFO", "component": "o.e.c.r.a.AllocationService", "cluster.name": "docker-cluster", "node.name": "bf0a8af96f80", "cluster.uuid": "NXTZ-ENOQM6OQkrfYO_udA", "node.id": "M7MchhXcR4G0-rNUFgbkpA",  "message": "Cluster health status changed from [RED] to [YELLOW] (reason: [shards started [[hoang-20240717][0]] ...])."  }
```

Test connection đến ES localhost có https bằng cert `.crt` thành công:

```sh
$ cd /opt/test/datadrive/elasticsearch/es-certs/unzip-certs/node/
$ curl --cacert ./node.crt https://localhost:9200 -u elastic
Enter host password for user 'elastic':
{
  "name" : "bf0a8af96f80",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "NXTZ-ENOQM6OQkrfYO_udA",
  "version" : {
    "number" : "7.3.2",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "1c1faf1",
    "build_date" : "2019-09-06T14:40:30.409026Z",
    "build_snapshot" : false,
    "lucene_version" : "8.1.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```

Chú ý dùng file `node.crt hay ca.crt` sẽ thành công, nhưng file `node.key hay ca.key` bị lỗi curl.

Như vậy là thành công khá rồi khi curl command ko cần phải dùng `--insecure hay -k`. 🎈🎈

Tuy nhiên bây giờ nếu curl từ 1 VM khác đến VM cài ES này, sẽ bị lỗi:

```sh
# Lỗi
$ curl --cacert ./node.crt https://es.internal.ABC.net:9200 -u elastic
Enter host password for user 'elastic':
curl: (60) SSL: no alternative certificate subject name matches target host name 'es.internal.ABC.net'
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

## 4.3. Generate cert .crt (localhost, host DNS/private IP) từ ElasticSearch container ko enable ssl

Để giải quyết lỗi này cần tạo lại cert như sau, Làm lại từ đầu, SSH vào container ES chưa được enable SSL:

```sh
$ docker exec -it  elasticsearch /bin/bash
```

Sửa nội dung file `instance.yml`. Chú ý `es.internal.ABC.net và 10.10.13.26` là DNS và private IP của Server cài ES:

```yml
instances:
  name: 'node'
  dns: ['localhost', 'es.internal.ABC.net']
  ip: ['127.0.0.1', '10.10.13.26']
```

Gen lại file `certs.zip`:

```sh
[root@bf0a8af96f80 elasticsearch]# bin/elasticsearch-certutil cert --keep-ca-key ca --pem --in instance.yml --out certs.zip

[root@bf0a8af96f80 elasticsearch]# ll
total 568
-rw-r--r--  1 elasticsearch root  13675 Sep  6  2019 LICENSE.txt
-rw-r--r--  1 elasticsearch root 502598 Sep  6  2019 NOTICE.txt
-rw-r--r--  1 elasticsearch root   8500 Sep  6  2019 README.textile
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 bin
-rw-------  1 root          root   5079 Jul 18 15:06 certs.zip
drwxrwxr-x  1 elasticsearch root   4096 Jul 18 14:53 config
drwxrwxr-x  3 elasticsearch root   4096 Jul 17 14:16 data
-rw-r--r--  1 root          root    117 Jul 18 15:06 instance.yml
drwxr-xr-x  1 elasticsearch root   4096 Sep  6  2019 jdk
drwxr-xr-x  3 elasticsearch root   4096 Sep  6  2019 lib
drwxrwxr-x  1 elasticsearch root   4096 Jul 18 14:53 logs
drwxr-xr-x 33 elasticsearch root   4096 Sep  6  2019 modules
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 plugins
```

Ra exit khỏi container, xóa hết cert trong folder `/opt/test/datadrive/elasticsearch/es-certs/unzip-certs` đi, sẽ dùng file `certs.zip` mới nhất

```sh
# ở ngoài Host, mình sẽ copy certs.zip vào folder `/opt/test/datadrive/elasticsearch/es-certs/unzip-certs`
$ cd /opt/test/datadrive/elasticsearch/es-certs/unzip-certs

$ docker cp elasticsearch:/usr/share/elasticsearch/certs.zip .

$ unzip certs.zip
Archive:  certs.zip
   creating: ca/
  inflating: ca/ca.crt
  inflating: ca/ca.key
   creating: node/
  inflating: node/node.crt
  inflating: node/node.key
```

## 4.4. Enable ElasticSearch SSL dùng file .crt (localhost, host DNS/Private IP)

Sửa file `docker-compose-es.yml` giống như bên trên để dùng các certs. (Chỗ này file hơi dài nên mình ko paste lại nữa, kéo lên là có rồi, y hệt)

```s
$ docker-compose -f docker-compose-es.yml up -d

# check logs OK
$ docker logs -f elasticsearch

{"type": "server", "timestamp": "2024-07-18T14:53:46,685+0000", "level": "INFO", "component": "o.e.g.GatewayService", "cluster.name": "docker-cluster", "node.name": "bf0a8af96f80", "cluster.uuid": "NXTZ-ENOQM6OQkrfYO_udA", "node.id": "M7MchhXcR4G0-rNUFgbkpA",  "message": "recovered [1] indices into cluster_state"  }
{"type": "server", "timestamp": "2024-07-18T14:53:47,594+0000", "level": "INFO", "component": "o.e.c.r.a.AllocationService", "cluster.name": "docker-cluster", "node.name": "bf0a8af96f80", "cluster.uuid": "NXTZ-ENOQM6OQkrfYO_udA", "node.id": "M7MchhXcR4G0-rNUFgbkpA",  "message": "Cluster health status changed from [RED] to [YELLOW] (reason: [shards started [[hoang-20240717][0]] ...])."  }
```

giờ check curl từ localhost OK:

```s
$ cd /opt/test/datadrive/elasticsearch/es-certs/unzip-certs/node/
$ curl --cacert ./node.crt https://localhost:9200 -u elastic
Enter host password for user 'elastic':
{
  "name" : "bf0a8af96f80",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "NXTZ-ENOQM6OQkrfYO_udA",
  "version" : {
    "number" : "7.3.2",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "1c1faf1",
    "build_date" : "2019-09-06T14:40:30.409026Z",
    "build_snapshot" : false,
    "lucene_version" : "8.1.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}


# Nếu dùng http thường (not https) sẽ bị lỗi (như expected)
# Lỗi
$ curl --cacert ./node.crt http://localhost:9200 -u elastic
Enter host password for user 'elastic':
curl: (52) Empty reply from server


# Nếu dùng https nhưng ko cung cấp cacert sẽ bị lỗi (như expected)
# Lỗi
$ curl https://localhost:9200 -u elastic
Enter host password for user 'elastic':
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

mang file `node.crt` sang VM khác sẽ curl OK ngay 😁😀:

```sh
$ curl --cacert ./node.crt https://es.internal.ABC.net:9200 -u elastic
Enter host password for user 'elastic':
{
  "name" : "e314d10e8eed",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "NXTZ-ENOQM6OQkrfYO_udA",
  "version" : {
    "number" : "7.3.2",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "1c1faf1",
    "build_date" : "2019-09-06T14:40:30.409026Z",
    "build_snapshot" : false,
    "lucene_version" : "8.1.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```

Giờ tìm cách để trong command curl có thể dùng file `.p12` thay cho file `node.crt`.

## 4.5. Thử cách convert file .crt (đang dùng curl tốt) sang .p12

Thử convert file crt sang p12 file, nhưng sẽ bị lỗi:
(refer https://www.ssl.com/how-to/create-a-pfx-p12-certificate-file-using-openssl/)
```s
$ openssl pkcs12 -export -out ./node.p12 -inkey ./node.key -in ./node.crt
=> ra file p12 nhưng ko dùng để curl từ vm khác đc. Sẽ bị lỗi:

# Lỗi
$ curl --cacert ./node.p12 https://localhost:9200 -u elastic
Enter host password for user 'elastic':
curl: (77) error setting certificate verify locations:
  CAfile: ./node.p12
  CApath: /etc/ssl/certs

# Lỗi
$ curl --cert-type P12 --cert ./node.p12 https://localhost:9200
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.

# Lỗi
$ curl -v --cacert ./ca.p12 https://localhost:9200 -u elastic
Enter host password for user 'elastic':
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* error setting certificate verify locations:
  CAfile: ./ca.p12
  CApath: /etc/ssl/certs
* Closing connection 0
curl: (77) error setting certificate verify locations:
  CAfile: ./ca.p12
  CApath: /etc/ssl/certs

# Lỗi
$ curl -v --cert-type P12 --cert ./ca.p12 https://localhost:9200 -u elastic
Enter host password for user 'elastic':
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS alert, unknown CA (560):
* SSL certificate problem: unable to get local issuer certificate
* Closing connection 0
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

Nếu dùng command này để export ra p12 file, rồi curl sẽ bị lỗi:

```s
$ openssl pkcs12 -export -out node.p12 -in ./node.crt -inkey ./node.key -passout pass: -nokeys

# Lỗi
$ curl -v --cert-type P12 --cert ./node.p12 https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* could not load PKCS12 client certificate, OpenSSL error error:140AB043:SSL routines:SSL_CTX_use_certificate:passed a null parameter
* Closing connection 0
curl: (58) could not load PKCS12 client certificate, OpenSSL error error:140AB043:SSL routines:SSL_CTX_use_certificate:passed a null parameter

# Lỗi
$ curl -v --cacert ./node.p12 https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* error setting certificate verify locations:
  CAfile: ./node.p12
  CApath: /etc/ssl/certs
* Closing connection 0
curl: (77) error setting certificate verify locations:
  CAfile: ./node.p12
  CApath: /etc/ssl/certs

```

Nếu dùng command này curl sẽ bị lỗi:

```s
# http://gagravarr.org/writing/openssl-certs/general.shtml#cert-convert
$ openssl pkcs12 -export -in ./node.crt -nokeys -nodes -out ./node.p12

# Lỗi
$ curl --cert-type P12 --cert ./node.p12 https://localhost:9200
curl: (58) could not load PKCS12 client certificate, OpenSSL error error:140AB043:SSL routines:SSL_CTX_use_certificate:passed a null parameter

# Lỗi
$ openssl pkcs12 -export -in ./node.crt -nokeys -nodes -out ./node.p12 -passout pass:
$ curl --cert-type P12 --cert ./node.p12 https://localhost:9200
curl: (58) could not load PKCS12 client certificate, OpenSSL error error:140AB043:SSL routines:SSL_CTX_use_certificate:passed a null parameter
```

Thử dùng command này để convert file .crt sang .p12:

```s
openssl pkcs12 -export -name servercert -in node.crt -inkey node.key -out node.p12

# Lỗi
$ curl --cacert ./node.p12 https://localhost:9200 -u elastic
Enter host password for user 'elastic':
curl: (77) error setting certificate verify locations:
  CAfile: ./node.p12
  CApath: /etc/ssl/certs

# Lỗi
$ curl --cert-type P12 --cert ./node.p12 https://localhost:9200
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

Thử tiếp command convert p12 file có password vì trong post này có ng bảo thế: https://stackoverflow.com/a/78111846

```s
# Có input password 12345678
$ openssl pkcs12 -export -in node.crt -inkey node.key \
                         -out node.p12 -name localhost

$ chmod 664 node.p12

# Nếu ko có password trong curl sẽ bị lỗi
# Lỗi
$ curl -v --cert-type P12 --cert ./node.p12  https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* could not parse PKCS12 file, check password, OpenSSL error error:23076071:PKCS12 routines:PKCS12_parse:mac verify failure
* Closing connection 0
curl: (58) could not parse PKCS12 file, check password, OpenSSL error error:23076071:PKCS12 routines:PKCS12_parse:mac verify failure

# điền password có dấu nháy
# Lỗi
$ curl -v --cert-type P12 --cert ./node.p12:'12345678' https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS alert, unknown CA (560):
* SSL certificate problem: unable to get local issuer certificate
* Closing connection 0
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.

# điền password ko có dấu nháy
# Lỗi
$ curl -v --cert-type P12 --cert ./node.p12:12345678 https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS alert, unknown CA (560):
* SSL certificate problem: unable to get local issuer certificate
* Closing connection 0
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.

# thêm cả --cacert ./node.p12
# Lỗi
$ curl -v --cacert ./node.p12 --cert-type P12 --cert ./node.p12:12345678 https://localhost:9200 -u elastic
Enter host password for user 'elastic':
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* error setting certificate verify locations:
  CAfile: ./node.p12
  CApath: /etc/ssl/certs
* Closing connection 0
curl: (77) error setting certificate verify locations:
  CAfile: ./node.p12
  CApath: /etc/ssl/certs
```

Nếu file `node.crt` có thể dùng OK, thì thử convert ONLY file `node.crt` sang `node.p12` xem sao?

```s
openssl pkcs12 -export -in node.crt -nokeys \
                         -out node.p12 -name localhost

# Điền password cho p12 là 12345678

# Lỗi
$ curl -v --cert-type P12 --cert ./node.p12:12345678 https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* could not load PKCS12 client certificate, OpenSSL error error:140AB043:SSL routines:SSL_CTX_use_certificate:passed a null parameter
* Closing connection 0
curl: (58) could not load PKCS12 client certificate, OpenSSL error error:140AB043:SSL routines:SSL_CTX_use_certificate:passed a null parameter

# Lỗi
$ curl -v --cacert ./node.p12:12345678 https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* error setting certificate verify locations:
  CAfile: ./node.p12:12345678
  CApath: /etc/ssl/certs
* Closing connection 0
curl: (77) error setting certificate verify locations:
  CAfile: ./node.p12:12345678
  CApath: /etc/ssl/certs
```

Thử làm lại việc export chỉ có chỉ định CAfile:

```s
# set password for p12 file = 12345678
$ openssl pkcs12 -export -in node.crt -inkey node.key \
    -out node.p12 -name localhost \
    -CAfile ../ca/ca.crt -caname root
Enter Export Password:
Verifying - Enter Export Password:

# Lỗi
$ curl -v --cacert ./node.p12:12345678 https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* error setting certificate verify locations:
  CAfile: ./node.p12:12345678
  CApath: /etc/ssl/certs
* Closing connection 0
curl: (77) error setting certificate verify locations:
  CAfile: ./node.p12:12345678
  CApath: /etc/ssl/certs

# Lỗi
$ curl -v --cert-type P12 --cert ./node.p12:12345678 https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS alert, unknown CA (560):
* SSL certificate problem: unable to get local issuer certificate
* Closing connection 0
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

Thử dùng `-CAfile` trỏ đến file `node.crt`:

```s
$ openssl pkcs12 -export -in node.crt -inkey node.key \
    -out node.p12 -name localhost \
    -CAfile node.crt -caname root

# Lỗi
$ curl -v --cert-type P12 --cert ./node.p12:12345678 https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS alert, unknown CA (560):
* SSL certificate problem: unable to get local issuer certificate
* Closing connection 0
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.

# Lỗi
$ curl -v --cacert ./node.p12:12345678 https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* error setting certificate verify locations:
  CAfile: ./node.p12:12345678
  CApath: /etc/ssl/certs
* Closing connection 0
curl: (77) error setting certificate verify locations:
  CAfile: ./node.p12:12345678
  CApath: /etc/ssl/certs
```

Thử copy file `/usr/share/elasticsearch/config/elasticsearch.keystore` ra ngoài Host:

```s
/opt/test/datadrive/elasticsearch/es-certs/unzip-certs/node$ docker cp elasticsearch:/usr/share/elasticsearch/config/elasticsearch.keystore .

# Lỗi
$ curl -v --cacert elasticsearch.keystore  https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* error setting certificate verify locations:
  CAfile: elasticsearch.keystore
  CApath: /etc/ssl/certs
* Closing connection 0
curl: (77) error setting certificate verify locations:
  CAfile: elasticsearch.keystore
  CApath: /etc/ssl/certs

# Lỗi
$ curl -v --cert elasticsearch.keystore  https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* could not load PEM client certificate, OpenSSL error error:0909006C:PEM routines:get_name:no start line, (no key found, wrong pass phrase, or wrong file format?)
* Closing connection 0
curl: (58) could not load PEM client certificate, OpenSSL error error:0909006C:PEM routines:get_name:no start line, (no key found, wrong pass phrase, or wrong file format?)
```

Nếu muốn đọc nội dung file `node.p12` bằng command sau:
```sh
$ openssl pkcs12 -info -nodes -in node.p12
```

### 4.5.1. Kết luận 

Nếu đã curl đến ElasticSearch bằng file .crt (ko đặt password), thì cứ dùng file đó. 

Không thể convert file .crt sang .p12 để dùng cho command curl được. Vì sẽ báo rất nhiều lỗi như trên. (chưa thử các ES version >7.3.2)

Nếu có ứng dụng Java app cần dùng file .p12, thì hãy convert file .crt sang .p12 (có password). Rồi đưa file .p12 (có password) cho java app dùng.

Chú ý có 1 số lỗi khi Java app connect đến ElasticSearch:

- 1 số Java app đòi ElasticSearch phải là https, nếu ko sẽ báo lỗi:  
  ```
  "stack_trace":"io.netty.handler.codec.DecoderException: io.netty.handler.ssl.NotSslRecordException: not an SSL/TLS record:
  ```

- 1 số Java app đòi file .p12 phải đúng định dạng, nếu ko sẽ ko build được `buildSSLContext`, báo lỗi:  
  ```
  Caused by: org.springframework.beans.BeanInstantiationException: Failed to instantiate [org.springframework.data.elasticsearch.client.ClientConfiguration]: Factory method 'clientConfiguration' threw exception with message: java.io.EOFException\n\tat org.springframework.beans.factory.support.SimpleInstantiationStrategy.instantiate(SimpleInstantiationStrategy.java:171)\n\tat org.springframework.beans.factory.support.ConstructorResolver.instantiate(ConstructorResolver.java:650)\n\t... 95 common frames omitted\nCaused by: java.lang.RuntimeException: java.io.EOFException\n\tat ReactiveElasticsearchConfiguration.buildSSLContext(ReactiveElasticsearchConfiguration.java:97)
  ```

- 1 số Java app đòi file .p12 phải có password, nếu ko sẽ báo lỗi:  
  ```
  tat io.netty.handler.ssl.SslHandler.decodeJdkCompatible(SslHandler.java:1329)\n\tat io.netty.handler.ssl.SslHandler.decode(SslHandler.java:1378)\n\tat io.netty.handler.codec.ByteToMessageDecoder.decodeRemovalReentryProtection(ByteToMessageDecoder.java:529)\n\tat io.netty.handler.codec.ByteToMessageDecoder.callDecode(ByteToMessageDecoder.java:468)\n\t... 15 common frames omitted\nCaused by: java.security.InvalidAlgorithmParameterException: the trustAnchors parameter must be non-empty
  ```

- 1 số Java app đòi file .p12 được rồi thì lại đòi ES phải là phiên bản tương thích (ví dụ 7.3.2 thì báo lỗi, nhưng 7.17.22 thì OK):  
  ```
  java.base/java.lang.Thread.run(Unknown Source)\nCaused by: org.elasticsearch.ElasticsearchException: Elasticsearch exception [type=exception, reason=Content-Type header [application/vnd.elasticsearch+json;compatible-with=7] is not supported]
  ```

## 4.6. Thử cách tạo mới file .p12 từ trong container ElasticSearch

### 4.6.1. Không dùng file elastic-stack-ca.p12 khi gen cert

SSH vào container để gen cert p12, Dùng command Dùng command `bin/elasticsearch-certutil cert --silent --in ./instance.yml --out ./certs.zip` để sinh ra `certs.zip`:
```s
$ docker exec -it elasticsearch /bin/bash
[root@e314d10e8eed elasticsearch]# ll
total 556
-rw-r--r--  1 elasticsearch root  13675 Sep  6  2019 LICENSE.txt
-rw-r--r--  1 elasticsearch root 502598 Sep  6  2019 NOTICE.txt
-rw-r--r--  1 elasticsearch root   8500 Sep  6  2019 README.textile
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 bin
drwxrwxr-x  1 elasticsearch root   4096 Jul 18 15:14 config
drwxrwxr-x  3 elasticsearch root   4096 Jul 17 14:16 data
drwxr-xr-x  1 elasticsearch root   4096 Sep  6  2019 jdk
drwxr-xr-x  3 elasticsearch root   4096 Sep  6  2019 lib
drwxrwxr-x  1 elasticsearch root   4096 Jul 18 15:14 logs
drwxr-xr-x 33 elasticsearch root   4096 Sep  6  2019 modules
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 plugins
[root@e314d10e8eed elasticsearch]# vi instance.yml
[root@e314d10e8eed elasticsearch]# vi instance.yml
[root@e314d10e8eed elasticsearch]# ll
total 560
-rw-r--r--  1 elasticsearch root  13675 Sep  6  2019 LICENSE.txt
-rw-r--r--  1 elasticsearch root 502598 Sep  6  2019 NOTICE.txt
-rw-r--r--  1 elasticsearch root   8500 Sep  6  2019 README.textile
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 bin
drwxrwxr-x  1 elasticsearch root   4096 Jul 18 15:14 config
drwxrwxr-x  3 elasticsearch root   4096 Jul 17 14:16 data
-rw-r--r--  1 root          root    116 Jul 18 15:54 instance.yml
drwxr-xr-x  1 elasticsearch root   4096 Sep  6  2019 jdk
drwxr-xr-x  3 elasticsearch root   4096 Sep  6  2019 lib
drwxrwxr-x  1 elasticsearch root   4096 Jul 18 15:14 logs
drwxr-xr-x 33 elasticsearch root   4096 Sep  6  2019 modules
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 plugins

[root@e314d10e8eed elasticsearch]# cat instance.yml
instances:
  name: 'node'
  dns: ['localhost', 'es.internal.ABC.net']
  ip: ['127.0.0.1', '10.10.13.26']


[root@e314d10e8eed elasticsearch]# bin/elasticsearch-certutil cert --silent --in instance.yml --out certs.zip
WARNING: An illegal reflective access operation has occurred
WARNING: Illegal reflective access by org.bouncycastle.jcajce.provider.drbg.DRBG (file:/usr/share/elasticsearch/lib/tools/security-cli/bcprov-jdk15on-1.61.jar) to constructor sun.security.provider.Sun()
WARNING: Please consider reporting this to the maintainers of org.bouncycastle.jcajce.provider.drbg.DRBG
WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
WARNING: All illegal access operations will be denied in a future release
Enter password for node/node.p12 :
[root@e314d10e8eed elasticsearch]#
[root@e314d10e8eed elasticsearch]# ll
total 564
-rw-r--r--  1 elasticsearch root  13675 Sep  6  2019 LICENSE.txt
-rw-r--r--  1 elasticsearch root 502598 Sep  6  2019 NOTICE.txt
-rw-r--r--  1 elasticsearch root   8500 Sep  6  2019 README.textile
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 bin
-rw-------  1 root          root   3727 Jul 18 15:55 certs.zip
drwxrwxr-x  1 elasticsearch root   4096 Jul 18 15:14 config
drwxrwxr-x  3 elasticsearch root   4096 Jul 17 14:16 data
-rw-r--r--  1 root          root    116 Jul 18 15:54 instance.yml
drwxr-xr-x  1 elasticsearch root   4096 Sep  6  2019 jdk
drwxr-xr-x  3 elasticsearch root   4096 Sep  6  2019 lib
drwxrwxr-x  1 elasticsearch root   4096 Jul 18 15:14 logs
drwxr-xr-x 33 elasticsearch root   4096 Sep  6  2019 modules
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 plugins
```

Copy file `certs.zip` ra ngoài, rồi unzip

```sh
s$ unzip certs.zip
Archive:  certs.zip
   creating: node/
  inflating: node/node.p12
```

Cấu trúc sau khi unzip:

```
/opt/test/datadrive$ tree .
.
├── docker-compose-es.yml
├── elasticsearch
│   ├── data
│   └── es-certs
│       ├── unzip-certs
│       │   ├── certs.zip
│       │   └── node
│       │       └── node.p12
└── instance.yml
```


Sửa file `docker-compose-es.yml`:
```yml
version: "3.4"

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.3.2
    container_name: elasticsearch
    restart: always
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    environment:
      discovery.type: single-node
      bootstrap.memory_lock: "true"
      TAKE_FILE_OWNERSHIP: "true"
      ELASTIC_PASSWORD: "12345678"
      xpack.license.self_generated.type: trial
      # xpack.security.enabled: "false"
      xpack.security.enabled: "true"
      xpack.security.http.ssl.enabled: "true"
      xpack.security.http.ssl.keystore.type: PKCS12
      xpack.security.http.ssl.keystore.path: /usr/share/elasticsearch/config/certs/node.p12
      xpack.security.http.ssl.keystore.password: ""
      xpack.security.http.ssl.truststore.path: /usr/share/elasticsearch/config/certs/node.p12
      xpack.security.http.ssl.truststore.password: ""
      xpack.security.http.ssl.client_authentication: required
      xpack.security.transport.ssl.verification_mode: certificate
      xpack.security.transport.ssl.enabled: "true"
      xpack.security.transport.ssl.keystore.type: PKCS12
      xpack.security.transport.ssl.keystore.path: /usr/share/elasticsearch/config/certs/node.p12
      xpack.security.transport.ssl.keystore.password: ""
      xpack.security.transport.ssl.truststore.path: /usr/share/elasticsearch/config/certs/node.p12
      xpack.security.transport.ssl.truststore.password: ""
      xpack.security.transport.ssl.client_authentication: required
    ports:
      - 9200:9200
      - 9300:9300
    volumes:
      - /opt/test/datadrive/elasticsearch/data:/usr/share/elasticsearch/data
      - /opt/test/datadrive/elasticsearch/es-certs/unzip-certs/node/node.p12:/usr/share/elasticsearch/config/certs/node.p12
```

Vẫn bị lỗi khi curl:

```s
# Lỗi
$ curl --cert-type P12 --cert ./node.p12 https://localhost:9200
curl: (60) SSL certificate problem: self signed certificate in certificate chain
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.

# Lỗi
$ curl --cacert ./node.p12 https://localhost:9200
curl: (77) error setting certificate verify locations:
  CAfile: ./node.p12
  CApath: /etc/ssl/certs
```

### 4.6.2. Có dùng file elastic-stack-ca.p12 khi gen cert

Thử làm giống command trong này: https://www.elastic.co/guide/en/elasticsearch/reference/current/certutil.html.

Dùng command `bin/elasticsearch-certutil cert --silent --in ./instance.yml --out ./certs.zip --ca ./elastic-stack-ca.p12` để sinh ra `certs.zip`:

```s
[root@0ba8072c316c elasticsearch]# bin/elasticsearch-certutil ca
WARNING: An illegal reflective access operation has occurred
WARNING: Illegal reflective access by org.bouncycastle.jcajce.provider.drbg.DRBG (file:/usr/share/elasticsearch/lib/tools/security-cli/bcprov-jdk15on-1.61.jar) to constructor sun.security.provider.Sun()
WARNING: Please consider reporting this to the maintainers of org.bouncycastle.jcajce.provider.drbg.DRBG
WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
WARNING: All illegal access operations will be denied in a future release
This tool assists you in the generation of X.509 certificates and certificate
signing requests for use with SSL/TLS in the Elastic stack.

The 'ca' mode generates a new 'certificate authority'
This will create a new X.509 certificate and private key that can be used
to sign certificate when running in 'cert' mode.

Use the 'ca-dn' option if you wish to configure the 'distinguished name'
of the certificate authority

By default the 'ca' mode produces a single PKCS#12 output file which holds:
    * The CA certificate
    * The CA's private key'

If you elect to generate PEM format certificates (the -pem option), then the output will
be a zip file containing individual files for the CA certificate and private key

Please enter the desired output file [elastic-stack-ca.p12]:
Enter password for elastic-stack-ca.p12 :
[root@0ba8072c316c elasticsearch]#
[root@0ba8072c316c elasticsearch]# ll
total 564
-rw-r--r--  1 elasticsearch root  13675 Sep  6  2019 LICENSE.txt
-rw-r--r--  1 elasticsearch root 502598 Sep  6  2019 NOTICE.txt
-rw-r--r--  1 elasticsearch root   8500 Sep  6  2019 README.textile
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 bin
drwxrwxr-x  1 elasticsearch root   4096 Jul 22 02:54 config
drwxrwxr-x  3 elasticsearch root   4096 Jul 17 14:16 data
-rw-------  1 root          root   2527 Jul 22 02:56 elastic-stack-ca.p12
-rw-r--r--  1 root          root    116 Jul 22 02:55 instance.yml
drwxr-xr-x  1 elasticsearch root   4096 Sep  6  2019 jdk
drwxr-xr-x  3 elasticsearch root   4096 Sep  6  2019 lib
drwxrwxr-x  1 elasticsearch root   4096 Jul 22 02:54 logs
drwxr-xr-x 33 elasticsearch root   4096 Sep  6  2019 modules
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 plugins
[root@0ba8072c316c elasticsearch]# cat instance.yml
instances:
  name: 'node'
  dns: ['localhost', 'es.internal.ABC.net']
  ip: ['127.0.0.1', '10.10.13.26']

[root@0ba8072c316c elasticsearch]# bin/elasticsearch-certutil cert --silent --in ./instance.yml --out ./certs.zip --ca ./elastic-stack-ca.p12
WARNING: An illegal reflective access operation has occurred
WARNING: Illegal reflective access by org.bouncycastle.jcajce.provider.drbg.DRBG (file:/usr/share/elasticsearch/lib/tools/security-cli/bcprov-jdk15on-1.61.jar) to constructor sun.security.provider.Sun()
WARNING: Please consider reporting this to the maintainers of org.bouncycastle.jcajce.provider.drbg.DRBG
WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
WARNING: All illegal access operations will be denied in a future release
Enter password for CA (elastic-stack-ca.p12) :
Enter password for node/node.p12 :
[root@0ba8072c316c elasticsearch]#
[root@0ba8072c316c elasticsearch]# ll
total 568
-rw-r--r--  1 elasticsearch root  13675 Sep  6  2019 LICENSE.txt
-rw-r--r--  1 elasticsearch root 502598 Sep  6  2019 NOTICE.txt
-rw-r--r--  1 elasticsearch root   8500 Sep  6  2019 README.textile
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 bin
-rw-------  1 root          root   3729 Jul 22 02:57 certs.zip
drwxrwxr-x  1 elasticsearch root   4096 Jul 22 02:54 config
drwxrwxr-x  3 elasticsearch root   4096 Jul 17 14:16 data
-rw-------  1 root          root   2527 Jul 22 02:56 elastic-stack-ca.p12
-rw-r--r--  1 root          root    116 Jul 22 02:55 instance.yml
drwxr-xr-x  1 elasticsearch root   4096 Sep  6  2019 jdk
drwxr-xr-x  3 elasticsearch root   4096 Sep  6  2019 lib
drwxrwxr-x  1 elasticsearch root   4096 Jul 22 02:54 logs
drwxr-xr-x 33 elasticsearch root   4096 Sep  6  2019 modules
drwxr-xr-x  2 elasticsearch root   4096 Sep  6  2019 plugins
```

Vẫn bị lỗi khi curl:

```s
# Nếu là cert cho localhost
# Lỗi
$ curl --cert-type P12 --cert ./node.p12 https://localhost:9200
curl: (60) SSL certificate problem: self signed certificate in certificate chain
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.

# Lỗi
$ curl -v --cert-type P12 --cert ./node.p12 https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Request CERT (13):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS alert, unknown CA (560):
* SSL certificate problem: self signed certificate in certificate chain
* Closing connection 0
curl: (60) SSL certificate problem: self signed certificate in certificate chain
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.

# Lỗi
$ curl --cacert ./node.p12 https://localhost:9200
curl: (77) error setting certificate verify locations:
  CAfile: ./node.p12
  CApath: /etc/ssl/certs

# Lỗi
$ curl -v --cacert ./node.p12 https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* error setting certificate verify locations:
  CAfile: ./node.p12
  CApath: /etc/ssl/certs
* Closing connection 0
curl: (77) error setting certificate verify locations:
  CAfile: ./node.p12
  CApath: /etc/ssl/certs

```

Thử export file `node.p12` thành file .crt để dùng trong curl command:

```s
$ ll
total 12
drwxrwxr-x 2 deploy deploy 4096 Jul 18 16:29 ./
drwxrwxr-x 3 deploy deploy 4096 Jul 18 16:30 ../
-rw-rw-r-- 1 deploy deploy 3451 Jul 18 16:29 node.p12

$ openssl pkcs12 -in ./node.p12 -clcerts -nokeys -out node.crt

$ ll
total 16
drwxrwxr-x 2 deploy deploy 4096 Jul 18 16:45 ./
drwxrwxr-x 3 deploy deploy 4096 Jul 18 16:30 ../
-rw------- 1 deploy deploy 1363 Jul 18 16:45 node.crt
-rw-rw-r-- 1 deploy deploy 3451 Jul 18 16:29 node.p12

# Nếu là cert cho localhost
# Lỗi
$ curl --cacert ./node.crt https://localhost:9200
curl: (56) OpenSSL SSL_read: error:14094412:SSL routines:ssl3_read_bytes:sslv3 alert bad certificate, errno 0

# Lỗi
$ curl -v --cacert ./node.crt https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: ./node.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Request CERT (13):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server did not agree to a protocol
* Server certificate:
*  subject: CN=node
*  start date: Jul 18 16:29:21 2024 GMT
*  expire date: Jul 18 16:29:21 2027 GMT
*  subjectAltName: host "localhost" matched cert''s "localhost"
*  issuer: CN=Elastic Certificate Tool Autogenerated CA
*  SSL certificate verify ok.
> GET / HTTP/1.1
> Host: localhost:9200
> User-Agent: curl/7.68.0
> Accept: */*
>
* TLSv1.3 (IN), TLS alert, bad certificate (554):
* OpenSSL SSL_read: error:14094412:SSL routines:ssl3_read_bytes:sslv3 alert bad certificate, errno 0
* Closing connection 0
curl: (56) OpenSSL SSL_read: error:14094412:SSL routines:ssl3_read_bytes:sslv3 alert bad certificate, errno 0
```

Có vẻ nó lấy được `host "localhost" matched` nhưng vẫn lỗi `alert bad certificate`. Ko hiểu?

Thử export file `node.p12` thành file .pem bằng command khác:

```s
$ openssl pkcs12 -in node.p12 -out node.key.pem -nocerts -nodes
$ openssl pkcs12 -in node.p12 -out node.crt.pem -clcerts -nokeys

# Lỗi
$ curl -E ./node.crt.pem --key ./node.key.pem https://localhost:9200
curl: (60) SSL certificate problem: self signed certificate in certificate chain
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.

# Lỗi
$ curl -v -E ./node.crt.pem --key ./node.key.pem https://localhost:9200
*   Trying 127.0.0.1:9200...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 9200 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Request CERT (13):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS alert, unknown CA (560):
* SSL certificate problem: self signed certificate in certificate chain
* Closing connection 0
curl: (60) SSL certificate problem: self signed certificate in certificate chain
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

### 4.6.3. Tổng kết

Như vậy để enable SSL/TLS cho ElasticSearch thì ko nên tạo file .p12

Hoặc là do mình dùng version ES cũ 7.3.2, chưa thử các version cao hơn.

# 5. Kafka - Enable SSL/TLS

Có 1 tutorial khá hoàn chỉnh nhưng chưa thử:

https://www.slingacademy.com/article/how-to-configure-ssl-tls-in-kafka/


# REFERENCES

Kafka:  
https://medium.com/@amberkakkar01/getting-started-with-apache-kafka-on-docker-a-step-by-step-guide-48e71e241cf2  
https://www.slingacademy.com/article/how-to-use-kafka-with-docker-and-docker-compose/  
https://howtodoinjava.com/kafka/kafka-cluster-setup-using-docker-compose/  
https://kifarunix.com/configure-apache-kafka-ssl-tls-encryption/  
https://www.slingacademy.com/article/how-to-configure-ssl-tls-in-kafka/  
 
Data Stax Cassandra:  
https://github.com/datastax/docker-images/blob/master/README.md  
https://github.com/datastax/docker-images  
https://docs.datastax.com/en/docker/managing/mount-data-volumes.html  
https://docs.datastax.com/en/dse/6.8/installing/docker.html  

ElasticSearch:  
https://discuss.elastic.co/t/elasticsearch-certutil-generate-both-pem-certificates-and-pkcs-12-keystores/255486  
https://discuss.elastic.co/t/curl-against-an-encrypted-elasticsearch-instance-with-certificate-verification/251503  
https://www.elastic.co/blog/configuring-ssl-tls-and-https-to-secure-elasticsearch-kibana-beats-and-logstash#preparations  
https://alexmarquardt.com/2018/11/05/security-tls-ssl-pki-authentication-in-elasticsearch/  
https://raphaeldelio.medium.com/how-to-start-a-elasticsearch-docker-container-with-ssl-tls-encryption-c3cf7e00c646  
https://discuss.elastic.co/t/elasticsearch-ssl-certificate-error-javax-crypto-badpaddingexception-given-final-block-not-properly-padded/247783/3  
https://www.elastic.co/guide/en/elasticsearch/reference/current/certutil.html  



