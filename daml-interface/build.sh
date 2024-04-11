#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

mkdir -pv target

_info "Building Daml models."
daml build --all

function capture_package_id() {
    daml damlc inspect-dar --json "$1" | jq '.main_package_id'
}

capture_package_id "${DAR_MODEL_V1}" > target/package-id-v1.json
capture_package_id "${DAR_MODEL_V2}" > target/package-id-v2.json
capture_package_id "${DAR_SCRIPTS}" > target/package-id-scripts.json
capture_package_id "${DAR_IFACE}" > target/package-id-iface.json

_info "Installing DAZL Python library."

pip install dazl


_info "Build successful.

Ledger can be started with ./start-ledger.sh"
