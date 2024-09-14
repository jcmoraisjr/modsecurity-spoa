#!/bin/bash
set -e

PROJECT_NAME="modsec"
COMPOSE="docker-compose"
if ! which $COMPOSE; then
    COMPOSE="docker compose"
fi

# Functions

function ci_log_entry() {

    local LOG_TYPE="${1:?Needs log type}"
    local LOG_MSG="${2:?Needs log message}"
    local COLOR='\033[93m'
    local ENDCOLOR='\033[0m'

    echo -e "${COLOR}$(date "+%Y-%m-%d %H:%M:%S") [$LOG_TYPE] ${LOG_MSG}${ENDCOLOR}"

}

# ci_log_group_* functions are used to make Github Actions output cleaner
function ci_log_group_start(){
    local LOG_TYPE="${1:?Needs log type}"
    local LOG_MSG="${2:?Needs log message}"

    if [ -n "${CI:-}" ]; then
        echo "::group::${LOG_MSG}"
    else
        ci_log_entry "${LOG_TYPE}" "${LOG_MSG}"
    fi
}

function ci_log_group_end {
    if [ -n "${CI:-}" ]; then
        echo "::endgroup::"
    fi
}

function containers_down {

    ci_log_entry "INFO" "Terminating containers"
    $COMPOSE -p "$PROJECT_NAME" down

}

# Always terminate containers

trap containers_down EXIT

# Run

ci_log_group_start "INFO" "Build containers"
$COMPOSE -p "$PROJECT_NAME" build
ci_log_group_end

ci_log_group_start "INFO" "Starting containers"
$COMPOSE -p "$PROJECT_NAME" up --force-recreate --detach haproxy
ci_log_group_end

ci_log_group_start "INFO" "Running tests"
$COMPOSE -p "$PROJECT_NAME" run client
ci_log_group_end

ci_log_group_start "INFO" "Showing logs"
$COMPOSE -p "$PROJECT_NAME" logs modsecurity-spoa
ci_log_group_end
