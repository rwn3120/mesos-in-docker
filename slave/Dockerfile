FROM radowan/mesos-in-docker:base
LABEL maintainer="radowan <radek.strejc@gmail.com>"

# arguments
ARG DEBIAN_FRONTEND=noninteractive
ARG SPARK_VERSION
ARG HADOOP_VERSION
ARG SPARK_IMAGE

# environment variables
ENV SPARK_VERSION="${SPARK_VERSION}"
ENV HADOOP_VERSION="${HADOOP_VERSION}"
ENV SPARK_IMAGE="${SPARK_IMAGE}"

# install docker
RUN wget -qO- https://get.docker.io/gpg | apt-key add -
RUN sh -c "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
RUN apt-get -y update
RUN curl -sSL https://get.docker.com/ | sh

# entry point
ADD "entrypoint.sh" "/usr/local/bin/entrypoint.sh"
ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]

# default entrypoint args
CMD ["/bin/bash"]
