# Triển khai Hadoop và Spark trên Docker

## 1. Chuẩn bị file cấu hình (Xem thêm tại [Phụ lục](#5-phụ-lục))

Đảm bảo bạn đã có đầy đủ các thư mục và file cấu hình như trong cấu trúc dưới đây. Nếu chưa, hãy thêm/tạo chúng.
> Lưu ý: Tên file `slaves` có thể thay thế bằng `workers` tùy theo phiên bản Hadoop. Trong ví dụ này, chúng ta sử dụng cả hai để đảm bảo tương thích.

```plaintext
.
├── Dockerfile
├── docker-compose.yml
├── README.md
├── configs
│   ├── hadoop
│   │   ├── core-site.xml
│   │   ├── hdfs-site.xml
│   │   ├── yarn-site.xml
│   │   ├── hadoop-env.sh
│   │   ├── workers
│   │   └── slaves
│   ├── spark
│   │   ├── spark-defaults.conf
│   │   ├── spark-env.sh
│   │   └── spark-ha.conf
│   └── zookeeper
│       └── zoo.cfg
└── files
    ├── apache-zookeeper-3.8.4-bin.tar.gz
    ├── hadoop-3.4.0.tar.gz
    └── spark-3.4.3-bin-hadoop3.tgz
```

## 2. Build và khởi chạy

Mở terminal tại thư mục chứa file `docker-compose.yml` và chạy lệnh sau:

```bash
docker-compose up --build -d
```

- `--build`: Lệnh này sẽ build lại image từ `Dockerfile` nếu có thay đổi.
- `-d`: Chạy các container ở chế độ nền (detached mode).

Kiểm tra trạng thái các container:

```bash
docker-compose ps
```

Bạn sẽ thấy `hadoop-master`, `hadoop-slave1`, `hadoop-slave2` và `hadoop-slave3` đang chạy.

## 3. Khởi chạy các dịch vụ Hadoop và Spark

### 3.1. Truy cập container master

Sử dụng lệnh sau để truy cập vào terminal của `hadoop-master`:

```bash
docker exec -it hadoop-master bash
```

### 3.2: Format HDFS namenode

Chỉ thực hiện lệnh này **lần đầu tiên** khi khởi tạo cụm.

```bash
hdfs namenode -format
```

### 3.3: Khởi chạy Hadoop

Dùng các script có sẵn để khởi chạy HDFS và YARN.

```bash
# Khởi động HDFS (Hệ thống file phân tán)
start-dfs.sh

# Khởi động YARN (Quản lý tài nguyên)
start-yarn.sh

# Kiểm tra NameNode, SecondaryNameNode, ResourceManager, Jps
jps
```

> Sau khi khởi động, xem giao diện: \
Hadoop: [http://hadoop-master:9870](http://localhost:9870) \
Yarn: [http://hadoop-master:8088](http://localhost:8088)

### 3.4: Khởi chạy Spark

Cấu hình Spark Master và Workers để chúng có thể tìm thấy nhau.

**Tạo file** `spark-env.sh` tại `./configs/spark/spark-env.sh` nếu chưa có. File này giúp các workers biết **Master** ở đâu.

```bash
# spark-env.sh
export SPARK_MASTER_HOST=hadoop-master
export SPARK_MASTER_PORT=7077
export SPARK_WORKER_CORES=2
export SPARK_WORKER_MEMORY=2g
export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop
```

Sau đó, trong terminal của `hadoop-master`, chạy các lệnh sau:

```bash
# Khởi Chạy Zookeeper
/usr/local/zookeeper/bin/bin/zkServer.sh start

# Khởi động Spark Master
start-master.sh -h 0.0.0.0 -p 7077 --webui-port 18080 --properties-file /usr/local/spark/conf/spark-ha.conf
```

Tiếp theo, trong terminal của các datanode: `hadoop-slave1`, `hadoop-slave2`, `hadoop-slave3` chạy các lệnh sau:

```bash
# Truy cập vào terminal của datanode (lần lượt từ slave1 đến slave3)
docker exec -it hadoop-slave1 bash

# Khởi động Spark Workers
start-worker.sh spark://hadoop-master:7077
```

## 4. Kiểm tra và vận hành

**Kiểm tra các tiến trình Java:** Dùng lệnh `jps` trong terminal của master và slaves để xem các tiến trình `NameNode`, `DataNode`, `ResourceManager`, `NodeManager`, `Master` và `Worker` đã chạy chưa.

> Giao diện web: \
HDFS NameNode UI: [http://hadoop-master:9870](http://localhost:9870) \
YARN UI: [http://hadoop-master:8088](http://localhost:8088) \
Spark Master UI: [http://localhost:18080](http://localhost:18080)

Trên trang Spark UI, bạn sẽ thấy danh sách các workers đang hoạt động.

## 5. Phụ lục

### 5.1. Download files

> Hadoop: [hadoop-3.4.0.tar.gz](https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz) | [backup_url](https://media.githubusercontent.com/media/kamedev02/hadoop-spark-docker-setup-big-data/refs/heads/main/files/hadoop-3.4.0.tar.gz?download=true) \
Spark: [spark-3.4.3-bin-hadoop3.tgz](https://archive.apache.org/dist/spark/spark-3.4.3/spark-3.4.3-bin-hadoop3.tgz) | [backup_url](https://media.githubusercontent.com/media/kamedev02/hadoop-spark-docker-setup-big-data/refs/heads/main/files/spark-3.4.3-bin-hadoop3.tgz?download=true) \
Zookeeper: [apache-zookeeper-3.8.4-bin.tar.gz](https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz)

### 5.2. Nội dung các file cấu hình

#### `/configs/hadoop/core-site.xml`

```xml
<?xml version="1.0"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://hadoop-master:9000</value>
    </property>
    <property>
        <name>hadoop.proxyuser.root.groups</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.proxyuser.root.hosts</name>
        <value>*</value>
    </property>
</configuration>
```

#### `/configs/hadoop/hdfs-site.xml`

```xml
<?xml version="1.0"?>
<configuration>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:///root/hdfs/namenode</value>
        <description>NameNode directory for namespace and transaction logs storage.</description>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:///root/hdfs/datanode</value>
        <description>DataNode directory</description>
    </property>
    <property>
        <name>dfs.replication</name>
        <value>2</value>
    </property>
</configuration>
```

#### `/configs/hadoop/yarn-site.xml`

```xml
<?xml version="1.0"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>hadoop-master</value>
    </property>
    <property>
        <name>yarn.nodemanager.log-dirs</name>
        <value>/usr/local/hadoop/logs/yarn/logs</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>0.0.0.0:8088</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address</name>
        <value>hadoop-master:8032</value>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.address</name>
        <value>hadoop-master:8030</value>
    </property>
</configuration>
```

#### `/configs/hadoop/hadoop-env.sh`

```sh
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-"/etc/hadoop"}
export HADOOP_OPTS="$HADOOP_OPTS -Djava.net.preferIPv4Stack=true"
export HADOOP_NAMENODE_OPTS="-Dhadoop.security.logger=${HADOOP_SECURITY_LOGGER:-INFO,RFAS} -Dhdfs.audit.logger=${HDFS_AUDIT_LOGGER:-INFO,NullAppender} $HADOOP_NAMENODE_OPTS"
export HADOOP_DATANODE_OPTS="-Dhadoop.security.logger=ERROR,RFAS $HADOOP_DATANODE_OPTS"
export HADOOP_SECONDARYNAMENODE_OPTS="-Dhadoop.security.logger=${HADOOP_SECURITY_LOGGER:-INFO,RFAS} -Dhdfs.audit.logger=${HDFS_AUDIT_LOGGER:-INFO,NullAppender} $HADOOP_SECONDARYNAMENODE_OPTS"
export HADOOP_NFS3_OPTS="$HADOOP_NFS3_OPTS"
export HADOOP_PORTMAP_OPTS="-Xmx512m $HADOOP_PORTMAP_OPTS"
export HADOOP_CLIENT_OPTS="-Xmx512m $HADOOP_CLIENT_OPTS"
export HADOOP_SECURE_DN_USER=${HADOOP_SECURE_DN_USER}
export HADOOP_SECURE_DN_LOG_DIR=${HADOOP_LOG_DIR}/${HADOOP_HDFS_USER}
export HADOOP_PID_DIR=${HADOOP_PID_DIR}
export HADOOP_SECURE_DN_PID_DIR=${HADOOP_PID_DIR}
export HADOOP_IDENT_STRING=$USER
export HADOOP_NICENESS=0
```

#### `/configs/hadoop/slaves`

```plaintext
hadoop-slave1
hadoop-slave2
hadoop-slave3
```

#### `/configs/hadoop/workers`

```plaintext
hadoop-slave1
hadoop-slave2
hadoop-slave3
```

> Đối với file slaves và workers thì cần ngắt dòng *LF (Line Feed)* thay vì *CRLF (Carriage Return + Line Feed)*

#### `/configs/spark/spark-defaults.conf`

```conf
spark.master                    spark://hadoop-master:7077
spark.eventLog.enabled          true
spark.eventLog.dir              /usr/local/spark/spark-events
spark.history.fs.logDirectory   /usr/local/spark/spark-events
```

#### `/configs/spark/spark-ha.conf`

```conf
spark.deploy.recoveryMode=ZOOKEEPER
spark.deploy.zookeeper.url=hadoop-master:2181
spark.deploy.zookeeper.dir=/spark
```

> Nếu `spark.deploy.zookeeper.dir=/spark` gây lỗi thì thay bằng `spark.deploy.zookeeper.dir=/usr/local/zookeeper/dataDir`.

#### `/configs/spark/spark-ha.sh`

```sh
#!/usr/bin/env bash
export SPARK_HOME=/usr/local/spark
export SPARK_MASTER_HOST=hadoop-master
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=18080
export SPARK_WORKER_CORES=2
export SPARK_WORKER_MEMORY=2g
export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop
```

#### `/configs/zookeeper/zoo.cfg`

```cfg
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/usr/local/zookeeper/dataDir
clientPort=2181
maxClientCnxns=60000
```
