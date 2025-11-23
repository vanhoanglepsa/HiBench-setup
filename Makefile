# Makefile for HiBench Hadoop & Spark Setup
# Usage: make <command>

.PHONY: help setup start stop restart status logs clean check build shell-spark shell-hadoop test

# Default target
help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  HiBench Hadoop & Spark Docker Setup"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "📦 Setup Commands:"
	@echo "  make setup        - Initialize and start everything (first time)"
	@echo "  make start        - Start containers"
	@echo "  make stop         - Stop containers"
	@echo "  make restart      - Restart all"
	@echo "  make clean        - Stop and remove everything (including volumes)"
	@echo ""
	@echo "📊 Monitoring:"
	@echo "  make status       - View container status"
	@echo "  make logs         - View logs of all services"
	@echo "  make check        - Check health of services"
	@echo ""
	@echo "🔧 Development:"
	@echo "  make shell-spark  - Enter Spark Master shell"
	@echo "  make shell-hadoop - Enter Hadoop NameNode shell"
	@echo "  make test         - Run benchmark test (WordCount)"
	@echo ""
	@echo "🌐 Web UIs:"
	@echo "  - Hadoop:  http://localhost:9870"
	@echo "  - Spark:   http://localhost:8080"
	@echo "  - Worker:  http://localhost:8081"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if Docker is running
check:
	@echo "🔍 Checking Docker..."
	@docker info > /dev/null 2>&1 || (echo "❌ Docker is not running!" && exit 1)
	@echo "✅ Docker OK"
	@echo ""
	@echo "🔍 Checking Docker Compose..."
	@which docker-compose > /dev/null || (echo "❌ Docker Compose is not installed!" && exit 1)
	@echo "✅ Docker Compose OK"

# Initial setup (build + start + init)
setup: check
	@echo "🚀 Starting HiBench environment setup..."
	@./scripts/setup.sh

# Build images (if needed)
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

# Restart all
restart:
	@echo "🔄 Restarting all services..."
	docker-compose restart
	@echo "✅ Services restarted!"

# View status
status:
	@./scripts/status.sh

# View logs
logs:
	docker-compose logs -f

# Logs for each service
logs-spark:
	docker-compose logs -f spark-master

logs-hadoop:
	docker-compose logs -f namenode

logs-worker:
	docker-compose logs -f spark-worker

# Enter Spark Master shell
shell-spark:
	@echo "🐚 Connecting to Spark Master shell..."
	@echo "Tip: HiBench directory: /opt/hibench"
	@echo "Tip: Config files: /hibench/"
	docker exec -it spark-master bash

# Enter Hadoop NameNode shell
shell-hadoop:
	@echo "🐚 Connecting to Hadoop NameNode shell..."
	docker exec -it namenode bash

# Clean up (remove everything including volumes)
clean:
	@echo "🧹 Cleaning up everything..."
	@read -p "⚠️  Remove everything including HDFS data? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		echo "✅ Cleaned!"; \
	else \
		echo "❌ Cancelled"; \
	fi

# Test with WordCount benchmark (Official HiBench)
test:
	@echo "🧪 Running Official HiBench WordCount benchmark test..."
	@bash test/hibench-official-wordcount.sh

# Quick test (only check connectivity)
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

# View HDFS
hdfs-ls:
	docker exec namenode hdfs dfs -ls /

# HDFS report
hdfs-report:
	docker exec namenode hdfs dfsadmin -report

# Clean HDFS data (keep containers)
hdfs-clean:
	@echo "🗑️  Cleaning HiBench data on HDFS..."
	docker exec namenode hdfs dfs -rm -r -f /HiBench/* || true
	@echo "✅ HDFS cleaned!"

