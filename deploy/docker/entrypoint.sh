#!/usr/bin/env bash
set -euo pipefail

mkdir -p "${DSH_HOME}"
# The source launcher uses tsx for local development. The container has already
# run the complete build, so use its compiled CLI: this preserves TypeScript
# const-enum lowering across workspace package boundaries at runtime.
exec node /opt/dps/apps/cli/lib/bin.js "$@"
