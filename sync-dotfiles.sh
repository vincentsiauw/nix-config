#!/usr/bin/env bash
# =============================================================
# sync-dotfiles.sh — Copy dotfiles from this Mac into nix-config
# Run on the OLD laptop to populate the repo before pushing.
#
# Usage:
#   cd ~/mac-setup/nix-config
#   bash sync-dotfiles.sh
#   git add -A && git commit -m "sync dotfiles" && git push
# =============================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME}"
VSCODE_USER="${HOME_DIR}/Library/Application Support/Code/User"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
log()  { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
step() { echo -e "\n${BOLD}${BLUE}▶ $1${NC}"; }

echo ""
echo -e "${BOLD}Syncing dotfiles → nix-config repo${NC}"
echo ""

mkdir -p "${REPO_DIR}/dotfiles"
mkdir -p "${REPO_DIR}/vscode-prompts"
mkdir -p "${REPO_DIR}/agents"

# ─── Shell dotfiles ───────────────────────────────────────────
step "Shell dotfiles"
[[ -f "${HOME_DIR}/.p10k.zsh" ]] \
  && cp "${HOME_DIR}/.p10k.zsh" "${REPO_DIR}/dotfiles/.p10k.zsh" \
  && log ".p10k.zsh"

# ─── VS Code settings ─────────────────────────────────────────
step "VS Code settings"
[[ -f "${VSCODE_USER}/settings.json" ]] \
  && cp "${VSCODE_USER}/settings.json" "${REPO_DIR}/dotfiles/vscode-settings.json" \
  && log "settings.json"

[[ -f "${VSCODE_USER}/mcp.json" ]] \
  && cp "${VSCODE_USER}/mcp.json" "${REPO_DIR}/dotfiles/vscode-mcp.json" \
  && log "mcp.json"

[[ -f "${VSCODE_USER}/keybindings.json" ]] \
  && cp "${VSCODE_USER}/keybindings.json" "${REPO_DIR}/dotfiles/vscode-keybindings.json" \
  && log "keybindings.json"

# ─── VS Code user prompts (agents) ────────────────────────────
step "VS Code user prompts"
if [[ -d "${VSCODE_USER}/prompts" ]]; then
  cp -r "${VSCODE_USER}/prompts/"* "${REPO_DIR}/vscode-prompts/" 2>/dev/null || true
  COUNT=$(ls "${REPO_DIR}/vscode-prompts/" | wc -l | tr -d ' ')
  log "vscode-prompts: ${COUNT} files"
fi

# ─── Copilot skills ───────────────────────────────────────────
step "Copilot skills (~/.agents)"
if [[ -d "${HOME_DIR}/.agents" ]]; then
  cp -r "${HOME_DIR}/.agents/"* "${REPO_DIR}/agents/"
  COUNT=$(find "${REPO_DIR}/agents" -name "*.md" | wc -l | tr -d ' ')
  log "agents: ${COUNT} SKILL.md files"
fi

# ─── .gitignore safety check ──────────────────────────────────
step "Checking for secrets in staged files"
SECRETS_PATTERN="-----BEGIN|PRIVATE KEY|PAT|ghp_|github_pat_|password|token"
if git -C "${REPO_DIR}" diff --cached --name-only 2>/dev/null | \
     xargs -I{} grep -lEi "${SECRETS_PATTERN}" "${REPO_DIR}/{}" 2>/dev/null | grep -q .; then
  warn "Possible secret detected in staged files — review before pushing!"
else
  log "No obvious secrets detected"
fi

echo ""
echo -e "${BOLD}Done. Next:${NC}"
echo "  cd ${REPO_DIR}"
echo "  git add -A"
echo "  git diff --cached   # review what's being committed"
echo "  git commit -m 'sync dotfiles'"
echo "  git push"
echo ""
echo -e "${YELLOW}Never commit:${NC} SSH private keys, .pem files, GitHub PATs"
echo ""
