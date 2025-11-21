# ⚡ Quick Start - HiBench trên Docker (MacBook M3)

## Bắt Đầu Trong 3 Phút

### 1️⃣ Khởi Động

```bash
cd /Users/tranvanhuy/Desktop/Set-up

# Sử dụng Makefile (khuyến nghị)
make setup

# HOẶC sử dụng script trực tiếp
./scripts/setup.sh
```

Chờ ~60 giây để các services khởi động...

### 2️⃣ Kiểm Tra

```bash
make status
```

Bạn sẽ thấy 4 containers đang chạy:
- ✅ namenode
- ✅ datanode  
- ✅ spark-master
- ✅ spark-worker

### 3️⃣ Chạy Benchmark Đầu Tiên

```bash
# Vào Spark Master container
make shell-spark

# Trong container, chạy:
cd /opt/hibench

# Copy configs
cp /hibench/*.conf conf/

# Chạy WordCount (benchmark đơn giản nhất)
bin/workloads/micro/wordcount/prepare/prepare.sh
bin/workloads/micro/wordcount/spark/run.sh

# Xem kết quả
cat report/hibench.report
```

---

## 📊 Truy Cập Web UI

Mở browser và truy cập:

- **Hadoop HDFS**: http://localhost:9870
- **Spark Master**: http://localhost:8080
- **Spark Worker**: http://localhost:8081

---

## 🎯 Các Lệnh Hay Dùng

```bash
# Xem status
make status

# Vào Spark shell
make shell-spark

# Vào Hadoop shell  
make shell-hadoop

# Xem logs
make logs

# Restart tất cả
make restart

# Dừng hệ thống
make stop

# Xóa hết (bao gồm data)
make clean
```

---

## 🧪 Test Nhanh

```bash
# Chạy WordCount test tự động
make test

# Test connectivity
make test-quick

# Xem HDFS
make hdfs-ls

# Clean HDFS data
make hdfs-clean
```

---

## 🚀 Các Benchmark Khác

Sau khi vào container với `make shell-spark`:

```bash
cd /opt/hibench

# TeraSort (Sort lớn)
bin/workloads/micro/terasort/prepare/prepare.sh
bin/workloads/micro/terasort/spark/run.sh

# Sort
bin/workloads/micro/sort/prepare/prepare.sh
bin/workloads/micro/sort/spark/run.sh

# PageRank (Graph processing)
bin/workloads/websearch/pagerank/prepare/prepare.sh
bin/workloads/websearch/pagerank/spark/run.sh

# K-Means (Machine Learning)
bin/workloads/ml/kmeans/prepare/prepare.sh
bin/workloads/ml/kmeans/spark/run.sh

# SQL benchmarks
bin/workloads/sql/scan/prepare/prepare.sh
bin/workloads/sql/scan/spark/run.sh
```

---

## 🐛 Gặp Lỗi?

### Container không start

```bash
# Xem logs
make logs

# Hoặc xem từng service
docker-compose logs namenode
docker-compose logs spark-master
```

### Port bị chiếm

Kiểm tra ports:
```bash
lsof -i :9870  # Hadoop
lsof -i :8080  # Spark
```

Nếu bị chiếm, stop process đó hoặc đổi port trong `docker-compose.yml`

### HDFS lỗi

```bash
# Vào namenode
make shell-hadoop

# Kiểm tra HDFS
hdfs dfsadmin -report
hdfs dfs -ls /

# Nếu cần format lại (XÓA DATA)
hdfs namenode -format
```

### Memory không đủ

Chỉnh trong `docker-compose.yml`:

```yaml
spark-worker:
  environment:
    - SPARK_WORKER_MEMORY=1g  # Giảm từ 2g xuống 1g
```

---

## 📚 Đọc Thêm

- File README.md đầy đủ: [README.md](./README.md)
- HiBench docs: https://github.com/Intel-bigdata/HiBench
- Makefile commands: `make help`

---

**Happy Benchmarking! 🎉**

