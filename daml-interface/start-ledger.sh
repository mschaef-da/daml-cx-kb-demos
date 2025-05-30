#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

if [ ! -f ${DAR_MODEL_V1} ]; then
    _error "DAR file ${DAR_MODEL_V1} not found, run build.sh."
fi

if [ ! -f ${DAR_MODEL_V2} ]; then
    _error "DAR file ${DAR_MODEL_V2} not found, run build.sh."
fi

mkdir -pv log
mkdir -pv target

pid_file="target/canton.pid"
if [ -f "$pid_file" ]; then
    pid=$(<"$pid_file")

    if ps -p $pid > /dev/null; then
        _info "Ledger already running. (PID: $pid)"
        exit 1
    else
        _warning "Stale PID file found, but process not running. Cleaning up $pid_file and starting ledger."
        rm "$pid_file"
    fi
fi

daml sandbox --debug \
     --dar ${DAR_MODEL_V1} \
     --dar ${DAR_MODEL_V2} \
     &> log/canton-console.log &
echo $! > "$pid_file"

pid=$(<"$pid_file")

_info "Started Canton ledger (PID: $pid) with log output in log/

Waiting a few seconds for ledger startup..."

sleep 10

_info "Running startup script to create party."
daml script --ledger-host localhost --ledger-port 6865 \
   --dar ${DAR_SCRIPTS} \
   --script-name Scripts:ensureTestParties

rm -fv target/parties.json

# This has to happen _after_ running ensureTestParties so that
# the initialized ledger environment has the party mapping
# available.
init_ledger_environment

_info "Running startup script to initialize ledger."
daml script --ledger-host localhost --ledger-port 6865 \
   --dar ${DAR_SCRIPTS} \
   --script-name Scripts:createTestContracts \
   --input-file target/parties.json

_info "Ledger running and initialized.

Run Python script with ./run-main.sh

Stop the ledger with ./stop-ledger.sh"
