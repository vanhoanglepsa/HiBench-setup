#!/bin/bash

# Script to initialize HDFS for HiBench
# Run this script after Hadoop cluster has started

set -e

echo "🔧 Initializing HDFS for HiBench..."

# Wait for HDFS to be ready
echo "⏳ Waiting for HDFS to start..."
sleep 10

# Create directories for HiBench
echo "📁 Creating HiBench directories on HDFS..."
hdfs dfs -mkdir -p /HiBench
hdfs dfs -mkdir -p /spark-logs
hdfs dfs -mkdir -p /user/root

# Set permissions
echo "🔒 Setting access permissions..."
hdfs dfs -chmod -R 777 /HiBench
hdfs dfs -chmod -R 777 /spark-logs
hdfs dfs -chmod -R 777 /user

echo "✅ HDFS initialization complete!"
echo ""
echo "📊 Checking HDFS:"
hdfs dfs -ls /

