#!/bin/bash

# Script setup môi trường HiBench với Hadoop và Spark

set -e

echo "🚀 Bắt đầu setup môi trường HiBench..."
echo ""

# Kiểm tra Docker
echo "🐳 Kiểm tra Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker chưa được cài đặt. Vui lòng cài Docker Desktop."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker daemon chưa chạy. Vui lòng khởi động Docker Desktop."
    exit 1
fi

echo "✅ Docker đã sẵn sàng"
echo ""

# Kiểm tra Docker Compose
echo "🔧 Kiểm tra Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose chưa được cài đặt."
    exit 1
fi

echo "✅ Docker Compose đã sẵn sàng"
echo ""

# Build và start containers
echo "🔨 Build và khởi động các containers..."
docker-compose up -d

echo ""
echo "⏳ Chờ các services khởi động (60 giây)..."
sleep 60

# Khởi tạo HDFS
echo ""
echo "📁 Khởi tạo HDFS..."
docker exec -it namenode bash -c "
    hdfs dfs -mkdir -p /HiBench
    hdfs dfs -mkdir -p /spark-logs
    hdfs dfs -mkdir -p /user/root
    hdfs dfs -chmod -R 777 /HiBench
    hdfs dfs -chmod -R 777 /spark-logs
    hdfs dfs -chmod -R 777 /user
"

echo ""
echo "✅ Setup hoàn tất!"
echo ""
echo "📊 Các Web UI có thể truy cập:"
echo "  - Hadoop NameNode: http://localhost:9870"
echo "  - Spark Master:     http://localhost:8080"
echo "  - Spark Worker:     http://localhost:8081"
echo "  - Spark App UI:     http://localhost:4040 (khi chạy job)"
echo ""
echo "📝 Để chạy HiBench benchmark, sử dụng:"
echo "   docker exec -it spark-master bash"
echo "   cd /hibench"
echo ""

