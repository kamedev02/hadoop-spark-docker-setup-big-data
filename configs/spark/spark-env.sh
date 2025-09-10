#!/usr/bin/env bash
export SPARK_HOME=/usr/local/spark
export SPARK_MASTER_HOST=hadoop-master
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=18080
export SPARK_WORKER_CORES=2
export SPARK_WORKER_MEMORY=2g
export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop