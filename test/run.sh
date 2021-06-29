#!/bin/bash
set -e

PROJECT_NAME="modsec"

# Functions

function log_entry() {

    local LOG_TYPE="${1:?Needs log type}"
    local LOG_MSG="${2:?Needs log message}"
    local COLOR='\033[93m'
    local ENDCOLOR='\033[0m'

    echo -e "${COLOR}$(date "+%Y-%m-%d %H:%M:%S") [$LOG_TYPE] ${LOG_MSG}${ENDCOLOR}"

}

function containers_down {

    log_entry "INFO" "Terminating containers"
    docker-compose -p "$PROJECT_NAME" down

}

# Always terminate containers

trap containers_down EXIT SIGHUP SIGINT SIGTERM

# Run

log_entry "INFO" "Build containers"
docker-compose -p "$PROJECT_NAME" build

log_entry "INFO" "Starting containers"
docker-compose -p "$PROJECT_NAME" up --force-recreate --detach haproxy

log_entry "INFO" "Running tests"
docker-compose -p "$PROJECT_NAME" run client

log_entry "INFO" "Showing logs"
docker-compose -p "$PROJECT_NAME" logs modsecurity-spoa | grep -v "clients connected"
