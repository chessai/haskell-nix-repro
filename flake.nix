{
  description = "haskell.nix flake devShell weirdness repro";

  inputs = {
    nixpkgs = {
      follows = "haskell-nix/nixpkgs-unstable";
    };

    haskell-nix = {
      url = "github:input-output-hk/haskell.nix";
      inputs.nixpkgs.follows = "haskell-nix/nixpkgs-2111";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs =
    { self
    , nixpkgs
    , haskell-nix
    , flake-utils
    , ...
    }:
    let
      supportedSystems =
        [ "x86_64-linux" ];

      overlays = [ haskell-nix.overlay ]
        ;

      nixpkgsFor = system: import nixpkgs {
        inherit system;
        inherit (haskell-nix) config;
        inherit overlays;
      };

      projectFor = system:
        let
          # pkgsCross.musl64 does most of the heavy lifting
          # when it comes to static linking
          pkgs = (nixpkgsFor system).pkgsCross.musl64;
          gitignore = pkgs.nix-gitignore.gitignoreSourcePure ''
            result
            result-*
            dist-newstyle
            .github
          '';
        in
        pkgs.haskell-nix.cabalProject' {
          src = gitignore ./.;
          compiler-nix-name = "ghc8107";
          cabalProjectFileName = "cabal.project";
          index-state = "2022-01-05T00:00:00Z";
          modules = [{
            packages = { };
          }];
          shell = {
            withHoogle = true;

            exactDeps = true;

            nativeBuildInputs = [
              pkgs.cabal-install
              pkgs.ghcid
            ];

            additional = ps: [
              ps.Win32-network
            ];
          };
          sha256map = {
             "https://github.com/input-output-hk/Win32-network.git"."3825d3abf75f83f406c1f7161883c438dac7277d" =
               "19wahfv726fa3mqajpqdqhnl9ica3xmf68i254q45iyjcpj1psqx";
           };
        };
    in
    flake-utils.lib.eachSystem supportedSystems (system: rec {
      pkgs = nixpkgsFor system;
      project = projectFor system;
      flake = project.flake { };
      devShell = flake.devShell;
    });
}
