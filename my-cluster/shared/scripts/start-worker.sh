#!/bin/bash
# Worker node (node04, node05): DataNode + NodeManager

source /shared/env/profile.sh

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
