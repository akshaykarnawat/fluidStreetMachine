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
#
# Note: platform specific dependencies are installed in the virtual environment
# allowing this to work with lambda functions.
###############################################################################
function install_dependencies() {
    local site_pkg_dir=./${ENV_NAME}/lib/python3.*/site-packages/

    cd ${site_pkg_dir}

    # install python package dependencies
    pip3 install --upgrade \
    --platform ${PLATFORM} \
    --only-binary=:all: ${PY_PACKAGES} \
    --target .

    # recursively give access to read and execute the package files
    chmod -R 755 .
}

###############################################################################
# create_packaged_zip
# install dependencies in the virtual python environment
###############################################################################
function create_packaged_zip() {
    # zip all packages and append the lambda files to the zip ignoring the path
    zip -r9 ${ZIP_FILE_PATH} .
    zip -jg ${ZIP_FILE_PATH} ${LAMBDA_FUNC_LOCATION}/*
}

###############################################################################
# MAIN
###############################################################################
USER=$(whoami)
SCRIPT=$0
SCRIPT_DIR_PATH="${0%/*}"
ENV_NAME=${1}
LAMBDA_FUNC_LOCATION=${2}
ZIP_FILE_PATH=${3}

source ${SCRIPT_DIR_PATH}/logger.sh

APP_PATH=$(dirname ${SCRIPT_DIR_PATH})
RUN_LOG_FILE=$(logger::init ${APP_PATH}/logs snowflake_lambda)
CURRENT_TIME="$(date +'%Y%m%d%H%M%S')"

PLATFORM=manylinux_2_12_x86_64
PY_PACKAGES=snowflake-connector-python

create_and_activate_virtual_env
install_dependencies
create_packaged_zip
