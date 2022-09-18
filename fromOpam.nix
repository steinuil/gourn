{ lib }:
with (import ./parser.nix { inherit lib; });
with (import ./ident.nix { inherit lib; });
with (import ./string.nix { inherit lib; });
with (import ./comment.nix { inherit lib; });
with (import ./value.nix { inherit lib; });
let
  inherit (builtins) substring;
in
{
  # fromOpamFile = filename: { };
}
