#!/usr/bin/env bash
set -euo pipefail

TOOL_NAME="podjump"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="${SCRIPT_DIR}/${TOOL_NAME}"
INSTALL_DIR="${HOME}/.local/bin"
TARGET_SCRIPT="${INSTALL_DIR}/${TOOL_NAME}"
ZSHRC="${HOME}/.zshrc"
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

info() { printf '[info] %s\n' "$*"; }
warn() { printf '[warn] %s\n' "$*" >&2; }
fail() { printf '[error] %s\n' "$*" >&2; exit 1; }

has_exact_line() {
  local line="$1"
  local file="$2"
  [[ -f "$file" ]] || return 1
  awk -v expected="$line" '
    $0 == expected { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$file"
}

ensure_line() {
  local line="$1"
  local file="$2"
  if has_exact_line "$line" "$file"; then
    return 1
  fi
  printf '\n%s\n' "$line" >> "$file"
  return 0
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || MISSING_REQUIRED+=("$cmd")
}

check_optional() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || MISSING_OPTIONAL+=("$cmd")
}

[[ -f "$SOURCE_SCRIPT" ]] || fail "cannot find ${SOURCE_SCRIPT}"

MISSING_REQUIRED=()
MISSING_OPTIONAL=()

require_command kubectl
require_command fzf
check_optional kubectx
check_optional kubens

if [[ ${#MISSING_REQUIRED[@]} -gt 0 ]]; then
  fail "missing required dependencies: ${MISSING_REQUIRED[*]}

Install on macOS:
  brew install kubectl fzf

Then re-run:
  ./install.sh"
fi

mkdir -p "$INSTALL_DIR"
cp "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"
info "installed: ${TARGET_SCRIPT}"

touch "$ZSHRC"

if ensure_line "$PATH_LINE" "$ZSHRC"; then
  info "added PATH entry to ${ZSHRC}"
else
  info "PATH entry already present in ${ZSHRC}"
fi

if [[ ${#MISSING_OPTIONAL[@]} -gt 0 ]]; then
  warn "optional tools not found: ${MISSING_OPTIONAL[*]} (nice to have, not required)"
fi

if kubectl config current-context >/dev/null 2>&1; then
  info "kubectl context check: ok ($(kubectl config current-context))"
else
  warn "kubectl has no active context right now. Log in to your clusters before using ${TOOL_NAME}."
fi

printf '\n'
printf 'Install complete.\n'
printf 'Next step (pick one):\n'
printf '  1) open a new terminal session\n'
printf '  2) run: source "%s"\n' "$ZSHRC"
printf '\n'
printf 'Then run:\n'
printf '  %s\n' "$TOOL_NAME"
printf '\n'
printf 'Fallback if command is not found yet:\n'
printf '  %s\n' "${TARGET_SCRIPT}"
printf '\n'
printf 'To uninstall later:\n'
printf '  ./uninstall.sh\n'
