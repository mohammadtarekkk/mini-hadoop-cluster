# Mini Hadoop HA Cluster

A 5-node Hadoop High Availability cluster running on Docker with **automatic service startup**. Uses committed Docker images with pre-installed software and startup scripts that bring all services up automatically on `docker-compose up`.

## Cluster Architecture

| Node | HDFS | YARN | Coordination |
|------|------|------|-------------|
| **node01** | NameNode (Active) | ResourceManager | ZooKeeper, JournalNode, ZKFC |
| **node02** | NameNode (Standby) | ResourceManager | ZooKeeper, JournalNode, ZKFC |
| **node03** | DataNode | NodeManager | ZooKeeper, JournalNode |
| **node04** | DataNode | NodeManager | — |
| **node05** | DataNode | NodeManager | — |

## Project Structure

```
my-cluster/
├── docker-compose.yml          ← Orchestrates 5 nodes with auto-start
└── shared/                     ← Mounted volume (shared across all nodes)
    ├── config/                 ← Hadoop configuration files
    │   ├── core-site.xml
    │   ├── hdfs-site.xml
    │   ├── yarn-site.xml
    │   ├── mapred-site.xml
    │   └── workers
    ├── env/                    ← Environment variable files
    │   ├── profile.sh          ← Shell profile (auto-loaded on login)
    │   ├── hadoop-env-append.sh← Hadoop daemon user settings
    │   └── zoo.cfg             ← ZooKeeper configuration
    ├── scripts/                ← Per-node startup scripts
    │   ├── start-node01.sh     ← ZK → JN → NN → ZKFC → RM
    │   ├── start-node02.sh     ← ZK → JN → wait node01 → NN → ZKFC → RM
    │   ├── start-node03.sh     ← ZK → JN → wait NN → DN → NM
    │   └── start-worker.sh     ← wait NN → DN → NM
    └── data/                   ← Shared data directory
```

## Prerequisites

- Docker & Docker Compose
- Committed Docker images (see [Initial Setup](#initial-setup) below)

## Quick Start

If images are already committed:

```bash
docker-compose up -d
```

Wait ~2 minutes. All services start automatically. Verify:

```bash
docker exec -it node01 bash
hdfs haadmin -getAllServiceState
yarn rmadmin -getAllServiceState
```

## Lifecycle Commands

| Action | Command | Effect |
|--------|---------|--------|
| **Start cluster** | `docker-compose up -d` | Creates containers, scripts auto-start all services |
| **Stop cluster** | `docker-compose down` | Destroys containers (images are safe) |
| **Restart cluster** | `down` then `up -d` | Fresh start from committed images |

## Web UIs

| Service | URL |
|---------|-----|
| HDFS NameNode (Active) | http://localhost:9871 |
| HDFS NameNode (Standby) | http://localhost:9872 |
| YARN ResourceManager 1 | http://localhost:8081 |
| YARN ResourceManager 2 | http://localhost:8082 |
| JournalNode 1/2/3 | http://localhost:8481 / :8482 / :8483 |


## Configuration Files

Located in `shared/config/`:

| File | Purpose |
|------|---------|
| `core-site.xml` | HA nameservice URI + ZooKeeper quorum |
| `hdfs-site.xml` | HDFS HA with QJM, fencing, auto-failover, replication=1 |
| `yarn-site.xml` | YARN HA with two ResourceManagers + ZK failover |
| `mapred-site.xml` | MapReduce on YARN with classpath |
| `workers` | DataNode/NodeManager hosts (node03, node04, node05) |

## Making Changes

| Change | What to do |
|--------|-----------|
| Startup scripts | Edit in `shared/scripts/` on Windows, `down/up` |
| Hadoop configs | Edit in `shared/config/`, add copy command to scripts, `down/up` |
| New software | Install in container → `docker commit` → `down/up` |

## Initial Setup

> Only needed once to create the committed images.

### 1. Start bare containers
```bash
# Use ubuntu:24.04 image with sleep infinity (original docker-compose)
docker-compose up -d
```

### 2. Install Java (on all 5 nodes)
```bash
docker exec -it node01 bash
apt update && apt install -y openjdk-17-jdk netcat-openbsd nano net-tools
```

### 3. Install Hadoop (on all 5 nodes)
```bash
tar -xzf /shared/hadoop-3.4.2.tar.gz -C /opt
mv /opt/hadoop-3.4.2 /opt/hadoop
mkdir -p /opt/hadoop/dfs/name /opt/hadoop/dfs/data /opt/hadoop/dfs/journal /opt/hadoop/logs
cp /shared/config/* /opt/hadoop/etc/hadoop/
cat /shared/env/hadoop-env-append.sh >> /opt/hadoop/etc/hadoop/hadoop-env.sh
cp /shared/env/profile.sh /etc/profile.d/hadoop.sh
echo 'source /etc/profile.d/hadoop.sh' >> /etc/bash.bashrc
```

### 4. Install ZooKeeper (on node01, node02, node03 only)
```bash
tar -xzf /shared/apache-zookeeper-3.8.6-bin.tar.gz -C /opt
mv /opt/apache-zookeeper-3.8.6-bin /opt/zookeeper
mkdir -p /opt/zookeeper/data
cp /shared/env/zoo.cfg /opt/zookeeper/conf/zoo.cfg
echo "1" > /opt/zookeeper/data/myid    # 2 on node02, 3 on node03
```

### 5. First-time format
```bash
# Start ZK + JN on node01/02/03, then:
docker exec node01 bash -c "source /etc/profile.d/hadoop.sh && echo 'Y' | hdfs namenode -format -clusterID mycluster"
docker exec node01 bash -c "source /etc/profile.d/hadoop.sh && echo 'Y' | hdfs zkfc -formatZK"
docker exec node01 bash -c "source /etc/profile.d/hadoop.sh && hdfs --daemon start namenode"
docker exec node02 bash -c "source /etc/profile.d/hadoop.sh && echo 'Y' | hdfs namenode -bootstrapStandby"
```

### 6. Commit images
```bash
docker commit node01 hadoop-node01:latest
docker commit node02 hadoop-node02:latest
docker commit node03 hadoop-node03:latest
docker commit node04 hadoop-worker:latest
```

### 7. Switch to final docker-compose and test
```bash
docker-compose down
docker-compose up -d
```

## Technologies

- **Hadoop** 3.4.2
- **ZooKeeper** 3.8.6
- **Docker** + Docker Compose
- **Ubuntu** 24.04
- **Java** 17 (OpenJDK)
