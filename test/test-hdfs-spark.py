#!/usr/bin/env python3
"""
Simple test script: Read file from HDFS using Spark and perform analysis
Uses DataFrame API to avoid serialization issues
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, length, split, explode, lower, count as sql_count
import sys

def main():
    print("=" * 60)
    print("🚀 SPARK + HDFS TEST")
    print("=" * 60)
    print()
    
    # Create Spark Session
    print("📊 Initializing Spark Session...")
    spark = SparkSession.builder \
        .appName("HDFS-Spark-Test") \
        .master("spark://spark-master:7077") \
        .config("spark.driver.memory", "1g") \
        .config("spark.executor.memory", "2g") \
        .getOrCreate()
    
    print("✅ Spark Session is ready!")
    print(f"   - Spark Version: {spark.version}")
    print(f"   - Master: {spark.sparkContext.master}")
    print()
    
    # File path on HDFS
    hdfs_path = "hdfs://namenode:9000/test/sample-data.txt"
    
    print(f"📁 Reading file from HDFS: {hdfs_path}")
    
    try:
        # Read file from HDFS as DataFrame
        df = spark.read.text(hdfs_path)
        
        print("✅ File read successfully!")
        print()
        
        # 1. Count lines
        line_count = df.count()
        print(f"📝 Total lines: {line_count}")
        print()
        
        # 2. Display first 5 lines
        print("📋 First 5 lines:")
        print("-" * 60)
        first_lines = df.take(5)
        for i, row in enumerate(first_lines, 1):
            print(f"  {i}. {row.value}")
        print("-" * 60)
        print()
        
        # 3. Word Count with DataFrame API
        print("🔤 Keyword analysis:")
        
        # Split into words
        words_df = df.select(explode(split(lower(col("value")), "\\s+")).alias("word"))
        
        # Filter out empty strings
        words_df = words_df.filter(col("word") != "")
        
        # Count total words
        total_words = words_df.count()
        print(f"   - Total words: {total_words}")
        
        # Count frequency and get top 10
        word_freq = words_df.groupBy("word").agg(sql_count("*").alias("count"))
        top_words = word_freq.orderBy(col("count").desc()).take(10)
        
        print("   - Top 10 most frequent words:")
        for row in top_words:
            print(f"     • {row.word}: {row['count']} times")
        print()
        
        # 4. Find lines containing "Spark"
        spark_lines = df.filter(col("value").contains("Spark") | col("value").contains("spark"))
        spark_count = spark_lines.count()
        print(f"🔍 Found {spark_count} lines containing 'Spark':")
        print("-" * 60)
        for i, row in enumerate(spark_lines.collect(), 1):
            print(f"  {i}. {row.value}")
        print("-" * 60)
        print()
        
        # 5. Statistics
        print("📊 Statistics:")
        
        # Calculate length of each line
        df_with_length = df.withColumn("line_length", length(col("value")))
        
        # Aggregate statistics
        stats = df_with_length.agg(
            sql_count("*").alias("total_lines"),
            sql_count("line_length").alias("total_chars_sum")
        ).collect()[0]
        
        # Get min, max, avg
        length_stats = df_with_length.select("line_length").describe().collect()
        
        # Parse results
        for stat in length_stats:
            if stat['summary'] == 'mean':
                avg_length = float(stat['line_length'])
            elif stat['summary'] == 'max':
                max_length = int(float(stat['line_length']))
            elif stat['summary'] == 'min':
                min_length = int(float(stat['line_length']))
        
        # Calculate total characters
        total_chars = df_with_length.agg({"line_length": "sum"}).collect()[0][0]
        
        print(f"   - Total characters: {int(total_chars)}")
        print(f"   - Average line length: {avg_length:.2f} characters")
        print(f"   - Longest line: {max_length} characters")
        print(f"   - Shortest line: {min_length} characters")
        print()
        
        print("=" * 60)
        print("✅ TEST COMPLETED SUCCESSFULLY!")
        print("=" * 60)
        print()
        print("💡 You can:")
        print("   - View Spark UI: http://localhost:4040")
        print("   - View HDFS UI: http://localhost:9870")
        print("   - Check file on HDFS:")
        print(f"     docker exec namenode hdfs dfs -ls /test/")
        print()
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        print()
        print("💡 Check:")
        print("   1. Has the file been uploaded to HDFS?")
        print("   2. Is HDFS NameNode running?")
        print("   3. Is Spark cluster active?")
        sys.exit(1)
    
    finally:
        # Stop Spark Session
        spark.stop()

if __name__ == "__main__":
    main()

