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
# get_stack_status
# get stack's satus
#
# Returns:
#   stack_status: status of stack
#
###############################################################################
function get_stack_status() {
    local stack_name=${1}
    echo aws cloudformation describe-stacks \
    --query "Stacks[?contains(StackName,'${stack_name}')].StackStatus" \
    --output text
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

        # [[ $(get_stack_status ${stack_name}) != CREATE_COMPLETE ]] && sleep 10
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

    dirsToUpload=("databases" "functions" "iac" "jobs/step_functions")
    for dir in ${dirsToUpload[@]}; do
        aws s3 sync --delete ./${dir} s3://${code_deploy_bucket}/${dir}
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
# deploy_orchestration
# Create Step functions, lambda, and event bridge
#
# Arguments:
#   stack_name: name of stack
#   code_deploy_bucket: name of S3 bucket with code artifacts
#
###############################################################################
function deploy_orchestration() {
    local stack_name=${1}
    local code_deploy_bucket=${2}
    local execution_input=$(echo $(cat "${3}") | tr -d '[ ]')
    execution_input=$(echo \"${execution_input//\"/\\\"}\")

    stack=$(describe_stacks "Stacks[?contains(StackName,'${stack_name}')].StackName" text)
    # if the stack does not exist create it, else update the stack's function
    if [[ ${stack} != ${stack_name} ]]; then
        echo Input to the stack is ${execution_input}
        aws cloudformation create-stack --stack-name ${stack_name} \
        --template-body file://${TEMPLATE_PATH}/etl_state_machine.yaml \
        --parameters \
            ParameterKey=ProjectName,ParameterValue=${PROJECT_NAME} \
            ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
        --region ${AWS_REGION} --capabilities CAPABILITY_IAM
        sleep 30
    fi
    # echo $(describe_stacks "Stacks[?contains(StackName,'${stack_name}')].StackId" text)

    # # update the codebase for Matillion job
    # local matillion_job_function=$(describe_stacks "Stacks[?contains(StackName,'${stack_name}')].Outputs[0][?contains(OutputKey, 'MatillionJobRunner')].OutputValue" text)
    # [[ -n matillion_job_function ]] && \
    # aws lambda update-function-code --function-name ${matillion_job_function} --region ${AWS_REGION} --s3-bucket ${code_deploy_bucket} --s3-key ${SNOW_LAMBDA_KEY}

    # # update the codebase for Snowflake job
    # local snowflake_job_function=$(describe_stacks "Stacks[?contains(StackName,'${stack_name}')].Outputs[0][?contains(OutputKey, 'SnowflakeRunner')].OutputValue" text)
    # [[ -n snowflake_job_function ]] && \
    # aws lambda update-function-code --function-name ${snowflake_job_function} --region ${AWS_REGION} --s3-bucket ${code_deploy_bucket} --s3-key ${SNOW_LAMBDA_KEY}

}

###############################################################################
# deploy_all
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
function deploy_all() {

    echo All the stacks currently deployed:
    get_all_stacks

    # create IAM roles, policies, and groups
    create_iam ${PROJECT_NAME}-iam-${ENVIRONMENT}

    # create S3 code deploy bucket and deploy artifacts
    local code_deploy_bucket=$(create_code_deploy_bucket ${PROJECT_NAME}-code-deploy-s3-bucket-${ENVIRONMENT})
    echo ${code_deploy_bucket}
    deploy_artifacts ${code_deploy_bucket}

    # create s3 raw and curated buckets
    create_data_bucket ${PROJECT_NAME}-s3-bucket-raw-${ENVIRONMENT} Raw
    create_data_bucket ${PROJECT_NAME}-s3-bucket-curated-${ENVIRONMENT} Curated

    # deploy the clodformation templates for glue job
    #deploy_glue

    # create step functions, lambda functions, and event bridge from cloudformation template
    deploy_orchestration "generation-data-ELT-state-machine-${ENVIRONMENT}" ${code_deploy_bucket} "./configs/step_functions/ELTStateMachine_input.json"

    # # update handler for the lambda function
    # echo "Updating function's lambda handler"
    # local handler_name=snowflake_transformation.lambda_handler
    # aws lambda update-function-configuration --function-name ${lambda_function} --region ${AWS_REGION} --handler ${handler_name}

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
deploy_all
