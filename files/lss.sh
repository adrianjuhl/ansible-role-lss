#!/usr/bin/env bash

# Local secret store - get, put, list, unlock secrets.
#
# The secret exists within ${HOME}/.lss-secrets/

usage()
{
  cat <<USAGE_TEXT
Usage: $(basename "${BASH_SOURCE[0]}") [options] command [command-parameter]
Available commands:
  get              Returns a stored secret
  put              Stores a secret
  list             Lists the stored secrets
  unlock           Prompt for the machine local master password to unlock the get and put operations
Command parameters:
  <secret-name-path>   (get, put) The name of the secret to either return (get) or store (put).
                       The secret-name-path can be a path, such as path/to/mysecret, whereby
                       secrets will be stored in a corresponding hierarchy of directories.
General options:
  -h, --help         Print this help and exit
  -v, --verbose      Print script debug info
USAGE_TEXT
}

main()
{
  initialize
  parse_script_params "${@}"
  local LSS_SECRETS_DIRECTORY="${HOME}/.lss-secrets"
  local LSS_MASTER_FILE="/run/lss_master_${USER}"
  ensure_lss_secrets_directory_exists
  if [ "${COMMAND}" == "" ]; then
    msg "Error: No command given"
    msg "Use --help for usage help"
    abort_script
  fi
  case "${COMMAND}" in
    get)
      get_secret --secret-name-path ${SECRET_NAME_PATH}
      ;;
    put)
      put_secret --secret-name-path ${SECRET_NAME_PATH}
      ;;
    list)
      list_secrets
      ;;
    unlock)
      unlock_secrets
      ;;
    *)
      msg "Error: Unknown command: ${COMMAND}"
      msg "Use --help for usage help"
      abort_script
      ;;
  esac
}

get_secret()
  # param: --secret-name-path <secret-name-path>
{
  local secret_name_path=''
  while [ "${#}" -gt 0 ]
  do
    case ${1} in
      --secret-name-path)
        local secret_name_path="${2-}"
        shift
        ;;
      *)
        msg "Error: [in get_secret()] Unknown parameter: ${1}"
        abort_script
        ;;
    esac
    shift
  done
  if [ -z "${secret_name_path}" ]; then
    msg "Error: [in get_secret()] Missing required parameter: secret-name-path"
    abort_script
  fi
  local machine_local_master_password=$(get_machine_local_master_password)
  local encrypted_secret=$(cat ${LSS_SECRETS_DIRECTORY}/${secret_name_path})
  local plaintext_secret=$(jasypt-decrypt verbose=false input="${encrypted_secret}" password="${machine_local_master_password}")
  echo -n "${plaintext_secret}"
}

put_secret()
  # param: --secret-name-path <secret-name-path>
{
  local secret_name_path=''
  while [ "${#}" -gt 0 ]
  do
    case ${1} in
      --secret-name-path)
        local secret_name_path="${2-}"
        shift
        ;;
      *)
        msg "Error: [in put_secret()] Unknown parameter: ${1}"
        abort_script
        ;;
    esac
    shift
  done
  if [ -z "${secret_name_path}" ]; then
    msg "Error: [in put_secret()] Missing required parameter: secret-name-path"
    abort_script
  fi
  local machine_local_master_password=$(get_machine_local_master_password)

  echo -n "Enter the secret: "
  read -sr SECRET_INPUT
  echo
  local plaintext_secret="${SECRET_INPUT}" 
  
  local encrypted_secret=$(jasypt-encrypt verbose=false input="${plaintext_secret}" password="${machine_local_master_password}")
  mkdir -p "$(dirname "${LSS_SECRETS_DIRECTORY}/${secret_name_path}")"
  echo -n "${encrypted_secret}" > "${LSS_SECRETS_DIRECTORY}/${secret_name_path}"
}

list_secrets()
{
  find "${LSS_SECRETS_DIRECTORY}" -type f | sed -e 's|'"$(dirname "${LSS_SECRETS_DIRECTORY}/.")/"'||' | sort
}

unlock_secrets()
{
  prompt_for_machine_local_master_password
  store_machine_local_master_password
}

prompt_for_machine_local_master_password()
{
  echo -n "Enter the machine local master password: "
  read -sr MACHINE_LOCAL_MASTER_PASSWORD
  echo
}

store_machine_local_master_password()
{
  sudo touch ${LSS_MASTER_FILE}
  sudo chown ${USER}:${USER} ${LSS_MASTER_FILE}
  sudo chmod 600 ${LSS_MASTER_FILE}
  echo -n "${MACHINE_LOCAL_MASTER_PASSWORD}" | sudo tee ${LSS_MASTER_FILE} >/dev/null
}

get_machine_local_master_password()
{
  local machine_local_master_password=$(cat ${LSS_MASTER_FILE} 2>/dev/null)
  if [ -z "${machine_local_master_password}" ]; then
    msg "Error: Machine local master password not found. Use 'lss unlock' to set machine local master password."
    abort_script
  fi
  echo "${machine_local_master_password}"
}

ensure_lss_secrets_directory_exists()
{
  stat "${LSS_SECRETS_DIRECTORY}" >/dev/null 2>&1
  if [ "$?" -gt 0 ]; then
    mkdir "${LSS_SECRETS_DIRECTORY}"
    chmod 700 "${LSS_SECRETS_DIRECTORY}"
  fi
}

parse_script_params()
{
  #msg "script params (${#}) are: ${@}"
  # default values of variables set from params
  COMMAND=""
  SECRET_NAME_PATH=""
  while [ "${#}" -gt 0 ]
  do
    case "${1-}" in
      --help | -h)
        usage
        exit
        ;;
      --verbose | -v)
        set -x
        ;;
      -?*)
        msg "Error: Unknown parameter: ${1}"
        msg "Use --help for usage help"
        abort_script
        ;;
      *)
        if [ "${COMMAND}" == "" ]; then
          COMMAND="${1-}"
        else
          SECRET_NAME_PATH="${1-}"
          break
        fi
        ;;
    esac
    shift
  done
  if [ "${COMMAND}" == "get" ] || [ "${COMMAND}" == "put" ]; then
    if [ -z "${SECRET_NAME_PATH}" ]; then
      msg "Error: Missing required parameter: secret-name-path"
      abort_script
    fi
  fi
}

initialize()
{
  THIS_SCRIPT_PROCESS_ID=$$
  initialize_abort_script_config
}

initialize_abort_script_config()
{
  # Exit shell script from within the script or from any subshell within this script - adapted from:
  # https://cravencode.com/post/essentials/exit-shell-script-from-subshell/
  # Exit with exit status 1 if this (top level process of this script) receives the SIGUSR1 signal.
  # See also the abort_script() function which sends the signal.
  trap "exit 1" SIGUSR1
}

abort_script()
{
  echo >&2 "aborting..."
  kill -SIGUSR1 ${THIS_SCRIPT_PROCESS_ID}
  exit
}

msg()
{
  echo >&2 -e "${@}"
}

# Main entry into the script - call the main() function
main "${@}"
