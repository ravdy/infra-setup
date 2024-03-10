#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

run_playbook_main() {
  local -r environment="${ENVIRONMENT:-}"
  if [[ -z "${environment}" ]]; then
    _die "Missing ENVIRONMENT. Please specify with" "    export ENVIRONMENT='commons-preprod'"
  fi

  local -r segment="${SEGMENT:-}"
  if [[ -z "${segment}" ]]; then
    _die "Missing SEGMENT. Please specify with" "    export SEGMENT='west'"
  fi

  export OBJC_DISABLE_INITIALIZE_FORK_SAFETY="YES"  # required by Ansible on OS X
  export ANSIBLE_CONFIG="ansible/ansible-${environment}.cfg"

  if [ ! -f "$ANSIBLE_CONFIG" ]; then
      echo "will use default config because file ${ANSIBLE_CONFIG} file does not exist"
      export ANSIBLE_CONFIG="ansible/ansible.cfg"
  fi

  if [[ -n "${AWS_SESSION_TOKEN}" ]]; then  # using an assumed role
    local -r tmp_profile="${AWS_PROFILE:-}"
    unset AWS_PROFILE
    # necessary because of bug
    # https://github.com/ansible-collections/amazon.aws/issues/1223
    # only affects ability to access SSM Parameters
  fi

  ansible-playbook --verbose \
     --inventory "ansible/inventory/inventory-${environment}-${segment}.yaml" \
     --extra-vars "env=${environment}" \
     --extra-vars "segment=${segment}" \
     ${ANSIBLE_EXTRA_VARS:-} \
     --user ubuntu \
     $@

  if [[ -n "${AWS_SESSION_TOKEN}" ]]; then  # using an assumed role
    export AWS_PROFILE="${tmp_profile:-}"  # restore
  fi
}


_die() {
  for line in "${@}"; do
    echo "${line}" >&2
  done
  (exit 1)
}


run_playbook_main "${@}"
