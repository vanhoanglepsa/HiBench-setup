# 🐛 Troubleshooting Guide

## Các Vấn Đề Thường Gặp và Cách Khắc Phục

---

## 1. Docker Issues

### ❌ Docker Desktop không khởi động

**Triệu chứng:**
```bash
$ make setup
❌ Docker chưa chạy!
```

**Giải pháp:**
1. Mở Docker Desktop từ Applications
2. Đợi Docker Desktop khởi động hoàn toàn (icon không còn loading)
3. Thử lại: `make check`

### ❌ "Cannot connect to Docker daemon"

**Giải pháp:**
```bash
# Restart Docker Desktop
# Hoặc từ terminal:
killall Docker
open -a Docker

# Đợi ~30 giây, sau đó:
docker ps
```

---

## 2. Container Issues

### ❌ Container không start

**Kiểm tra logs:**
```bash
docker-compose logs namenode
docker-compose logs spark-master
```

**Thử restart:**
```bash
make stop
make start
```

**Nếu vẫn lỗi, rebuild:**
```bash
docker-compose down -v
make setup
```

### ❌ Container bị "Exited" status

```bash
# Xem tại sao container exit
docker logs namenode
docker logs datanode

# Thường là do port conflict hoặc config sai
# Xem phần Port Issues bên dưới
```

### ❌ Healthcheck failed

```bash
# Xem chi tiết
docker inspect namenode | grep -A 10 Health

# Restart container
docker-compose restart namenode

# Hoặc thử tăng timeout trong docker-compose.yml:
healthcheck:
  interval: 60s  # Tăng từ 30s
  timeout: 20s   # Tăng từ 10s
```

---

## 3. Port Issues

### ❌ "Port already in use"

**Triệu chứng:**
```
Error: bind: address already in use 0.0.0.0:9870
```

**Kiểm tra port nào đang bị chiếm:**
```bash
lsof -i :9870  # Hadoop NameNode
lsof -i :8080  # Spark Master
lsof -i :7077  # Spark port
lsof -i :9000  # HDFS
```

**Giải pháp 1: Kill process đang chiếm port**
```bash
# Tìm PID
lsof -i :9870

# Kill process
kill -9 <PID>
```

**Giải pháp 2: Đổi port**

Chỉnh `docker-compose.yml`:
```yaml
namenode:
  ports:
    - "9871:9870"  # Đổi port ngoài thành 9871
    - "9001:9000"
```

Sau đó truy cập: http://localhost:9871

---

## 4. HDFS Issues

### ❌ HDFS không accessible

**Kiểm tra:**
```bash
docker exec namenode hdfs dfsadmin -report
```

**Nếu NameNode chưa format:**
```bash
# ⚠️ CÂU LỆNH NÀY SẼ XÓA TẤT CẢ DỮ LIỆU
docker exec namenode hdfs namenode -format

# Restart
docker-compose restart namenode datanode
```

### ❌ "Connection refused" khi truy cập HDFS

**Kiểm tra NameNode có chạy không:**
```bash
docker exec namenode jps
# Phải thấy "NameNode" trong output
```

**Kiểm tra port:**
```bash
docker exec namenode netstat -tuln | grep 9000
docker exec namenode netstat -tuln | grep 9870
```

**Nếu không thấy, restart:**
```bash
docker exec namenode /opt/hadoop/sbin/start-dfs.sh
```

### ❌ "No space left on device"

**Kiểm tra HDFS capacity:**
```bash
make hdfs-report
```

**Xóa dữ liệu cũ:**
```bash
make hdfs-clean

# Hoặc xóa thủ công:
docker exec namenode hdfs dfs -rm -r /HiBench/*
```

**Kiểm tra Docker disk space:**
```bash
docker system df

# Dọn dẹp nếu cần:
docker system prune -a
```

---

## 5. Spark Issues

### ❌ Spark job bị lỗi

**Xem Spark UI:**
- http://localhost:8080 (Master)
- http://localhost:4040 (Application khi đang chạy)

**Xem logs:**
```bash
docker logs spark-master
docker logs spark-worker

# Logs trong container:
docker exec spark-master tail -f /opt/spark/logs/*.out
```

### ❌ "Master not responding"

**Kiểm tra Master có chạy không:**
```bash
docker exec spark-master jps
# Phải thấy "Master"
```

**Restart Spark:**
```bash
docker-compose restart spark-master spark-worker
```

### ❌ Worker không connect được Master

**Kiểm tra network:**
```bash
docker exec spark-worker ping spark-master

# Nếu không ping được:
docker network inspect set-up_hibench-net
```

**Restart worker:**
```bash
docker-compose restart spark-worker
```

---

## 6. HiBench Issues

### ❌ "Command not found" khi chạy HiBench

**Kiểm tra HiBench có được build không:**
```bash
docker exec spark-master ls -la /opt/hibench/bin/workloads/
```

**Nếu không có, rebuild:**
```bash
docker exec spark-master bash -c "
cd /opt/hibench && 
mvn -Phadoopbench -Psparkbench -Dscala=2.12 -Dspark=3.1 clean package
"
```

### ❌ Config file không tìm thấy

**Copy configs:**
```bash
docker exec spark-master bash -c "
cp /hibench/hibench.conf /opt/hibench/conf/
cp /hibench/spark.conf /opt/hibench/conf/
cp /hibench/hadoop.conf /opt/hibench/conf/
"
```

### ❌ "Unable to connect to HDFS"

**Kiểm tra HDFS từ Spark container:**
```bash
docker exec spark-master hdfs dfs -ls /
```

**Nếu lỗi, kiểm tra config:**
```bash
docker exec spark-master cat /opt/hibench/conf/hadoop.conf | grep hdfs.master
# Phải là: hdfs://namenode:9000
```

### ❌ Benchmark chạy chậm hoặc timeout

**Giảm scale:**
```bash
# Chỉnh conf/hibench.conf
hibench.scale.profile   tiny  # Thay vì small
```

**Tăng timeout:**
```bash
# Chỉnh conf/spark.conf
spark.network.timeout           1200s  # Tăng từ 600s
```

---

## 7. Memory Issues

### ❌ "Out of Memory" (OOM)

**Triệu chứng:**
```
java.lang.OutOfMemoryError: Java heap space
```

**Giải pháp 1: Tăng memory cho Docker**

Docker Desktop → Settings → Resources → Memory → 8GB+

**Giải pháp 2: Giảm memory footprint**

Chỉnh `docker-compose.yml`:
```yaml
spark-worker:
  environment:
    - SPARK_WORKER_MEMORY=1g  # Giảm từ 2g
```

Chỉnh `hibench-workspace/spark.conf`:
```properties
spark.executor.memory   1g    # Giảm từ 2g
spark.driver.memory     512m  # Giảm từ 1g
```

**Giải pháp 3: Giảm data size**

Chỉnh `hibench-workspace/hibench.conf`:
```properties
hibench.scale.profile   tiny
hibench.wordcount.datasize  100MB  # Giảm từ 500MB
```

### ❌ Container bị killed (exit code 137)

**Nguyên nhân:** Docker OOM Killer

**Giải pháp:**
1. Tăng memory limit cho Docker Desktop
2. Giảm resource usage như trên
3. Chạy ít containers hơn

---

## 8. Network Issues

### ❌ Containers không ping được nhau

**Kiểm tra network:**
```bash
docker network ls
docker network inspect set-up_hibench-net
```

**Recreate network:**
```bash
docker-compose down
docker network rm set-up_hibench-net
docker-compose up -d
```

### ❌ Không truy cập được Web UI từ host

**Kiểm tra port forwarding:**
```bash
docker-compose ps
# Xem cột PORTS
```

**Thử truy cập:**
```bash
curl http://localhost:9870
curl http://localhost:8080
```

**Nếu không được, restart Docker Desktop**

---

## 9. MacBook M3 Specific Issues

### ❌ "exec format error" hoặc platform issues

**Nguyên nhân:** Image không compatible với ARM64

**Giải pháp:**

Chỉnh `docker-compose.yml`, thêm platform:
```yaml
services:
  namenode:
    platform: linux/amd64  # Hoặc linux/arm64
```

**Hoặc build custom image:**
```bash
docker build --platform linux/arm64 -t custom-hadoop .
```

### ❌ Performance chậm

**Nguyên nhân:** Rosetta 2 translation (nếu dùng amd64 images)

**Giải pháp:** Sử dụng native ARM64 images (đã config sẵn trong setup)

---

## 10. Permission Issues

### ❌ "Permission denied" trong container

**Vào root shell:**
```bash
docker exec -u root -it spark-master bash
```

**Fix permissions:**
```bash
chmod -R 755 /opt/hibench
chown -R root:root /opt/hibench
```

### ❌ HDFS permission denied

**Disable permissions (trong docker setup):**

File `config/hadoop/hdfs-site.xml`:
```xml
<property>
  <name>dfs.permissions.enabled</name>
  <value>false</value>
</property>
```

---

## 🆘 Khi Tất Cả Đều Thất Bại

### Nuclear Option: Reset hoàn toàn

```bash
# 1. Stop và xóa hết
docker-compose down -v

# 2. Xóa tất cả volumes
docker volume prune -f

# 3. Xóa tất cả networks
docker network prune -f

# 4. Xóa images (optional)
docker rmi $(docker images -q "bde2020/*")

# 5. Setup lại từ đầu
make setup
```

### Kiểm tra system

```bash
# Docker version
docker --version
docker-compose --version

# Docker resources
docker info | grep -E "CPUs|Memory"

# MacOS version
sw_vers
```

---

## 📞 Nhận Trợ Giúp

### Collect logs để debug

```bash
# Export tất cả logs
docker-compose logs > debug_logs.txt

# Check containers
docker ps -a >> debug_logs.txt

# Check networks
docker network ls >> debug_logs.txt

# System info
docker info >> debug_logs.txt
```

### Kiểm tra status chi tiết

```bash
make status > status.txt
make check > check.txt
docker-compose ps > containers.txt
```

---

**Gặp vấn đề khác?**
- Xem logs: `make logs`
- Kiểm tra status: `make status`
- Xem HiBench docs: https://github.com/Intel-bigdata/HiBench

**Happy Debugging! 🔧**

