#!/usr/bin/env bash

. ../../automated-build/config.cfg

usage() {
    echo '
    ###############################################################
    Help:

    * Description:
        - Makes a Singularity API call to update the software database entry
    * Usage:
        - ./scripts/db.sh [software name]

    ###############################################################
    '
}

if [ "$#" -ne 1 ]; then
    usage
    exit 100
fi

OUTPUT_FILE=./meta.json

curl --location --request PUT "${SINGULARITY_API_HOST}/singularity/${1}"  -H "Content-Type: application/json" -H "Authorization: bearer ${SINGULARITY_API_KEY}" --data "@${OUTPUT_FILE}"
