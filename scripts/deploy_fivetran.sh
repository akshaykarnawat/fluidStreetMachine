#!/bin/bash

###############################################################################
# File:         deploy_fivetran.sh
# Description:  Deploy fivetran connectors and destinations and setups the
#               pipeline to start processing data.
# Author:       @akshaykarnawat
###############################################################################


###############################################################################
# MAIN
###############################################################################
USER=$(whoami)
SCRIPT=$0
SCRIPT_DIR_PATH="${0%/*}"

source ${SCRIPT_DIR_PATH}/logger.sh

APP_PATH=$(dirname ${SCRIPT_DIR_PATH})
DEPLOY_LOG_FILE=$(logger::init ${APP_PATH}/logs/deploy)
CURRENT_TIME="$(date +'%Y%m%d%H%M%S')"

logger::log [INFO] "=======================================" ${DEPLOY_LOG_FILE}
logger::log [INFO] "=========== FIVETRAN DEPLOYER =========" ${DEPLOY_LOG_FILE}
logger::log [INFO] "=======================================" ${DEPLOY_LOG_FILE}
logger::log [INFO] "Current time is: ${CURRENT_TIME}" ${DEPLOY_LOG_FILE}
logger::log [INFO] "=======================================" ${DEPLOY_LOG_FILE}

# todo create the group
# todo create the destination in the group
# bash ${SCRIPT_DIR_PATH}/fivetran.sh -e configs/fivertan/fivetran_endpoints.json -f create_destination -s configs/fivertan/snowflake_destination_config.json -a "group_id=wharves_confess region=AWS_US_WEST_2 snowflake_host=fsb33346.prod3.us-west-2.aws.snowflakecomputing.com snowflake_database=dev" | tee -a ${DEPLOY_LOG_FILE}

# creating the email connector
logger::log [INFO] "Creating email connector" ${DEPLOY_LOG_FILE}
bash ${SCRIPT_DIR_PATH}/fivetran.sh -e configs/fivertan/fivetran_endpoints.json -f create_connector -s configs/fivertan/email_connector_config.json -a "group_id=wharves_confess run_setup_tests=false paused=true pause_after_trial=true sync_frequency=360 schema=fivetran_data file_option=upsert_file file_type=csv delimiter=, compression=infer table=school_attendance" | tee -a ${DEPLOY_LOG_FILE}

# creating the sage intacct connector
# logger::log [INFO] "Creating sage connector" ${DEPLOY_LOG_FILE}
# bash ${SCRIPT_DIR_PATH}/fivetran.sh -e configs/fivertan/fivetran_endpoints.json -f create_connector -s configs/fivertan/sage_connector_config.json -a "group_id=wharves_confess run_setup_tests=false paused=true pause_after_trial=true sync_frequency=360 schema=fivetran_data login_password=secr3t user_i_d=fivetran company_i_d=generation" | tee -a ${DEPLOY_LOG_FILE}

# add any other connector or destination we want to create
# can also use additional endpoint as seem fit