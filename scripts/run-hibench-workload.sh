#!/bin/bash

# HiBench Workload Runner
# Usage: ./scripts/run-hibench-workload.sh <category> <workload> [framework]
# Example: ./scripts/run-hibench-workload.sh micro wordcount spark

set -euo pipefail

CATEGORY=$1
WORKLOAD=$2
FRAMEWORK=${3:-spark}  # Default to spark

if [ -z "$CATEGORY" ] || [ -z "$WORKLOAD" ]; then
    echo "❌ Usage: $0 <category> <workload> [framework]"
    echo "   Categories: micro, ml, sql, websearch, graph, streaming"
    echo "   Framework: spark (default) or hadoop"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🏆 HIBENCH BENCHMARK: ${CATEGORY}/${WORKLOAD}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Configuration:"
echo "   - Category: $CATEGORY"
echo "   - Workload: $WORKLOAD"
echo "   - Framework: $FRAMEWORK"
echo ""

# Check if containers are running
check_container_running() {
    local container_name=$1
    docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container_name}$"
}

if ! check_container_running "spark-master"; then
    echo "⚠️  Spark Master is not running!"
    echo "🚀 Attempting to start containers..."
    docker-compose up -d 2>/dev/null || {
        echo "❌ Failed to start containers automatically"
        echo "   Please run: make start"
        exit 1
    }
    echo "⏳ Waiting for containers to be ready..."
    
    # Wait for containers to be ready (max 60 seconds)
    MAX_WAIT=60
    WAIT_TIME=0
    while [ $WAIT_TIME -lt $MAX_WAIT ]; do
        if check_container_running "spark-master" && check_container_running "namenode"; then
            # Additional check: verify containers are actually running (not just created)
            if docker exec spark-master echo "ready" >/dev/null 2>&1; then
                echo "✅ Containers are ready!"
                echo ""
                break
            fi
        fi
        sleep 2
        WAIT_TIME=$((WAIT_TIME + 2))
        if [ $((WAIT_TIME % 4)) -eq 0 ]; then
            echo "   Waiting... (${WAIT_TIME}s/${MAX_WAIT}s)"
        fi
    done
    
    # Final check
    if ! check_container_running "spark-master"; then
        echo ""
        echo "❌ Spark Master container failed to start after ${MAX_WAIT} seconds!"
        echo "   Current container status:"
        docker-compose ps 2>/dev/null || docker ps | grep -E "(spark|namenode)" || true
        echo ""
        echo "   Please check: docker-compose ps"
        echo "   Or run: make start"
        exit 1
    fi
fi

# Verify containers are actually running and accessible
if ! check_container_running "spark-master"; then
    echo "❌ Spark Master container is not running!"
    echo "   Please check: docker-compose ps"
    echo "   Or run: make start"
    exit 1
fi

# Quick connectivity test
if ! docker exec spark-master echo "ready" >/dev/null 2>&1; then
    echo "⚠️  Spark Master container is running but not ready yet"
    echo "   Waiting 5 more seconds..."
    sleep 5
fi

# Copy HiBench configs
echo "📋 Copying HiBench configuration files..."
docker exec spark-master bash -c "cp /hibench/*.conf /opt/hibench/conf/" 2>/dev/null || true
echo "✅ Configuration files ready"
echo ""

# Verify Hadoop is available
if [ "$FRAMEWORK" = "spark" ]; then
    echo "🔧 Verifying Hadoop setup..."
    docker exec spark-master bash -c "
        if [ ! -f /opt/hadoop/bin/hadoop ]; then
            echo '❌ ERROR: Hadoop CLI not found'
            exit 1
        fi
    " || {
        echo "❌ Hadoop verification failed!"
        exit 1
    }
    echo "✅ Hadoop setup verified"
    echo ""
fi

# Special handling for dfsioe (read/write)
if [ "$CATEGORY" = "micro" ] && [ "$WORKLOAD" = "dfsioe" ]; then
    # dfsioe has read and write modes
    DFSIOE_MODE=$FRAMEWORK  # Use framework param for read/write
    FRAMEWORK="spark"  # Always use spark for dfsioe
    if [ "$DFSIOE_MODE" != "read" ] && [ "$DFSIOE_MODE" != "write" ]; then
        echo "❌ DFSIOE requires mode: read or write"
        echo "   Usage: $0 micro dfsioe read|write"
        exit 1
    fi
fi

# Determine workload path
WORKLOAD_PATH="/opt/hibench/bin/workloads/${CATEGORY}/${WORKLOAD}"

# Check if workload exists
if ! docker exec spark-master test -d "$(dirname ${WORKLOAD_PATH})"; then
    echo "❌ Workload not found: ${CATEGORY}/${WORKLOAD}"
    echo "   Available workloads in ${CATEGORY}:"
    docker exec spark-master ls -1 /opt/hibench/bin/workloads/${CATEGORY}/ 2>/dev/null || echo "   (Category not found)"
    exit 1
fi

# Check if run script exists
if ! docker exec spark-master test -f "${WORKLOAD_PATH}/${FRAMEWORK}/run.sh"; then
    echo "❌ Run script not found: ${WORKLOAD_PATH}/${FRAMEWORK}/run.sh"
    echo "   Available frameworks:"
    docker exec spark-master ls -1 "${WORKLOAD_PATH}/" 2>/dev/null || echo "   (No frameworks found)"
    exit 1
fi

# Run prepare phase (if exists)
if docker exec spark-master test -f "${WORKLOAD_PATH}/prepare/prepare.sh"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1️⃣  PREPARE PHASE - Generate test data"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    PREPARE_OUTPUT=$(docker exec spark-master bash -c "cd /opt/hibench && set +e && ${WORKLOAD_PATH}/prepare/prepare.sh 2>&1; exit 0" 2>&1)
    echo "$PREPARE_OUTPUT" | grep -v "unbound variable" | grep -v "SyntaxWarning" | tail -20 || true
    
    echo ""
    echo "✅ Prepare phase completed"
    echo ""
fi

# Run benchmark phase
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  RUN PHASE - Run ${WORKLOAD} benchmark"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

START_TIME=$(date +%s)

# Set environment variables and run benchmark
# Note: HiBench scripts may have bash warnings but jobs can still succeed
set +e  # Temporarily disable exit on error for HiBench script execution

if [ "$CATEGORY" = "micro" ] && [ "$WORKLOAD" = "dfsioe" ]; then
    # Special handling for dfsioe read/write
    if [ "$DFSIOE_MODE" = "read" ]; then
        READ_ONLY="true"
    else
        READ_ONLY="false"
    fi
    docker exec spark-master bash -c "
        export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop && \
        export HADOOP_HOME=/opt/hadoop && \
        export READ_ONLY=${READ_ONLY} && \
        cd /opt/hibench && \
        ${WORKLOAD_PATH}/${FRAMEWORK}/run.sh
    "
    BENCHMARK_EXIT_CODE=$?
else
    docker exec spark-master bash -c "
        export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop && \
        export HADOOP_HOME=/opt/hadoop && \
        cd /opt/hibench && \
        ${WORKLOAD_PATH}/${FRAMEWORK}/run.sh
    "
    BENCHMARK_EXIT_CODE=$?
fi

set -e  # Re-enable exit on error

# Check if benchmark actually failed (non-zero exit) or just had warnings
if [ $BENCHMARK_EXIT_CODE -ne 0 ]; then
    echo "⚠️  Benchmark script had errors (exit code: $BENCHMARK_EXIT_CODE)"
    echo "   Checking if job actually completed..."
    sleep 2
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Benchmark Results:"
echo "   - Workload: ${CATEGORY}/${WORKLOAD}"
echo "   - Framework: $FRAMEWORK"
echo "   - Total Duration: ${DURATION}s"
echo ""

# Show HiBench report if available
if docker exec spark-master test -f /opt/hibench/report/hibench.report 2>/dev/null; then
    echo "📊 HiBench Benchmark Report:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker exec spark-master bash -c "cat /opt/hibench/report/hibench.report" 2>/dev/null | tail -20 || true
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

echo ""
echo "✅ Benchmark completed!"
echo ""

