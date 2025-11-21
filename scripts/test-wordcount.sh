#!/bin/bash

# Script test nhanh WordCount benchmark
# Chạy script này để verify setup hoạt động đúng

set -e

echo "🧪 Running WordCount Benchmark Test..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Kiểm tra container có chạy không
echo "1️⃣  Checking containers..."
if ! docker ps | grep -q "spark-master"; then
    echo "❌ Spark Master container not running!"
    echo "Run: make start"
    exit 1
fi

if ! docker ps | grep -q "namenode"; then
    echo "❌ Hadoop NameNode container not running!"
    echo "Run: make start"
    exit 1
fi

echo "✅ Containers are running"
echo ""

# Copy configs
echo "2️⃣  Copying HiBench configs..."
docker exec spark-master bash -c "cp /hibench/*.conf /opt/hibench/conf/" 2>/dev/null || true
echo "✅ Configs copied"
echo ""

# Prepare data
echo "3️⃣  Preparing WordCount data..."
echo "   (This may take 2-3 minutes...)"
docker exec spark-master bash -c "cd /opt/hibench && bin/workloads/micro/wordcount/prepare/prepare.sh"
echo "✅ Data prepared"
echo ""

# Run benchmark
echo "4️⃣  Running WordCount benchmark..."
echo "   (This may take 1-2 minutes...)"
docker exec spark-master bash -c "cd /opt/hibench && bin/workloads/micro/wordcount/spark/run.sh"
echo "✅ Benchmark completed"
echo ""

# Show results
echo "5️⃣  Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker exec spark-master bash -c "cat /opt/hibench/report/hibench.report" | tail -5
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "✅ Test completed successfully!"
echo ""
echo "💡 View detailed results:"
echo "   docker exec spark-master cat /opt/hibench/report/hibench.report"
echo ""
echo "🌐 Check Spark UI: http://localhost:8080"
echo ""

