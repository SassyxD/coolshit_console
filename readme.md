# s4ssyxd Console Setup

Bootstrap developer tools for Linux and Windows. Installs: Git, Curl, Fastfetch, Figlet (with extra fonts), Node.js LTS, kubectl, Neovim (LazyVim), Docker, and a terminal banner.

## Files
- `install_linux.sh` — Debian/Ubuntu (apt-based) setup
- `install_win.bat` — Windows setup via winget

## Prerequisites
- Linux: sudo privileges, apt
- Windows: Run as Administrator, winget (App Installer)

## Install

### Linux
```bash
wget https://raw.githubusercontent.com/SassyxD/coolshit_console/main/install_linux.sh -O install_linux.sh
chmod +x install_linux.sh
./install_linux.sh
```

Alternative (curl):
```bash
curl -fsSL https://raw.githubusercontent.com/SassyxD/coolshit_console/main/install_linux.sh -o install_linux.sh
chmod +x install_linux.sh && ./install_linux.sh
```

After install:
- Open a new terminal
- If Docker was newly installed: `newgrp docker` or log out/in

### Windows (PowerShell, Run as Administrator)
```powershell
Invoke-WebRequest https://raw.githubusercontent.com/SassyxD/coolshit_console/main/install_win.bat -OutFile install_win.bat
Start-Process cmd -ArgumentList "/c install_win.bat" -Verb RunAs -Wait
```

Alternative (Admin CMD):
```bat
curl -L -o install_win.bat https://raw.githubusercontent.com/SassyxD/coolshit_console/main/install_win.bat
install_win.bat
```

After install:
- Close and reopen PowerShell
- Docker Desktop may require sign-out/in or a reboot

## What Gets Installed

### Linux
- Packages: git, curl, ca-certificates, software-properties-common, gnupg, lsb-release
- figlet, lolcat
- fastfetch (PPA with snap fallback)
- Docker (service enabled; adds current user to docker group)
- kubectl
- Build tools: ninja-build, gettext, cmake, unzip
- Node.js LTS 20.x (NodeSource)
- Neovim + LazyVim
- Extra figlet fonts (xero/figlet-fonts)
- `~/.bashrc` patch: random figlet banner and fastfetch on shell start

### Windows
- Git, Curl, GnuPG, 7zip
- fastfetch
- figlet (Windows build)
- Node.js LTS
- kubectl
- Neovim + LazyVim (`%LOCALAPPDATA%\nvim`)
- Docker Desktop
- Extra figlet fonts to `%ProgramData%\figlet-fonts`
- PowerShell profile patch: random figlet banner with colorized output and fastfetch on terminal start

## Troubleshooting

- fastfetch (Linux) fails via PPA: script falls back to snap automatically.
- winget not found (Windows): install “App Installer” from Microsoft Store.
- Banner not shown:
  - Linux: check `~/.bashrc` contains the block marked `S4ssyxd Random Banner`; open a new terminal.
  - Windows: `notepad $PROFILE` and check for the same block; open a new PowerShell.
- Docker unusable after install:
  - Linux: `newgrp docker` or log out/in.
  - Windows: restart Docker Desktop or reboot if prompted.

## Re-running
Both scripts are idempotent. Re-running will skip or update existing components and refresh the banner block.

## Remove Banner

### Linux
Edit `~/.bashrc` and delete:
```
# >>> S4ssyxd Random Banner >>>
...
# <<< S4ssyxd Random Banner <<<
```
Then open a new terminal.

### Windows
```powershell
notepad $PROFILE
```
Delete the same marked block. Open a new PowerShell.

## License
MIT
