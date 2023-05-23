#!/usr/bin/env bash

# Unofficial bash strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

GIT_ROOT=$(git rev-parse --show-toplevel)

if [[ ! -f "$GIT_ROOT"/examples/artifacts/handler.zip ]]; then
    "$GIT_ROOT"/scripts/package.sh
fi

# We have to log into ECR now that we're doing Lambdas with containers
aws ecr get-login-password --region 'us-east-1' | docker login --username AWS --password-stdin "$(aws sts get-caller-identity | jq -r '.Account').dkr.ecr.us-east-1.amazonaws.com"

# We also need access to the public ECR registry
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

pushd "$GIT_ROOT"/tests >/dev/null || exit 1
go test -timeout 30m -count=1 -parallel 10 -short ./...
