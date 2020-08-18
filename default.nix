{ makeEnv ? false, config ? { /*allowBroken = true;*/ }, ... }:
let
  # fetch pinned version of nixpkgs
  nixpkgs = import (
    builtins.fetchTarball {
      # fetch latest nixpkgs https://github.com/NixOS/nixpkgs-channels/tree/nixos-20.03 as of Tue 18 Aug 2020 02:51:27 PM UTC
      url = "https://github.com/NixOS/nixpkgs-channels/archive/cb1996818edf506c0d1665ab147c253c558a7426.tar.gz";
      sha256 = "0lb6idvg2aj61nblr41x0ixwbphih2iz8xxc05m69hgsn261hk3j";
    }
  ) { inherit config; };
  # override haskell compiler version, add and override dependencies in nixpkgs
  haskellPackages = nixpkgs.haskell.packages."ghc8101".override (
    old: {
      all-cabal-hashes = nixpkgs.fetchurl {
        # fetch latest cabal hashes https://github.com/commercialhaskell/all-cabal-hashes/tree/hackage as of Tue 18 Aug 2020 02:51:27 PM UTC
        url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/112fef7b4bf392d4d4c36fbbe00ed061685ba26c.tar.gz";
        sha256 = "0x0mkpwnndw7n62l089gimd76n9gy749giban9pacf5kxbsfxrdc";
      };
      overrides = self: super: with nixpkgs.haskell.lib; rec {
        mkDerivation = args: super.mkDerivation (args // { jailbreak = true; });
        # latest version of memory as of Tue 18 Aug 2020 02:51:27 PM UTC
        memory = self.callHackage "memory" "0.15.0" {};
      };
    }
  );
  # function to bring devtools in to a package environment
  devtools = old: { nativeBuildInputs = old.nativeBuildInputs ++ [ nixpkgs.cabal-install nixpkgs.ghcid ]; }; # ghc and hpack are automatically included
  # ignore files specified by gitignore in nix-build
  source = nixpkgs.nix-gitignore.gitignoreSource [] ./.;
  # use overridden-haskellPackages to call gitignored-source
  drv = haskellPackages.callCabal2nix "git" source {};
in
if makeEnv then drv.env.overrideAttrs devtools else drv
