#!/bin/bash
# node02: ZK + JN + NN (Standby) + ZKFC + RM

source /shared/env/profile.sh

# ZK
echo "2" > /opt/zookeeper/data/myid
zkServer.sh start
sleep 5

# Wait for ZK quorum (at least 2 of 3)
while true; do
  ZK_UP=0
  nc -z node01 2181 2>/dev/null && ZK_UP=$((ZK_UP+1))
  nc -z node02 2181 2>/dev/null && ZK_UP=$((ZK_UP+1))
  nc -z node03 2181 2>/dev/null && ZK_UP=$((ZK_UP+1))
  [ $ZK_UP -ge 2 ] && break
  sleep 2
done

# JN
hdfs --daemon start journalnode
sleep 5

# Wait for node01 NN
while ! nc -z node01 8020 2>/dev/null; do
  sleep 2
done

# NN
hdfs --daemon start namenode
sleep 5

# ZKFC
hdfs --daemon start zkfc
sleep 3

# RM
yarn --daemon start resourcemanager

# Keep container alive
tail -f /dev/null
