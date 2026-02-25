#!/bin/bash
# Worker node (node04, node05): DN + NM

source /shared/env/profile.sh

# Wait for at least one NN
while ! nc -z node01 8020 2>/dev/null && ! nc -z node02 8020 2>/dev/null; do
  sleep 2
done

# DN
hdfs --daemon start datanode
sleep 3

# NM
yarn --daemon start nodemanager

# Keep container alive
tail -f /dev/null
