#!/bin/bash -e 
SCRIPT=$(readlink -f "${0}")
SCRIPT_BASENAME=$(basename "${SCRIPT}")
SCRIPT_NAME=$(echo "${SCRIPT_BASENAME}" | sed 's/\\..*//')
SCRIPT_DIR=$(dirname "${SCRIPT}")

function out() { echo -e "\e[32m${@}\e[39m"; }
function inf() { echo -e "\e[97m${@}\e[39m"; }
function err() { echo -e "\e[31m${@}\e[39m" 1>&2; }
function wrn() { echo -e "\e[33m${@}\e[39m" 1>&2; }
function dbg() { if [ "${DBG}" == "true" ]; then echo -e "\e[34m${@}\e[39m"; fi }

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

function promptYesNo() {
        if [ "${FORCE_YES}" == "Y" ]; then
                $@ "[Y/n] Y"
                echo "Y"
        else
                read -p "$($@ "[Y/n]")" -n 1 -r
                echo "${REPLY}"
        fi
}

function jsonParse {
        KEY=${2:-}
        echo "${1}" | jq -r "${KEY}"
}

