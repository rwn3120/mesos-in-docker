#!/bin/bash -e

HOSTS_CONF="/shared/hosts.conf"
ZOO_CONF="/shared/zoo.conf"

# local hosts configuration
LOCAL_HOSTS_CONF="/etc/hosts"
# local zoo configuration
LOCAL_ZOO_CONF_DIR="/etc/zookeeper/conf"
LOCAL_ZOO_ID_CONF="${LOCAL_ZOO_CONF_DIR}/myid"
LOCAL_ZOO_SERVICE_CONF="${LOCAL_ZOO_CONF_DIR}/zoo.cfg"

# Output server ID
ZOOKEEPER_ID=$(grep "$(hostname)" /shared/zoo.conf | sed 's/=.*//; s/.*\.//')
echo "Zookeeper ID: ${ZOOKEEPER_ID}"
echo "${ZOOKEEPER_ID}" > "${LOCAL_ZOO_ID_CONF}"

# add known hosts to /etc/hosts
cat "${HOSTS_CONF}" | grep -v "$(hostname)" >> "${LOCAL_HOSTS_CONF}"

# add zookeeper servers to configuration
echo "Adding zookeeper servers from ${ZOO_CONF}"
cat "${ZOO_CONF}" >> "${LOCAL_ZOO_SERVICE_CONF}"

# start zookeeper
echo "Starting zookeeper..."
/etc/init.d/zookeeper start

# set ready flag
echo "1" > "/tmp/node.ready"

# pass command
echo "Executing ${@}"
${@}
