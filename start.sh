#!/bin/bash -e 
. utils.sh

# Container JSON fields
IMAGE_KEY="image" HOST_KEY="hostname" IP_KEY="ip" PRIVILEGED_KEY="privileged"
# Network JSON fields
KEYS_KEY="keys" NETWORK_KEY="network" GATEWAY_KEY="gateway" SUBNET_KEY="subnet" DRIVER_KEY="driver" SCOPE_KEY="scope"
# Mesos JSON fields
MASTERS_KEY="masters" SLAVES_KEY="slaves"
# Zookeeper JSON fileds
ZOO_KEY="zoo" ZOO_NODES_KEY="nodes" ZOO_PEER_PORT_KEY="peer_port" ZOO_LEADER_PORT_KEY="leader_port"

function containerJson {
	jq -n \
		--arg "${IMAGE_KEY}" "${1}" \
		--arg "${HOST_KEY}" "${2}" \
		--arg "${IP_KEY}" "${3}" \
		--arg "${PRIVILEGED_KEY}" "${4}" \
		"{\"${IMAGE_KEY}\":\$${IMAGE_KEY},\"${HOST_KEY}\":\$${HOST_KEY},\"${IP_KEY}\":\$${IP_KEY},\"${PRIVILEGED_KEY}\":\$${PRIVILEGED_KEY}}"
}

function finalize() {
	if [ $# -gt 1 ]; then
		if [[ $1 = *[[:digit:]]* ]]; then
			RC=$1
		else 
			RC=255
			warn "${1} is not a number. Exiting with ${RC}"
		fi
		MESSAGE="${@:2}"
	else 
		RC=0
		MESSAGE="${@:1}"
	fi
	fx=$(if [[ ${RC} -eq 0 ]]; then echo "out"; else echo "err"; fi)
	if [[ "${MESSAGE}" != "" ]]; then
		${fx} "${MESSAGE}\nExiting with ${RC}"
	else
		${fx} "Exiting with ${RC}"
	fi
	exit $RC
}

function checkError {
	RC=$(echo "${1}" | tr -cd 0-9 )
	if [ "${RC}" == "" ]; then finalize 254 "Unknown return code. ${2}"; fi
	if [ ${RC} -ne 0 ]; then finalize ${RC} "${2}"; fi;
}

function handleKill() {
	signal="${1}"
	wrn "Kill signal ${signal} received."
	finalize 254 "Interrupted with ${signal}!"
}

function usage() {
	finalize \
"${SCRIPT_NAME} - utility to run mesos cluster(s) on your local

Example:
\t${SCRIPT_BASENAME} [-y] [conf]
Options:
\t-y\t...auto response Yes on every prompt
\tconf\t...path to file with your cluster configuration"
}

# set trap
for sig in `seq $(kill -l | tail -1 | awk '{print $3}' | sed 's/[^0-9]*//g')`; do
        trap "handleKill ${sig}" $sig;
done

while getopts ":yYh" opt; do
        case ${opt} in
                y )   FORCE_YES="Y"
                        ;;
                h)      usage
                        ;;
                \? )    failure 7 "Invalid option: -${OPTARG}"
                        ;;
                : )     failure 8 "Invalid option: -${OPTARG} requires an argument." 1>&2
                        ;;
        esac
done
shift $((OPTIND -1))

dbg "Initializing...\n"
# get path to configuration file
SHARED="${SCRIPT_DIR}/shared"
CONF="${SCRIPT_DIR}/conf"

# Path to cluster configuration file
CLUSTER_FILE="${1}"
CLUSTER_FILE=${CLUSTER_FILE:="${CONF}/cluster.conf"}

# check if config exists
if [ ! -f "${CLUSTER_FILE}" ]; then
        finalize 1 "${CLUSTER_FILE} does not exist or is not a file!"
else 
        CLUSTER_FILE=$(readlink -f "${CLUSTER_FILE}")
fi

# Container JSON fields
NAME_KEY="name"
IMAGE_KEY="image" HOST_KEY="hostname" IP_KEY="ip"
# Network JSON fields
KEYS_KEY="keys" NETWORK_KEY="network" GATEWAY_KEY="gateway" SUBNET_KEY="subnet" DRIVER_KEY="driver" SCOPE_KEY="scope"
# Mesos JSON fields
MASTERS_KEY="masters" SLAVES_KEY="slaves"
# Zookeeper JSON fileds
ZOO_KEY="zoo" ZOO_NODES_KEY="nodes" ZOO_PEER_PORT_KEY="peer_port" ZOO_LEADER_PORT_KEY="leader_port"

# images
MESOS_IMAGE="radowan/mesos-in-docker"
ZOOKEEPER_IMAGE="${MESOS_IMAGE}:zookeeper-latest"
MESOS_MASTER_IMAGE="${MESOS_IMAGE}:master-latest"
MESOS_SLAVE_IMAGE="${MESOS_IMAGE}:slave-latest"
MESOS_VERSION=$(docker run --rm -t "${MESOS_MASTER_IMAGE}" --mesos-version | tr -d "\n\r" | tr -d "\n")
HADOOP_VERSION="$(docker run --rm -t "${MESOS_MASTER_IMAGE}" --hadoop-version | tr -d "\n\r" | tr -d "\n")"
SPARK_VERSION="$(docker run --rm -t "${MESOS_MASTER_IMAGE}" --spark-version | tr -d "\n\r" | tr -d  "\n")"
SPARK_IMAGE="mesosphere/spark:2.0.1-${SPARK_VERSION}-1-hadoop-${HADOOP_VERSION}"
SPARK_IMAGE_TAR="${SHARED}/spark-${SPARK_VERSION}-hadoop-${HADOOP_VERSION}.image.tar"

# default mount points
MOUNT_POINTS_OPT="-v \"${CONF}:/conf\" -v \"${SHARED}:/shared:ro\""
ENVIRONMENT_OPT="-e \"SPARK_IMAGE=${SPARK_IMAGE}\" -e \"SPARK_IMAGE_TAR=$(basename "${SPARK_IMAGE_TAR}")\""

# pull spark image
out "Cluster setup:
\t- Mesos ${MESOS_VERSION}
\t- Apache Spark ${SPARK_VERSION} 
\t- Hadoop ${HADOOP_VERSION}\n"

set +e  
docker image inspect "${SPARK_IMAGE}" &> /dev/null
RC=$?
set -e
if [ $RC -ne 0 ]; then
	out "Please wait..."
	out "... pulling ${SPARK_IMAGE}"
	docker pull "${SPARK_IMAGE}" >/dev/null
	out "... storing ${SPARK_IMAGE} to ${SPARK_IMAGE_TAR}"
	docker save "${SPARK_IMAGE}" > "${SPARK_IMAGE_TAR}"
fi
if [ ! -e "${SPARK_IMAGE_TAR}" ]; then
	out "Please wait..."        
	out "... storing ${SPARK_IMAGE} to ${SPARK_IMAGE_TAR}"
	docker save "${SPARK_IMAGE}" > "${SPARK_IMAGE_TAR}"
fi

# Container JSON fields
NAME_KEY="name"
IMAGE_KEY="image" HOST_KEY="hostname" IP_KEY="ip"
# Network JSON fields
KEYS_KEY="keys" NETWORK_KEY="network" GATEWAY_KEY="gateway" SUBNET_KEY="subnet" DRIVER_KEY="driver" SCOPE_KEY="scope"
# Mesos JSON fields
MASTERS_KEY="masters" SLAVES_KEY="slaves"
# Zookeeper JSON fileds
ZOO_KEY="zoo" ZOO_NODES_KEY="nodes" ZOO_PEER_PORT_KEY="peer_port" ZOO_LEADER_PORT_KEY="leader_port"

out "Parsing ${CLUSTER_FILE}"
CLUSTER_JSON=$(cat "${CLUSTER_FILE}" | sed 's/#.*//')
CLUSTER=$(jsonParse "${CLUSTER_JSON}" ".${NAME_KEY}")
out "Reading ${CLUSTER} configuration"

CLUSTER_CONF="${CONF}/${CLUSTER}"
mkdir -p "${CLUSTER_CONF}"
HOSTS_CONF="${CLUSTER_CONF}/hosts.conf"
ZOO_CONF="${CLUSTER_CONF}/zoo.conf"
MESOS_NAME_CONF="${CLUSTER_CONF}/mesos_name.conf"
MESOS_QUORUM_CONF="${CLUSTER_CONF}/mesos_quorum.conf"
MESOS_MASTERS_CONF="${CLUSTER_CONF}/mesos_masters.conf"
MESOS_SLAVES_CONF="${CLUSTER_CONF}/mesos_slaves.conf"
MESOS_ZOO_CONF="${CLUSTER_CONF}/mesos_zoo.conf"
MARATHON_ZOO_CONF="${CLUSTER_CONF}/marathon_zoo.conf"

# Set cluster name
echo -n "${CLUSTER}" > "${MESOS_NAME_CONF}"

# Read network configuration
out "... network"
truncate --size 0 "${HOSTS_CONF}"
NETWORK_JSON=$(jsonParse "${CLUSTER_JSON}" ".${NETWORK_KEY}")
NETWORK="${CLUSTER}.net"
GATEWAY=$(jsonParse "${NETWORK_JSON}" ".${GATEWAY_KEY}")
SUBNET=$(jsonParse "${NETWORK_JSON}" ".${SUBNET_KEY}")
DRIVER=$(jsonParse "${NETWORK_JSON}" ".${DRIVER_KEY}")
SCOPE=$(jsonParse "${NETWORK_JSON}" ".${SCOPE_KEY}")

CONTAINERS=()

# Read zoo configuration
out "... ZOO"
truncate --size 0 "${ZOO_CONF}"
ZOO_JSON=$(jsonParse "${CLUSTER_JSON}" ".${ZOO_KEY}")
ZOO_PEER_PORT=$(jsonParse "${ZOO_JSON}" ".${ZOO_PEER_PORT_KEY}")
ZOO_LEADER_PORT=$(jsonParse "${ZOO_JSON}" ".${ZOO_LEADER_PORT_KEY}")
ZOO_CLIENT_PORT=2181 # default value
ZOO_NODES_JSON=$(jsonParse "${ZOO_JSON}" ".${ZOO_NODES_KEY}")
ZOO_NODE_COUNT=$(jsonParse "${ZOO_NODES_JSON}" ". | length")
echo -n "zk://" > "${MESOS_ZOO_CONF}"
echo -n "zk://" > "${MARATHON_ZOO_CONF}"
for index in $(seq 0 $((${ZOO_NODE_COUNT} -1 ))); do
        ZOOKEEPER_ID=$(($index + 1))
        ID="zookeeper${ZOOKEEPER_ID}"
        HOST="${ID}.${NETWORK}"
        IP=$(jsonParse "${ZOO_NODES_JSON}" ".[${index}]")
        echo -e "${IP}\t${HOST} ${ID}" >> "${HOSTS_CONF}"
        echo "server.${ZOOKEEPER_ID}=${HOST}:${ZOO_PEER_PORT}:${ZOO_LEADER_PORT}" >> "${ZOO_CONF}"
	echo -n "${HOST}:${ZOO_CLIENT_PORT}," >> "${MESOS_ZOO_CONF}"
        echo -n "${HOST}:${ZOO_CLIENT_PORT}," >> "${MARATHON_ZOO_CONF}"
        CONTAINERS+=("$(containerJson "${ZOOKEEPER_IMAGE}" "${HOST}" "${IP}")")
done
sed -i 's/,$/\/mesos\n/' "${MESOS_ZOO_CONF}"
sed -i 's/,$/\/marathon\n/' "${MARATHON_ZOO_CONF}"

# Read masters configuration
out "... masters"
truncate --size 0 "${MESOS_MASTERS_CONF}"
MASTERS_JSON=$(jsonParse "${CLUSTER_JSON}" ".${MASTERS_KEY}")
MASTER_COUNT=$(jsonParse "${MASTERS_JSON}" ". | length")
for j in $(seq 0 $((${MASTER_COUNT} - 1))); do
        ID="master$(($j + 1))"
        HOST="${ID}.${NETWORK}"
        IP=$(jsonParse "${MASTERS_JSON}" ".[${j}]")
        echo -e "${IP}\t${HOST} ${ID}" >> "${HOSTS_CONF}"
        CONTAINERS+=("$(containerJson "${MESOS_MASTER_IMAGE}" "${HOST}" "${IP}")")
done
MESOS_QUORUM=$((${ZOOKEEPER_ID} / 2 + 1))
echo "${MESOS_QUORUM}" > "${MESOS_QUORUM_CONF}"

# Read slaves configuration
out "... slaves"
truncate --size 0 "${MESOS_SLAVES_CONF}"
SLAVES_JSON=$(jsonParse "${CLUSTER_JSON}" ".${SLAVES_KEY}")
SLAVE_COUNT=$(jsonParse "${SLAVES_JSON}" ". | length")
for j in $(seq 0 $((${SLAVE_COUNT} - 1))); do
        ID="slave$(($j + 1))"
        HOST="${ID}.${NETWORK}"
        IP=$(jsonParse "${SLAVES_JSON}" ".[${j}]")
        echo -e "${IP}\t${HOST} ${ID}" >> "${HOSTS_CONF}"
        CONTAINERS+=("$(containerJson "${MESOS_SLAVE_IMAGE}" "${HOST}" "${IP}" "--privileged")")
done

# Print network setup
inf "\nNetwork setup for cluster ${CLUSTER}:
\tvlan:    ${NETWORK}
\tgateway: ${GATEWAY}
\tsubnet:  ${SUBNET}
\tdriver:  ${DRIVER}
\tscope:   ${SCOPE}
\thosts:
$(cat "${HOSTS_CONF}" | sed 's/^/\t\t /')\n"

# Solve conflicts
out "Searching for conflicts..."
RUNNING_CONTAINERS=()
for containerJson in "${CONTAINERS[@]}"; do
        HOST=$(jsonParse "${containerJson}" ".${HOST_KEY}")
        set +e 
        docker container inspect "${HOST}" &> /dev/null
	RC=$?
        set -e
        if [ $RC -eq 0 ]; then 
                RUNNING_CONTAINERS+=("${HOST}"); 
        fi
done
if [ ${#RUNNING_CONTAINERS[@]} -ne 0 ]; then
	REPLY=$(promptYesNo wrn "... conflicting containers: ${RUNNING_CONTAINERS[@]}. Remove conflicting containers?")
        if [[ $REPLY =~ ^[Yy]$ ]] || [ "${REPLY}" == "" ]; then
		for c in "${RUNNING_CONTAINERS[@]}"; do 
			docker rm -f "${c}" >> /dev/null
		done
	fi
else 
	out "... no conflicting containers"
fi
set +e
docker network inspect "${NETWORK}" &> /dev/null
RC=$?
set -e
if [ $RC -eq 0 ]; then
	REPLY=$(promptYesNo wrn "... conflicting network: ${NETWORK}. Remove conflicting network?")
	if [[ $REPLY =~ ^[Yy]$ ]] || [ "${REPLY}" == "" ]; then
                docker network remove "${NETWORK}" >/dev/null
        else
                finalize 10 "Network ${NETWORK} already exists. Can't continue."
        fi
else 
	out "... no conflicting network"
fi	

# Create cluster network
out "\nCreating network ${NETWORK}"
docker network create --gateway="${GATEWAY}" --subnet="${SUBNET}" "${NETWORK}" >/dev/null

# Start cluster
out "Starting cluster..."
# default mount points
MOUNT_POINTS_OPT="-v \"${CLUSTER_CONF}:/conf\" -v \"${SHARED}:/shared:ro\""
ENVIRONMENT_OPT="-e \"SPARK_IMAGE=${SPARK_IMAGE}\" -e \"SPARK_IMAGE_TAR=$(basename "${SPARK_IMAGE_TAR}")\""
for containerJson in "${CONTAINERS[@]}"; do
	IMAGE=$(jsonParse "${containerJson}" ".${IMAGE_KEY}")
	HOST=$(jsonParse "${containerJson}" ".${HOST_KEY}")
	IP=$(jsonParse "${containerJson}" ".${IP_KEY}")
	PRIVILEGED=$(jsonParse "${containerJson}" ".${PRIVILEGED_KEY}")
        cmd="docker run --rm -td ${PRIVILEGED} -P ${ENVIRONMENT_OPT} ${MOUNT_POINTS_OPT} --net=\"${NETWORK}\" --ip=\"${IP}\" --name \"${HOST}\" --hostname \"${HOST}\" \"${IMAGE}\""
        dbg "${cmd}"
	echo -n "... node ${HOST} "
        eval ${cmd} >> /dev/null
        checkError $? "Could not start container ${HOST}!"
	until docker exec "${HOST}" ls /tmp/node.ready &>/dev/null; do
        	docker ps | grep "${HOST}" >/dev/null
		if [ $? -ne 0 ]; then
			failure 14 "Container ${HOST} died!"
		fi
		echo -n ".";
	        sleep 0.250
	done
	echo ".. started"
done

REPLY=$(promptYesNo wrn "Super-user action required: /etc/hosts file must be edited to access cluster ${CLUSTER} from your local browser. Continue?")
if [[ $REPLY =~ ^[Yy]$ ]] || [ "${REPLY}" == "" ]; then
	sudo sed -i "/${NETWORK}/d" /etc/hosts 
	cat "${HOSTS_CONF}" | sudo tee --append /etc/hosts > /dev/null
fi

out "Done"
