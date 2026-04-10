#!/bin/bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
PATTERN="^(feat|fix|docs|chore|refactor|test|deps|ci|step5|step6)/"

if [[ "$BRANCH" == "main" || "$BRANCH" == "master" || "$BRANCH" == "develop" ]]; then
  exit 0
fi

if [[ ! "$BRANCH" =~ $PATTERN ]]; then
  echo "Invalid branch name: $BRANCH"
  echo "Must match: feat/, fix/, docs/, chore/, refactor/, test/, deps/, ci/"
  exit 1
fi
