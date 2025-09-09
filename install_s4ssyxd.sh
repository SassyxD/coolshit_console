#!/usr/bin/env bash
# install_s4ssyxd.sh
# Ubuntu Server setup for s4ssyxd banner: figlet+lolcat (random font) + fastfetch + docker + k9s
# Idempotent & safe-ish

set -u  # (ไม่ set -e เพื่อให้ขั้นตอนที่พังบางอันไม่ทำให้ทั้งสคริปต์หยุด)

log() { printf "\n\033[1;36m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\n\033[1;31m[ERR ]\033[0m %s\n" "$*"; }

NONINTERACTIVE=${DEBIAN_FRONTEND:-}
export DEBIAN_FRONTEND=noninteractive

#---------- Base update ----------
log "Updating APT..."
sudo apt-get update -y || true

#---------- Essentials ----------
log "Installing base packages: git, curl, ca-certificates, software-properties-common..."
sudo apt-get install -y git curl ca-certificates software-properties-common gnupg lsb-release || true

#---------- Figlet + Lolcat ----------
log "Installing figlet + lolcat..."
sudo apt-get install -y figlet lolcat || true

#---------- fastfetch (try apt PPA -> snap -> build fallback no) ----------
install_fastfetch() {
  if command -v fastfetch >/dev/null 2>&1; then
    log "fastfetch already installed."
    return 0
  fi

  log "Trying to install fastfetch via PPA..."
  if sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch >/dev/null 2>&1; then
    sudo apt-get update -y || true
    if sudo apt-get install -y fastfetch; then
      log "Installed fastfetch via PPA."
      return 0
    fi
  fi

  log "PPA failed or unavailable. Trying snap..."
  if command -v snap >/dev/null 2>&1; then
    if sudo snap install fastfetch >/dev/null 2>&1; then
      # expose snap bin in PATH if needed
      if ! command -v fastfetch >/dev/null 2>&1 && [ -x /snap/bin/fastfetch ]; then
        log "fastfetch available at /snap/bin/fastfetch; will call via absolute path in .bashrc."
      fi
      log "Installed fastfetch via snap."
      return 0
    fi
  fi

  warn "fastfetch install failed. Banner will still work, but fastfetch won’t show."
  return 1
}
install_fastfetch

#---------- Docker ----------
install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed."
  else
    log "Installing docker.io..."
    sudo apt-get install -y docker.io || {
      warn "docker.io install via apt failed."
    }
  fi

  # Enable/Start Docker
  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable docker >/dev/null 2>&1 || true
    sudo systemctl start docker >/dev/null 2>&1 || true
  fi

  # Add current user to docker group (if exists)
  if getent group docker >/dev/null 2>&1; then
    sudo usermod -aG docker "$USER" || true
    log "Added $USER to docker group. (เปิด terminal ใหม่ หรือรัน: newgrp docker)"
  fi
}
install_docker

#---------- k9s (apt or snap) ----------
install_k9s() {
  if command -v k9s >/dev/null 2>&1; then
    log "k9s already installed."
    return 0
  fi
  log "Trying to install k9s via apt..."
  if sudo apt-get install -y k9s >/dev/null 2>&1; then
    log "Installed k9s via apt."
    return 0
  fi
  log "Apt k9s not found. Trying snap..."
  if command -v snap >/dev/null 2>&1; then
    if sudo snap install k9s >/dev/null 2>&1; then
      log "Installed k9s via snap."
      return 0
    fi
  fi
  warn "k9s install skipped (not found via apt/snap)."
  return 1
}
install_k9s

#---------- Download Figlet Fonts ----------
install_figlet_fonts() {
  local tmpdir="/tmp/figlet-fonts.$$"
  local target="/usr/share/figlet"

  log "Fetching additional figlet fonts from GitHub (xero/figlet-fonts)..."
  rm -rf "$tmpdir"
  if git clone --depth=1 https://github.com/xero/figlet-fonts.git "$tmpdir" >/dev/null 2>&1; then
    # copy only .flf to avoid broken entries
    sudo mkdir -p "$target"
    sudo find "$tmpdir" -type f -name "*.flf" -print0 | xargs -0 -I{} sudo cp "{}" "$target"/
    log "Installed extra figlet fonts to $target"
  else
    warn "Could not clone figlet-fonts; skipping extra fonts."
  fi
  rm -rf "$tmpdir"
}
install_figlet_fonts

#---------- Patch ~/.bashrc (idempotent) ----------
log "Patching ~/.bashrc with random figlet + lolcat + fastfetch banner..."

BASHRC="$HOME/.bashrc"
MARK_START="# >>> S4ssyxd Random Banner >>>"
MARK_END="# <<< S4ssyxd Random Banner <<<"

# Remove old block if exists
if grep -q "$MARK_START" "$BASHRC" 2>/dev/null; then
  # delete from MARK_START to MARK_END
  sed -i "/$MARK_START/,/$MARK_END/d" "$BASHRC"
fi

# Detect fastfetch path (apt/snap/none)
FASTFETCH_BIN="fastfetch"
if ! command -v fastfetch >/dev/null 2>&1; then
  if [ -x /snap/bin/fastfetch ]; then
    FASTFETCH_BIN="/snap/bin/fastfetch"
  else
    FASTFETCH_BIN=""  # not installed
  fi
fi

cat >> "$BASHRC" <<'EOF'

# >>> S4ssyxd Random Banner >>>
# Clear screen for a clean entry
clear

# Build a list of valid .flf figlet fonts
mapfile -t _S4_FONTS < <(find /usr/share/figlet -maxdepth 1 -type f -name "*.flf" 2>/dev/null)

# Fallback to default 'standard' if none found
if [ ${#_S4_FONTS[@]} -eq 0 ]; then
  _S4_CHOSEN="standard"
else
  _S4_CHOSEN="${_S4_FONTS[$RANDOM % ${#_S4_FONTS[@]}]}"
fi

# Pretty separator
printf "\n"
printf "%0.s=" {1..80} | lolcat
printf "\n"

# Render banner
if [ "$_S4_CHOSEN" = "standard" ]; then
  figlet "s4ssyxd" | lolcat
else
  figlet -f "$_S4_CHOSEN" "s4ssyxd" | lolcat
fi

# Pretty separator
printf "%0.s=" {1..80} | lolcat
printf "\n\n"

# Run fastfetch if available
if command -v fastfetch >/dev/null 2>&1; then
  fastfetch
elif [ -x /snap/bin/fastfetch ]; then
  /snap/bin/fastfetch
fi

printf "\n"
# <<< S4ssyxd Random Banner <<<
EOF

log "All set! Open a NEW terminal to see the banner."
log "If Docker just got installed, run:  \033[1mnewgrp docker\033[0m  (or log out & in) for group to take effect."

# restore env
export DEBIAN_FRONTEND=$NONINTERACTIVE
