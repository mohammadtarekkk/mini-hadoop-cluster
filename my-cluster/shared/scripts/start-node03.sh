#!/bin/bash
# node03: ZooKeeper + JournalNode + DataNode + NodeManager

source /shared/env/profile.sh

# --- ZooKeeper ---
echo "3" > /opt/zookeeper/data/myid
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

# --- JournalNode ---
hdfs --daemon start journalnode
sleep 3

# Wait for at least one NameNode
while ! nc -z node01 8020 2>/dev/null && ! nc -z node02 8020 2>/dev/null; do
  sleep 2
done

# --- DataNode ---
hdfs --daemon start datanode
sleep 3

# --- NodeManager ---
yarn --daemon start nodemanager

# Keep container alive
tail -f /dev/null
