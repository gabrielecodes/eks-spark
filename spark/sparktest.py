from delta import *
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("DeltaLakeTest") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .getOrCreate()

# test delta table
df = spark.range(0, 10)
df.write.format("delta").mode("overwrite").saveAsTable("test_range")

# test reading delta
res = spark.table("test_range")
res.show()
spark.sql("DESCRIBE HISTORY test_range").show(truncate=False)