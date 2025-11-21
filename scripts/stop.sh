#!/bin/bash

# Script dừng và dọn dẹp môi trường

set -e

echo "🛑 Đang dừng các containers..."
docker-compose down

echo ""
echo "🧹 Dọn dẹp hoàn tất!"
echo ""
echo "💡 Để xóa hoàn toàn volumes (dữ liệu HDFS), chạy:"
echo "   docker-compose down -v"
echo ""

