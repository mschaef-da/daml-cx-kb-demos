#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

if [ ! -f ${HUB_JWT_FILE} ]; then
    _error "JWT file ${HUB_JWT_FILE} missing. Please copy user JWT from Hub UI and store in a file of this name."
fi

init_ledger_environment

_info "Running startup script to initialize ledger."
daml script ${LEDGER_SCRIPT_CONNECTION} \
   --dar ${DAR_SCRIPTS} \
   --script-name Scripts:createTestContracts \
   --input-file target/parties.json

_info "Ledger running and initialized.

Run contract upgrade with ./run-upgrade.sh"
