{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { }
, newpkgs ? import sources.nixpkgs-master { }
}:

with pkgs;

beamPackages.mixRelease {
  pname = "mix2nix";
  version = "0.1.6";
  src = ./.;
  buildInputs = [
    newpkgs.gleam
    (import ./nix/mix_gleam.nix {})
  ];
  nativeBuildInputs = [
    makeWrapper
  ];
  postInstall = ''
    mkdir -p $out/bin
    wrapProgram $out/bin/mix2nix \
      --set RELEASE_COOKIE REPLACEME \
      --run 'export MIX2NIX_ARGV="$@"' \
      --add-flags "eval ':mix2nix.main([])'"
  '';
}
