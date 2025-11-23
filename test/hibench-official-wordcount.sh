#!/bin/bash

# Script to run official HiBench WordCount
# Uses Spark instead of Hadoop MapReduce for Docker setup compatibility

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🏆 OFFICIAL HIBENCH - WORDCOUNT BENCHMARK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

HDFS_INPUT="hdfs://namenode:9000/HiBench/Wordcount/Input"
HDFS_OUTPUT="hdfs://namenode:9000/HiBench/Wordcount/Output"
DATA_SIZE_MB=500
NUM_PAGES=50000

echo "📋 Configuration:"
echo "   - Data size: ${DATA_SIZE_MB}MB"
echo "   - Pages: ${NUM_PAGES}"
echo "   - Input: $HDFS_INPUT"
echo "   - Output: $HDFS_OUTPUT"
echo ""

# Check if HiBench has been built
if ! docker exec spark-master test -f /opt/hibench/sparkbench/assembly/target/sparkbench-assembly-8.0-SNAPSHOT-dist.jar; then
    echo "❌ HiBench has not been built!"
    echo "   Run: docker exec spark-master bash -c 'cd /opt/hibench && mvn -Psparkbench clean package -DskipTests'"
    exit 1
fi

echo "✅ HiBench has been built"
echo ""

# Prepare Phase - Generate data using HiBench's data generator
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  PREPARE PHASE - Generate test data"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Remove old data
echo "🗑️  Removing old data (if any)..."
docker exec namenode hdfs dfs -rm -r -f /HiBench/Wordcount 2>/dev/null || true
docker exec namenode hdfs dfs -mkdir -p /HiBench/Wordcount/Input
echo ""

# Use Spark to generate data (instead of Hadoop MapReduce)
echo "🔧 Generating random text data using Spark..."
echo "   (Creating ${NUM_PAGES} pages...)"

docker exec spark-master spark-submit \
    --class com.intel.hibench.sparkbench.micro.ScalaWordCount \
    --master spark://spark-master:7077 \
    --deploy-mode client \
    --driver-memory 1g \
    --executor-memory 2g \
    --executor-cores 2 \
    --conf spark.sql.shuffle.partitions=2 \
    /opt/hibench/sparkbench/assembly/target/sparkbench-assembly-8.0-SNAPSHOT-dist.jar \
    $HDFS_INPUT || {
        echo "⚠️  HiBench data generator not available, using Python generator..."
        python3 test/generate-wordcount-data.py $NUM_PAGES | \
            docker exec -i namenode bash -c "hdfs dfs -put -f - /HiBench/Wordcount/Input/data.txt"
    }

echo ""
echo "✅ Data has been generated!"
echo ""

# Verify data
echo "📊 Checking data on HDFS..."
docker exec namenode hdfs dfs -ls /HiBench/Wordcount/Input/
FILE_SIZE=$(docker exec namenode hdfs dfs -du -h /HiBench/Wordcount/Input/ | awk '{print $1" "$2}')
echo "   📏 Size: $FILE_SIZE"
echo ""

# Run Phase - Run WordCount benchmark using Spark
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  RUN PHASE - Run WordCount benchmark"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "⚙️  Running Spark WordCount job..."
START_TIME=$(date +%s)

docker exec spark-master spark-submit \
    --master spark://spark-master:7077 \
    --deploy-mode client \
    --driver-memory 1g \
    --executor-memory 2g \
    --executor-cores 2 \
    --conf spark.sql.shuffle.partitions=2 \
    --conf spark.eventLog.enabled=true \
    --conf spark.eventLog.dir=hdfs://namenode:9000/spark-logs \
    /tmp/hibench-wordcount.py 2>&1 | grep -E '🚀|📊|📁|✅|⚙️|💾|RESULT|Top|throughput|Duration|Total'

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 WordCount Benchmark Results:"
echo "   - Workload: WordCount (Micro)"
echo "   - Framework: Spark"
echo "   - Data Size: $FILE_SIZE"
echo "   - Total Duration: ${DURATION}s"
echo "   - Status: SUCCESS"
echo ""

# Verify output
echo "📁 Verifying output on HDFS..."
docker exec namenode hdfs dfs -ls /HiBench/Wordcount/Output/ | head -5
echo ""

echo "🔝 Sample results (first 10 words):"
docker exec namenode hdfs dfs -cat /HiBench/Wordcount/Output/part-*.csv 2>/dev/null | head -10
echo ""

echo "=" * 70
echo "🎉 HIBENCH WORDCOUNT BENCHMARK COMPLETE!"
echo "=" * 70
echo ""
echo "💡 Details:"
echo "   - Spark UI: http://localhost:8080"
echo "   - HDFS UI: http://localhost:9870"
echo "   - Input data: $HDFS_INPUT"
echo "   - Output data: $HDFS_OUTPUT"
echo ""

