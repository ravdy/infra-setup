#!/usr/bin/env bash

set -e
set -o pipefail
set -x

function convert_report() {
  JQ_PLAN='
    (
      [.resource_changes[]?.change.actions?] | flatten
    ) | {
      "create":(map(select(.=="create")) | length),
      "update":(map(select(.=="update")) | length),
      "delete":(map(select(.=="delete")) | length)
    }
  '
  # ignore the first and last line, then parse out the details for the terraform report to display in the Gitlab MR
  tail -n 2 | head -n 1 | jq -r "$JQ_PLAN"
}

function aws_region() {
  if [ $1 == 'east' ]; then
    echo "us-east-1"
  elif [ $1 == 'west' ]; then
    echo "us-west-2"
  fi
}

function tf_module() {
  if [ $1 == 'env' ]; then
    echo "env"
  elif [[ "$1" == "base" ]] || [[ "$1" == 'ext' ]]; then
    echo "$2-$1"
  fi
}