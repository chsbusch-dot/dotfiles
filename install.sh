#!/bin/bash
set -e

# Backward-compatible entrypoint for curl | bash installs.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/dotfileinstaller.sh" "$@"
