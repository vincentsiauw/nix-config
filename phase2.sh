#!/usr/bin/env bash
# =============================================================
# phase2.sh — Mac Bootstrap Phase 2 (run directly in terminal)
# Needs TTY for gh auth login.
#
# Usage:
#   gh repo clone vincentsiauw/nix-config /tmp/nix-config
#   bash /tmp/nix-config/phase2.sh
# =============================================================

set -euo pipefail

GITHUB_USER="vincentsiauw"
NIX_CONFIG_REPO="${GITHUB_USER}/nix-config"
NIX_CONFIG_DIR="${HOME}/.config/nix-darwin"
GIT_EMAIL="vincent.vincent@bfi.co.id"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
log()  { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
info() { echo -e "${BLUE}ℹ${NC}  $1"; }
step() { echo -e "\n${BOLD}${BLUE}▶ $1${NC}"; }

# Source nix + brew into this shell
NIX_PROFILE='/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
[[ -e "${NIX_PROFILE}" ]] && source "${NIX_PROFILE}"
[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

echo ""
echo -e "${BOLD}=================================================${NC}"
echo -e "${BOLD}  Mac Bootstrap — Phase 2${NC}"
echo -e "${BOLD}=================================================${NC}"

# ── 1. GitHub CLI auth ────────────────────────────────────────
step "1. GitHub CLI auth"
if gh auth status &>/dev/null; then
  log "Already authenticated: $(gh api user --jq .login)"
else
  gh auth login --hostname github.com --git-protocol https --web
  log "GitHub CLI authenticated"
fi

# ── 2. Clone nix-config ───────────────────────────────────────
step "2. Clone nix-config"
if [[ -d "${NIX_CONFIG_DIR}/.git" ]]; then
  git -C "${NIX_CONFIG_DIR}" pull && log "nix-config up to date"
else
  mkdir -p "$(dirname "${NIX_CONFIG_DIR}")"
  gh repo clone "${NIX_CONFIG_REPO}" "${NIX_CONFIG_DIR}"
  log "Cloned to ${NIX_CONFIG_DIR}"
fi

# ── 3. darwin-rebuild switch ──────────────────────────────────
step "3. darwin-rebuild switch (installs everything)"
info "First run takes 15-30 min — downloading packages..."
if command -v darwin-rebuild &>/dev/null; then
  darwin-rebuild switch --flake "${NIX_CONFIG_DIR}"
else
  nix run nix-darwin -- switch --flake "${NIX_CONFIG_DIR}"
fi
log "darwin-rebuild switch completed"

# ── 4. VS Code extensions ─────────────────────────────────────
step "4. VS Code extensions"
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
  warn "VS Code not in PATH — open VS Code once, then re-run this script"
fi

# ── 5. SSH keys ───────────────────────────────────────────────
step "5. SSH keys"
mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
[[ ! -f "${HOME}/.ssh/id_ed25519" ]] \
  && ssh-keygen -t ed25519 -C "${GIT_EMAIL}" -f "${HOME}/.ssh/id_ed25519" -N "" \
  && log "Generated id_ed25519" \
  || log "id_ed25519 already exists"
[[ ! -f "${HOME}/.ssh/jk_ed25519" ]] \
  && ssh-keygen -t ed25519 -C "${GIT_EMAIL}-jk" -f "${HOME}/.ssh/jk_ed25519" -N "" \
  && log "Generated jk_ed25519" \
  || log "jk_ed25519 already exists"
eval "$(ssh-agent -s)" &>/dev/null || true
ssh-add "${HOME}/.ssh/id_ed25519" "${HOME}/.ssh/jk_ed25519" 2>/dev/null || true

# ── Summary ───────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}=================================================${NC}"
echo -e "${BOLD}${GREEN}  Setup Complete!${NC}"
echo -e "${BOLD}${GREEN}=================================================${NC}"
echo ""
echo -e "${BOLD}Remaining manual steps:${NC}"
echo ""
echo -e "  1. ${YELLOW}Add SSH public key to GitHub${NC} → https://github.com/settings/keys"
echo "     $(cat "${HOME}/.ssh/id_ed25519.pub" 2>/dev/null || echo '(not found)')"
echo ""
echo -e "  2. ${YELLOW}GitHub PAT${NC} (for go mod / HTTPS git clone):"
echo "     https://github.com/settings/tokens"
echo '     git config --global url."https://jamesvincentsiauw-mac:<PAT>@github.com".insteadOf https://github.com'
echo ""
echo -e "  3. ${YELLOW}Colima${NC}: colima start --cpu 4 --memory 8 --disk 60"
echo ""
echo -e "  4. ${YELLOW}Restart terminal${NC}: exec zsh"
echo ""
echo -e "  5. ${YELLOW}VS Code${NC}: sign in to GitHub Copilot (Account menu)"
echo ""
echo -e "${BOLD}Update config later:${NC} darwin-rebuild switch --flake ~/.config/nix-darwin"
