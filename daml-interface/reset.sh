#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

_info "Cleaning Daml models."
daml clean --all

rm -rfv  target

_info "Project has been reset."
