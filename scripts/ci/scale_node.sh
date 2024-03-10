#!/usr/bin/env bash

function display_usage() {
  echo "Usage: $0 <ENV> <SEGMENT>"
}

export ENV=$1
export SEGMENT=$2



if [[ -z "$ENV" ]]; then
  echo "Missing ENV argument"
  display_usage
  exit 1
fi

if [[ -z "$ENV" ]]; then
  echo "Missing SEGMENT argument"
  display_usage
  exit 1
fi


# The CI pipeline will need to make a commit and push changes back to the repository
if [[ "$CI" == "true" ]]; then
  git remote set-url --push origin "https://${COMMONS_CI_PUSH_USER}:${COMMONS_CI_PUSH_TOKEN}@gitlab.com/${CI_PROJECT_PATH}.git"
  git config --global user.email "$GITLAB_USER_EMAIL"
  git config --global user.name "$GITLAB_USER_NAME"
  git checkout -B "$CI_COMMIT_BRANCH"
fi

CONFIG_FILE="config/$ENV/$SEGMENT/config.tfvars"
SIZE=$(cat "config/k8s_worker_desired_size.conf")

CHECK_CONFIG=$(grep "k8s_worker_desired_size = 0" $CONFIG_FILE)
RC=$?

if [ $RC == 0 ]; then
  sed -i "s/k8s_worker_desired_size = 0/k8s_worker_desired_size = $SIZE/g" $CONFIG_FILE
  UPDATE_MSG="++Scaling up $ENV $SEGMENT"
else
  sed -i 's/k8s_worker_desired_size = [0-9]*/k8s_worker_desired_size = 0/g' $CONFIG_FILE
  UPDATE_MSG="++Scaling down $ENV $SEGMENT"
fi

echo "$UPDATE_MSG"

# commit the changes
if [[ "$CI" == "true" ]]; then
  git add "$CONFIG_FILE"
  git commit -v -m "$UPDATE_MSG"
  git push -o ci.variable="ENVIRONMENT=$ENV" -o ci.variable="SEGMENT=$SEGMENT" -o ci.variable="OPERATION=terraform" -o ci.variable="MODULE=base" -o ci.variable="TERRAFORM=yes" --follow-tags origin HEAD:$CI_COMMIT_BRANCH
fi
