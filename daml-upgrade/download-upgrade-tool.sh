#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

function check_artifactory_credentials() {
    if [ ! -v ARTIFACTORY_READONLY_USER ]; then
        _error "Missing Artifactory username in environment variable: ARTIFACTORY_READONLY_USER"
    fi

    if [ ! -v ARTIFACTORY_READONLY_PASSWORD ]; then
        _error "Missing Artifactory password in environment variable: ARTIFACTORY_READONLY_PASSWORD"
    fi
}

_info "Checking for upgrade code generator: ${JAR_UPGRADE_CODEGEN}"
if [ ! -f ${JAR_UPGRADE_CODEGEN} ]; then
    _info "Upgrade code generator not found. Downloading..."

    check_artifactory_credentials

    echo "--user ${ARTIFACTORY_READONLY_USER}:${ARTIFACTORY_READONLY_PASSWORD}" | \
        curl -K- ${JAR_ARTIFACTORY_BASE_URL}/${JAR_UPGRADE_CODEGEN} \
             --output ${JAR_UPGRADE_CODEGEN}
fi

_info "Checking for upgrade code runner: ${JAR_UPGRADE_RUNNER}"
if [ ! -f $JAR_UPGRADE_RUNNER ]; then
    _info "Upgrade code runner not found. Downloading..."

    check_artifactory_credentials

    echo "--user ${ARTIFACTORY_READONLY_USER}:${ARTIFACTORY_READONLY_PASSWORD}" | \
        curl -K- ${JAR_ARTIFACTORY_BASE_URL}/${JAR_UPGRADE_RUNNER} \
             --output ${JAR_UPGRADE_RUNNER}
fi

_info "Upgrade tool downloaded and ready for use."
