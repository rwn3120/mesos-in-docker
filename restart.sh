#!/bin/bash -e 
. utils.sh

"${SCRIPT_DIR}/stop.sh" $@
"${SCRIPT_DIR}/start.sh" $@
