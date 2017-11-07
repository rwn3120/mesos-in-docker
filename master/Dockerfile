FROM debian:jessie
LABEL maintainer="radowan <radek.strejc@gmail.com>"

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL en_US.UTF-8
ENV SPARK_HOME /opt/spark

# add jessie backports (java 8)
RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list

# retrieve new lists of packages
RUN apt-get -y update

# install utils
RUN apt-get -y install \
        vim mc wget curl telnet procps tar \
	gnupg2 systemd locales apt-transport-https

RUN wget "http://mirror.dkm.cz/apache/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.6.tgz" -O "/tmp/spark.tgz"
RUN mkdir -p "${SPARK_HOME}"
RUN tar -xzf "/tmp/spark.tgz" --strip 1 -C "${SPARK_HOME}"
RUN rm "/tmp/spark.tgz"

## Set LOCALE to UTF8
RUN echo "${LC_ALL} UTF-8" > /etc/locale.gen && \
    locale-gen "${LC_ALL}" && \
    dpkg-reconfigure locales && \
    /usr/sbin/update-locale LANG="${LC_ALL}"

# install java
RUN apt-get -t jessie-backports -y install \
	openjdk-8-jre 

# setup mesos repository (see https://open.mesosphere.com/downloads/mesos/#installation)
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
RUN echo "deb http://repos.mesosphere.io/debian jessie main" | tee /etc/apt/sources.list.d/mesosphere.list
RUN apt-get -y update

# install mesos + marathon + chronos
RUN apt-get -y install \
	mesos \
	marathon \
	chronos

# docker
RUN wget -qO- https://get.docker.io/gpg | apt-key add -
RUN sh -c "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
RUN apt-get -y update
RUN curl -sSL https://get.docker.com/ | sh

# expose ports
EXPOSE 80 8080 8888 8081 7077 443 2000 2001 2002 3000 4000 4040 5050 5051 8000 9000

# entry point
ADD "entrypoint.sh" "/usr/local/bin/entrypoint.sh"
ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]

# default entrypoint args
CMD ["/bin/bash"]
