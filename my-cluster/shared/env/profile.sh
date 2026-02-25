# this will be copied to /etc/profile.d/hadoop.sh on every node
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export HADOOP_COMMON_HOME=/opt/hadoop
export HADOOP_HDFS_HOME=/opt/hadoop
export HADOOP_YARN_HOME=/opt/hadoop
export HADOOP_MAPRED_HOME=/opt/hadoop
export ZOOKEEPER_HOME=/opt/zookeeper
export PATH=$PATH:/opt/hadoop/bin:/opt/hadoop/sbin:/opt/zookeeper/bin
