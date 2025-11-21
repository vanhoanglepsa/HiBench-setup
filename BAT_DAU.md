# 🚀 BẮT ĐẦU - HƯỚNG DẪN SETUP HIBENCH

## ⚡ Setup Nhanh Trong 5 Phút

### Bước 1: Mở Terminal và Chạy Setup

```bash
cd /Users/tranvanhuy/Desktop/Set-up
make setup
```

**Hoặc:**

```bash
cd /Users/tranvanhuy/Desktop/Set-up
./scripts/setup.sh
```

### Bước 2: Chờ ~60 Giây

Script sẽ tự động:
- ✅ Kiểm tra Docker
- ✅ Download và start các containers (Hadoop + Spark)
- ✅ Khởi tạo HDFS
- ✅ In ra các Web UI URLs

### Bước 3: Kiểm Tra

```bash
make status
```

Bạn sẽ thấy 4 containers:
- namenode (Hadoop)
- datanode (Hadoop)
- spark-master (Spark)
- spark-worker (Spark)

---

## 🎯 Chạy Benchmark Đầu Tiên (WordCount)

### Cách 1: Tự Động (Khuyến Nghị)

```bash
make test
```

### Cách 2: Thủ Công

```bash
# Vào Spark Master container
make shell-spark

# Trong container:
cd /opt/hibench
cp /hibench/*.conf conf/

# Chạy WordCount
bin/workloads/micro/wordcount/prepare/prepare.sh
bin/workloads/micro/wordcount/spark/run.sh

# Xem kết quả
cat report/hibench.report
```

---

## 🌐 Truy Cập Web UI

Mở browser:

- **Hadoop**: http://localhost:9870
- **Spark Master**: http://localhost:8080
- **Spark Worker**: http://localhost:8081

---

## 📚 Các Lệnh Thường Dùng

```bash
# Xem trạng thái
make status

# Vào Spark shell
make shell-spark

# Vào Hadoop shell
make shell-hadoop

# Xem logs
make logs

# Restart
make restart

# Dừng
make stop

# Xóa hết (bao gồm data)
make clean
```

---

## 📖 Đọc Thêm

- **Quick Start**: [QUICKSTART.md](QUICKSTART.md) - Hướng dẫn 3 phút
- **Ví Dụ Chi Tiết**: [EXAMPLES.md](EXAMPLES.md) - Các benchmarks khác
- **Khắc Phục Lỗi**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Troubleshooting
- **Hướng Dẫn Đầy Đủ**: [README.md](README.md) - Full documentation

---

## 🆘 Gặp Lỗi?

```bash
# Xem logs
make logs

# Kiểm tra Docker
make check

# Reset hoàn toàn
make clean
make setup
```

**Xem chi tiết**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## ⚙️ Tùy Chỉnh

### Thay Đổi RAM/CPU

File: `docker-compose.yml`

```yaml
spark-worker:
  environment:
    - SPARK_WORKER_CORES=4    # Tăng CPU
    - SPARK_WORKER_MEMORY=4g  # Tăng RAM
```

### Thay Đổi Kích Thước Data

File: `hibench-workspace/hibench.conf`

```properties
hibench.scale.profile   large  # Options: tiny, small, large, huge
```

---

## 🎉 Hoàn Thành!

Bạn đã setup thành công Hadoop + Spark với HiBench!

**Bước tiếp theo:**
1. Chạy thêm benchmarks khác (xem [EXAMPLES.md](EXAMPLES.md))
2. Tùy chỉnh config theo nhu cầu
3. Monitor performance qua Web UI

**Happy Benchmarking! 🚀**

