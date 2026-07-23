#!/usr/bin/env bash
# Personal dotfiles — Arch Linux
# Deploy via GNU stow. Safe to re-run.

set -euo pipefail

GREEN="\033[1;32m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"
BOLD="\033[1m"

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
STATE_FILE="$DOTFILES/.install-state"
CURRENT_STEP=""

# ── Flags ──
VERBOSE=false
for arg in "$@"; do
  case "$arg" in
  -v | --verbose) VERBOSE=true ;;
  -h | --help)
    echo "Usage: ./install.sh [--verbose] [--help]"
    echo
    echo "  --verbose, -v   Show commands as they run"
    echo "  --help, -h      Show this help"
    echo
    echo "  Steps are tracked in .install-state — completed steps are skipped"
    echo "  on re-run. Delete .install-state to force a full re-run."
    exit 0
    ;;
  *)
    echo -e "${RED}[ERR]${RESET} Unknown flag: $arg"
    exit 1
    ;;
  esac
done

# ── Logging ──
log() { echo -e "${BLUE}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error() { echo -e "${RED}[ERR]${RESET} $1" >&2; }
header() {
  echo
  echo -e "${CYAN}━━━ $1 ━━━${RESET}"
}
vrun() {
  $VERBOSE && echo -e " ${CYAN}→${RESET} $*" >&2
  "$@"
}

# ── Error trap ──
trap 'error "Step '\''${CURRENT_STEP:-?}'\'' failed at line $LINENO\n       Fix the issue and re-run — completed steps are saved."; exit 1' ERR

# ── State tracking ──
is_step_done() { grep -qxF "$1" "$STATE_FILE" 2>/dev/null; }
mark_step_done() { echo "$1" >>"$STATE_FILE"; }

# ── Pre-flight checks ──
preflight() {
  CURRENT_STEP="preflight"
  header "Pre-flight checks"

  local issues=()

  command -v pacman &>/dev/null || issues+=("pacman not found — not an Arch-based system?")
  command -v sudo &>/dev/null || issues+=("sudo not found")
  command -v paru &>/dev/null || issues+=("paru not found — AUR helper required")

  if ! ping -c 1 -W 2 archlinux.org &>/dev/null; then
    issues+=("No internet connectivity")
  fi

  if [ ${#issues[@]} -gt 0 ]; then
    error "Pre-flight checks failed:"
    for i in "${issues[@]}"; do echo "  • $i"; done
    exit 1
  fi

  success "All pre-flight checks passed"
}

# ── Package pre-scan ──
scan_packages() {
  local file="$1" manager="$2" label="$3" missing=()
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" == "#"* ]] && continue
    if ! "$manager" -Si "$pkg" &>/dev/null; then
      missing+=("$pkg")
    fi
  done <"$file"

  if [ ${#missing[@]} -gt 0 ]; then
    warn "$label packages not found in repos:"
    for pkg in "${missing[@]}"; do echo "    ${RED}✗${RESET} $pkg"; done
  else
    success "All $label packages found in repos"
  fi
}

# ── 1. System packages ──
step_packages() {
  CURRENT_STEP="packages"
  header "Installing packages"

  if [ -f "$DOTFILES/aur-packages.txt" ]; then
    scan_packages "$DOTFILES/aur-packages.txt" paru "AUR"
    local aur_pkgs=($(grep -v '^#' "$DOTFILES/aur-packages.txt" | tr '\n' ' '))
    if [ ${#aur_pkgs[@]} -gt 0 ]; then
      log "Installing ${#aur_pkgs[@]} AUR packages..."
      vrun paru -S --needed --noconfirm "${aur_pkgs[@]}" || warn "Some AUR packages may have failed"
    fi
  fi

  if [ -f "$DOTFILES/packages.txt" ]; then
    scan_packages "$DOTFILES/packages.txt" pacman "Official"
    local pkgs=($(grep -v '^#' "$DOTFILES/packages.txt" | tr '\n' ' '))
    if [ ${#pkgs[@]} -gt 0 ]; then
      log "Installing ${#pkgs[@]} official packages..."
      vrun sudo pacman -S --needed --noconfirm "${pkgs[@]}" || warn "Some official packages may have failed"
    fi
  fi
  success "Packages installed"
}

# ── 2. Dotfiles (stow) ──
step_dotfiles() {
  CURRENT_STEP="dotfiles"
  header "Linking dotfiles"
  if ! command -v stow &>/dev/null; then
    vrun sudo pacman -S --needed --noconfirm stow
  fi

  local stow_dir="$DOTFILES/config"
  local target_dir="$HOME"
  local backup_dir="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
  local did_backup=false

  for module in hypr fish foot starship tmux nvim fastfetch btop thunar caelestia mpv; do
    if [ -d "$stow_dir/$module" ]; then
      log "Stowing $module..."
      if vrun stow --dir="$stow_dir" --target="$target_dir" -R "$module" 2>/dev/null; then
        :
      else
        warn "$module has existing files, adopting..."
        if ! $did_backup; then
          mkdir -p "$backup_dir"
          did_backup=true
        fi
        vrun stow --dir="$stow_dir" --target="$target_dir" --adopt "$module"
      fi
    fi
  done

  if $did_backup; then
    if [ -n "$(git -C "$DOTFILES" diff --name-only -- config/ 2>/dev/null)" ]; then
      log "Backing up adopted files to $backup_dir/"
      git -C "$DOTFILES" diff --name-only -- config/ 2>/dev/null | while IFS= read -r f; do
        local dest="$backup_dir/${f#config/}"
        mkdir -p "$(dirname "$dest")"
        cp "$DOTFILES/$f" "$dest" 2>/dev/null || true
      done
    fi
    success "Existing files backed up to $backup_dir/"
  fi

  if [ -d "$DOTFILES/.git" ]; then
    git -C "$DOTFILES" checkout -- config/ 2>/dev/null || true
  fi
  success "Dotfiles linked"
}

# ── 3. mpv — material-osc & thumbfast ──
step_mpv() {
  CURRENT_STEP="mpv"
  header "Setting up mpv (material-osc + thumbfast)"

  if [ -f "$DOTFILES/material-osc/bundle.py" ]; then
    log "material-osc source found — building from source..."

    local had_fonttools=false
    if pacman -Q python-fonttools &>/dev/null; then
      had_fonttools=true
    fi
    vrun sudo pacman -S --needed --noconfirm python-fonttools

    vrun python3 "$DOTFILES/material-osc/bundle.py" 0.0.6

    mkdir -p "$DOTFILES/config/mpv/.config/mpv"/{fonts,scripts}
    vrun cp "$DOTFILES/material-osc/build/0.0.6/fonts/"* \
      "$DOTFILES/config/mpv/.config/mpv/fonts/"
    vrun cp "$DOTFILES/material-osc/build/0.0.6/scripts/"* \
      "$DOTFILES/config/mpv/.config/mpv/scripts/"

    if ! $had_fonttools; then
      vrun sudo pacman -R --noconfirm python-fonttools
    fi
    success "material-osc built and staged"
  else
    log "material-osc source not available — using pre-built config/mpv/ files"
  fi

  mkdir -p "$HOME/.config/mpv/scripts"
  log "Downloading thumbfast.lua..."
  vrun curl -fsSL \
    "https://raw.githubusercontent.com/po5/thumbfast/master/thumbfast.lua" \
    -o "$HOME/.config/mpv/scripts/thumbfast.lua"
  success "thumbfast.lua installed"
}

# ── 4. Post-install verification ──
step_verify() {
  CURRENT_STEP="verify"
  header "Post-install verification"

  local bins=(fish foot nvim btop starship tmux fastfetch hyprctl)
  local ok=true

  for bin in "${bins[@]}"; do
    if command -v "$bin" &>/dev/null; then
      echo "  ${GREEN}✓${RESET} $bin"
    else
      echo "  ${RED}✗${RESET} $bin — not on PATH"
      ok=false
    fi
  done

  $ok && success "All checks passed" || warn "Some binaries missing — try re-logging in"
}

# ── Main ──
main() {
  echo
  echo -e "${CYAN}╔══════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║${RESET}          ${BOLD}Personal Dotfiles Installer${RESET}             ${CYAN}║${RESET}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════╝${RESET}"
  $VERBOSE && echo -e " ${CYAN}→${RESET} Verbose mode on" >&2
  echo

  preflight

  local steps=(
    "packages:step_packages"
    "mpv:step_mpv"
    "dotfiles:step_dotfiles"
    "verify:step_verify"
  )

  for step_def in "${steps[@]}"; do
    local name="${step_def%%:*}"
    local fn="${step_def##*:}"

    if is_step_done "$name"; then
      success "Step '$name' already completed — skipping"
      continue
    fi

    CURRENT_STEP="$name"
    $fn
    mark_step_done "$name"
  done

  echo
  echo -e "${GREEN}╔══════════════════════════════════════════════════╗${RESET}"
  echo -e "${GREEN}║${RESET}      ${BOLD}Installation complete!${RESET}                     ${GREEN}║${RESET}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════╝${RESET}"
  echo
  echo "  Run ./install.sh again after paru -Syu to re-stow configs."
  echo "  Delete .install-state to force a full re-run."
  echo
}

main
