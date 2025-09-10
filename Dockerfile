FROM ubuntu:22.04

# Cài Java, SSH
RUN apt-get update && \
    apt-get install -y sudo openjdk-11-jdk openssh-server rsync wget curl nano && \
    mkdir /var/run/sshd && \
    rm -rf /var/lib/apt/lists/*

# Cài Hadoop
COPY files/hadoop-3.4.0.tar.gz /tmp/
RUN tar -xzf /tmp/hadoop-3.4.0.tar.gz -C /tmp && \
    mv /tmp/hadoop-3.4.0 /usr/local/hadoop && \
    rm /tmp/hadoop-3.4.0.tar.gz

# Cài Zookeeper
COPY files/apache-zookeeper-3.8.4-bin.tar.gz /tmp/
RUN mkdir -p /usr/local/zookeeper && \
    tar -xzf /tmp/apache-zookeeper-3.8.4-bin.tar.gz -C /usr/local/zookeeper && \
    mv /usr/local/zookeeper/apache-zookeeper-3.8.4-bin /usr/local/zookeeper/bin && \
    rm /tmp/apache-zookeeper-3.8.4-bin.tar.gz

RUN mkdir -p /usr/local/zookeeper/dataDir
COPY ./configs/zookeeper/zoo.cfg /usr/local/zookeeper/bin/conf/zoo.cfg

# Cài Spark
COPY files/spark-3.4.3-bin-hadoop3.tgz /tmp/
RUN tar -xzf /tmp/spark-3.4.3-bin-hadoop3.tgz -C /tmp && \
    mv /tmp/spark-3.4.3-bin-hadoop3 /usr/local/spark && \
    rm /tmp/spark-3.4.3-bin-hadoop3.tgz

RUN mkdir -p /usr/local/spark/conf
COPY ./configs/spark/spark-defaults.conf /usr/local/spark/conf/spark-defaults.conf
COPY ./configs/spark/spark-ha.conf /usr/local/spark/conf/spark-ha.conf

# SSH key (tự trust chính mình để Hadoop start-dfs.sh không bị hỏi password)
RUN ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa && \
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

# Biến môi trường
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:/usr/local/spark/bin:/usr/local/spark/sbin
ENV SPARK_HOME=/usr/local/spark

# Cho phép Hadoop chạy bằng root
ENV HDFS_NAMENODE_USER=root
ENV HDFS_DATANODE_USER=root
ENV HDFS_SECONDARYNAMENODE_USER=root
ENV YARN_RESOURCEMANAGER_USER=root
ENV YARN_NODEMANAGER_USER=root

# Start SSH khi container start
CMD ["/usr/sbin/sshd", "-D"]