#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────
# OpenLeash Installer
# curl -fsSL https://openleash.ai/install.sh | bash
# ──────────────────────────────────────────────────────

# --- Color helpers ---
GREEN=$'\033[38;5;78m'    # #34d399
GOLD=$'\033[38;5;220m'    # #fbbf24
RED=$'\033[31m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# --- Output helpers ---
info()    { printf "${GREEN}▸${RESET} %s\n" "$*"; }
warn()    { printf "${GOLD}▸${RESET} %s\n" "$*"; }
error()   { printf "$RED✗${RESET} %s\n" "$*" >&2; }
success() { printf "${GREEN}✓${RESET} %s\n" "$*"; }

# --- Cleanup ---
ANIM_PID=""
cleanup() {
  if [ -n "$ANIM_PID" ] && kill -0 "$ANIM_PID" 2>/dev/null; then
    kill "$ANIM_PID" 2>/dev/null || true
    wait "$ANIM_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

# --- ASCII art ---
LOBSTER_STATIC="${GREEN}${BOLD}
        \\\\    //
         \\\\  //
      .-\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"-.
     /  ${GOLD}o${GREEN}            ${GOLD}o${GREEN}  \\
    |    .-\"\"\"\"\"\"\"-.    |
    |   / ~~~~~~~~~ \\   |
     \\ |  ~~~~~~~~~  | /
      \\|_____________|/
       ${GOLD}|${GREEN}      |      ${GOLD}|${GREEN}
       ${GOLD}|${GREEN}    __|__    ${GOLD}|${GREEN}
       ${GOLD}|${GREEN}   /     \\   ${GOLD}|${GREEN}
        \\ /       \\ /
         V  ${GOLD}(leash)${GREEN}  V
         |    ${GOLD}|${GREEN}    |
        / \\   ${GOLD}|${GREEN}   / \\
       /   \\  ${GOLD}|${GREEN}  /   \\
${RESET}"

LOBSTER_SUCCESS="${GREEN}${BOLD}
        \\\\    //
         \\\\  //
      .-\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"-.
     /  ${GOLD}^${GREEN}            ${GOLD}^${GREEN}  \\
    |    .-\"\"\"\"\"\"\"-.    |
    |   / ~~~~~~~~~ \\   |
     \\ |  ~~~~~~~~~  | /
      \\|_____________|/
       ${GOLD}|${GREEN}      |      ${GOLD}|${GREEN}
       ${GOLD}|${GREEN}    __|__    ${GOLD}|${GREEN}
       ${GOLD}|${GREEN}   /  ${GREEN}✓${GREEN}  \\   ${GOLD}|${GREEN}
        \\ /       \\ /
         V         V
${RESET}"

FRAME_1="${DIM}
        \\\\    //
         \\\\  //
      .-\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"-.
     /  o            o  \\
    |    .-\"\"\"\"\"\"\"-.    |
     \\ |  ~~~~~~~~~  | /
      \\|_____________|/
         |    |    |
        / \\   |   / \\
       /   \\--+  /   \\
${RESET}"

FRAME_2="${DIM}
        \\\\    //
         \\\\  //
      .-\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"-.
     /  o            o  \\
    |    .-\"\"\"\"\"\"\"-.    |
     \\ |  ~~~~~~~~~  | /
      \\|_____________|/
         |    |    |
        / \\   |   / \\
       /   \\  +--/   \\
${RESET}"

FRAME_3="${DIM}
        \\\\    //
         \\\\  //
      .-\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"-.
     /  o            o  \\
    |    .-\"\"\"\"\"\"\"-.    |
     \\ |  ~~~~~~~~~  | /
      \\|_____________|/
         |    |    |
        / \\   |   / \\
       /   +--'  /   \\
${RESET}"

FRAME_LINES=11

animate_lobster() {
  local frames=("$FRAME_1" "$FRAME_2" "$FRAME_3" "$FRAME_2")
  local i=0
  # Print initial frame to reserve space
  printf "%s" "${frames[0]}"
  while true; do
    sleep 0.4
    i=$(( (i + 1) % ${#frames[@]} ))
    # Move cursor up and redraw
    printf "\033[${FRAME_LINES}A"
    printf "%s" "${frames[$i]}"
  done
}

# ──────────────────────────────────────────────────────
# Start
# ──────────────────────────────────────────────────────

printf "%s" "$LOBSTER_STATIC"
printf "\n"
printf "  ${BOLD}OpenLeash Installer${RESET}\n"
printf "  ${DIM}Local-first policy gate for AI agents${RESET}\n"
printf "\n"

# --- OS detection ---
OS="$(uname -s)"
ARCH="$(uname -m)"
IS_WSL=false

case "$OS" in
  Darwin)  PLATFORM="macos"  ;;
  Linux)
    PLATFORM="linux"
    if [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; then
      IS_WSL=true
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    error "Windows is not supported by this installer."
    error "Please use: npm install -g @openleash/cli"
    exit 1
    ;;
  *)
    error "Unsupported operating system: $OS"
    exit 1
    ;;
esac

info "Detected platform: ${BOLD}${PLATFORM}${RESET} (${ARCH})"
if [ "$IS_WSL" = true ]; then
  info "Running inside WSL (${WSL_DISTRO_NAME:-unknown})"
fi

# --- Node.js detection ---
NODE_CMD=""
MIN_NODE=18

find_node() {
  # Check node on PATH
  if command -v node >/dev/null 2>&1; then
    NODE_CMD="node"
    return 0
  fi

  # Check common nvm paths
  local nvm_dirs=(
    "$HOME/.nvm/versions/node"
    "$HOME/.local/share/nvm/versions/node"
  )
  for dir in "${nvm_dirs[@]}"; do
    if [ -d "$dir" ]; then
      local latest
      latest=$(ls -1v "$dir" 2>/dev/null | tail -n1)
      if [ -n "$latest" ] && [ -x "$dir/$latest/bin/node" ]; then
        export PATH="$dir/$latest/bin:$PATH"
        NODE_CMD="node"
        return 0
      fi
    fi
  done

  return 1
}

check_node_version() {
  local version
  version=$("$NODE_CMD" --version 2>/dev/null | sed 's/^v//')
  local major
  major=$(echo "$version" | cut -d. -f1)
  if [ "$major" -ge "$MIN_NODE" ] 2>/dev/null; then
    success "Node.js v${version} found"
    return 0
  else
    warn "Node.js v${version} found, but v${MIN_NODE}+ is required"
    return 1
  fi
}

install_node() {
  info "Installing Node.js..."
  echo ""

  if [ "$PLATFORM" = "macos" ]; then
    # Use Homebrew on macOS
    if ! command -v brew >/dev/null 2>&1; then
      info "Installing Homebrew first..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

      # Add brew to PATH for Apple Silicon / Intel
      if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    fi
    brew install node
    NODE_CMD="node"

  elif [ "$PLATFORM" = "linux" ]; then
    # Detect package manager
    if command -v apt-get >/dev/null 2>&1; then
      info "Setting up NodeSource repository (apt)..."
      curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
      sudo apt-get install -y nodejs
    elif command -v dnf >/dev/null 2>&1; then
      info "Setting up NodeSource repository (dnf)..."
      curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
      sudo dnf install -y nodejs
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -Sy --noconfirm nodejs npm
    elif command -v apk >/dev/null 2>&1; then
      sudo apk add --no-cache nodejs npm
    else
      error "Could not detect a supported package manager."
      error "Please install Node.js >= ${MIN_NODE} manually: https://nodejs.org"
      exit 1
    fi
    NODE_CMD="node"
  fi

  # Verify
  if ! command -v node >/dev/null 2>&1; then
    error "Node.js installation failed."
    error "Please install Node.js >= ${MIN_NODE} manually: https://nodejs.org"
    exit 1
  fi

  success "Node.js $(node --version) installed"
}

# --- Main install flow ---
NEED_NODE_INSTALL=false

if find_node; then
  if ! check_node_version; then
    NEED_NODE_INSTALL=true
  fi
else
  warn "Node.js not found"
  NEED_NODE_INSTALL=true
fi

if [ "$NEED_NODE_INSTALL" = true ]; then
  install_node
fi

echo ""
info "Installing OpenLeash..."
echo ""

# Start animation in background
animate_lobster &
ANIM_PID=$!

# Install OpenLeash globally
npm install -g @openleash/cli 2>&1 | tail -n 5

# Stop animation
if [ -n "$ANIM_PID" ] && kill -0 "$ANIM_PID" 2>/dev/null; then
  kill "$ANIM_PID" 2>/dev/null || true
  wait "$ANIM_PID" 2>/dev/null || true
  ANIM_PID=""
fi

# Clear the animation area
printf "\033[${FRAME_LINES}A"
for _ in $(seq 1 $FRAME_LINES); do
  printf "\033[2K\n"
done
printf "\033[${FRAME_LINES}A"

# --- PATH verification ---
if ! command -v openleash >/dev/null 2>&1; then
  # Try common npm global bin paths
  NPM_BIN="$(npm config get prefix 2>/dev/null)/bin"
  if [ -x "$NPM_BIN/openleash" ]; then
    warn "openleash installed but not on PATH"
    warn "Add to your shell profile:  export PATH=\"${NPM_BIN}:\$PATH\""
  else
    error "Installation may have failed. Try: npm install -g @openleash/cli"
    exit 1
  fi
fi

# --- Success ---
printf "%s" "$LOBSTER_SUCCESS"
echo ""
success "${BOLD}OpenLeash installed successfully!${RESET}"
echo ""
printf "  ${GREEN}Next steps:${RESET}\n"
printf "\n"
printf "    ${BOLD}openleash start${RESET}    ${DIM}# Start the policy sidecar${RESET}\n"
printf "    ${BOLD}openleash wizard${RESET}   ${DIM}# Configure policies interactively${RESET}\n"
printf "\n"
printf "  ${DIM}Docs: https://openleash.ai${RESET}\n"
printf "  ${DIM}GitHub: https://github.com/openleash/openleash${RESET}\n"
echo ""
