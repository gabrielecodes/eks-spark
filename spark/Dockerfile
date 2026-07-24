FROM apache/spark:4.1.0-scala2.13-java17-ubuntu

USER root

ENV SPARK_VERSION=4.1.0
ENV DELTA_VERSION=4.1.0

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sS -o /opt/spark/jars/delta-spark_2.13-${DELTA_VERSION}.jar \
    https://repo1.maven.org/maven2/io/delta/delta-spark_2.13/${DELTA_VERSION}/delta-spark_2.13-${DELTA_VERSION}.jar && \
    curl -sS -o /opt/spark/jars/delta-storage-${DELTA_VERSION}.jar \
    https://repo1.maven.org/maven2/io/delta/delta-storage/${DELTA_VERSION}/delta-storage-${DELTA_VERSION}.jar

RUN pip3 install --no-cache-dir \
    pyspark==${SPARK_VERSION} \
    delta-spark==${DELTA_VERSION}

ENV PYSPARK_PYTHON=python3
ENV PYSPARK_DRIVER_PYTHON=python3

USER spark

WORKDIR /opt/spark