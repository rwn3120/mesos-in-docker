FROM mesos-in-docker:master-latest
LABEL maintainer="radowan <radek.strejc@gmail.com>"

ARG DEBIAN_FRONTEND=noninteractive

# expose ports
EXPOSE 80 8080 8888 443 2000 2001 2002 3000 4000 4040 5050 5051 8000 9000

# entry point
ADD "entrypoint.sh" "/usr/local/bin/entrypoint.sh"
ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]

# default entrypoint args
CMD ["/bin/bash"]
