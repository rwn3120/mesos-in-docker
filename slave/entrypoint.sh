#!/bin/bash -e

function out() { echo -e "\e[32m${@}\e[39m"; }
function err() { echo -e "\e[31m${@}\e[39m" 1>&2; }

# shared files
HOSTS_CONF="/shared/hosts.conf"
MESOS_NAME_CONF="/shared/mesos_name.conf"
MESOS_ZOO_CONF="/shared/mesos_zoo.conf"
MESOS_QUORUM_CONF="/shared/mesos_quorum.conf"
SPARK_IMAGE="mesosphere/spark:2.0.1-2.2.0-1-hadoop-2.6"
SPARK_IMAGE_TAR="/shared/$(basename "${SPARK_IMAGE}").tar"

# local configuration paths
LOCAL_MESOS_ETC="/etc/mesos"
LOCAL_MESOS_SLAVE_ETC="/etc/mesos-slave"
LOCAL_MARATHON_ETC="/etc/marathon/conf"

# local system configuration files
LOCAL_HOSTS_CONF="/etc/hosts"

# local mesos zoo configuration files
LOCAL_MESOS_ZOO_CONF="${LOCAL_MESOS_ETC}/zk"

# local mesos slave configuration files
LOCAL_MESOS_SLAVE_IP="${LOCAL_MESOS_SLAVE_ETC}/ip"
LOCAL_MESOS_SLAVE_HOSTNAME="${LOCAL_MESOS_SLAVE_ETC}/hostname"

# setup system environment
out "Environment setup..."
# add known hosts to /etc/hosts
out "... known hosts"
cat "${HOSTS_CONF}" | grep -v "$(hostname)" >> "${LOCAL_HOSTS_CONF}"

# start docker
out "... starting docker"
/etc/init.d/docker start 

# setup mesos
out "Setting up mesos..."
# setup mesos zoo
out "... zoo"
cp "${MESOS_ZOO_CONF}" "${LOCAL_MESOS_ZOO_CONF}"

# setup mesos slave
out "... slave"
# set slave IP
cat "${HOSTS_CONF}" | grep "$(hostname)" | tail -1 | awk '{print $1}' > "${LOCAL_MESOS_SLAVE_IP}"
# set slave hostname
echo $(hostname) > "${LOCAL_MESOS_SLAVE_HOSTNAME}"

# start mesos slave
out "Starting mesos-slave..."
export MESOS_CLUSTER=$(cat "${MESOS_NAME_CONF}")
export MESOS_PORT=5050
export MESOS_MASTER=$(cat "${LOCAL_MESOS_ZOO_CONF}")
export MESOS_LOG_DIR="/var/log/mesos"
export MESOS_WORK_DIR=$( cat "${LOCAL_MESOS_SLAVE_ETC}/work_dir")
export MESOS_SLAVE_STDOUT="${MESOS_LOG_DIR}/$(hostname).stdout"
export MESOS_SLAVE_STDERR="${MESOS_LOG_DIR}/$(hostname).stderr"
export MESOS_ISOLATION="cgroups/cpu,cgroups/mem,cgroups/pids,namespaces/pid,filesystem/shared,filesystem/linux,volume/sandbox_path"
export MESOS_LAUNCHER="linux"
mesos-slave --no-systemd_enable_support  --containerizers="mesos,docker" 1>"${MESOS_SLAVE_STDOUT}" 2>"${MESOS_SLAVE_STDERR}" &
export MESOS_SLAVE_PID=$!
if $(sleep 0.25 && ps -p "${MESOS_SLAVE_PID}" > /dev/null); then
	out "... running [${MESOS_SLAVE_PID}]"	
else 
	err "... failed to start"
	exit 1
fi

if [ ! -f "${SPARK_IMAGE_TAR}" ]; then
	out "Pulling ${SPARK_IMAGE}"
#	docker pull "${SPARK_IMAGE}" >/dev/null
	out "Storing ${SPARK_IMAGE} to ${SPARK_IMAGE_TAR}"
#	docker save -o "${SPARK_IMAGE_TAR}" "${SPARK_IMAGE}"
else 
	out "Loading ${SPARK_IMAGE} from ${SPARK_IMAGE_TAR}"
#	docker load -i "${SPARK_IMAGE_TAR}"
fi


# set ready flag
echo "1" > "/tmp/node.ready"

# pass command
echo "Executing ${@}"
${@}