// HiBench WordCount Data Generator - Scala version
// Generate random text data similar to HiBench RandomTextWriter

import org.apache.spark.sql.SparkSession
import scala.util.Random

object WordCountDataGenerator {
  
  val WORDS = Array(
    "spark", "hadoop", "mapreduce", "hdfs", "yarn", "data", "processing",
    "distributed", "computing", "cluster", "analytics", "big", "scale",
    "apache", "intel", "benchmark", "performance", "memory", "disk",
    "network", "storage", "database", "query", "sql", "join", "aggregation",
    "sort", "shuffle", "partition", "executor", "driver", "worker", "master",
    "container", "resource", "allocation", "scheduling", "framework",
    "algorithm", "dataset", "dataframe", "rdd", "transformation", "action"
  )
  
  def generateLine(wordsPerLine: Int): String = {
    val numWords = wordsPerLine + Random.nextInt(10) - 5
    (1 to numWords).map(_ => WORDS(Random.nextInt(WORDS.length))).mkString(" ")
  }
  
  def main(args: Array[String]): Unit = {
    val spark = SparkSession.builder()
      .appName("HiBench-WordCount-DataGen")
      .getOrCreate()
      
    import spark.implicits._
    
    val numLines = if (args.length > 0) args(0).toInt else 50000
    val outputPath = if (args.length > 1) args(1) else "hdfs://namenode:9000/HiBench/Wordcount/Input"
    
    println(s"Generating $numLines lines of random text...")
    
    // Generate data
    val data = (1 to numLines).map(_ => generateLine(15))
    val df = spark.sparkContext.parallelize(data, 2).toDF("value")
    
    // Write to HDFS
    df.write.mode("overwrite").text(outputPath)
    
    println(s"✅ Data generated and saved to: $outputPath")
    
    spark.stop()
  }
}

