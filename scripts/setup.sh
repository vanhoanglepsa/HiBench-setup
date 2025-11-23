#!/bin/bash

# Script to setup HiBench environment with Hadoop and Spark

set -e

echo "🚀 Starting HiBench environment setup..."
echo ""

# Check Docker
echo "🐳 Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker daemon is not running. Please start Docker Desktop."
    exit 1
fi

echo "✅ Docker is ready"
echo ""

# Check Docker Compose
echo "🔧 Checking Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed."
    exit 1
fi

echo "✅ Docker Compose is ready"
echo ""

# Build and start containers
echo "🔨 Building and starting containers..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to start (60 seconds)..."
sleep 60

# Initialize HDFS
echo ""
echo "📁 Initializing HDFS..."
docker exec -it namenode bash -c "
    hdfs dfs -mkdir -p /HiBench
    hdfs dfs -mkdir -p /spark-logs
    hdfs dfs -mkdir -p /user/root
    hdfs dfs -chmod -R 777 /HiBench
    hdfs dfs -chmod -R 777 /spark-logs
    hdfs dfs -chmod -R 777 /user
"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📊 Web UIs available:"
echo "  - Hadoop NameNode: http://localhost:9870"
echo "  - Spark Master:     http://localhost:8080"
echo "  - Spark Worker:     http://localhost:8081"
echo "  - Spark App UI:     http://localhost:4040 (when running jobs)"
echo ""
echo "📝 To run HiBench benchmark, use:"
echo "   docker exec -it spark-master bash"
echo "   cd /hibench"
echo ""

