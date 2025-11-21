#!/usr/bin/env python3
"""
HiBench-style WordCount Benchmark
Chạy WordCount trên Spark với data từ HDFS
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import explode, split, lower, col, count as sql_count
import time
import sys

def main():
    print("=" * 70)
    print("🚀 HIBENCH WORDCOUNT BENCHMARK")
    print("=" * 70)
    print()
    
    # Tạo Spark Session
    print("📊 Khởi tạo Spark Session...")
    spark = SparkSession.builder \
        .appName("HiBench-WordCount") \
        .master("spark://spark-master:7077") \
        .config("spark.driver.memory", "1g") \
        .config("spark.executor.memory", "2g") \
        .config("spark.executor.cores", "2") \
        .getOrCreate()
    
    print("✅ Spark Session sẵn sàng!")
    print(f"   - Version: {spark.version}")
    print(f"   - Master: {spark.sparkContext.master}")
    print()
    
    # HDFS paths
    input_path = "hdfs://namenode:9000/HiBench/Wordcount/Input"
    output_path = "hdfs://namenode:9000/HiBench/Wordcount/Output"
    
    print(f"📁 Input: {input_path}")
    print(f"📁 Output: {output_path}")
    print()
    
    try:
        # Đọc dữ liệu từ HDFS
        print("⏳ Đọc dữ liệu từ HDFS...")
        start_time = time.time()
        
        df = spark.read.text(input_path)
        total_lines = df.count()
        
        print(f"✅ Đọc thành công {total_lines} dòng")
        print()
        
        # WordCount
        print("⚙️  Đang xử lý WordCount...")
        process_start = time.time()
        
        # Split words và count
        words_df = df.select(explode(split(lower(col("value")), "\\s+")).alias("word"))
        words_df = words_df.filter(col("word") != "")
        word_counts = words_df.groupBy("word").agg(sql_count("*").alias("count"))
        word_counts = word_counts.orderBy(col("count").desc())
        
        # Write results to HDFS
        print(f"💾 Ghi kết quả vào HDFS: {output_path}")
        word_counts.write.mode("overwrite").csv(output_path)
        
        process_end = time.time()
        
        # Statistics
        total_words = words_df.count()
        unique_words = word_counts.count()
        
        end_time = time.time()
        duration = end_time - start_time
        processing_time = process_end - process_start
        
        print()
        print("=" * 70)
        print("📊 KẾT QUẢ BENCHMARK")
        print("=" * 70)
        print(f"  Tổng dòng:           {total_lines:,}")
        print(f"  Tổng từ:             {total_words:,}")
        print(f"  Từ unique:           {unique_words:,}")
        print(f"  Tổng thời gian:      {duration:.2f} giây")
        print(f"  Thời gian xử lý:     {processing_time:.2f} giây")
        print(f"  Throughput:          {total_words/duration:,.0f} words/second")
        print("=" * 70)
        print()
        
        # Top 10 words
        print("🔝 Top 10 từ xuất hiện nhiều nhất:")
        top_10 = word_counts.take(10)
        for i, row in enumerate(top_10, 1):
            print(f"   {i:2d}. {row.word:20s} : {row['count']:,} lần")
        
        print()
        print("✅ BENCHMARK HOÀN TẤT!")
        print()
        
    except Exception as e:
        print(f"❌ LỖI: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    
    finally:
        spark.stop()

if __name__ == "__main__":
    main()

