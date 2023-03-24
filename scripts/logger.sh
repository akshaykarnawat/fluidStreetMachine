#!/bin/bash

###############################################################################
# File:         logger.sh
# Description:  Utility script to log messages
# Author:       @akshaykarnawat
###############################################################################


###############################################################################
# logger::init
# initializes the log file in the desired path
#
# Arguments:
#   RUN_LOG_PATH: directory path where to initialize a run log file
# Returns:
#   RUN_LOG_FILE: run log file path
#
###############################################################################
function logger::init() {
    local RUN_LOG_PATH="${1}"
    local PREFIX="${2}"
    local CURRENT_TIME="$(date +'%Y%m%d%H%M%S')"

    # create the log path directory
    mkdir -p ${RUN_LOG_PATH}
    chmod 775 ${RUN_LOG_PATH}

    # find any log file older than 30 days and delete
    #find ${RUN_LOG_PATH} -type -f -mtime +30 -delete

    # create the log file in the log path
    local RUN_LOG_FILE=${RUN_LOG_PATH}/${PREFIX}_${CURRENT_TIME}.log
    touch ${RUN_LOG_FILE}
    chmod 775 ${RUN_LOG_FILE}

    echo ${RUN_LOG_FILE}
}

###############################################################################
# logger::log
# logs the messages in the run log file
#
# Arguments:
#   LOG_LEVEL: logging level (aka. info, error, warn, etc.)
#   MESSAGE: message to log
#   RUN_LOG_FILE: run log file path
###############################################################################
function logger::log() {
    local LOG_LEVEL=${1}
    local MESSAGE=${2}
    local RUN_LOG_FILE=${3}
    local HOSTNAME=$(hostname)
    local CURRENT_TIME="$(date +'%Y-%m-%d %H:%M:%S')"

    echo "${CURRENT_TIME} ${LOG_LEVEL} [${HOSTNAME}]: ${MESSAGE}" \
    >> ${RUN_LOG_FILE}
}
