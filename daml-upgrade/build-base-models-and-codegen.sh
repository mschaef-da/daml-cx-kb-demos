#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

./download-upgrade-tool.sh

mkdir -pv target

_info "Building testv1 model."
(cd testv1 && daml build) && cp ${DAR_MODEL_V1} target
(cd scripts && daml build) && cp ${DAR_SCRIPTS} target

_info "Building testv2 model."
(cd testv2 && daml build) && cp ${DAR_MODEL_V2} target

_info "Generating code for migration."
java -jar ${JAR_UPGRADE_CODEGEN} generate \
  --old ./${DAR_MODEL_V1} \
  --new ./${DAR_MODEL_V2}  \
  --output-directory ./upgrade-model \
  --upgrade-version 1.0.0

_info "Code generation successful.

At this point, the code in ./upgrade-model needs to be modified to
provide conversion functions and default values. After this is done,
the build can be continued with ./build-upgrade-model.sh."
