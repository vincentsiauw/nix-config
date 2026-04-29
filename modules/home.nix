{ pkgs, lib, config, ... }:

let
  # Absolute path to this flake — home-manager sets this automatically
  # when useGlobalPkgs + useUserPackages are enabled.
  flakeRoot = ../.; # nix-config repo root, as a Nix path
in {
  home.stateVersion  = "24.11";
  home.username      = "vincent";
  home.homeDirectory = "/Users/vincent";

  home.packages = with pkgs; [
    gopls delve go-tools  # Go LSP + debugger + static analysis
    curl htop
  ];

  # ─── Git ───────────────────────────────────────────────────────
  programs.git = {
    enable    = true;
    userName  = "jamesvincentsiauw-mac";
    userEmail = "vincent.vincent@bfi.co.id";
    lfs.enable = true;
    extraConfig = {
      push.autoSetupRemote = true;
      core = { filemode = false; autocrlf = false; };
      pack.windowsMemory  = "256m";
      # GitHub PAT rewrite — add AFTER setup:
      #   git config --global url."https://jamesvincentsiauw-mac:<PAT>@github.com".insteadOf https://github.com
    };
  };

  # ─── Zsh ───────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    autosuggestion.enable     = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable  = true;
      plugins = [ "git" ];
    };
    initExtraFirst = ''
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
    '';
    initExtra = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

      export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
      export GOPATH="$HOME/go"
      export PATH="$GOPATH/bin:$PATH"

      [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

      eval "$(direnv hook zsh)"
    '';
  };

  # ─── Direnv ────────────────────────────────────────────────────
  programs.direnv = {
    enable            = true;
    nix-direnv.enable = true;
  };

  # ─── SSH ───────────────────────────────────────────────────────
  # Key files are NOT stored in git — generate fresh with ssh-keygen
  # after setup, then register public keys on GitHub and target servers.
  programs.ssh = {
    enable      = true;
    extraConfig = "Include ~/.colima/ssh_config";
    matchBlocks = {
      "bastion-instance"          = { hostname = "52.25.33.216";   user = "ubuntu"; identityFile = "~/.ssh/bfi.pem"; };
      "staging-private-instance"  = { hostname = "10.10.5.98";     user = "ubuntu"; proxyCommand = "ssh -q -W %h:%p bastion-instance"; identityFile = "~/.ssh/bfi.pem"; };
      "staging-public-instance"   = { hostname = "10.10.120.96";   user = "ubuntu"; proxyCommand = "ssh -q -W %h:%p bastion-instance"; identityFile = "~/.ssh/bfi.pem"; };
      "prod-private-instance"     = { hostname = "10.10.205.54";   user = "ubuntu"; proxyCommand = "ssh -q -W %h:%p bastion-instance"; identityFile = "~/.ssh/bfi-prod.pem"; };
      "prod-public-instance"      = { hostname = "10.10.64.118";   user = "ubuntu"; proxyCommand = "ssh -q -W %h:%p bastion-instance"; identityFile = "~/.ssh/bfi-prod.pem"; };
      "apollo-instance"           = { hostname = "10.11.21.17";    user = "ubuntu"; proxyCommand = "ssh -q -W %h:%p bastion-instance"; identityFile = "~/.ssh/bfi.pem"; };
      "github.com-personal"       = { hostname = "github.com";     user = "git";    identityFile = "~/.ssh/id_ed25519";   identitiesOnly = true; };
      "github.com-jk"             = { hostname = "github.com";     user = "git";    identityFile = "~/.ssh/jk_ed25519";   identitiesOnly = true; };
    };
  };

  # ─── Dotfiles deployed by home-manager ─────────────────────────
  # p10k prompt config (no secrets)
  home.file.".p10k.zsh" = lib.mkIf (builtins.pathExists (flakeRoot + "/dotfiles/.p10k.zsh")) {
    source = flakeRoot + "/dotfiles/.p10k.zsh";
  };

  # VS Code user settings
  home.file."Library/Application Support/Code/User/settings.json" =
    lib.mkIf (builtins.pathExists (flakeRoot + "/dotfiles/vscode-settings.json")) {
      source = flakeRoot + "/dotfiles/vscode-settings.json";
    };

  home.file."Library/Application Support/Code/User/mcp.json" =
    lib.mkIf (builtins.pathExists (flakeRoot + "/dotfiles/vscode-mcp.json")) {
      source = flakeRoot + "/dotfiles/vscode-mcp.json";
    };

  # VS Code user prompts (custom agents)
  home.file."Library/Application Support/Code/User/prompts" =
    lib.mkIf (builtins.pathExists (flakeRoot + "/vscode-prompts")) {
      source    = flakeRoot + "/vscode-prompts";
      recursive = true;
    };

  # GitHub Copilot custom skills
  home.file.".agents" =
    lib.mkIf (builtins.pathExists (flakeRoot + "/agents")) {
      source    = flakeRoot + "/agents";
      recursive = true;
    };

  # ─── Environment ───────────────────────────────────────────────
  home.sessionVariables = {
    GOPATH = "$HOME/go";
    EDITOR = "code --wait";
  };
}
