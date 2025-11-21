# Makefile cho HiBench Hadoop & Spark Setup
# Sử dụng: make <command>

.PHONY: help setup start stop restart status logs clean check build shell-spark shell-hadoop test

# Default target
help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  HiBench Hadoop & Spark Docker Setup"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "📦 Setup Commands:"
	@echo "  make setup        - Khởi tạo và start toàn bộ (lần đầu)"
	@echo "  make start        - Start các containers"
	@echo "  make stop         - Stop các containers"
	@echo "  make restart      - Restart tất cả"
	@echo "  make clean        - Dừng và xóa hết (bao gồm volumes)"
	@echo ""
	@echo "📊 Monitoring:"
	@echo "  make status       - Xem trạng thái containers"
	@echo "  make logs         - Xem logs của tất cả services"
	@echo "  make check        - Kiểm tra health của services"
	@echo ""
	@echo "🔧 Development:"
	@echo "  make shell-spark  - Vào shell của Spark Master"
	@echo "  make shell-hadoop - Vào shell của Hadoop NameNode"
	@echo "  make test         - Chạy test benchmark (WordCount)"
	@echo ""
	@echo "🌐 Web UIs:"
	@echo "  - Hadoop:  http://localhost:9870"
	@echo "  - Spark:   http://localhost:8080"
	@echo "  - Worker:  http://localhost:8081"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Kiểm tra Docker có chạy không
check:
	@echo "🔍 Kiểm tra Docker..."
	@docker info > /dev/null 2>&1 || (echo "❌ Docker chưa chạy!" && exit 1)
	@echo "✅ Docker OK"
	@echo ""
	@echo "🔍 Kiểm tra Docker Compose..."
	@which docker-compose > /dev/null || (echo "❌ Docker Compose chưa cài!" && exit 1)
	@echo "✅ Docker Compose OK"

# Setup ban đầu (build + start + init)
setup: check
	@echo "🚀 Bắt đầu setup HiBench environment..."
	@./scripts/setup.sh

# Build images (nếu cần)
build:
	@echo "🔨 Building Docker images..."
	docker-compose build

# Start containers
start: check
	@echo "▶️  Starting containers..."
	docker-compose up -d
	@echo "✅ Containers started!"
	@echo ""
	@make status

# Stop containers
stop:
	@echo "⏹️  Stopping containers..."
	@./scripts/stop.sh

# Restart tất cả
restart:
	@echo "🔄 Restarting all services..."
	docker-compose restart
	@echo "✅ Services restarted!"

# Xem status
status:
	@./scripts/status.sh

# Xem logs
logs:
	docker-compose logs -f

# Logs của từng service
logs-spark:
	docker-compose logs -f spark-master

logs-hadoop:
	docker-compose logs -f namenode

logs-worker:
	docker-compose logs -f spark-worker

# Vào shell của Spark Master
shell-spark:
	@echo "🐚 Connecting to Spark Master shell..."
	@echo "Tip: HiBench directory: /opt/hibench"
	@echo "Tip: Config files: /hibench/"
	docker exec -it spark-master bash

# Vào shell của Hadoop NameNode
shell-hadoop:
	@echo "🐚 Connecting to Hadoop NameNode shell..."
	docker exec -it namenode bash

# Clean up (xóa hết bao gồm volumes)
clean:
	@echo "🧹 Cleaning up everything..."
	@read -p "⚠️  Xóa tất cả bao gồm dữ liệu HDFS? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		echo "✅ Cleaned!"; \
	else \
		echo "❌ Cancelled"; \
	fi

# Test với WordCount benchmark
test:
	@echo "🧪 Running WordCount benchmark test..."
	docker exec -it spark-master bash -c "cd /opt/hibench && \
		cp /hibench/*.conf conf/ && \
		bin/workloads/micro/wordcount/prepare/prepare.sh && \
		bin/workloads/micro/wordcount/spark/run.sh && \
		cat report/hibench.report"

# Quick test (chỉ check connectivity)
test-quick:
	@echo "⚡ Quick connectivity test..."
	@echo "Testing HDFS..."
	docker exec namenode hdfs dfs -ls /
	@echo ""
	@echo "Testing Spark..."
	docker exec spark-master spark-submit --version

# Init HDFS directories
init-hdfs:
	@echo "📁 Initializing HDFS directories..."
	docker exec namenode bash -c "\
		hdfs dfs -mkdir -p /HiBench && \
		hdfs dfs -mkdir -p /spark-logs && \
		hdfs dfs -mkdir -p /user/root && \
		hdfs dfs -chmod -R 777 /HiBench && \
		hdfs dfs -chmod -R 777 /spark-logs && \
		hdfs dfs -chmod -R 777 /user"
	@echo "✅ HDFS initialized!"

# Xem HDFS
hdfs-ls:
	docker exec namenode hdfs dfs -ls /

# HDFS report
hdfs-report:
	docker exec namenode hdfs dfsadmin -report

# Clean HDFS data (giữ containers)
hdfs-clean:
	@echo "🗑️  Cleaning HiBench data on HDFS..."
	docker exec namenode hdfs dfs -rm -r -f /HiBench/* || true
	@echo "✅ HDFS cleaned!"

