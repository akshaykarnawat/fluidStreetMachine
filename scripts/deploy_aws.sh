#!/bin/bash

###############################################################################
# File:         deploy_aws.sh
# Description:  AWS deployment script
# Author:       @akshaykarnawat
###############################################################################



###############################################################################
# get_all_stacks
# get all the current stacks deployed
###############################################################################
function get_all_stacks() {
    aws cloudformation list-stacks --stack-status-filter "CREATE_COMPLETE" --query "StackSummaries[].StackName"
}

###############################################################################
# get_all_stacks
# get all the current stacks deployed
###############################################################################
function depoy() {
    local TEMPLATE_PATH=${1}

    echo Here are all the stacks currently deployed
    get_all_stacks

    local layer="Raw"
    local bucket_name=gen3-data-arch.${layer}.${ENVIRONMENT}
    local stack_name=${PROJECT_NAME}-s3-bucket-${layer}-${ENVIRONMENT}

    # creating a stack if the stack does not exist already
    stack=$(aws cloudformation describe-stacks --query "Stacks[?contains(StackName,'${stack_name}')].StackName" --output text)
    if [[ ${stack} != ${stack_name} ]]; then
        aws cloudformation create-stack --stack-name ${stack_name} \
        --template-body file://${TEMPLATE_PATH}/s3_bucket.yaml \
        --parameters ParameterKey=ProjectName,ParameterValue=${PROJECT_NAME} \
        ParameterKey=BucketName,ParameterValue=${bucket_name} \
        ParameterKey=DataLayer,ParameterValue=${layer} \
        ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
        --region us-east-1
    fi

    # todo fixme -- get the list of buckets and check if the bucket exists before adding anything to the bucket
    sleep 60 # temp

    aws s3 cp artifact.zip s3://${bucket_name}/

}

###############################################################################
# MAIN
###############################################################################
USER=$(whoami)
SCRIPT=${0}
SCRIPT_DIR_PATH="${0%/*}"
ENVIRONMENT=${1}

source ${SCRIPT_DIR_PATH}/logger.sh

APP_PATH=$(dirname ${SCRIPT_DIR_PATH})
DEPLOY_LOG_FILE=$(logger::init ${APP_PATH}/logs/deploy aws_cloudformation)
CURRENT_TIME="$(date +'%Y%m%d%H%M%S')"
PROJECT_NAME=data-arch

logger::log [INFO] "=======================================" ${DEPLOY_LOG_FILE}
logger::log [INFO] "============= AWS DEPLOYER ============" ${DEPLOY_LOG_FILE}
logger::log [INFO] "=======================================" ${DEPLOY_LOG_FILE}
logger::log [INFO] "Current time is: ${CURRENT_TIME}" ${DEPLOY_LOG_FILE}
logger::log [INFO] "=======================================" ${DEPLOY_LOG_FILE}

deploy ${APP_PATH}/iac/cfn