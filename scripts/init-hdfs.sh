#!/bin/bash

# Script khởi tạo HDFS cho HiBench
# Chạy script này sau khi Hadoop cluster đã khởi động

set -e

echo "🔧 Đang khởi tạo HDFS cho HiBench..."

# Chờ HDFS sẵn sàng
echo "⏳ Chờ HDFS khởi động..."
sleep 10

# Tạo thư mục cho HiBench
echo "📁 Tạo thư mục HiBench trên HDFS..."
hdfs dfs -mkdir -p /HiBench
hdfs dfs -mkdir -p /spark-logs
hdfs dfs -mkdir -p /user/root

# Set permissions
echo "🔒 Thiết lập quyền truy cập..."
hdfs dfs -chmod -R 777 /HiBench
hdfs dfs -chmod -R 777 /spark-logs
hdfs dfs -chmod -R 777 /user

echo "✅ Khởi tạo HDFS hoàn tất!"
echo ""
echo "📊 Kiểm tra HDFS:"
hdfs dfs -ls /

