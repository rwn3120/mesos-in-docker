#!/bin/bash -e 
SCRIPT=$(readlink -f "${0}")
SCRIPT_BASENAME=$(basename "${SCRIPT}")
SCRIPT_NAME=$(echo "${SCRIPT_BASENAME}" | sed 's/\\..*//')
SCRIPT_DIR=$(dirname "${SCRIPT}")

. "${SCRIPT_DIR}/utils.sh"

# print help if needed
for arg in ${@}; do
	if [ "${arg}" == "-h" ] || [ "${arg}" == "--help" ]; then
		finalize "${SCRIPT_NAME} - utitlity to stop running mesos cluster(s) on your local\n\nExample:\n\t${SCRIPT_BASENAME} <cluster name>\n"
	fi
done

CONF="${SCRIPT_DIR}/conf"

# Network JSON fields
NAME_KEY="name"

# Path to cluster configuration file
CLUSTER_CONF="${1}"
CLUSTER_CONF=${CLUSTER_CONF:="${CONF}/cluster.conf"}

# check if config exists
if [ ! -f "${CLUSTER_CONF}" ]; then
        finalize 1 "${CLUSTER_CONF} does not exist or is not a file!"
else
        CLUSTER_CONF=$(readlink -f "${CLUSTER_CONF}")
fi

JSON=$(cat "${CLUSTER_CONF}" | sed 's/#.*//')
CLUSTER=$(jsonParse "${JSON}" ".${NAME_KEY}")

NETWORK="${CLUSTER}.net"
for c in $(docker ps -a | grep "${CLUSTER}.net\$" 2>/dev/null| sed 's/.* //'); do 
	wrn "Removing container ${c}"
	docker rm -f "${c}" >> /dev/null 
done
set +e
docker network inspect "${NETWORK}" &> /dev/null
RC=$?
set -e
if [ $RC -eq 0 ]; then
	wrn "Removing network ${NETWORK}"
	docker network rm "${NETWORK}" >> /dev/null
fi

out "Cluster ${CLUSTER} stopped."
