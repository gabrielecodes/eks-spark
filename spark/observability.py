import time
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, rand, sum as spark_sum

RUN_FOR_SECONDS = 3600
BATCH_SECONDS = 10

spark = (
    SparkSession.builder
    .appName("spark-observability-demo")
    .getOrCreate()
)

sc = spark.sparkContext

start = time.time()
iteration = 0

while time.time() - start < RUN_FOR_SECONDS:
    iteration += 1

    df = (
        spark.range(0, 10_000_000, numPartitions=8)
        .withColumn("group", (col("id") % 1000))
        .withColumn("value", rand())
    )

    result = (
        df.groupBy("group")
          .agg(spark_sum("value").alias("total"))
          .collect()
    )

    elapsed = int(time.time() - start)

    print(
        f"iteration={iteration} "
        f"elapsed_seconds={elapsed} "
        f"result_rows={len(result)}"
    )

    time.sleep(BATCH_SECONDS)

spark.stop()