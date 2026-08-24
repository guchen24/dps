#!/usr/bin/env bash
set -euo pipefail

mkdir -p "${DSH_HOME}"
exec /opt/dps/node_modules/.bin/tsx /opt/dps/apps/cli/src/bin.ts "$@"
