#!/usr/bin/env bash
# install_s4ssyxd.sh — all-in-one setup for Ubuntu Server
# - Kubernetes CLI (kubectl)
# - Docker (enable + add user to docker group)
# - Node.js LTS (NodeSource)
# - Dev toolchain: ninja-build, gettext, cmake, unzip, curl
# - Neovim (apt) + LazyVim starter (~/.config/nvim)
# - figlet + lolcat + extra figlet fonts
# - fastfetch (PPA -> snap fallback)
# - ~/.bashrc banner with RANDOM figlet font + fastfetch
#
# Tested on Ubuntu 20.04/22.04/24.04

set -u
log()  { printf "\n\033[1;36m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m[WARN]\033[0m %s\n" "$*"; }

NONINTERACTIVE=${DEBIAN_FRONTEND:-}
export DEBIAN_FRONTEND=noninteractive

# ---------- APT base ----------
log "Updating APT..."
sudo apt-get update -y || true

log "Installing essentials..."
sudo apt-get install -y git curl ca-certificates software-properties-common gnupg lsb-release || true

# ---------- figlet + lolcat ----------
log "Installing figlet + lolcat..."
sudo apt-get install -y figlet lolcat || true

# ---------- fastfetch (PPA -> snap fallback) ----------
install_fastfetch() {
  if command -v fastfetch >/dev/null 2>&1; then
    log "fastfetch already installed."
    return 0
  fi
  log "Installing fastfetch via PPA..."
  if sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch >/dev/null 2>&1; then
    sudo apt-get update -y || true
    if sudo apt-get install -y fastfetch; then
      log "fastfetch installed (PPA)."
      return 0
    fi
  fi
  log "PPA failed or unavailable. Trying snap..."
  if command -v snap >/dev/null 2>&1; then
    if sudo snap install fastfetch >/dev/null 2>&1; then
      log "fastfetch installed (snap)."
      return 0
    fi
  fi
  warn "fastfetch not installed (skipped)."
  return 1
}
install_fastfetch

# ---------- Docker ----------
install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed."
  else
    log "Installing docker.io..."
    sudo apt-get install -y docker.io || warn "docker.io install via apt failed."
  fi

  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable docker >/dev/null 2>&1 || true
    sudo systemctl start docker  >/dev/null 2>&1 || true
  fi

  if getent group docker >/dev/null 2>&1; then
    sudo usermod -aG docker "$USER" || true
    log "Added $USER to docker group (run: newgrp docker)."
  fi
}
install_docker

# ---------- Kubernetes (kubectl) ----------
install_k8s() {
  if command -v kubectl >/dev/null 2>&1; then
    log "kubectl already installed: $(kubectl version --client --short 2>/dev/null || echo ok)"
    return 0
  fi

  log "Installing kubectl (official apt repo)..."
  sudo apt-get install -y apt-transport-https ca-certificates curl
  sudo mkdir -p /etc/apt/keyrings
  sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg

  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

  sudo apt-get update -y
  sudo apt-get install -y kubectl || warn "kubectl install failed."
}
install_k8s

# ---------- Dev toolchain ----------
log "Installing build toolchain: ninja-build, gettext, cmake, unzip, curl..."
sudo apt-get install -y ninja-build gettext cmake unzip curl || true

# ---------- Node.js LTS (NodeSource 20.x) ----------
install_node() {
  if command -v node >/dev/null 2>&1; then
    log "Node.js already installed: $(node -v)"
    return 0
  fi
  log "Installing Node.js LTS (20.x via NodeSource)..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || {
    warn "NodeSource setup failed."; return 1;
  }
  sudo apt-get install -y nodejs || warn "nodejs install failed."
  if command -v node >/dev/null 2>&1; then
    log "Node.js installed: $(node -v)"
  fi
}
install_node

# ---------- Neovim + LazyVim ----------
log "Installing Neovim (apt)..."
sudo apt-get install -y neovim || warn "neovim install failed (LazyVim may not work)."

bootstrap_lazyvim() {
  local nvim_dir="$HOME/.config/nvim"
  if [ -d "$nvim_dir" ] && [ -n "$(ls -A "$nvim_dir" 2>/dev/null)" ]; then
    warn "~/.config/nvim already exists; skip LazyVim clone."
    return 0
  fi
  log "Cloning LazyVim starter -> $nvim_dir"
  git clone https://github.com/LazyVim/starter "$nvim_dir" || {
    warn "Clone LazyVim failed."; return 1;
  }
  (cd "$nvim_dir" && git checkout main >/dev/null 2>&1 || true)
  rm -rf "$nvim_dir/.git"
  log "LazyVim ready (open 'nvim' to auto-install plugins)."
}
bootstrap_lazyvim

# ---------- Extra figlet fonts ----------
install_figlet_fonts() {
  local tmpdir="/tmp/figlet-fonts.$$"
  local target="/usr/share/figlet"
  log "Fetching extra figlet fonts (xero/figlet-fonts)..."
  rm -rf "$tmpdir"
  if git clone --depth=1 https://github.com/xero/figlet-fonts.git "$tmpdir" >/dev/null 2>&1; then
    sudo mkdir -p "$target"
    sudo find "$tmpdir" -type f -name "*.flf" -print0 | xargs -0 -I{} sudo cp "{}" "$target"/
    log "Installed .flf fonts to $target"
  else
    warn "Clone figlet-fonts failed; skipping."
  fi
  rm -rf "$tmpdir"
}
install_figlet_fonts

# ---------- Patch ~/.bashrc banner (idempotent) ----------
log "Patching ~/.bashrc for random figlet banner + fastfetch..."
BASHRC="$HOME/.bashrc"
MARK_START="# >>> S4ssyxd Random Banner >>>"
MARK_END="# <<< S4ssyxd Random Banner <<<"

# backup once
if [ ! -f "$HOME/.bashrc.bak_s4ssyxd" ]; then
  cp -f "$BASHRC" "$HOME/.bashrc.bak_s4ssyxd" 2>/dev/null || true
fi

# remove old block
if grep -q "$MARK_START" "$BASHRC" 2>/dev/null; then
  sed -i "/$MARK_START/,/$MARK_END/d" "$BASHRC"
fi

cat >> "$BASHRC" <<'EOF'

# >>> S4ssyxd Random Banner >>>
clear

# Collect valid figlet fonts (.flf)
mapfile -t _S4_FONTS < <(find /usr/share/figlet -maxdepth 1 -type f -name "*.flf" 2>/dev/null)

# Pick random or fallback to 'standard'
if [ ${#_S4_FONTS[@]} -eq 0 ]; then
  _S4_CHOSEN="standard"
else
  _S4_CHOSEN="${_S4_FONTS[$RANDOM % ${#_S4_FONTS[@]}]}"
fi

# Separator
printf "\n"; printf "%0.s=" {1..80} | lolcat; printf "\n"

# Banner
if [ "$_S4_CHOSEN" = "standard" ]; then
  figlet "s4ssyxd" | lolcat
else
  figlet -f "$_S4_CHOSEN" "s4ssyxd" | lolcat
fi

# Separator
printf "%0.s=" {1..80} | lolcat; printf "\n\n"

# fastfetch if available
if command -v fastfetch >/dev/null 2>&1; then
  fastfetch
elif [ -x /snap/bin/fastfetch ]; then
  /snap/bin/fastfetch
fi

printf "\n"
# <<< S4ssyxd Random Banner <<<
EOF

log "DONE ✅  Open a NEW terminal to see the banner."
log "If Docker was newly installed: run 'newgrp docker' (or log out/in)."

export DEBIAN_FRONTEND=$NONINTERACTIVE
