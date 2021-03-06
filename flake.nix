{
  description = "plutarch-template";

  inputs.nixpkgs.follows = "plutarch/nixpkgs";
  inputs.haskell-nix.follows = "plutarch/haskell-nix";
  # temporary fix for nix versions that have the transitive follows bug
  # see https://github.com/NixOS/nix/issues/6013
  inputs.nixpkgs-2111 = { url = "github:NixOS/nixpkgs/nixpkgs-21.11-darwin"; };

  # Rev is this PR https://github.com/peter-mlabs/plutarch/pull/5.
  inputs.plutarch.url =
    "github:peter-mlabs/plutarch?rev=a7a410da209b9c14c834a41e07b1c197c2a4dcd6";
  inputs.plutarch.inputs.nixpkgs.follows =
    "plutarch/haskell-nix/nixpkgs-unstable";

  outputs = inputs@{ self, nixpkgs, haskell-nix, plutarch, ... }:
    let
      supportedSystems = with nixpkgs.lib.systems.supported;
        tier1 ++ tier2 ++ tier3;

      perSystem = nixpkgs.lib.genAttrs supportedSystems;

      nixpkgsFor = system:
        import nixpkgs {
          inherit system;
          overlays = [ haskell-nix.overlay ];
          inherit (haskell-nix) config;
        };
      nixpkgsFor' = system:
        import nixpkgs {
          inherit system;
          inherit (haskell-nix) config;
        };

      ghcVersion = "ghc921";

      projectFor = system:
        let pkgs = nixpkgsFor system;
        in let pkgs' = nixpkgsFor' system;
        in (nixpkgsFor system).haskell-nix.cabalProject' {
          src = ./.;
          compiler-nix-name = ghcVersion;
          inherit (plutarch) cabalProjectLocal;
          extraSources = plutarch.extraSources ++ [
            {
              src = inputs.plutarch;
              subdirs = [
                "."
                "plutarch-test"
                "plutarch-extra"
                "plutarch-numeric"
                "plutarch-safemoney"
              ];
            }
          ];
          modules = [ (plutarch.haskellModule system) ];
          shell = {
            withHoogle = true;

            exactDeps = true;

            # We use the ones from Nixpkgs, since they are cached reliably.
            # Eventually we will probably want to build these with haskell.nix.
            nativeBuildInputs = with pkgs'; [
              entr
              haskellPackages.apply-refact
              git
              fd
              cabal-install
              haskell.packages."${ghcVersion}".hlint
              haskellPackages.cabal-fmt
              nixpkgs-fmt
              graphviz
            ];

            inherit (plutarch) tools;

            additional = ps: [
              ps.plutarch
              ps.tasty-quickcheck
              ps.plutarch-extra
              ps.plutarch-numeric
              ps.plutarch-safemoney
              ps.plutarch-test
            ];
          };
        };
    in {
      project = perSystem projectFor;
      flake = perSystem (system: (projectFor system).flake { });
      packages = perSystem (system: self.flake.${system}.packages);
      devShell = perSystem (system: self.flake.${system}.devShell);
    };
}