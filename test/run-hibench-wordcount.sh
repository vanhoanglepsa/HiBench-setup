#!/bin/bash

# Script chạy HiBench-style WordCount benchmark

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 HIBENCH WORDCOUNT BENCHMARK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Paths
HDFS_INPUT="hdfs://namenode:9000/HiBench/Wordcount/Input"
HDFS_OUTPUT="hdfs://namenode:9000/HiBench/Wordcount/Output"
NUM_LINES=50000  # Small scale

echo "1️⃣  Kiểm tra containers..."
if ! docker ps | grep -q "spark-master"; then
    echo "❌ Spark Master không chạy!"
    exit 1
fi
echo "✅ Containers OK"
echo ""

echo "2️⃣  Tạo dữ liệu test ($NUM_LINES lines)..."
# Generate data và upload trực tiếp lên HDFS
docker exec namenode bash -c "hdfs dfs -mkdir -p /HiBench/Wordcount/Input" 2>/dev/null || true

python3 test/generate-wordcount-data.py $NUM_LINES | \
    docker exec -i namenode bash -c "hdfs dfs -put -f - /HiBench/Wordcount/Input/data.txt"

echo "✅ Dữ liệu đã upload lên HDFS"
echo ""

echo "3️⃣  Kiểm tra dữ liệu trên HDFS..."
docker exec namenode hdfs dfs -ls /HiBench/Wordcount/Input/
FILE_SIZE=$(docker exec namenode hdfs dfs -du -h /HiBench/Wordcount/Input/ | awk '{print $1" "$2}')
echo "   📊 Kích thước: $FILE_SIZE"
echo ""

echo "4️⃣  Copy script vào container..."
docker cp test/hibench-wordcount.py spark-master:/tmp/
echo "✅ Script đã sẵn sàng"
echo ""

echo "5️⃣  Xóa output cũ (nếu có)..."
docker exec namenode hdfs dfs -rm -r -f /HiBench/Wordcount/Output 2>/dev/null || true
echo ""

echo "6️⃣  Chạy WordCount benchmark..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker exec spark-master spark-submit \
    --master spark://spark-master:7077 \
    --deploy-mode client \
    --driver-memory 1g \
    --executor-memory 2g \
    --executor-cores 2 \
    /tmp/hibench-wordcount.py

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "7️⃣  Kiểm tra kết quả trên HDFS..."
docker exec namenode hdfs dfs -ls /HiBench/Wordcount/Output/
echo ""

echo "🎉 BENCHMARK HOÀN TẤT!"
echo ""
echo "💡 Bạn có thể:"
echo "   - Xem Spark UI: http://localhost:8080"
echo "   - Xem HDFS UI: http://localhost:9870"
echo "   - Xem kết quả: docker exec namenode hdfs dfs -cat /HiBench/Wordcount/Output/part-*.csv | head -20"
echo ""

