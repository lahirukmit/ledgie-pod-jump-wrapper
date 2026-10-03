#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="${SCRIPT_DIR}/ledgie-access"
INSTALL_DIR="${HOME}/.local/bin"
TARGET_SCRIPT="${INSTALL_DIR}/ledgie-access"
TARGET_ALIAS_BIN="${INSTALL_DIR}/access"
ZSHRC="${HOME}/.zshrc"
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
ALIAS_LINE="alias access='ledgie-access'"

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
ln -sf "$TARGET_SCRIPT" "$TARGET_ALIAS_BIN"

touch "$ZSHRC"

PATH_ADDED="false"
ALIAS_ADDED="false"

if ensure_line "$PATH_LINE" "$ZSHRC"; then
  PATH_ADDED="true"
fi

if ensure_line "$ALIAS_LINE" "$ZSHRC"; then
  ALIAS_ADDED="true"
fi

info "installed: ${TARGET_SCRIPT}"
info "installed shortcut command: ${TARGET_ALIAS_BIN}"

if [[ "$PATH_ADDED" == "true" ]]; then
  info "added PATH entry to ${ZSHRC}"
else
  info "PATH entry already present in ${ZSHRC}"
fi

if [[ "$ALIAS_ADDED" == "true" ]]; then
  info "added alias to ${ZSHRC}: access -> ledgie-access"
else
  info "alias already present in ${ZSHRC}"
fi

if [[ ${#MISSING_OPTIONAL[@]} -gt 0 ]]; then
  warn "optional tools not found: ${MISSING_OPTIONAL[*]} (nice to have, not required)"
fi

if kubectl config current-context >/dev/null 2>&1; then
  info "kubectl context check: ok ($(kubectl config current-context))"
else
  warn "kubectl has no active context right now. Run kubectx/kubectl login before using ledgie-access."
fi

printf '\n'
printf 'Install complete.\n'
printf 'Next step (pick one):\n'
printf '  1) open a new terminal session\n'
printf '  2) run: source "%s"\n' "$ZSHRC"
printf '\n'
printf 'Then run:\n'
printf '  access --help\n'
