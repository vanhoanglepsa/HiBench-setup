# Dockerfile cho HiBench với Hadoop và Spark
# Tối ưu cho MacBook M3 (ARM64)

FROM --platform=linux/arm64/v8 openjdk:8-jdk-slim

LABEL maintainer="HiBench Setup"
LABEL description="Hadoop + Spark environment for HiBench benchmarking"

# Environment Variables
ENV HADOOP_VERSION=3.2.4
ENV SPARK_VERSION=3.1.3
ENV SCALA_VERSION=2.12
ENV HIBENCH_VERSION=master

ENV HADOOP_HOME=/opt/hadoop
ENV SPARK_HOME=/opt/spark
ENV HIBENCH_HOME=/opt/hibench
ENV JAVA_HOME=/usr/local/openjdk-8

ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    maven \
    ssh \
    rsync \
    vim \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Download and install Hadoop
RUN wget -q https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt/ && \
    mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    rm hadoop-${HADOOP_VERSION}.tar.gz

# Download and install Spark
RUN wget -q https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.2.tgz && \
    tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.2.tgz -C /opt/ && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop3.2 ${SPARK_HOME} && \
    rm spark-${SPARK_VERSION}-bin-hadoop3.2.tgz

# Setup SSH for Hadoop
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

# Create necessary directories
RUN mkdir -p ${HADOOP_HOME}/logs \
    ${SPARK_HOME}/logs \
    /data \
    /tmp/hadoop

# Clone and build HiBench
RUN git clone https://github.com/Intel-bigdata/HiBench.git ${HIBENCH_HOME}

WORKDIR ${HIBENCH_HOME}

# Build HiBench (chỉ build Hadoop và Spark workloads)
RUN mvn -Phadoopbench -Psparkbench -Dscala=${SCALA_VERSION} -Dspark=${SPARK_VERSION} clean package

# Expose ports
# Hadoop: 9000 (HDFS), 9870 (NameNode UI), 8088 (ResourceManager UI)
# Spark: 7077 (Master), 8080 (Master UI), 4040 (Application UI), 8081 (Worker UI)
EXPOSE 9000 9870 8088 7077 8080 4040 8081

# Default command
CMD ["/bin/bash"]

