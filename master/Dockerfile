FROM radowan/mesos-in-docker:base-latest
LABEL maintainer="radowan <radek.strejc@gmail.com>"

ARG DEBIAN_FRONTEND=noninteractive
ENV SPARK_VERSION="2.2.0"
ENV HADOOP_VERSION="2.6"
ENV SPARK_HOME="/opt/spark-${SPARK_VERSION}-bin-hadoop-${HADOOP_VERSION}"

# install spark
RUN wget "http://mirror.dkm.cz/apache/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" -O "/tmp/spark.tgz"
RUN mkdir -p "${SPARK_HOME}" \
	&& tar -xzf "/tmp/spark.tgz" --strip 1 -C "${SPARK_HOME}" \
	&& rm "/tmp/spark.tgz"

# install marathon & chronos
RUN apt-get update -y
RUN apt-get -y install mesos marathon chronos

# entry point
ADD "entrypoint.sh" "/usr/local/bin/entrypoint.sh"
ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]

# default entrypoint args
CMD ["/bin/bash"]
