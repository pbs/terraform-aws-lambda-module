#!/usr/bin/env bash

# Unofficial bash strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

GIT_ROOT=$(git rev-parse --show-toplevel)

if [[ ! -f "$GIT_ROOT"/examples/artifacts/handler.zip ]]; then
    "$GIT_ROOT"/scripts/package.sh
fi

pushd "$GIT_ROOT"/tests > /dev/null || exit 1
go test -timeout 30m -count=1 -parallel 10 ./...
