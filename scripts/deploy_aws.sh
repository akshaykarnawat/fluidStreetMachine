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
    --output json
}

###############################################################################
# describe_stacks
# search the stacks given the following arguments
#
# Arguments:
#   query: search query
#   output_mode: output mode of "text", "json", etc.
# Returns:
#   stack_information: stack info after query filter in desired output mode
#
###############################################################################
function describe_stacks() {
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
# Returns:
#   stackId: cloud formation stack id
#
###############################################################################
function create_iam() {
    local stack_name=${1}

    # check to see if the stack exists already
    stack=$(describe_stacks "Stacks[?contains(StackName,'${stack_name}')].StackName" text)

    if [[ ${stack} != ${stack_name} ]]; then
        aws cloudformation create-stack --stack-name ${stack_name} \
        --template-body file://${TEMPLATE_PATH}/iam.yaml \
        --parameters \
            ParameterKey=Users,ParameterValue="" \
            ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
        --region ${AWS_REGION}
    fi

    echo $(describe_stacks "Stacks[?contains(StackName,'${stack_name}')].StackId" text)
}

###############################################################################
# create_code_deploy_bucket
# Create code deploy S3 bucket which will hold all deployable artifacts
#
# Arguments:
#   stack_name: name of stack
# Returns:
#   code_deploy_bucket: code deploy bucket name
#
###############################################################################
function create_code_deploy_bucket() {
    local stack_name=${1}

    # check to see if the stack exists already
    stack=$(describe_stacks "Stacks[?contains(StackName,'${stack_name}')].StackName" text)
    if [[ ${stack} != ${stack_name} ]]; then
        aws cloudformation create-stack --stack-name ${stack_name} \
        --template-body file://${TEMPLATE_PATH}/code_deploy_s3_bucket.yaml \
        --parameters \
            ParameterKey=ProjectName,ParameterValue=${PROJECT_NAME} \
            ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
        --region ${AWS_REGION} 1>&2
        sleep 30
    fi

    echo $(describe_stacks "Stacks[?contains(StackName,'${stack_name}')].Outputs[0][?contains(OutputKey, 'BucketName')].OutputValue" text)
}

###############################################################################
# deploy_artifacts
# deploy artifacts to the code deploy bucket
#
# Arguments:
#   code_deploy_bucket: name of code deploy bucket
#
###############################################################################
function deploy_artifacts() {
    local code_deploy_bucket="${1}"
    local all_artifacts_zip_key=packages/artifact.zip
    SNOW_LAMBDA_KEY=packages/snow_lambda.zip

    aws s3 cp artifact.zip s3://${code_deploy_bucket}/${all_artifacts_zip_key}
    aws s3 cp snow_lambda.zip s3://${code_deploy_bucket}/${SNOW_LAMBDA_KEY}

    dirsToUpload=("databases" "functions" "iac")
    for dir in ${dirsToUpload[@]}; do
        aws s3 cp ./${dir} s3://${code_deploy_bucket}/${dir} --recursive
    done

}

###############################################################################
# create_data_bucket
# Create data bucket for the given data layer
#
# Arguments:
#   stack_name: name of stack
#   data_layer: raw or curated data layer
# Returns:
#   bucket: bucket name
#
###############################################################################
function create_data_bucket() {
    local stack_name=${1}
    local data_layer=${2}

    stack=$(describe_stacks "Stacks[?contains(StackName,'${stack_name}')].StackName" text)
    if [[ ${stack} != ${stack_name} ]]; then
        aws cloudformation create-stack --stack-name ${stack_name} \
        --template-body file://${TEMPLATE_PATH}/s3_bucket.yaml \
        --parameters \
            ParameterKey=ProjectName,ParameterValue=${PROJECT_NAME} \
            ParameterKey=DataLayer,ParameterValue=${data_layer} \
            ParameterKey=Environment,ParameterValue=${ENVIRONMENT^} \
        --region ${AWS_REGION} 1>&2
        sleep 30
    fi

    echo $(describe_stacks "Stacks[?contains(StackName,'${stack_name}')].Outputs[0][?contains(OutputKey, 'BucketName')].OutputValue" text)
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
    create_iam ${PROJECT_NAME}-iam-${ENVIRONMENT}

    # create S3 code deploy bucket and deploy artifacts
    local code_deploy_bucket=$(create_code_deploy_bucket ${PROJECT_NAME}-code-deploy-s3-bucket-${ENVIRONMENT})
    echo $code_deploy_bucket
    deploy_artifacts ${code_deploy_bucket}

    # create s3 raw and curated buckets
    create_data_bucket ${PROJECT_NAME}-s3-bucket-raw-${ENVIRONMENT} Raw
    create_data_bucket ${PROJECT_NAME}-s3-bucket-curated-${ENVIRONMENT} Curated

    # deploy the clodformation templates for glue job
    #deploy_glue

    # create step functions, lambda functions, and event bridge from cloudformation template -- todo
    # update lambda function codebase with the snow_lambda package
    echo "Updating function's code"
    local function_name=Snowflake
    lambda_function=$(aws lambda list-functions --query "Functions[?contains(FunctionName, '${function_name}')].FunctionName" --output text)
    [[ -n lambda_function ]] && \
    aws lambda update-function-code --function-name ${lambda_function} --region ${AWS_REGION} --s3-bucket ${code_deploy_bucket} --s3-key ${SNOW_LAMBDA_KEY}

    sleep 15
    # update handler for the lambda function
    echo "Updating function's lambda handler"
    local handler_name=snowflake_transformation.lambda_handler
    aws lambda update-function-configuration --function-name ${lambda_function} --region ${AWS_REGION} --handler ${handler_name}

}

###############################################################################
# MAIN
###############################################################################
USER=$(whoami)
SCRIPT=${0}
SCRIPT_DIR_PATH="${0%/*}"
ENVIRONMENT=${1,,}

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
AWS_REGION=us-east-1
deploy
