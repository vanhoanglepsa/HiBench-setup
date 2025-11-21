#!/bin/bash

# Script kiểm tra trạng thái hệ thống

echo "📊 Trạng thái containers:"
echo ""
docker-compose ps

echo ""
echo "📈 Resource usage:"
docker stats --no-stream

echo ""
echo "🌐 Web UIs:"
echo "  - Hadoop NameNode: http://localhost:9870"
echo "  - Spark Master:     http://localhost:8080"
echo "  - Spark Worker:     http://localhost:8081"
echo ""

echo "🗂️  HDFS Status:"
docker exec namenode hdfs dfsadmin -report

echo ""
echo "📁 HDFS Directories:"
docker exec namenode hdfs dfs -ls /

