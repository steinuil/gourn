{ pkgs ? import <nixpkgs> { }, nixt }:

let
  run = p: str:
    let result = p { buf = str; pos = 0; }; in
    if !result.isOk then null else
    result.v;

  matches = p: str: run p str == str;

  fails = p: str: run p str == null;
in

with import ./comment.nix { lib = pkgs.lib; };

nixt.mkSuite "comment" {
  "empty" = matches pComment "(**)";
  "some stuff" = matches pComment "(* test*test *)";
  "nested" = matches pComment "(* abc (* def *) *)";
  "single line" = matches pLineComment "####test\n";
}
