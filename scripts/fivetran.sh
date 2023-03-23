#!/bin/bash

###############################################################################
# File:         fivetran.sh
# Description:  Shell script which serves as a wrapper to Fivetran RESTful
#               interface. Provides the ability to parameterize the configs
#               and endpoint urls via the command line.
# Author:       @akshaykarnawat
###############################################################################


###############################################################################
# print_error
###############################################################################
function print_error() {
    >&2 echo -e "$@"
}

###############################################################################
# fail
#
# Arguments:
#   exitCode: shell exit codes
#
###############################################################################
function fail() {
    local exitCode=${2:-1}
    [[ -n ${1} ]] && print_error "${1}"
    exit ${exitCode}
}

###############################################################################
# fivetran::usage
# prints usage of the shell script
###############################################################################
function fivetran::usage() {
    fail "$(cat <<-EOF

    usage: fivetran.sh [-e] [-f] [-s] [-d] [-a]
        -e -- [Required] Endpoint Config File
        -f -- [Required] Endpoint Function
        -s -- [Optional] Source Connector Config File
        -d -- [Optional] Destination Config File
        -a -- [Optional] Additional Parameterized Arguments

    Notes:
    Please make sure .env file is defined in the parent directory with the \\
    AUTH_TOKEN value. The API key can be retrieved from fivetran and encoded \\
    with \`base64 AUTH_KEY:SECRET_TOKEN\`

    Examples:
    [ Getting all users ]
    bash ./fivetran.sh -e /full/path/to/endpoint/config/file.json -f "get_users"

    [ Getting groups ]
    bash ./fivetran.sh -e /full/path/to/endpoint/config/file.json -f "get_groups"

    [ Create Connector ]
    bash ./fivetran.sh -e /full/path/to/endpoint/config/file.json \\
    -f "create_connector" -s /full/path/to/connector/configfile.json \\
    -a "group_id=wharves_confess schema=dev ..."

    [ Create Destination ]
    bash ./fivetran.sh -e /full/path/to/endpoint/config/file.json \\
    -f "create_destination" -d /full/path/to/destination/configfile.json \\
    -a "group_id=wharves_confess schema=dev user_id=fivetran_dev_user ..."

    [ Test Connector ]
    bash ./fivetran.sh -e /full/path/to/endpoint/config/file.json \\
    -f "test_connector" -a "CONNECTOR_ID=renown_tacitly"

    [ Force Sync Connector ]
    bash ./fivetran.sh -e /full/path/to/endpoint/config/file.json \\
    -f "force_sync_connector" -a "CONNECTOR_ID=renown_tacitly"

    [ Pause Connector ]
    bash ./fivetran.sh -e /full/path/to/endpoint/config/file.json \\
    -f "pause_connector" -a "CONNECTOR_ID=renown_tacitly"

EOF
    )"
}

###############################################################################
# fivetran::parse_arguments
# parse script arguments to global variables
###############################################################################
function fivetran::parse_arguments() {
    [[ $# -le 0 ]] && fivetran::usage
    while getopts "e:f:s:d:a:" opt; do
        case "${opt}" in
            e) ENDPOINT_CONFIG_PATH=${OPTARG} ;;
            f) FUNCTION=${OPTARG} ;;
            s) CONNECTOR_CONFIG_PATH=${OPTARG} ;;
            d) DESTINATION_CONFIG_PATH=${OPTARG} ;;
            a) ARGUMENTS=${OPTARG} ;;
            *) print_error "Unexpected Option: ${opt} \n" && fivetran::usage ;;
        esac
    done
}

###############################################################################
# fivetran::validate_arguments
# validate the arguments
###############################################################################
function fivetran::validate_arguments() {
    [[ -z ${ENDPOINT_CONFIG_PATH} ]] && \
    print_error "-e argument missing" && fivetran::usage

    [[ -z ${FUNCTION} ]] && \
    print_error "-f argument missing" && fivetran::usage

    # if the function we are calling is create connector then make sure the
    # connector config file is provided
    [[ ${FUNCTION} == create_connector ]] && \
    [[ -z ${CONNECTOR_CONFIG_PATH} ]] && \
    print_error "-s argument missing" && fivetran::usage

    # if the function we are calling is create destination then make sure the
    # destination config file is provided
    [[ ${FUNCTION} == create_destination ]] && \
    [[ -z ${DESTINATION_CONFIG_PATH} ]] && \
    print_error "-d argument missing" && fivetran::usage
}

###############################################################################
# fivetran::parse_config
# parse the config file
#
# Arguments:
#   config_file: config file path
#
###############################################################################
function fivetran::parse_config() {
    [[ -z ${1} ]] && return
    logger::log [INFO] "Reading config file ${1}" ${RUN_LOG_FILE}
    echo $(cat "${1}")
}

###############################################################################
# fivetran::set_additional_arguments
# set the additional arguments as variables which can be used in the script
###############################################################################
function fivetran::set_additional_arguments() {
    local args=($(echo ${ARGUMENTS}))
    for arg in ${args[@]}; do
        $(eval echo "export ${arg}")
    done
}

###############################################################################
# fivetran::search_json
# search the json data string for the given key. Note: this is does not do a
# recursive lookup.
# Note: If the json string is { "school" : "lindbergh", "students" : {...} }
# and we search for school, the function will return value lindbergh.
#
# Arguments:
#   data: json_data in which we need to search
#   key: json key we need to search for
# Returns:
#   value: key's value
#
###############################################################################
function fivetran::search_json() {
    local data="${1}"
    local key="${2}"

    [[ ${#data} -le 0 ]] && fail "json data is null or empty"

    local value=$(python <<-EOF
import json
val = ''
try:
    val = ${data}.get('${key}', '')
except:
    val = json.dumps(json.loads(r"""${data}""").get('${key}', ''))
print(val)
EOF
)
    echo "${value}"
}

###############################################################################
# fivetran::generate_headers
# generate the curl command headers from the json headers dictionary
#
# Arguments:
#   headers: json headers data
# Returns:
#   headers_str: curl based header data string
#
###############################################################################
function fivetran::generate_headers() {
    local headers="${1}"
    local headers_str=$(python -c "print(' '.join(['-H \"%s: %s\"' %(k,v) for (k,v) in ${headers}.items()]))")
    headers_str=${headers_str//'${AUTH_TOKEN}'/${AUTH_TOKEN}}
    echo "${headers_str}"
}

###############################################################################
# fivetran::call_api
# call fivetran api with the required config
#
# Arguments:
#   endpoint config key: the endpoint name to call
# Returns:
#   response: api response
###############################################################################
function fivetran::call_api() {
    local endpoint_key="${1}"
    local config=$(fivetran::search_json "${ENDPOINT_CONFIG}" ${endpoint_key})

    # check to see if the config is available in endpoint config file
    [[ -z "${config}" ]] && \
    fail "Unable to find ${endpoint_key} in ${ENDPOINT_CONFIG_PATH}"

    # get the curl command parameters to build curl command
    local _method=$(fivetran::search_json "${config}" method)
    local _url=$(fivetran::search_json "${config}" url)
    local _headers=$(fivetran::search_json "${config}" headers)

    # evaluate the json data to be populated and replace the ${...} var with
    # arguments defined in additional arguments
    if [[ ${FUNCTION} != create_connector ]] && [[ ${FUNCTION} != create_destination ]]; then
        local _data="$(fivetran::search_json "${config}" data)"
        _data=$(eval echo ${_data//\'/\\\"})
    else
        local _data=$(eval echo "$(fivetran::search_json "${config}" data)")
        _data=$(eval echo ${_data//\"/\\\"})
    fi

    # build the curl command
    local curl_command="curl -s -X ${_method} $(eval echo "${_url}") $(fivetran::generate_headers "${_headers}") ${_data:+-d '${_data}'} "
    logger::log [INFO] "Curl command: ${curl_command}" ${RUN_LOG_FILE}

    # run the curl command
    response=$(echo ${curl_command} | sh)
    logger::log [INFO] "Curl response: ${response}" ${RUN_LOG_FILE}

    echo ${response}
}


###############################################################################
# fivetran::create_connector
# creates a fivetran connector
###############################################################################
function fivetran::create_connector() {

    local response=$(fivetran::call_api create_connector)
    local code=$(fivetran::search_json "${response}" code)
    local message=$(fivetran::search_json "${response}" message)

    echo [${code}] ${message} | tee -a ${RUN_LOG_FILE}
    #echo $(python -c "import json; print(json.dumps(json.loads(r'${response}').get('data', {}), indent=2))")

    local data=$(fivetran::search_json "${response}" data)
    [[ "${data}" == "" ]] && return

    local config=$(fivetran::search_json "${data}" config)
    echo "Connector ID: $(fivetran::search_json "${data}" id)" | tee -a ${RUN_LOG_FILE}
    echo "Send email to: $(fivetran::search_json "${config}" email)" | tee -a ${RUN_LOG_FILE}

}


###############################################################################
# MAIN
###############################################################################
USER=$(whoami)
SCRIPT=$0
SCRIPT_DIR_PATH="${0%/*}"

source ${SCRIPT_DIR_PATH}/logger.sh

APP_PATH=$(dirname ${SCRIPT_DIR_PATH})
RUN_LOG_FILE=$(logger::init ${APP_PATH}/logs)
CURRENT_TIME="$(date +'%Y%m%d%H%M%S')"

#load .env file
source ${APP_PATH}/.env

fivetran::parse_arguments "$@"
fivetran::validate_arguments

logger::log [INFO] "==========================================" ${RUN_LOG_FILE}
logger::log [INFO] "============= FIVETRAN RUNNER ============" ${RUN_LOG_FILE}
logger::log [INFO] "==========================================" ${RUN_LOG_FILE}
logger::log [INFO] "Current time is: ${CURRENT_TIME}" ${RUN_LOG_FILE}

logger::log [INFO] "================ ARGUMENTS ===============" ${RUN_LOG_FILE}
logger::log [INFO] "Endpoint Config Path: ${ENDPOINT_CONFIG_PATH}" ${RUN_LOG_FILE}
logger::log [INFO] "Connector Config Path: ${CONNECTOR_CONFIG_PATH}" ${RUN_LOG_FILE}
logger::log [INFO] "Destination Config Path: ${DESTINATION_CONFIG_PATH}" ${RUN_LOG_FILE}
logger::log [INFO] "Arguments: ${ARGUMENTS}" ${RUN_LOG_FILE}
logger::log [INFO] "Function: ${FUNCTION}" ${RUN_LOG_FILE}
logger::log [INFO] "==========================================" ${RUN_LOG_FILE}

logger::log [INFO] "============= CONNECTOR CONFIG ===========" ${RUN_LOG_FILE}
CONNECTOR_CONFIG=$(fivetran::parse_config ${CONNECTOR_CONFIG_PATH})
logger::log [INFO] "${CONNECTOR_CONFIG}" ${RUN_LOG_FILE}
logger::log [INFO] "==========================================" ${RUN_LOG_FILE}

logger::log [INFO] "============ DESTINATION CONFIG ==========" ${RUN_LOG_FILE}
DESTINATION_CONFIG=$(fivetran::parse_config ${DESTINATION_CONFIG_PATH})
logger::log [INFO] "${DESTINATION_CONFIG}" ${RUN_LOG_FILE}
logger::log [INFO] "==========================================" ${RUN_LOG_FILE}

[[ -n ${ARGUMENTS} ]] && fivetran::set_additional_arguments

logger::log [INFO] "============= ENDPOINT CONFIG ============" ${RUN_LOG_FILE}
ENDPOINT_CONFIG=$(fivetran::parse_config ${ENDPOINT_CONFIG_PATH})
logger::log [INFO] "${ENDPOINT_CONFIG}" ${RUN_LOG_FILE}
logger::log [INFO] "==========================================" ${RUN_LOG_FILE}

fivetran::call_api ${FUNCTION}


# ~:~:~:~:~:~:~:~:~:~:~:~:~~:~:~:~:~:~:~:~:~:~:~:~:~~:~:~:~:~:~:~:~:~:~:~:~:~:~
# tests - generic func
# ~:~:~:~:~:~:~:~:~:~:~:~:~~:~:~:~:~:~:~:~:~:~:~:~:~~:~:~:~:~:~:~:~:~:~:~:~:~:~
# fivetran::call_api create_connector
# fivetran::call_api test_connector
# fivetran::call_api unpause_connector
# fivetran::call_api get_group_details

# ~:~:~:~:~:~:~:~:~:~:~:~:~~:~:~:~:~:~:~:~:~:~:~:~:~~:~:~:~:~:~:~:~:~:~:~:~:~:~
# tests - parsed response func
# ~:~:~:~:~:~:~:~:~:~:~:~:~~:~:~:~:~:~:~:~:~:~:~:~:~~:~:~:~:~:~:~:~:~:~:~:~:~:~
# fivetran::create_connector
