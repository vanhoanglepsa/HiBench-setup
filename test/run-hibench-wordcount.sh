#!/bin/bash

# Script to run HiBench-style WordCount benchmark

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 HIBENCH WORDCOUNT BENCHMARK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Paths
HDFS_INPUT="hdfs://namenode:9000/HiBench/Wordcount/Input"
HDFS_OUTPUT="hdfs://namenode:9000/HiBench/Wordcount/Output"
NUM_LINES=50000  # Small scale

echo "1️⃣  Checking containers..."
if ! docker ps | grep -q "spark-master"; then
    echo "❌ Spark Master is not running!"
    exit 1
fi
echo "✅ Containers OK"
echo ""

echo "2️⃣  Generating test data ($NUM_LINES lines)..."
# Generate data and upload directly to HDFS
docker exec namenode bash -c "hdfs dfs -mkdir -p /HiBench/Wordcount/Input" 2>/dev/null || true

python3 test/generate-wordcount-data.py $NUM_LINES | \
    docker exec -i namenode bash -c "hdfs dfs -put -f - /HiBench/Wordcount/Input/data.txt"

echo "✅ Data has been uploaded to HDFS"
echo ""

echo "3️⃣  Checking data on HDFS..."
docker exec namenode hdfs dfs -ls /HiBench/Wordcount/Input/
FILE_SIZE=$(docker exec namenode hdfs dfs -du -h /HiBench/Wordcount/Input/ | awk '{print $1" "$2}')
echo "   📊 Size: $FILE_SIZE"
echo ""

echo "4️⃣  Copying script to container..."
docker cp test/hibench-wordcount.py spark-master:/tmp/
echo "✅ Script is ready"
echo ""

echo "5️⃣  Removing old output (if any)..."
docker exec namenode hdfs dfs -rm -r -f /HiBench/Wordcount/Output 2>/dev/null || true
echo ""

echo "6️⃣  Running WordCount benchmark..."
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

echo "7️⃣  Checking results on HDFS..."
docker exec namenode hdfs dfs -ls /HiBench/Wordcount/Output/
echo ""

echo "🎉 BENCHMARK COMPLETE!"
echo ""
echo "💡 You can:"
echo "   - View Spark UI: http://localhost:8080"
echo "   - View HDFS UI: http://localhost:9870"
echo "   - View results: docker exec namenode hdfs dfs -cat /HiBench/Wordcount/Output/part-*.csv | head -20"
echo ""

