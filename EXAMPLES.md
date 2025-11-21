# 📚 Ví Dụ Chi Tiết - HiBench Benchmarks

## 🎯 Mục Lục

1. [WordCount - Text Processing](#1-wordcount---text-processing)
2. [TeraSort - Sorting](#2-terasort---sorting)
3. [PageRank - Graph Processing](#3-pagerank---graph-processing)
4. [K-Means - Machine Learning](#4-k-means---machine-learning)
5. [SQL Queries](#5-sql-queries)
6. [Tùy Chỉnh Config](#6-tùy-chỉnh-config)

---

## 1. WordCount - Text Processing

### Mô tả
Đếm số lần xuất hiện của mỗi từ trong một tập dữ liệu text lớn.

### Chạy Benchmark

```bash
# Vào container
make shell-spark

# Trong container
cd /opt/hibench
cp /hibench/*.conf conf/

# Prepare data (tạo ~500MB text data)
bin/workloads/micro/wordcount/prepare/prepare.sh

# Run Spark job
bin/workloads/micro/wordcount/spark/run.sh

# Xem kết quả
cat report/hibench.report
```

### Kiểm tra dữ liệu trên HDFS

```bash
# Xem input data
hdfs dfs -ls /HiBench/Wordcount/Input

# Xem output
hdfs dfs -ls /HiBench/Wordcount/Output

# Đọc một phần output
hdfs dfs -cat /HiBench/Wordcount/Output/part-00000 | head -20
```

### Tùy chỉnh kích thước data

Chỉnh file `conf/hibench.conf`:

```properties
hibench.wordcount.datasize  1GB    # Thay đổi từ 500MB
```

---

## 2. TeraSort - Sorting

### Mô tả
Sort một lượng lớn dữ liệu (100-byte records), benchmark phổ biến cho Hadoop/Spark.

### Chạy Benchmark

```bash
cd /opt/hibench

# Prepare (tạo random data để sort)
bin/workloads/micro/terasort/prepare/prepare.sh

# Run sort
bin/workloads/micro/terasort/spark/run.sh

# Verify output đã sorted chưa
bin/workloads/micro/terasort/verify/verify.sh
```

### Scale lên

```bash
# Chỉnh trong conf/hibench.conf
hibench.terasort.datasize  5GB    # Thay đổi scale
```

---

## 3. PageRank - Graph Processing

### Mô tả
Tính PageRank score cho graph (mô phỏng web pages và links).

### Chạy Benchmark

```bash
cd /opt/hibench

# Prepare graph data
bin/workloads/websearch/pagerank/prepare/prepare.sh

# Run PageRank (3 iterations)
bin/workloads/websearch/pagerank/spark/run.sh
```

### Tùy chỉnh

```properties
# conf/hibench.conf
hibench.pagerank.pages          100000  # Số lượng pages
hibench.pagerank.numiterations  5       # Số iterations
```

### Xem output

```bash
hdfs dfs -ls /HiBench/Pagerank/Output
hdfs dfs -cat /HiBench/Pagerank/Output/part-00000 | head -10
```

---

## 4. K-Means - Machine Learning

### Mô tả
Clustering algorithm, phân loại data points thành K clusters.

### Chạy Benchmark

```bash
cd /opt/hibench

# Prepare training data
bin/workloads/ml/kmeans/prepare/prepare.sh

# Run K-Means clustering
bin/workloads/ml/kmeans/spark/run.sh
```

### Tùy chỉnh

```properties
# conf/hibench.conf
hibench.kmeans.num_of_clusters     5      # Số clusters
hibench.kmeans.num_of_samples      10000000  # Số samples
hibench.kmeans.dimensions          20     # Số dimensions
hibench.kmeans.max_iteration       10     # Max iterations
```

### Xem model output

```bash
hdfs dfs -ls /HiBench/Kmeans/Output
hdfs dfs -cat /HiBench/Kmeans/Output/part-00000 | head
```

---

## 5. SQL Queries

### Scan Query

```bash
cd /opt/hibench

# Prepare table data
bin/workloads/sql/scan/prepare/prepare.sh

# Run SQL scan query
bin/workloads/sql/scan/spark/run.sh
```

### Join Query

```bash
# Prepare
bin/workloads/sql/join/prepare/prepare.sh

# Run
bin/workloads/sql/join/spark/run.sh
```

### Aggregation Query

```bash
# Prepare
bin/workloads/sql/aggregation/prepare/prepare.sh

# Run
bin/workloads/sql/aggregation/spark/run.sh
```

---

## 6. Tùy Chỉnh Config

### Thay đổi Scale Profile

File: `conf/hibench.conf`

```properties
# Options: tiny, small, large, huge, gigantic, bigdata
hibench.scale.profile   large

# Hoặc tùy chỉnh từng workload:
hibench.wordcount.datasize    5GB
hibench.sort.datasize         10GB
hibench.terasort.datasize     20GB
```

### Tùy chỉnh Spark Resources

File: `conf/spark.conf`

```properties
# Tăng memory
spark.executor.memory           4g
spark.driver.memory             2g

# Tăng cores
spark.executor.cores            4

# Tăng số executors
spark.executor.instances        2
```

### Tùy chỉnh HDFS

File: `conf/hadoop.conf`

```properties
# Tăng replication (nếu có nhiều datanodes)
hibench.hdfs.replication        2

# Thay đổi block size
hibench.default.hdfs.block.size    268435456  # 256MB
```

---

## 📊 So Sánh Kết Quả

### Xem Report

```bash
# Xem tất cả kết quả
cat /opt/hibench/report/hibench.report

# Xem dạng table
column -t -s $'\t' /opt/hibench/report/hibench.report

# Export sang local
docker cp spark-master:/opt/hibench/report/hibench.report ./results.txt
```

### Format Report

Report bao gồm các cột:
- **Type**: Workload type (micro, websearch, ml, sql)
- **Date**: Thời gian chạy
- **Time**: Tổng thời gian (seconds)
- **Input**: Kích thước input data
- **Output**: Kích thước output data
- **Throughput**: MB/s

---

## 🔧 Debug & Troubleshooting

### Xem Spark UI trong khi chạy

Mở browser: http://localhost:4040

### Xem logs chi tiết

```bash
# Trong container
tail -f /opt/spark/logs/*.out

# Hoặc từ host
docker logs -f spark-master
```

### Memory issues

Nếu gặp OOM (Out of Memory):

```properties
# Giảm scale
hibench.scale.profile   tiny

# Hoặc giảm memory footprint
spark.memory.fraction   0.6
spark.memory.storageFraction   0.3
```

### HDFS space issues

```bash
# Xóa dữ liệu cũ
hdfs dfs -rm -r /HiBench/Wordcount
hdfs dfs -rm -r /HiBench/Terasort

# Hoặc xóa tất cả
make hdfs-clean
```

---

## 🚀 Chạy Multiple Benchmarks

### Script tự động

Tạo file `run_all_benchmarks.sh`:

```bash
#!/bin/bash

cd /opt/hibench
cp /hibench/*.conf conf/

BENCHMARKS=(
    "micro/wordcount"
    "micro/sort"
    "micro/terasort"
    "websearch/pagerank"
    "ml/kmeans"
)

for bench in "${BENCHMARKS[@]}"; do
    echo "Running $bench..."
    bin/workloads/$bench/prepare/prepare.sh
    bin/workloads/$bench/spark/run.sh
done

echo "All benchmarks completed!"
cat report/hibench.report
```

Chạy:

```bash
docker exec -it spark-master bash run_all_benchmarks.sh
```

---

## 📈 Performance Tuning Tips

### 1. Optimize Parallelism

```properties
hibench.default.map.parallelism     4
hibench.default.shuffle.parallelism 4
```

### 2. Adjust Spark Configuration

```properties
spark.default.parallelism          8
spark.sql.shuffle.partitions       8
```

### 3. Enable Compression

```properties
spark.shuffle.compress              true
spark.io.compression.codec          snappy
```

### 4. Tune Memory

```properties
spark.executor.memory               4g
spark.driver.memory                 2g
spark.memory.fraction               0.6
```

---

**Happy Benchmarking! 🎯**

