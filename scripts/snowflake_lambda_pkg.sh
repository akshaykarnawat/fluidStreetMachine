#!/bin/bash

###############################################################################
# File:         snowflake_lambda_pkg.sh
# Description:  Shell script packages the snowflake lambda function handler
#               along with the snowflake-connector-python package to be
#               deployed as zip to lambda function.
###############################################################################

# high level steps
#virtualenv venv
#source venv/bin/activate
#cd venv/lib64/python3.9/site-packages/
# https://github.com/pyca/cryptography/issues/6390
# https://stackoverflow.com/questions/75389710/error-lib64-libc-so-6-version-glibc-2-28-not-found-required-by-var-task-c
#pip3 install --platform manylinux_2_12_x86_64 --only-binary=:all: snowflake-connector-python --target .
#chmod -R 755 .
#zip -r9 ~/snow_lambda.zip .
#cd ~
#vim lambda_function.py
# {{copy lambda function code in vim}}
#zip -g snow_lambda.zip lambda_function.py
#aws s3 cp snow_lambda.zip s3://snowflake-connector-lambda

###############################################################################
# create_and_activate_virtual_env
# Create and activate the virtual python environment
###############################################################################
function create_and_activate_virtual_env() {
    virtualenv snow_lambda
    source snow_lambda/bin/activate
}

###############################################################################
# install_dependencies
# install dependencies in the virtual python environment
###############################################################################
function install_dependencies() {
    cd ./snow_lambda/lib*/python3.*/site-packages/
    pip3 install --platform manylinux_2_12_x86_64 --only-binary=:all: snowflake-connector-python --target .
    chmod -R 755 .
}

###############################################################################
# create_packaged_zip
# install dependencies in the virtual python environment
###############################################################################
function create_packaged_zip() {
    zip -r9 ~/snow_lambda.zip .
    zip -g ~/snow_lambda.zip ${APP_PATH}/functions/run_snowflake_transformations.py
}

###############################################################################
# MAIN
###############################################################################
USER=$(whoami)
SCRIPT=$0
SCRIPT_DIR_PATH="${0%/*}"

source ${SCRIPT_DIR_PATH}/logger.sh

APP_PATH=$(dirname ${SCRIPT_DIR_PATH})
RUN_LOG_FILE=$(logger::init ${APP_PATH}/logs snowflake_lambda_pkg)
CURRENT_TIME="$(date +'%Y%m%d%H%M%S')"

create_and_activate_virtual_env
install_dependencies
create_packaged_zip
