{
  description = "Vincent's macOS environment — nix-darwin + home-manager";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin      = { url = "github:LnL7/nix-darwin"; inputs.nixpkgs.follows = "nixpkgs"; };
    home-manager    = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager }:
  let
    # Change to "x86_64-darwin" for Intel Mac
    system = "aarch64-darwin";
    pkgs   = nixpkgs.legacyPackages.${system};
  in {
    darwinConfigurations."vincent-mac" = nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [
        ./modules/darwin.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs    = true;
          home-manager.useUserPackages  = true;
          home-manager.users.vincent    = import ./modules/home.nix;
        }
      ];
    };
  };
}
