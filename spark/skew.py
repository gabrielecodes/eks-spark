# Detect skew

from pyspark.sql import SparkSession, functions as F
from pyspark.sql.types import (
    StructType,
    StructField,
    IntegerType,
    StringType,
    DoubleType
)

spark = SparkSession.builder.appName("SkewTest").getOrCreate()

# salting
SALTS = 10

transactions_data = [
    (1, 120.50),
    (1, 75.00),
    (2, 300.25),
    (3, 50.00),
    (3, 220.10),
    (4, 15.75),
    (5, 999.99),
]

transactions_schema = StructType([
    StructField("customer_id", IntegerType(), False),
    StructField("amount", DoubleType(), True),
])

transactions = spark.createDataFrame(
    transactions_data,
    transactions_schema
)


customers_data = [
    (1, "France"),
    (2, "Germany"),
    (3, "France"),
    (4, "Italy"),
    (5, "Spain"),
]

customers_schema = StructType([
    StructField("customer_id", IntegerType(), False),
    StructField("country", StringType(), True),
])

customers = spark.createDataFrame(
    customers_data,
    customers_schema
)

transactions_salted = (
    transactions.withColumn(
        "salt",
        (F.rand() * SALTS).cast("int")
    )
) 

salt_values = spark.range(SALTS).withColumnRenamed("id", "salt")

customers_salted = customers.crossJoin(salt_values)

joined = (
    transactions_salted
    .join(
        customers_salted,
        on=["customer_id", "salt"],
        how="inner"
    )
)

counts = transactions.groupBy("customer_id").count()
