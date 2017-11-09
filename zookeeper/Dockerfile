FROM debian:jessie
LABEL maintainer="radowan <radek.strejc@gmail.com>"

# default arguments
ARG DEBIAN_FRONTEND=noninteractive

# retrieve new lists of packages
RUN apt-get update

# install utils & zookeeper
RUN apt-get install -y \
        vim-tiny curl \
	zookeeper zookeeperd zookeeper-bin

# expose zookeeper's ports
EXPOSE 2181 2888 3888

# entry point
ADD "entrypoint.sh" "/usr/local/bin/entrypoint.sh"
ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]

# default entrypoint args
CMD ["/bin/bash"]
