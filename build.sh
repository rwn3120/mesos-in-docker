#!/bin/bash -e
SCRIPT=$(readlink -f "${0}")
SCRIPT_BASENAME=$(basename "${SCRIPT}")
SCRIPT_NAME=$(echo "${SCRIPT_BASENAME}" | sed 's/\\..*//')
SCRIPT_DIR=$(dirname "${SCRIPT}")

. "${SCRIPT_DIR}/utils.sh"

TAGS=("zookeeper" "base" "spark" "master" "slave")
for tag in "${TAGS[@]}"; do 
	# get path to docker context
	DOCKER_CONTEXT="${SCRIPT_DIR}/${tag}"
	
	# prepare build args
	build_args=()
	case "${tag}" in "spark" | "master" | "slave")	
		build_args+=("--build-arg=SPARK_VERSION=${SPARK_VERSION}")
		build_args+=("--build-arg=HADOOP_VERSION=${HADOOP_VERSION}");;
	esac
	case "${tag}" in 
		"base")		build_args+=("--squash")
				;;
		"spark")	build_args+=("--squash")
				tag=${SPARK_IMAGE_TAG}
				;;
		"slave")	build_args+=("--build-arg=SPARK_IMAGE=$(getId "${SPARK_IMAGE_TAG}")")
				;;
	esac

	ID=$(getId "${tag}")
	
	# build
	echo -e "\nBuilding ${ID} ..."
	docker build \
		-t "${ID}" \
		${build_args[@]} \
		"${DOCKER_CONTEXT}"

	# distribute
	if [ "${1}" == "--distrib" ]; then
		docker push "${ID}"
	fi
done
