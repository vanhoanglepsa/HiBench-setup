# 📁 Project Structure

## Cấu Trúc Thư Mục

```
Set-up/
│
├── 📄 README.md                    # Hướng dẫn đầy đủ
├── 📄 QUICKSTART.md                # Hướng dẫn nhanh 3 phút
├── 📄 EXAMPLES.md                  # Ví dụ chi tiết các benchmarks
├── 📄 TROUBLESHOOTING.md           # Guide khắc phục lỗi
├── 📄 CHANGELOG.md                 # Lịch sử thay đổi
├── 📄 PROJECT_STRUCTURE.md         # File này
├── 📄 LICENSE                      # Apache License 2.0
│
├── 🐳 docker-compose.yml           # Docker orchestration chính
├── 🐳 Dockerfile                   # Custom Docker image (optional)
├── 🐳 .dockerignore                # Ignore files cho Docker build
│
├── 📝 Makefile                     # Automation commands
├── 🙈 .gitignore                   # Git ignore patterns
│
├── 📁 config/                      # Các file cấu hình
│   ├── 📁 hadoop/
│   │   ├── core-site.xml          # Hadoop core configuration
│   │   └── hdfs-site.xml          # HDFS configuration
│   └── 📁 spark/
│       ├── spark-defaults.conf    # Spark default settings
│       └── spark-env.sh           # Spark environment variables
│
├── 📁 scripts/                     # Automation scripts
│   ├── setup.sh                   # ⭐ Setup ban đầu (main entry point)
│   ├── stop.sh                    # Dừng tất cả services
│   ├── status.sh                  # Kiểm tra trạng thái
│   ├── init-hdfs.sh               # Khởi tạo HDFS directories
│   └── test-wordcount.sh          # Test nhanh WordCount
│
├── 📁 hibench-workspace/           # HiBench configurations
│   ├── hibench.conf               # Main HiBench config
│   ├── spark.conf                 # Spark-specific config
│   └── hadoop.conf                # Hadoop-specific config
│
└── 📁 data/                        # Data directory (mounted to containers)
    └── .gitkeep                   # Keep directory in git
```

---

## 📋 Chi Tiết Từng File

### Root Level Files

#### Documentation Files
- **README.md**: Tài liệu chính, hướng dẫn đầy đủ từ setup đến troubleshooting
- **QUICKSTART.md**: Quick start guide, 3 phút từ zero đến chạy benchmark đầu tiên
- **EXAMPLES.md**: Các ví dụ chi tiết, cách chạy từng loại benchmark
- **TROUBLESHOOTING.md**: Danh sách các lỗi thường gặp và cách fix
- **CHANGELOG.md**: Lịch sử versions và features
- **PROJECT_STRUCTURE.md**: File này, giải thích cấu trúc project

#### Configuration Files
- **docker-compose.yml**: 
  - Định nghĩa 4 services: namenode, datanode, spark-master, spark-worker
  - Network configuration: hibench-net
  - Volume mounts: hadoop_namenode, hadoop_datanode
  - Port mappings cho Web UIs
  - Health checks

- **Dockerfile**:
  - Base image: openjdk:8-jdk-slim (ARM64 compatible)
  - Install Hadoop 3.2.4
  - Install Spark 3.1.3
  - Clone và build HiBench
  - Tối ưu cho MacBook M3

- **.dockerignore**: Exclude files không cần thiết khi build Docker image

#### Automation
- **Makefile**: 
  - Commands: setup, start, stop, restart, status, logs
  - Shell access: shell-spark, shell-hadoop
  - Testing: test, test-quick
  - HDFS operations: hdfs-ls, hdfs-report, hdfs-clean
  - Help: `make help`

- **.gitignore**: Git ignore patterns cho logs, data, IDE files

- **LICENSE**: Apache License 2.0

---

### 📁 config/

Chứa các file cấu hình cho Hadoop và Spark.

#### config/hadoop/
- **core-site.xml**: 
  ```xml
  - fs.defaultFS: hdfs://namenode:9000
  - hadoop.tmp.dir: /tmp/hadoop
  - hadoop.http.staticuser.user: root
  ```

- **hdfs-site.xml**:
  ```xml
  - dfs.replication: 1
  - dfs.permissions.enabled: false (để đơn giản)
  - dfs.webhdfs.enabled: true
  - dfs.namenode.name.dir: /hadoop/dfs/name
  - dfs.datanode.data.dir: /hadoop/dfs/data
  ```

#### config/spark/
- **spark-defaults.conf**:
  ```
  - spark.master: spark://spark-master:7077
  - spark.driver.memory: 1g
  - spark.executor.memory: 2g
  - spark.executor.cores: 2
  - spark.eventLog.enabled: true
  - spark.eventLog.dir: hdfs://namenode:9000/spark-logs
  ```

- **spark-env.sh**:
  ```bash
  - JAVA_HOME, SPARK_MASTER_HOST, SPARK_MASTER_PORT
  - SPARK_WORKER_CORES, SPARK_WORKER_MEMORY
  - HADOOP_CONF_DIR
  ```

---

### 📁 scripts/

Automation scripts để quản lý environment.

- **setup.sh** (⭐ Main entry point):
  ```bash
  1. Check Docker & Docker Compose
  2. docker-compose up -d
  3. Wait 60s for services to start
  4. Initialize HDFS directories
  5. Print Web UI URLs
  ```

- **stop.sh**:
  ```bash
  - Stop all containers: docker-compose down
  - Option to remove volumes: docker-compose down -v
  ```

- **status.sh**:
  ```bash
  - Show container status: docker-compose ps
  - Show resource usage: docker stats
  - Show HDFS status: hdfs dfsadmin -report
  - List Web UI URLs
  ```

- **init-hdfs.sh**:
  ```bash
  - Create HDFS directories: /HiBench, /spark-logs, /user/root
  - Set permissions: chmod 777
  ```

- **test-wordcount.sh**:
  ```bash
  1. Check containers running
  2. Copy HiBench configs
  3. Prepare WordCount data
  4. Run WordCount benchmark
  5. Show results
  ```

---

### 📁 hibench-workspace/

HiBench configuration files, sẽ được mount vào containers.

- **hibench.conf** (Main config):
  ```properties
  - hibench.hadoop.home: /opt/hadoop
  - hibench.spark.home: /opt/spark
  - hibench.hdfs.master: hdfs://namenode:9000
  - hibench.spark.master: spark://spark-master:7077
  - hibench.scale.profile: small
  - Data sizes cho các workloads
  ```

- **spark.conf**:
  ```properties
  - Spark-specific settings
  - Executor/driver memory & cores
  - Serialization, network timeouts
  - Event logging
  ```

- **hadoop.conf**:
  ```properties
  - Hadoop paths
  - HDFS master URL
  - MapReduce settings (nếu dùng)
  - HDFS replication & block size
  ```

---

### 📁 data/

Local data directory, có thể mount vào containers để share data.

- **.gitkeep**: Keep empty directory in git

---

## 🔄 Data Flow

```
User
  │
  ├─> make setup
  │     └─> scripts/setup.sh
  │           └─> docker-compose up -d
  │                 ├─> namenode container
  │                 ├─> datanode container
  │                 ├─> spark-master container
  │                 └─> spark-worker container
  │
  ├─> make shell-spark
  │     └─> docker exec -it spark-master bash
  │
  └─> Run HiBench
        ├─> Read configs from /hibench/*.conf
        ├─> Write data to HDFS (hdfs://namenode:9000/HiBench/)
        ├─> Submit Spark job to spark-master:7077
        ├─> Execute on spark-worker
        └─> Write results to /opt/hibench/report/
```

---

## 🌐 Network Architecture

```
Docker Network: hibench-net (bridge)
│
├─> namenode (9000, 9870)
│     ├─> HDFS storage
│     └─> Web UI: http://localhost:9870
│
├─> datanode
│     └─> HDFS data blocks
│
├─> spark-master (7077, 8080, 4040)
│     ├─> Spark cluster manager
│     ├─> Master UI: http://localhost:8080
│     └─> App UI: http://localhost:4040
│
└─> spark-worker (8081)
      ├─> Execute tasks
      └─> Worker UI: http://localhost:8081
```

---

## 📦 Docker Volumes

```
hadoop_namenode
  └─> /hadoop/dfs/name (HDFS metadata)

hadoop_datanode
  └─> /hadoop/dfs/data (HDFS data blocks)
```

---

## 🚀 Typical Workflow

1. **Setup** (once):
   ```bash
   make setup
   ```

2. **Development**:
   ```bash
   make shell-spark
   cd /opt/hibench
   cp /hibench/*.conf conf/
   ```

3. **Run Benchmark**:
   ```bash
   bin/workloads/micro/wordcount/prepare/prepare.sh
   bin/workloads/micro/wordcount/spark/run.sh
   ```

4. **Check Results**:
   ```bash
   cat report/hibench.report
   # Or Web UI: http://localhost:8080
   ```

5. **Cleanup**:
   ```bash
   make stop
   # or
   make clean  # Remove all data
   ```

---

## 🔧 Customization Points

### Resource Allocation
- **docker-compose.yml**: 
  - `SPARK_WORKER_CORES`
  - `SPARK_WORKER_MEMORY`

### Benchmark Scale
- **hibench-workspace/hibench.conf**:
  - `hibench.scale.profile`
  - Individual workload data sizes

### Spark Tuning
- **hibench-workspace/spark.conf**:
  - Executor/driver memory
  - Parallelism settings
  - Shuffle configuration

### Hadoop Config
- **config/hadoop/*.xml**:
  - HDFS replication
  - Block size
  - Permissions

---

## 📊 Log Locations

### On Host (via docker-compose logs)
```bash
docker-compose logs namenode
docker-compose logs spark-master
```

### Inside Containers
```
/opt/hadoop/logs/        # Hadoop logs
/opt/spark/logs/         # Spark logs
/opt/hibench/report/     # HiBench results
```

---

**Cấu trúc này được thiết kế để:**
- ✅ Dễ hiểu và maintain
- ✅ Tách biệt config và code
- ✅ Automation tối đa
- ✅ Scalable và customizable
- ✅ Production-ready

**Tìm hiểu thêm**: Xem các file .md trong root directory! 📚

