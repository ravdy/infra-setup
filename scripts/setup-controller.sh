#!/usr/bin/env bash

if [ -z "$GITLAB_ACCESS_TOKEN" ]; then
  printf "WARNING:  Missing GITLAB_ACCESS_TOKEN."
fi

if [ -z "$GITLAB_REGISTRATION_TOKEN" ]; then
  printf "WARNING:  Missing GITLAB_REGISTRATION_TOKEN."
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pwd

TARGET_HOST=${TARGET_HOST:-controllers}

export ANSIBLE_EXTRA_VARS="--extra-vars target_host=${TARGET_HOST}"
#./run-playbook.sh ./edbence-infrastructure/ansible/controls/setup-bastion.yaml


export ANSIBLE_EXTRA_VARS="${ANSIBLE_EXTRA_VARS} --extra-vars gitlab_access_token=$GITLAB_ACCESS_TOKEN  --extra-vars  gitlab_registration_token=$GITLAB_REGISTRATION_TOKEN"

./run-playbook.sh ./edbence-infrastructure/ansible/controls/setup-controller-v2.yaml $@
