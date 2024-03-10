#!/usr/bin/env bash


tf.usage() {
  echo "${0} [OPTIONS] ACTION [EXTRA_ACTION_ARGUMENTS]"
  echo
  echo "'export ENVIRONMENT=xample-dev' replaces '--environment ENV'."
  echo "'export SEGMENT=west' replaces '--segment SEGMENT' for terraform that needs a SEGMENT."
  echo
  echo "-e|--environment ENV  xample-dev, commons-prod, xmarkets-qa-1."
  echo "-s|--segment SEGMENT  east, west, blue, green. For Terraform that needs it."
  echo "-m|--module MODULE    Name of the terraform sub-directory to run. Default 'terraform'."
  echo "-b|--bucket BUCKET    Name of the S3 bucket for storing state. Default 'edbence-tfstate-east'."
  echo "-t|--tfstate PATH     Path of the state file in S3. Default 'ACCOUNT/ENV-MODULE.tfstate'."
  echo "-v|--var-file PATH    Path to a Terraform varfile, if there is one."
  echo
  echo "-L|--legacy   A flag which changes some defaults and labeling the Terraform module path."
  echo "              MODULE becomes 'terraform/MODULE'."
  echo "              If MODULE == 'env', then:"
  echo "                default bucket: 'edbence-ENV-terraform-infra-state'."
  echo "                default tfstate PATH: 'ENV-global-terraform-infra-state'."
  echo "              Otherwise:"
  echo "                default bucket: 'edbence-ENV-SEGMENT-terraform-infra-state'."
  echo "                default tfstate PATH: 'ENV-MODULE-terraform-infra-state'."
}


tf.main() {
  # parse out any grouped short args, like -Le
  local -a temp_args=()
  local stack_first=
  local stack_remainder=
  while [[ "${#}" -gt 0 ]]; do
    if [[ "${1}" =~ ^-[Lesmbtvh]{2,}$ ]]; then  # stacked group
      stack_first="$(echo "${1}" | cut -c '1-2')"
      stack_remainder="$(echo "${1}" | cut -c '1,3-')"
      shift

      set -- "${stack_remainder}" "${@}" "${stack_first}"
    else
      temp_args+=("${1}")
      shift
    fi
  done
  set -- "${temp_args[@]}"

  # parse out cries for help and -L|--legacy before anything else
  local legacy="false"
  local arg=
  for arg in "${@}"; do
    case "${arg}" in
      -h|--help|help)
        tf.usage
        return 0
        ;;
      -L|--legacy)
        legacy="true"
        ;;
    esac
  done

  # --<key> arguments
  local environment="${ENVIRONMENT:-}"
  local segment="${SEGMENT:-}"
  local module="terraform"
  local bucket=
  [[ "${legacy}" == "false" ]] && bucket="edbence-tfstate-east"
  local s3key=
  local varfile=

  # positional arguments
  local position="ACTION"
  local action=
  local -a args=()
  while [[ "${#}" -gt 0 ]]; do
    case "${1}" in
      -L|--legacy)  # already handled, skip and shift
        shift
        ;;
      -e|--environment)
        [[ -z "${2:-}" ]] && tf.die "Must include parameter for ${1} argument."
        environment="${2}"
        shift 2
        ;;
      -s|--segment)
        [[ -z "${2:-}" ]] && tf.die "Must include parameter for ${1} argument."
        segment="${2}"
        shift 2
        ;;
      -m|--module)
        [[ -z "${2:-}" ]] && tf.die "Must include parameter for ${1} argument."
        module="${2}"
        shift 2
        ;;
      -b|--bucket)
        [[ -z "${2:-}" ]] && tf.die "Must include parameter for ${1} argument."
        bucket="${2}"
        shift 2
        ;;
      -t|--tfstate)
        [[ -z "${2:-}" ]] && tf.die "Must include parameter for ${1} argument."
        s3key="${2}"
        shift 2
        ;;
      -v|--var-file)
        [[ -z "${2:-}" ]] && tf.die "Must include parameter for ${1} argument."
        varfile="${2}"
        shift 2
        ;;
      *)  # positional arguments
        case "${position}" in
          ACTION)
            action="${1}"
            position=EXTRA
            shift
            ;;
          EXTRA)
            args+=("${1}")
            shift
            ;;
        esac
        ;;
    esac
  done

  [[ -z "${action}" ]] && tf.die "Missing ACTION: init, plan, apply, etc."

  # bucket in Legacy mode
  if [[ "${legacy}" == "true" && -z "${bucket}" ]]; then
    bucket="edbence-${environment}-${segment}-terraform-infra-state"
    [[ "${module}" == "env" ]] && bucket="edbence-${environment}-terraform-infra-state"
  fi

  local account_id="$(aws sts get-caller-identity --query 'Account' --output text)"

  # tfstate in Legacy mode
  local tfstate="${account_id}/${environment}-${module}.tfstate"
  if [[ "${legacy}" == "true" ]]; then
    if [[ "${module}" == "env" ]]; then
      tfstate="${environment}-global-terraform-infra-state"
    else
      tfstate="${environment}-${module}-terraform-infra-state"
    fi
  fi
  if [[ -n "${s3key}" ]]; then
    tfstate="${s3key}"
  fi

  # module path
  [[ "${module}" != "terraform" ]] && module="terraform/${module}"

  # add to the args if appropriate for the action
  case "${action}" in
    init)
      args+=(-backend-config="bucket=${bucket}")
      args+=(-backend-config="key=${tfstate}")
      args+=(-backend-config="region=${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}")
      args+=(-reconfigure)
      ;;
    plan|apply|destroy|console|import|refresh)
      args+=(-var="environment=${environment}")
      [[ -n "${segment}" ]] && args+=(-var="segment=${segment}")
      if [[ -n "${varfile}" ]]; then
        args+=(-var-file="${varfile}")
      else
        CURRENT_SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
        DEPLOYMENT_CONF_DIR="$CURRENT_SCRIPT_DIRECTORY/config/$environment/$segment"
        DEPLOYMENT_TF_CONFIG="$DEPLOYMENT_CONF_DIR/config.tfvars"
        args+=(-var-file="${DEPLOYMENT_TF_CONFIG}")
      fi
      ;;
  esac

  terraform -chdir="${module}" "${action}" "${args[@]}"
}


tf.die() {
  local message="${1:-}"
  if [[ -t 1 ]]; then
    echo -e "\e[31;1mERROR;\e[0m ${message}" >&2
  else
    echo "ERROR: ${message}" >&2
  fi
  echo

  tf.usage >&2
  (exit 1)
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then  # run as a script, not being sourced
  # when run as a script, invoke bash strict mode
  set -o errexit
  set -o pipefail
  set -o nounset

  tf.main "${@}"
fi
