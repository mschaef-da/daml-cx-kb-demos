#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

daml navigator server localhost 6865 --feature-user-management false
