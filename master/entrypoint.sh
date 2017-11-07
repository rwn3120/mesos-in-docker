#!/bin/bash -e

function out() { echo -e "\e[32m${@}\e[39m"; }
function err() { echo -e "\e[31m${@}\e[39m" 1>&2; }

# shared files
HOSTS_CONF="/shared/hosts.conf"
MESOS_NAME_CONF="/shared/mesos_name.conf"
MESOS_ZOO_CONF="/shared/mesos_zoo.conf"
MARATHON_ZOO_CONF="/shared/marathon_zoo.conf"
MESOS_QUORUM_CONF="/shared/mesos_quorum.conf"

# local configuration paths
LOCAL_MESOS_ETC="/etc/mesos"
LOCAL_MESOS_MASTER_ETC="/etc/mesos-master"
LOCAL_MARATHON_ETC="/etc/marathon/conf"

# local system configuration files
LOCAL_HOSTS_CONF="/etc/hosts"

# local mesos zoo configuration files
LOCAL_MESOS_ZOO_CONF="${LOCAL_MESOS_ETC}/zk"

# local mesos master configuration files
LOCAL_MESOS_MASTER_QUORUM="${LOCAL_MESOS_MASTER_ETC}/quorum"
LOCAL_MESOS_MASTER_IP="${LOCAL_MESOS_MASTER_ETC}/ip"
LOCAL_MESOS_MASTER_HOSTNAME="${LOCAL_MESOS_MASTER_ETC}/hostname"

# local marathon configuration files
LOCAL_MARATHON_ZOO_CONF="${LOCAL_MARATHON_ETC}/zk"
LOCAL_MARATHON_ZOO_MASTER_CONF="${LOCAL_MARATHON_ETC}/master"

# setup system environment
out "Environment setup..."
# add known hosts to /etc/hosts
out "... known hosts"
cat "${HOSTS_CONF}" | grep -v "$(hostname)" >> "${LOCAL_HOSTS_CONF}"

# setup mesos
out "Setting up mesos..."
# setup mesos zoo
out "... zoo"
cp "${MESOS_ZOO_CONF}" "${LOCAL_MESOS_ZOO_CONF}"

# setup mesos master
out "... master"
cp "${MESOS_QUORUM_CONF}" "${LOCAL_MESOS_MASTER_QUORUM}"
# set master IP
cat "${HOSTS_CONF}" | grep "$(hostname)" | tail -1 | awk '{print $1}' > "${LOCAL_MESOS_MASTER_IP}"
# set master hostname
echo $(hostname) > "${LOCAL_MESOS_MASTER_HOSTNAME}"

# setup marathon zoo
out "... marathon"
mkdir -p /etc/marathon/conf
cp "${MARATHON_ZOO_CONF}" "${LOCAL_MARATHON_ZOO_CONF}"
cp "${LOCAL_MESOS_ZOO_CONF}" "${LOCAL_MARATHON_ZOO_MASTER_CONF}"

# start mesos master
out "Starting mesos-master..."
export MESOS_CLUSTER=$(cat "${MESOS_NAME_CONF}")
export MESOS_PORT=5050
export MESOS_ZK=$(cat "${LOCAL_MESOS_ZOO_CONF}")
export MESOS_QUORUM=$(cat "${LOCAL_MESOS_MASTER_QUORUM}")
export MESOS_REGISTRY="in_memory"
export MESOS_LOG_DIR="/var/log/mesos"
export MESOS_WORK_DIR=$( cat "${LOCAL_MESOS_MASTER_ETC}/work_dir")
export STDOUT_MESOS_MASTER="${MESOS_LOG_DIR}/$(hostname).stdout"
export STDERR_MESOS_MASTER="${MESOS_LOG_DIR}/$(hostname).stderr"
mesos-master 1>"${STDOUT_MESOS_MASTER}" 2>"${STDERR_MESOS_MASTER}" &
export MESOS_MASTER_PID=$!
if $(sleep 0.25 && ps -p "${MESOS_MASTER_PID}" > /dev/null); then
        out "... running [${MESOS_MASTER_PID}]"  
else
        err "... failed to start"
        exit 1
fi

out "Starting marathon..."
export MARATHON_HOSTNAME=$(hostname)
export MARATHON_ZK=$(cat "${LOCAL_MARATHON_ZOO_CONF}")
export MARATHON_MASTER=$(cat "${LOCAL_MARATHON_ZOO_MASTER_CONF}")
export STDOUT_MARATHON="${MESOS_LOG_DIR}/marathon.$(hostname).stdout"
export STDERR_MARATHON="${MESOS_LOG_DIR}/marathon.$(hostname).stderr"
marathon --no-logger 1>"${STDOUT_MARATHON}" 2>"${STDERR_MARATHON}" &
export MARATHON_PID=$!
if $(sleep 0.25 && ps -p "${MARATHON_PID}" > /dev/null); then
        out "... running [${MARATHON_PID}]"  
else
        err "... failed to start"
        exit 1
fi

out "Starting chronos..."
export STDOUT_CHRONOS="${MESOS_LOG_DIR}/chronos.$(hostname).stdout"
export STDERR_CHRONOS="${MESOS_LOG_DIR}/chronos.$(hostname).stderr"
chronos 1>"${STDOUT_CHRONOS}" 2>"${STDERR_CHRONOS}" &
export CHRONOS_PID=$!
if $(sleep 0.25 && ps -p "${CHRONOS_PID}" > /dev/null); then
        out "... running [${CHRONOS_PID}]"
else
        err "... failed to start"
        exit 1
fi

if [[ "$(hostname)" == *"master1"* ]]; then
	out "Starting spark..."
	export STDOUT_SPARK="${MESOS_LOG_DIR}/spark.$(hostname).stdout"
	export STDERR_SPARK="${MESOS_LOG_DIR}/spark.$(hostname).stderr"
	/opt/spark/sbin/start-mesos-dispatcher.sh --master "mesos://$(hostname):5050" 1>"${STDOUT_SPARK}" 2>"${STDERR_SPARK}"
fi


# set ready flag
echo "1" > "/tmp/node.ready"

# pass command
echo "Executing ${@}"
${@}
