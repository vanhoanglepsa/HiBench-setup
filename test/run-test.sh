#!/bin/bash

# Script to test HDFS + Spark integration
# Not related to HiBench

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🧪 TEST HDFS + SPARK INTEGRATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check containers
echo "1️⃣  Checking containers..."
if ! docker ps | grep -q "spark-master"; then
    echo "❌ Spark Master is not running!"
    echo "   Run: make start"
    exit 1
fi

if ! docker ps | grep -q "namenode"; then
    echo "❌ Hadoop NameNode is not running!"
    echo "   Run: make start"
    exit 1
fi

echo "✅ All containers are running"
echo ""

# Create test directory on HDFS
echo "2️⃣  Creating /test/ directory on HDFS..."
docker exec namenode hdfs dfs -mkdir -p /test 2>/dev/null || true
docker exec namenode hdfs dfs -chmod 777 /test
echo "✅ Directory is ready"
echo ""

# Upload test file to HDFS
echo "3️⃣  Uploading test file to HDFS..."
echo "   - File: sample-data.txt"
echo "   - Destination: hdfs://namenode:9000/test/"

# Copy file to container first
docker cp test/sample-data.txt namenode:/tmp/sample-data.txt

# Upload to HDFS
docker exec namenode hdfs dfs -put -f /tmp/sample-data.txt /test/

# Check if file has been uploaded
echo ""
echo "   📁 Checking file on HDFS:"
docker exec namenode hdfs dfs -ls /test/
echo ""

FILE_SIZE=$(docker exec namenode hdfs dfs -du -h /test/sample-data.txt | awk '{print $1" "$2}')
echo "   ✅ File uploaded successfully! (Size: $FILE_SIZE)"
echo ""

# Copy Python script to Spark container
echo "4️⃣  Preparing Spark job..."
docker cp test/test-hdfs-spark.py spark-master:/tmp/test-hdfs-spark.py
echo "✅ Script is ready"
echo ""

# Run Spark job
echo "5️⃣  Running Spark job to read and analyze file..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker exec spark-master spark-submit \
    --master spark://spark-master:7077 \
    --deploy-mode client \
    --driver-memory 1g \
    --executor-memory 2g \
    --executor-cores 2 \
    /tmp/test-hdfs-spark.py

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎉 Test complete!"
echo ""
echo "📊 You can view:"
echo "   - Spark Master UI:  http://localhost:8080"
echo "   - Spark App UI:     http://localhost:4040"
echo "   - Hadoop HDFS UI:   http://localhost:9870"
echo ""
echo "🧹 To clean up test data:"
echo "   docker exec namenode hdfs dfs -rm -r /test"
echo ""

