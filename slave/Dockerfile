FROM radowan/mesos-in-docker:base-latest
LABEL maintainer="radowan <radek.strejc@gmail.com>"

ARG DEBIAN_FRONTEND=noninteractive

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
