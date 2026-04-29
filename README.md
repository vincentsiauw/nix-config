# nix-config

Vincent's macOS environment — managed with [nix-darwin](https://github.com/LnL7/nix-darwin) + [home-manager](https://github.com/nix-community/home-manager).

## Setup on a new Mac

### Phase 1 — from any terminal (no pre-install needed)

```bash
curl -fsSL https://raw.githubusercontent.com/vincentsiauw/nix-config/main/bootstrap.sh | bash
```

Installs: Xcode CLI tools · Nix · Homebrew · GitHub CLI (`gh`)

### Phase 2 — run directly in terminal

```bash
bash ~/.config/nix-darwin-bootstrap/phase2.sh
```

Does: `gh auth login` → clone this repo → `darwin-rebuild switch` → VS Code extensions → generate SSH keys

---

## What gets installed

| Category | Tools |
|---|---|
| Go | `go`, `golangci-lint`, `gopls`, `delve` |
| Node | `node`, `yarn`, `deno` |
| Python | `python312`, `uv`, `ruff` |
| Java | `jdk`, `jdk17`, `jdk11`, `gradle` |
| Protobuf / gRPC | `protobuf`, `protoc-gen-go`, `buf`, `grpcurl`, `grpcui` |
| Database | `dbmate`, `postgresql_14` (client), `redis` (client) |
| Cloud | `awscli2` |
| Containers | `colima`, `docker`, `docker-compose` |
| Git | `git`, `git-lfs`, `gh` |
| Shell | `direnv`, `zsh` + Oh My Zsh + Powerlevel10k |
| GUI apps | VS Code, iTerm2, Warp, Postman, DBeaver, GoLand, Chrome, etc. |

## After setup — manual steps

1. **Add SSH public key to GitHub** → https://github.com/settings/keys
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

2. **GitHub PAT** (for `go mod` / HTTPS git clone):
   Create at https://github.com/settings/tokens, then:
   ```bash
   git config --global url."https://jamesvincentsiauw-mac:<PAT>@github.com".insteadOf https://github.com
   ```

3. **Start Docker**:
   ```bash
   colima start --cpu 4 --memory 8 --disk 60
   ```

4. **Restart terminal**: `exec zsh`

5. **VS Code**: Sign in to GitHub Copilot (Account menu)

---

## Update config

Edit `modules/darwin.nix` (system packages / casks) or `modules/home.nix` (dotfiles / git / zsh), then:

```bash
darwin-rebuild switch --flake ~/.config/nix-darwin
```

## Sync dotfiles from current Mac

```bash
cd ~/mac-setup/nix-config
bash sync-dotfiles.sh
git add -A && git commit -m "sync dotfiles" && git push
```

> **Never commit**: SSH private keys, `.pem` files, GitHub PATs. See `.gitignore`.
