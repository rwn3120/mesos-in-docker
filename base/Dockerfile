FROM debian:jessie
LABEL maintainer="radowan <radek.strejc@gmail.com>"

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL en_US.UTF-8

# add jessie backports (java 8)
RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list

# add mesos repository (see https://open.mesosphere.com/downloads/mesos/#installation)
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
RUN echo "deb http://repos.mesosphere.io/debian jessie main" | tee /etc/apt/sources.list.d/mesosphere.list

# retrieve new lists of packages
RUN apt-get -y update

# install utils
RUN apt-get -y install \
        vim mc wget curl telnet procps tar \
	python2.7-minimal gnupg2 systemd locales apt-transport-https apt-utils

# install java
RUN apt-get -t jessie-backports -y install \
        openjdk-8-jre

## Set locales to UTF8
RUN echo "${LC_ALL} UTF-8" > /etc/locale.gen && \
    locale-gen "${LC_ALL}" && \
    dpkg-reconfigure locales && \
    /usr/sbin/update-locale LANG="${LC_ALL}"

# install mesos
RUN apt-get -y install mesos

# expose ports
EXPOSE 80 8080 8888 8081 7077 443 2000 2001 2002 3000 4000 4040 5050 5051 8000 9000

# default command
CMD ["/bin/bash"]
