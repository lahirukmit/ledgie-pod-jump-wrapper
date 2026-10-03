#!/usr/bin/env bash
set -euo pipefail

TOOL_NAME="podjump"
INSTALL_DIR="${HOME}/.local/bin"
TARGET_SCRIPT="${INSTALL_DIR}/${TOOL_NAME}"

info() { printf '[info] %s\n' "$*"; }

if [[ -f "$TARGET_SCRIPT" || -L "$TARGET_SCRIPT" ]]; then
  rm -f "$TARGET_SCRIPT"
  info "removed: ${TARGET_SCRIPT}"
else
  info "nothing to remove: ${TARGET_SCRIPT} not found"
fi

printf '\n'
printf 'Uninstall complete.\n'
printf 'Only %s was removed.\n' "$TOOL_NAME"
printf 'No dependencies were removed (bash, kubectl, fzf, kubectx, kubens).\n'
printf '\n'
printf 'If `podjump` is still resolved in your shell, open a new terminal session\n'
printf 'or run:\n'
printf '  hash -r\n'
