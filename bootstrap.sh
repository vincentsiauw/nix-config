#!/usr/bin/env bash
# =============================================================
# bootstrap.sh — Fresh Mac setup from nix-config GitHub repo
#
# Run on a BRAND NEW Mac (nothing pre-installed):
#   curl -fsSL https://raw.githubusercontent.com/jamesvincentsiauw/nix-config/main/bootstrap.sh | bash
#
# What this does (fully automated):
#   1. Xcode CLI tools
#   2. Nix (Determinate Installer)
#   3. Homebrew
#   4. GitHub CLI → gh auth login (browser)
#   5. Clone jamesvincentsiauw/nix-config → ~/.config/nix-darwin
#   6. darwin-rebuild switch --flake   (installs EVERYTHING)
#   7. VS Code extensions
#   8. Generate new SSH keys + print instructions
# =============================================================

set -euo pipefail

GITHUB_USER="jamesvincentsiauw"
NIX_CONFIG_REPO="${GITHUB_USER}/nix-config"
NIX_CONFIG_DIR="${HOME}/.config/nix-darwin"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
info() { echo -e "${BLUE}ℹ${NC}  $1"; }
step() { echo -e "\n${BOLD}${BLUE}▶ $1${NC}"; }

echo ""
echo -e "${BOLD}=================================================${NC}"
echo -e "${BOLD}  Mac Bootstrap — ${GITHUB_USER}${NC}"
echo -e "${BOLD}=================================================${NC}"
echo ""

# ─── 1. Xcode CLI ─────────────────────────────────────────────
step "1. Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
  log "Already installed"
else
  info "Installing Xcode CLI tools..."
  xcode-select --install
  read -rp "Press Enter once Xcode CLI installation completes..."
fi

# ─── 2. Nix ───────────────────────────────────────────────────
step "2. Nix"
if command -v nix &>/dev/null; then
  log "Already installed: $(nix --version)"
else
  info "Installing Nix via Determinate Installer..."
  curl --proto '=https' --tlsv1.2 -sSf \
    https://install.determinate.systems/nix | sh -s -- install --no-confirm
  source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  log "Nix installed: $(nix --version)"
fi

# ─── 3. Homebrew ──────────────────────────────────────────────
step "3. Homebrew"
if command -v brew &>/dev/null; then
  log "Already installed"
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
  fi
  log "Homebrew installed"
fi

# ─── 4. GitHub CLI auth ───────────────────────────────────────
step "4. GitHub CLI — authenticate"
if ! command -v gh &>/dev/null; then
  info "Installing gh CLI..."
  brew install gh
fi

if gh auth status &>/dev/null; then
  log "Already authenticated as: $(gh api user --jq .login)"
else
  info "Opening GitHub login in browser..."
  gh auth login --hostname github.com --git-protocol https --web
  log "GitHub CLI authenticated"
fi

# ─── 5. Clone nix-config ──────────────────────────────────────
step "5. Clone nix-config"
if [[ -d "${NIX_CONFIG_DIR}/.git" ]]; then
  info "Already cloned — pulling latest..."
  git -C "${NIX_CONFIG_DIR}" pull
  log "nix-config up to date"
else
  mkdir -p "$(dirname "${NIX_CONFIG_DIR}")"
  gh repo clone "${NIX_CONFIG_REPO}" "${NIX_CONFIG_DIR}"
  log "Cloned to ${NIX_CONFIG_DIR}"
fi

# ─── 6. darwin-rebuild switch ─────────────────────────────────
step "6. darwin-rebuild switch (installs all packages)"
info "This will take a while on first run — packages are downloaded from nixpkgs."
echo ""

# On a fresh Mac, darwin-rebuild doesn't exist yet — use nix run
if command -v darwin-rebuild &>/dev/null; then
  darwin-rebuild switch --flake "${NIX_CONFIG_DIR}" 2>&1 | tee /tmp/darwin-rebuild.log
else
  nix run nix-darwin -- switch --flake "${NIX_CONFIG_DIR}" 2>&1 | tee /tmp/darwin-rebuild.log
fi

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
  log "darwin-rebuild switch completed"
else
  warn "Build had errors — see /tmp/darwin-rebuild.log"
  warn "Fix then re-run: darwin-rebuild switch --flake ~/.config/nix-darwin"
fi

# ─── 7. VS Code extensions ────────────────────────────────────
step "7. VS Code extensions"
# Wait for VS Code cask to be installed by Homebrew (step 6)
if command -v code &>/dev/null; then
  EXTENSIONS=(
    adrientoub.base64utils aldijav.golangwithdidi anthropic.claude-code
    arjun.swagger-viewer asyncapi.asyncapi-preview austin-lin.vscode-project-structure
    bmewburn.vscode-intelephense-client clarkyu.vscode-sql-beautify
    clemenspeters.format-json dbaeumer.vscode-eslint drblury.protobuf-vsc
    eamodio.gitlens github.copilot-chat golang.go grapecity.gc-excelviewer
    laravel.vscode-laravel ms-python.debugpy ms-python.python
    ms-python.vscode-pylance ms-toolsai.jupyter ms-toolsai.jupyter-keymap
    ms-toolsai.jupyter-renderers ms-toolsai.vscode-jupyter-cell-tags
    ms-toolsai.vscode-jupyter-slideshow ms-vscode-remote.remote-wsl
    ms-vscode.makefile-tools ms-vscode.vscode-speech quicktype.quicktype
    qwtel.sqlite-viewer rangav.vscode-thunder-client redhat.vscode-yaml
    rust-lang.rust-analyzer svelte.svelte-vscode techer.open-in-browser
    tomoki1207.pdf ukoloff.win-ca waderyan.gitblame wholroyd.jinja
  )
  OK=0; FAIL=0
  for ext in "${EXTENSIONS[@]}"; do
    code --install-extension "${ext}" --force &>/dev/null && ((OK++)) || ((FAIL++)) || true
  done
  log "VS Code extensions: ${OK} installed, ${FAIL} failed"
else
  warn "VS Code not yet in PATH — open VS Code manually once, then re-run:"
  warn "  bash ${NIX_CONFIG_DIR}/bootstrap.sh"
fi

# ─── 8. Generate new SSH keys ─────────────────────────────────
step "8. SSH Keys (generate fresh)"
mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"

GIT_EMAIL="vincent.vincent@bfi.co.id"

if [[ ! -f "${HOME}/.ssh/id_ed25519" ]]; then
  ssh-keygen -t ed25519 -C "${GIT_EMAIL}" -f "${HOME}/.ssh/id_ed25519" -N ""
  log "Generated ~/.ssh/id_ed25519 (personal GitHub)"
else
  log "~/.ssh/id_ed25519 already exists"
fi

if [[ ! -f "${HOME}/.ssh/jk_ed25519" ]]; then
  ssh-keygen -t ed25519 -C "${GIT_EMAIL}-jk" -f "${HOME}/.ssh/jk_ed25519" -N ""
  log "Generated ~/.ssh/jk_ed25519 (work GitHub)"
else
  log "~/.ssh/jk_ed25519 already exists"
fi

# Add keys to ssh-agent
eval "$(ssh-agent -s)" &>/dev/null || true
ssh-add "${HOME}/.ssh/id_ed25519" 2>/dev/null || true
ssh-add "${HOME}/.ssh/jk_ed25519" 2>/dev/null || true

# ─── Summary ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}=================================================${NC}"
echo -e "${BOLD}${GREEN}  Bootstrap Complete!${NC}"
echo -e "${BOLD}${GREEN}=================================================${NC}"
echo ""
echo -e "${BOLD}Manual steps remaining:${NC}"
echo ""
echo -e "  1. ${YELLOW}Register SSH public keys${NC} to GitHub:"
echo "     Personal key:"
echo "       $(cat "${HOME}/.ssh/id_ed25519.pub" 2>/dev/null || echo '(not found)')"
echo "     Work (jk) key:"
echo "       $(cat "${HOME}/.ssh/jk_ed25519.pub" 2>/dev/null || echo '(not found)')"
echo "     → https://github.com/settings/keys"
echo ""
echo -e "  2. ${YELLOW}Register SSH keys to BFI servers${NC} (bastion, staging, prod):"
echo "     Get devops to add your public key, OR copy developers.pem from old Mac"
echo "     (AirDrop: ~/.ssh/developers.pem → ~/.ssh/bfi.pem)"
echo ""
echo -e "  3. ${YELLOW}GitHub PAT for go mod / git clone via HTTPS${NC}:"
echo "     Create PAT at: https://github.com/settings/tokens"
echo "     Then run:"
echo '     git config --global url."https://jamesvincentsiauw-mac:<PAT>@github.com".insteadOf https://github.com'
echo ""
echo -e "  4. ${YELLOW}Colima (Docker)${NC}:"
echo "     colima start --cpu 4 --memory 8 --disk 60"
echo ""
echo -e "  5. ${YELLOW}Restart terminal${NC}: exec zsh"
echo ""
echo -e "  6. ${YELLOW}VS Code${NC}: Sign in to GitHub Copilot (Account menu)"
echo ""
echo -e "${BOLD}Update config anytime:${NC}"
echo "  darwin-rebuild switch --flake ~/.config/nix-darwin"
echo ""
