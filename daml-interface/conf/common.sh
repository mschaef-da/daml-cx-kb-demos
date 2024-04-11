
DAR_MODEL_V1=testv1/.daml/dist/test-0.0.1.dar
DAR_MODEL_V2=testv2/.daml/dist/test-0.0.2.dar
DAR_SCRIPTS=scripts/.daml/dist/test-scripts-0.0.1.dar
DAR_IFACE=iface/.daml/dist/iface-0.0.1.dar

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
    _info "Capturing party ID's from ledger"

    daml ledger list-parties --host localhost --port 6865 --json \
        | jq 'reduce .[] as $i ({}; .[$i.display_name] = $i.party)' \
             > target/parties.json

    LEDGER_SCRIPT_CONNECTION="--ledger-host localhost --ledger-port 6865"
}

function _get_party_id(){
    cat target/parties.json | jq -r '.[$name]' --exit-status --arg name "$1"
}

