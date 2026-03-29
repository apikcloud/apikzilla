#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
#  apikzilla — installer / updater
#  Usage: curl -fsSL https://raw.githubusercontent.com/apikcloud/apikzilla/main/install.sh | bash
# ─────────────────────────────────────────────

REPO="apikcloud/apikzilla"
BIN_NAME="apikzilla"
INSTALL_DIR="/usr/local/bin"

# ── colours ──────────────────────────────────
if [ -t 1 ]; then
  BOLD="\033[1m"; RESET="\033[0m"
  GREEN="\033[32m"; CYAN="\033[36m"; RED="\033[31m"; YELLOW="\033[33m"
else
  BOLD=""; RESET=""; GREEN=""; CYAN=""; RED=""; YELLOW=""
fi

info()    { printf "  ${CYAN}•${RESET}  %s\n" "$*"; }
success() { printf "  ${GREEN}✓${RESET}  %s\n" "$*"; }
warn()    { printf "  ${YELLOW}!${RESET}  %s\n" "$*"; }
die()     { printf "  ${RED}✗${RESET}  %s\n" "$*" >&2; exit 1; }
title()   { printf "\n${BOLD}%s${RESET}\n" "$*"; }

# ── detect OS / arch ─────────────────────────
detect_platform() {
  local os arch

  case "$(uname -s)" in
    Linux)  os="linux"   ;;
    Darwin) os="darwin"  ;;
    *)      die "Unsupported OS: $(uname -s)" ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64)   arch="x86_64"  ;;
    aarch64|arm64)  arch="aarch64" ;;
    *)              die "Unsupported architecture: $(uname -m)" ;;
  esac

  echo "${os}-${arch}"
}

# ── fetch latest version tag ─────────────────
latest_version() {
  curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' \
    | cut -d '"' -f 4
}

# ── check for existing install ───────────────
current_version() {
  if command -v "${BIN_NAME}" &>/dev/null; then
    "${BIN_NAME}" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"
  fi
}

# ── require sudo only if needed ──────────────
need_sudo() {
  [ ! -w "${INSTALL_DIR}" ]
}

run_sudo() {
  if need_sudo; then
    sudo "$@"
  else
    "$@"
  fi
}

# ── main ─────────────────────────────────────
main() {
  title "apikzilla installer"

  local platform version tarball url current

  platform="$(detect_platform)"
  info "Platform detected: ${platform}"

  version="$(latest_version)"
  [ -n "${version}" ] || die "Could not fetch latest release from GitHub."
  info "Latest version:    ${version}"

  current="$(current_version)"
  if [ -n "${current}" ]; then
    if [ "${current}" = "${version#v}" ] || [ "${current}" = "${version}" ]; then
      success "${BIN_NAME} ${current} is already up to date — nothing to do."
      exit 0
    fi
    warn "Upgrading ${current} → ${version}"
  fi

  tarball="${BIN_NAME}-${version}-${platform}.tar.gz"
  url="https://github.com/${REPO}/releases/download/${version}/${tarball}"

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "${TMP_DIR}"' EXIT

  info "Downloading ${tarball} …"
  curl -fsSL --progress-bar -o "${TMP_DIR}/${tarball}" "${url}" \
    || die "Download failed. Check your connection or visit https://github.com/${REPO}/releases"

  info "Extracting …"
  tar -xzf "${TMP_DIR}/${tarball}" -C "${TMP_DIR}"

  local bin_path="${TMP_DIR}/${BIN_NAME}"
  [ -f "${bin_path}" ] || die "Binary '${BIN_NAME}' not found in archive."
  chmod +x "${bin_path}"

  info "Installing to ${INSTALL_DIR}/${BIN_NAME} …"
  if need_sudo; then
    warn "sudo required to write to ${INSTALL_DIR}"
    if ! [ -t 0 ]; then
      warn "stdin is not a TTY — re-run as: bash <(curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh)"
      die "Cannot prompt for sudo password without a TTY."
    fi
  fi
  run_sudo mv "${bin_path}" "${INSTALL_DIR}/${BIN_NAME}"

  # Verify the binary was actually replaced
  installed_version="$("${INSTALL_DIR}/${BIN_NAME}" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")"
  if [ -z "${installed_version}" ] || [ "v${installed_version}" != "${version}" -a "${installed_version}" != "${version}" ]; then
    die "Installation verification failed — expected ${version}, got '${installed_version}'. Try running the installer directly (not piped)."
  fi

  echo ""
  success "${BIN_NAME} ${version} installed → ${INSTALL_DIR}/${BIN_NAME}"
  printf "       Run ${BOLD}${BIN_NAME} --help${RESET} to get started.\n\n"
}

main "$@"