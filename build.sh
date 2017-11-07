#!/bin/bash -e
SCRIPT=$(readlink -f "${0}")
SCRIPT_BASENAME=$(basename "${SCRIPT}")
SCRIPT_NAME=$(echo "${SCRIPT_BASENAME}" | sed 's/\\..*//')
SCRIPT_DIR=$(dirname "${SCRIPT}")

REPO="radowan"
NAME="mesos-in-docker"
VERSION="latest"

IMAGES=("zookeeper" "base" "master" "slave")

for image in "${IMAGES[@]}"; do 
	DOCKER_CONTEXT="${SCRIPT_DIR}/${image}"
	TAG="${REPO}/${NAME}:${image}-${VERSION}"
	docker build -t "${TAG}" "${DOCKER_CONTEXT}" 
	if [ "${1}" == "--distrib" ]; then
		docker push "${TAG}"
	fi
done
