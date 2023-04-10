#!/bin/bash

###############################################################################
# File:         deploy_aws.sh
# Description:  AWS deployment script
###############################################################################



###############################################################################
# get_all_stacks
# get all the current stacks deployed using the aws cli
#
# Returns:
#   stack_names: list of aws stacks
#
###############################################################################
function get_all_stacks() {
    local filter=CREATE_COMPLETE
    aws cloudformation list-stacks \
    --stack-status-filter "${filter}" \
    --query "StackSummaries[].StackName" \
    --output text
}

###############################################################################
# search_stacks
# search the stacks given the following arguments
#
# Arguments:
#   query: search query
#   output_mode: output mode of "text", "json", etc.
# Returns:
#   stack_information: stack information after query filter and desired output
#                      mode
#
###############################################################################
function search_stacks() {
    local query=${1}
    local output_mode=${2}
    aws cloudformation describe-stacks --query "${query}" --output ${output_mode}
}

###############################################################################
# create_iam
# Create IAM roles, policies, and groups
#
# Arguments:
#   stack_name: name of stack
#
###############################################################################
function create_iam() {
    local stack_name=${1}

    # check to see if the stack exists already
    stack=$(search_stacks "Stacks[?contains(StackName,'${stack_name}')].StackName" text)

    if [[ ${stack} != ${stack_name} ]]; then
        aws cloudformation create-stack --stack-name ${stack_name} \
        --template-body file://${TEMPLATE_PATH}/iam.yaml \
        --parameters \
            ParameterKey=Users,ParameterValue="" \
            ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
        --region us-east-1
    fi

    echo $(search_stacks "Stacks[?contains(StackName,'${stack_name}')].StackId" text)
}

###############################################################################
# create_code_deploy_bucket
# Create code deploy S3 bucket which will hold all deployable artifacts
#
# Arguments:
#   stack_name: name of stack
#
###############################################################################
function create_code_deploy_bucket() {
    local stack_name=${1}

    # check to see if the stack exists already
    stack=$(search_stacks "Stacks[?contains(StackName,'${stack_name}')].StackName" text)

    if [[ ${stack} != ${stack_name} ]]; then

        # todo: create the s3 bucket with the codedeploy specific name
    fi

    echo $(search_stacks "Stacks[?contains(StackName,'${stack_name}')].StackId" text)
    # TODO: return bucket name
}

###############################################################################
# deploy_artifacts
# deploy artifacts to the code deploy bucket
###############################################################################
function deploy_artifacts() {
    local code_deploy_bucket=${1}

    bucket=$(aws cloudformation describe-stacks --query "Stacks[?contains(StackName,'${stack_name}')].Outputs[0][?contains(OutputKey, 'BucketName')].OutputValue" --output text)
    aws s3 cp artifact.zip s3://${bucket}
    aws s3 cp snow_lambda.zip s3://${bucket}
    dirsToUpload=("databases" "functions" "iac/cfn")
    for i in ${dirsToUpload[@]}; do
        aws s3 cp ./$i s3://${bucket} --recursive
    done

}

###############################################################################
# deploy
# AWS deployment for the following items:
# [-] IAM Roles, policies, groups, etc.
# [-] Code deploy S3 bucket and deploy packaged artifacts
# [-] Raw and Curated S3 buckets
# [-] Glue job and catalogs
# [-] Step functions, lambda, event bridge
#
# Arguments:
#   template_path: location of aws cloudformation templates
#
###############################################################################
function deploy() {

    echo All the stacks currently deployed:
    get_all_stacks

    # create IAM roles, policies, and groups
    #create_iam

    # create S3 code deploy bucket and deploy artifacts
    #local code_deploy_bucket=$(create_code_deploy_bucket)
    #deploy_artifacts ${code_deploy_bucket}

    local layer="raw"
    local stack_name=${PROJECT_NAME}-s3-bucket-${layer}-${ENVIRONMENT}

    # creating a stack if the stack does not exist already
    stack=$(aws cloudformation describe-stacks --query "Stacks[?contains(StackName,'${stack_name}')].StackName" --output text)
    if [[ ${stack} != ${stack_name} ]]; then
        aws cloudformation create-stack --stack-name ${stack_name} \
        --template-body file://${TEMPLATE_PATH}/s3_bucket.yaml \
        --parameters \
            ParameterKey=ProjectName,ParameterValue=${PROJECT_NAME} \
            ParameterKey=DataLayer,ParameterValue=${layer} \
            ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
        --region us-east-1
        sleep 30 # temp
    fi

    # upload all artifacts and files to aws
    bucket=$(aws cloudformation describe-stacks --query "Stacks[?contains(StackName,'${stack_name}')].Outputs[0][?contains(OutputKey, 'BucketName')].OutputValue" --output text)
    aws s3 cp artifact.zip s3://${bucket}
    aws s3 cp snow_lambda.zip s3://${bucket}
    dirsToUpload=("databases" "functions" "iac/cfn")
    for i in ${dirsToUpload[@]}; do
        aws s3 cp ./$i s3://${bucket} --recursive
    done

    # use the cloudformation template to create s3 raw and curated buckets

    # then use cloudformation to deploy the creation of step functions, lambda, etc.

    # update lambda function codebase with the packaged version here
    lambda_function=$(aws lambda list-functions --query "Functions[?contains(FunctionName, 'Snowflake')].FunctionName" --output text)
    [[ -n lambda_function ]] && \
    aws lambda update-function-code --function-name ${lambda_function} --region us-east-1 --s3-bucket ${bucket} --s3-key snow_lambda.zip

    # deploy the clodformation templates for glue job

    # deploy the cloudformation templates for xyz

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

TEMPLATE_PATH=${APP_PATH}/iac/cfn
deploy
