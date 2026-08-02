# Identify the start of the new session/group of events

from pyspark.sql import SparkSession, functions as F, Window


spark = SparkSession.builder \
    .appName("SessionizationTest") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .getOrCreate()


data = [
    {"user_id": "u1", "event_time": "10:00"},
    {"user_id": "u1", "event_time": "10:10"},
    {"user_id": "u1", "event_time": "11:00"},
    {"user_id": "u1", "event_time": "11:10"},
    {"user_id": "u1", "event_time": "11:20"},
    {"user_id": "u1", "event_time": "11:25"},
    {"user_id": "u1", "event_time": "12:00"},
]

df = spark.createDataFrame(data)

window = Window.partitionBy("user_id").orderBy("event_time")

df = df.withColumn("prev_time", F.lag("event_time").over(window))

df = df.withColumn(
    "diff_minutes",
    F.timestamp_diff(
        "minute", 
        df.prev_time.cast("timestamp"), 
        df.event_time.cast("timestamp")
    ).cast("long")
)

# a condition identifies a new session
df = df.withColumn(
    "new_session",
    F.when(
        (F.col("diff_minutes").isNull()) |
        (F.col("diff_minutes") > 30)
    , 1
    ).otherwise(0)
)

# the cumulative sum gives an "id" to the session
win = Window.partitionBy("user_id").orderBy("event_time")
df = df.withColumn(
    "session_id",
    F.sum("new_session").over(
            win.rowsBetween(Window.unboundedPreceding, 0)
        )
    )

sessions = (
    df.groupBy("user_id", "session_id")
    .agg(
        F.min("event_time").alias("session_start"),
        F.max("event_time").alias("session_end"),
        F.count("*").alias("event_count")
    )
    .orderBy("user_id", "session_id")
)

sessions.show()