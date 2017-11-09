#!/bin/bash 
SCRIPT=$(readlink -f "${0}")
SCRIPT_BASENAME=$(basename "${SCRIPT}")
SCRIPT_NAME=$(echo "${SCRIPT_BASENAME}" | sed 's/\\..*//')
SCRIPT_DIR=$(dirname "${SCRIPT}")

export http_proxy="" 

echo "Submitting Spark application (compute Pi)"
JSON=$(curl -sSX POST -d@"${SCRIPT_DIR}/pi.json"  --header "Content-Type:application/json;charset=UTF-8" "http://master1.cluster1.net:7077/v1/submissions/create")



ID=$(echo "${JSON}" | jq -r ".submissionId")
STATUS="QUEUED"

echo "Application ID: ${ID}"
while [ "${STATUS}" == "RUNNING" ] || [ "${STATUS}" == "QUEUED" ];  do 
	JSON=$(curl -sS "http://master1.cluster1.net:7077/v1/submissions/status/${ID}" | jq ".")
	STATUS=$(echo "${JSON}" | jq -r ".driverState")
	MESSAGE=$(echo "${JSON}" | jq -r ".message")
	echo -en "Status: $STATUS\r"
	sleep 1;
done

echo "Application ${ID} finished with status ${STATUS}. Message:"
echo -e "${MESSAGE}"

