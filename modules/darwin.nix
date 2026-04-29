{ pkgs, ... }:

{
  # ─── Nix ───────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users         = [ "root" "vincent" ];
  };
  nixpkgs.config.allowUnfree = true;

  # ─── System CLI packages ───────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Go
    go
    golangci-lint

    # Node
    nodejs yarn deno

    # Python
    python312 uv ruff

    # Java
    jdk jdk17 jdk11 gradle

    # Protobuf / gRPC
    protobuf protoc-gen-go buf grpcurl grpcui

    # Database tooling
    dbmate postgresql_14  # psql client; server runs in Docker

    # Cloud
    awscli2

    # Containers
    colima docker-client docker-compose

    # Git
    git git-lfs gh

    # Shell utils
    direnv tree wget socat pandoc jq yq-go
  ];

  # ─── Homebrew (GUI casks + formulae not in nixpkgs) ─────────────
  homebrew = {
    enable = true;
    onActivation = {
      cleanup    = "uninstall";
      autoUpdate = true;
      upgrade    = true;
    };
    brews = [
      "awslogs"
      "spring-boot"
      "zplug"
      "zsh-autosuggestions"
      "zsh-syntax-highlighting"
      "atlas"
      "protolint"
      "temporal"
      "zx"
    ];
    casks = [
      "iterm2"
      "warp"
      "visual-studio-code"
      "google-chrome"
      "microsoft-edge"
      "discord"
      "whatsapp"
      "postman"
      "dbeaver-community"
      "goland"
      "intellij-idea-ce"
      "pycharm"
      "openvpn-connect"
      "remote-desktop-manager-free"
      "chromedriver"
      "claude-code"
    ];
  };

  # ─── macOS defaults ────────────────────────────────────────────
  system.defaults = {
    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat         = 15;
      KeyRepeat                = 2;
    };
    dock.autohide = true;
    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle   = "clmv";
    };
  };

  system.stateVersion = 5;
  programs.zsh.enable = true;

  users.users.vincent = {
    name  = "vincent";
    home  = "/Users/vincent";
    shell = pkgs.zsh;
  };
}
