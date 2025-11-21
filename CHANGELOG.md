# Changelog

All notable changes to this HiBench Docker Setup will be documented here.

## [1.0.0] - 2025-11-21

### ✨ Initial Release

#### Added
- **Docker Setup** cho Hadoop và Spark
  - Hadoop 3.2.1 (NameNode + DataNode)
  - Spark 3.1.1 (Master + Worker)
  - Docker Compose orchestration
  - ARM64 support cho MacBook M3

- **HiBench Configuration**
  - Pre-configured settings cho micro benchmarks
  - Spark và Hadoop configs
  - Scale profiles (tiny, small, large)
  - HDFS integration

- **Automation Scripts**
  - `setup.sh` - Khởi tạo toàn bộ environment
  - `stop.sh` - Dừng services
  - `status.sh` - Kiểm tra trạng thái
  - `init-hdfs.sh` - Khởi tạo HDFS directories
  - `test-wordcount.sh` - Test nhanh WordCount benchmark

- **Makefile Commands**
  - `make setup` - Setup ban đầu
  - `make start/stop/restart` - Quản lý containers
  - `make status` - Xem trạng thái
  - `make logs` - Xem logs
  - `make shell-spark` - Vào Spark shell
  - `make shell-hadoop` - Vào Hadoop shell
  - `make test` - Chạy WordCount test
  - `make clean` - Cleanup hoàn toàn

- **Documentation**
  - `README.md` - Hướng dẫn đầy đủ
  - `QUICKSTART.md` - Hướng dẫn nhanh 3 phút
  - `EXAMPLES.md` - Ví dụ chi tiết các benchmarks
  - `TROUBLESHOOTING.md` - Guide khắc phục lỗi
  - `CHANGELOG.md` - File này

- **Configuration Files**
  - Hadoop configs (core-site.xml, hdfs-site.xml)
  - Spark configs (spark-defaults.conf, spark-env.sh)
  - HiBench configs (hibench.conf, spark.conf, hadoop.conf)
  - Docker configs (docker-compose.yml, Dockerfile, .dockerignore)
  - `.gitignore` cho version control

- **Web UI Access**
  - Hadoop NameNode: http://localhost:9870
  - Spark Master: http://localhost:8080
  - Spark Worker: http://localhost:8081
  - Spark App UI: http://localhost:4040

#### Features
- ✅ One-command setup
- ✅ ARM64 optimized cho Apple Silicon (M1/M2/M3)
- ✅ Pre-configured HiBench workloads
- ✅ HDFS persistent storage với Docker volumes
- ✅ Resource customization
- ✅ Health checks cho tất cả services
- ✅ Comprehensive documentation
- ✅ Easy debugging tools

#### Supported Benchmarks
- **Micro Benchmarks**: WordCount, Sort, TeraSort
- **Web Search**: PageRank
- **Machine Learning**: K-Means
- **SQL**: Scan, Join, Aggregation

#### System Requirements
- MacBook M3 (hoặc Apple Silicon khác)
- Docker Desktop
- 8GB+ RAM recommended
- 20GB disk space

---

## Future Roadmap

### [1.1.0] - Planned
- [ ] Add YARN support
- [ ] More ML benchmarks (Bayes, LR)
- [ ] Graph benchmarks (Connected Components)
- [ ] Custom benchmark templates
- [ ] Performance comparison tools
- [ ] Auto-scaling workers

### [1.2.0] - Planned
- [ ] Kubernetes deployment option
- [ ] Monitoring stack (Prometheus + Grafana)
- [ ] CI/CD pipeline
- [ ] Cloud deployment scripts (AWS, GCP, Azure)

---

**Maintained by**: Setup Team  
**License**: Based on HiBench (Apache 2.0)

