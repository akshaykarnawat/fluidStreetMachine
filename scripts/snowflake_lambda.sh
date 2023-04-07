#!/bin/bash

###############################################################################
# File:         snowflake_lambda_pkg.sh
# Description:  Shell script packages the snowflake lambda function handler
#               along with the snowflake-connector-python package to be
#               deployed as zip to lambda function.
###############################################################################


###############################################################################
# create_and_activate_virtual_env
# Create and activate the virtual python environment
###############################################################################
function create_and_activate_virtual_env() {
    virtualenv ${ENV_NAME}
    source ${ENV_NAME}/bin/activate
}

###############################################################################
# install_dependencies
# install dependencies in the virtual python environment
###############################################################################
function install_dependencies() {
    local site_pkg_dir=./${ENV_NAME}/lib/python3.*/site-packages/
    cd ${site_pkg_dir}
    pip3 install --upgrade --platform ${PLATFORM} --only-binary=:all: ${PACKAGE} --target .
    chmod -R 755 .
}

###############################################################################
# create_packaged_zip
# install dependencies in the virtual python environment
###############################################################################
function create_packaged_zip() {
    local zip_file_location=~/workspace/${ENV_NAME}.zip
    zip -r9 ${zip_file_location} . | tee -a ${RUN_LOG_FILE}
    zip -jg ${zip_file_location} ${LAMBDA_FUNC_LOCATION}/* | tee -a ${RUN_LOG_FILE}
}

###############################################################################
# MAIN
###############################################################################
USER=$(whoami)
SCRIPT=$0
SCRIPT_DIR_PATH="${0%/*}"
ENV_NAME=${1}
LAMBDA_FUNC_LOCATION=${2}

source ${SCRIPT_DIR_PATH}/logger.sh

APP_PATH=$(dirname ${SCRIPT_DIR_PATH})
RUN_LOG_FILE=$(logger::init ${APP_PATH}/logs snowflake_lambda)
CURRENT_TIME="$(date +'%Y%m%d%H%M%S')"

PLATFORM=manylinux_2_12_x86_64
PACKAGE=snowflake-connector-python

create_and_activate_virtual_env
install_dependencies
create_packaged_zip
