#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

init_ledger_environment

_info "Capturing Alice's party ID."
party_alice=$(_get_party_id alice)

_info "Capturing Bob's party ID."
party_bob=$(_get_party_id bob)

coordinator_party=${party_alice}

_info "Capturing upgrade package ID."
package_id=$(daml damlc inspect-dar --json ${DAR_MODEL_UPGRADE} \
                 | jq -r '.main_package_id')

mkdir -pv target

function initialize_upgraders() {
    _info "Initializing upgraders."

    java -jar ${JAR_UPGRADE_RUNNER} initialize \
         ${LEDGER_SCRIPT_CONNECTION} \
         --upgrade-dar ${DAR_MODEL_UPGRADE} \
         --upgrade-coordinator "${coordinator_party}" \
         --upgrader "${party_alice}" \
         --upgrader "${party_bob}"
}

function create_upgrade_proposals() {
    _info "Creating upgrade proposals for Party: $1"

    java -jar ${JAR_UPGRADE_RUNNER} initialize-upgrader \
         ${LEDGER_SCRIPT_CONNECTION} \
         --upgrade-dar ${DAR_MODEL_UPGRADE} \
         --upgrader "$1"
}

function accept_upgrade_proposals() {
    _info "Accepting upgrade proposals for Party: $1"

    java -jar ${JAR_UPGRADE_RUNNER} upgrade-consent \
         ${LEDGER_SCRIPT_CONNECTION} \
         --upgrade-dar ${DAR_MODEL_UPGRADE} \
         --upgrade-coordinator "${coordinator_party}" \
         --party "$1"
}

function run_upgrade() {
    _info "Running upgrade for party: $1"

    java -jar ${JAR_UPGRADE_RUNNER} upgrade \
         ${LEDGER_SCRIPT_CONNECTION} \
         --upgrade-dar ${DAR_MODEL_UPGRADE} \
         --upgrader "$1"
}

function upgrade_cleanup() {
    _info "Cleaning up upgrade state for party: $1"
    java -jar ${JAR_UPGRADE_RUNNER} cleanup \
         ${LEDGER_SCRIPT_CONNECTION} \
         --upgrade-dar ${DAR_MODEL_UPGRADE} \
         --upgrade-coordinator "${coordinator_party}" \
         --upgrader "$1"

}

function upgrade_coordinator_cleanup() {
    _info "Cleaning up upgrade coordinator: $1"

    java -jar ${JAR_UPGRADE_RUNNER} upgrade-coordinator-cleanup \
         ${LEDGER_SCRIPT_CONNECTION} \
         --upgrade-dar ${DAR_MODEL_UPGRADE} \
         --upgrade-coordinator "${coordinator_party}"
}

_info "Starting Upgrade"
initialize_upgraders

create_upgrade_proposals "${party_alice}"
create_upgrade_proposals "${party_bob}"

accept_upgrade_proposals "${party_alice}"
accept_upgrade_proposals "${party_bob}"

run_upgrade "${party_alice}"
run_upgrade "${party_bob}"

upgrade_cleanup "${party_alice}"
upgrade_cleanup "${party_bob}"

upgrade_coordinator_cleanup "${coordinator_party}"

_info "Upgrade complete."
