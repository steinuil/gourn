{ lib }:
let
  inherit (import ./ident.nix { inherit lib; }) pIdent;
in
{
  # fromOpamFile = filename: { };
  inherit pIdent;
}
