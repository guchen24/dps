#!/usr/bin/env bash
set -euo pipefail

mkdir -p "${DSH_HOME}"
# Run the official source launcher so the workspace plugin resolver can load
# every Host package. The complete build above still validates and produces all
# Host, Typert Client, and Vite artifacts before this runtime starts.
exec /opt/dps/node_modules/.bin/tsx /opt/dps/apps/cli/src/bin.ts "$@"
