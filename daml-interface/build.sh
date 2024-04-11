#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

mkdir -pv target

_info "Building Daml models."
daml build --all

_info "Build successful.

Ledger can be started with ./start-ledger.sh"
