{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { }
, newpkgs ? import sources.nixpkgs-master { }
}:

with pkgs;
pkgs.mkShell {
  buildInputs = [
    elixir
    newpkgs.gleam
    (import ./nix/mix_gleam.nix {})
    inotify-tools
    bashInteractive
  ];
}
