# Calculate the top-selling product per category.

from pyspark.sql.types import (
    StructType,
    StructField,
    IntegerType,
    StringType,
    DoubleType,
    TimestampType
)
from pyspark.sql import SparkSession, functions as F, Window
from datetime import datetime


spark = SparkSession.builder \
    .appName("TopProductTest") \
    .getOrCreate()


data = [
    (101, "Electronics", 1200.50, datetime(2026, 5, 1, 10, 15, 0)),
    (102, "Electronics", 850.00,  datetime(2026, 5, 1, 11, 30, 0)),
    (103, "Clothing",    230.75, datetime(2026, 5, 2, 9, 45, 0)),
    (104, "Clothing",    540.20, datetime(2026, 5, 2, 14, 10, 0)),
    (105, "Furniture",  3200.00, datetime(2026, 5, 3, 16, 5, 0)),
    (106, "Furniture",  1500.99, datetime(2026, 5, 3, 17, 20, 0)),
    (107, "Books",        89.99, datetime(2026, 5, 4, 8, 0, 0)),
    (108, "Books",       120.49, datetime(2026, 5, 4, 8, 30, 0)),
]

schema = StructType([
    StructField("product_id", IntegerType(), False),
    StructField("category", StringType(), True),
    StructField("revenue", DoubleType(), True),
    StructField("updated_at", TimestampType(), True),
])

sales = spark.createDataFrame(data, schema)

win = Window.partitionBy("category").orderBy(
    F.col("revenue").desc(),
    F.col("updated_at").desc(),
    F.col("product_id").asc()
)

df = sales.withColumn(
    "rn", 
    F.row_number().over(win)    
).filter(
    F.col("rn") == 1
).select("category", "product_id", "revenue")

df.show()