


DAR_MODEL_V1=testv1/.daml/dist/test-0.0.1.dar
DAR_MODEL_V2=testv2/.daml/dist/test-0.0.2.dar
DAR_SCRIPTS=scripts/.daml/dist/test-scripts-0.0.1.dar
DAR_MODEL_UPGRADE=upgrade-model/.daml/dist/upgrade-project-1.0.0.dar

UPGRADE_PACKAGE_ID=upgrade-model/package_id

JAR_ARTIFACTORY_BASE_URL=https://digitalasset.jfrog.io/artifactory/daml-upgrade/3.4/3.4.2

JAR_UPGRADE_CODEGEN=migration-upgrade-codegen-3.4.2.jar
JAR_UPGRADE_RUNNER=migration-upgrade-runner-3.4.2.jar

HUB_JWT_FILE="hub-user-jwt.json"

UPGRADE_CONF="conf/upgrade.conf"
CLEANUP_CONF="conf/cleanup.conf"

# issue a user friendly red error and die
function _error(){
  _error_msg "$@"
  exit $?
}

# Issue a log message
function _log() {
  echo "$@"
}

# issue a user friendly red error
function _error_msg(){
  local RC=$?
  ((RC)) || RC=1
  echo -e "\e[1;31mERROR: $@\e[0m"
  return ${RC}
}

# issue a user friendly green informational message
function _info(){
  local first_line="INFO: "
  while read -r; do
    printf -- "\e[32;1m%s%s\e[0m\n" "${first_line:-      }" "${REPLY}"
    unset first_line
  done < <(echo -e "$@")
}

# issue a user friendly yellow warning
function _warning(){
  local first_line="WARNING: "
  while read -r; do
    printf -- "\e[33;1m%s%s\e[0m\n" "${first_line:-        }" "${REPLY}"
    unset first_line
  done < <(echo -e "$@")
}

# prints a little green check mark before $@
function _ok(){
  echo -e "\e[32;1m✔\e[0m ${@}"
}

# prints a little red x mark before $@ and sets check to 1 if you are using it
function _nope(){
  echo -e "\e[31;1m✘\e[0m ${@}"
}


#############

function jwt_decode(){
    jq -R 'split(".") | .[1] | @base64d | fromjson' <<< "$1"
}

function init_ledger_environment() {

    if [ -f ${HUB_JWT_FILE} ]; then
        if [ ! -f parties.json ]; then
            _error "Attempting to connect to Hub, but missing parties.json. Please download from Hub UI."
        fi

        cp ${HUB_JWT_FILE} target

        _info "Reading party ID's from parties.json"

        cat parties.json \
            | jq 'reduce .[] as $i ({}; .[$i.partyName] = $i.party)' \
                 > target/parties.json

        LEDGER_ID=$(cat parties.json | jq -r 'first | .ledgerId')

        APPLICATION_ID=$(jwt_decode $(<${HUB_JWT_FILE}) | jq -r '.sub')

        _info "Connecting to Hub ledger: ${LEDGER_ID} (application ID: ${APPLICATION_ID})"

        LEDGER_SCRIPT_CONNECTION="--ledger-host ${LEDGER_ID}.daml.app \
                                  --ledger-port 443 \
                                  --application-id ${APPLICATION_ID} \
                                  --tls \
                                  --access-token-file target/${HUB_JWT_FILE}"
        LEDGER_DOCKER_CONNECTION="${LEDGER_SCRIPT_CONNECTION}"
    else
        _info "Capturing party ID's from ledger"

        daml ledger list-parties --host localhost --port 6865 --json \
            | jq 'reduce .[] as $i ({}; .[$i.display_name] = $i.party)' \
                 > target/parties.json

        LEDGER_SCRIPT_CONNECTION="--ledger-host localhost --ledger-port 6865"
        LEDGER_DOCKER_CONNECTION="--ledger-host host.docker.internal --ledger-port 6865"
    fi
}


function _get_party_id(){
    cat target/parties.json | jq -r '.[$name]' --exit-status --arg name "$1"
}

