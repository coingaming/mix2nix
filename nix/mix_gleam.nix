{ sources ? import ./sources.nix
, pkgs ? import sources.nixpkgs { }
}:

with pkgs;
beamPackages.buildMix rec {
  name = "mix_gleam";
  version = "0.6.1";

  src = fetchHex {
    pkg = "${name}";
    version = "${version}";
    sha256 = "sha256-PbQtdi+pu/8ctp9Xuj8gYxMHQra1p6sGdZzEXyyPdKs=";
  };

  beamDeps = [];
}
