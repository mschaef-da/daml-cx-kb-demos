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
    cat <<EOF > target/initialize-upgraders.json
{
  "upgradeCoordinator": "$coordinator_party",
  "upgraders": [
    "$party_alice",
    "$party_bob"
  ]
}
EOF

    daml script ${LEDGER_SCRIPT_CONNECTION} \
         --dar ${DAR_MODEL_UPGRADE} \
         --script-name "DA.DamlUpgrade.InitiateUpgrade:initializeUpgraders" \
         --input-file target/initialize-upgraders.json
}

function init_upgrader() {
    _info "Initializing Upgrader Party: $1"

    docker run ${DOCKER_CONFIG} "${DAML_UPGRADE_IMAGE}" \
           java -jar upgrade-runner.jar init-upgrader \
           --config ${UPGRADE_CONF} \
           --upgrader "$1" \
           --upgrade-package-id "$package_id" \
           ${LEDGER_DOCKER_CONNECTION}
}


function accept_upgrade_proposals() {
    _info "Accepting upgrade proposals for Party: $1"
    cat <<EOF > target/accept-upgrade-parties.json
[
    "$1"
]
EOF

    # Token used needs to be authorized for all parties listed in the input file.
    daml script ${LEDGER_SCRIPT_CONNECTION} \
         --dar ${DAR_MODEL_UPGRADE} \
         --script-name "DA.DamlUpgrade.UpgradeConsent:acceptUpgradeProposalsScript" \
         --input-file target/accept-upgrade-parties.json
}

function run_upgrade() {
    _info "Running upgrade for party: $1"

    docker run ${DOCKER_CONFIG} "${DAML_UPGRADE_IMAGE}" \
           java -jar upgrade-runner.jar run-upgrade \
           --config ${UPGRADE_CONF} \
           --upgrader "$1" \
           --upgrade-package-id "$package_id" \
           ${LEDGER_DOCKER_CONNECTION}
}

function upgrade_cleanup() {
    _info "Cleaning up upgrade state for party: $1"

    docker run ${DOCKER_CONFIG} "${DAML_UPGRADE_IMAGE}" \
           java -jar upgrade-runner.jar cleanup \
           --config ${CLEANUP_CONF} \
           --upgrader "$1" \
           --upgrade-package-id "$package_id" \
           --batch-size 10 \
           ${LEDGER_DOCKER_CONNECTION}
}

function upgrade_coordinator_cleanup() {
    _info "Cleaning up upgrade coordinator: $1"

    echo "\"$1\"" > target/cleanup-status.json
    daml script ${LEDGER_SCRIPT_CONNECTION} \
         --dar ${DAR_MODEL_UPGRADE} \
         --script-name "DA.DamlUpgrade.Status:cleanupStatus" \
         --input-file target/cleanup-status.json
}

_info "Starting Upgrade"
initialize_upgraders

init_upgrader "${party_alice}"
init_upgrader "${party_bob}"

accept_upgrade_proposals "${party_alice}"
accept_upgrade_proposals "${party_bob}"

run_upgrade "${party_alice}"
run_upgrade "${party_bob}"

upgrade_cleanup "${party_alice}"
upgrade_cleanup "${party_bob}"

upgrade_coordinator_cleanup "${coordinator_party}"

_info "Upgrade complete."
