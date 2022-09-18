{ pkgs ? import <nixpkgs> { }, nixt }:

with import ./lexer.nix { lib = pkgs.lib; };

let
  run = str:
    let unfold = acc: tok:
      if tok.curr.t == "EOF" then
        acc
      else
        unfold (acc ++ [ tok.curr ]) tok.next;
    in
    unfold [ ] (tokenStream { buf = str; pos = 0; });

  test = str: expected: run str == expected;
in

nixt.mkSuite "lexer" {
  "empty" = test "" [ ];
  "operations" = test "=:= >= := =+" [
    { t = "ENVOP"; v = "=:="; }
    { t = "RELOP"; v = ">="; }
    { t = "ENVOP"; v = ":="; }
    { t = "ENVOP"; v = "=+"; }
  ];
  "whole file" =
    let
      file = ''
        opam-version: "2.0"
        synopsis: "opam-monorepo generated lockfile"
        maintainer: "opam-monorepo"
        depends: [
          "base-bigarray" {= "base"}
          "base-threads" {= "base"}
          "base-unix" {= "base"}
          "dune" {= "3.4.1"}
          "ocaml" {= "4.14.0"}
          "ocaml-base-compiler" {= "4.14.0"}
          "ocaml-config" {= "2"}
          "ocaml-options-vanilla" {= "1"}
          "opam-file-format" {= "2.1.4" & ?vendor}
        ]
        pin-depends: [
          "opam-file-format.2.1.4"
          "https://github.com/ocaml/opam-file-format/archive/refs/tags/2.1.4.tar.gz"
        ]
        x-opam-monorepo-duniverse-dirs: [
          [
            "https://github.com/ocaml/opam-file-format/archive/refs/tags/2.1.4.tar.gz"
            "opam-file-format"
            [
              "md5=cd9dac41c2153d07067c5f30cdcf77db"
              "sha512=fb5e584080d65c5b5d04c7d2ac397b69a3fd077af3f51eb22967131be22583fea507390eb0d7e6f5c92035372a9e753adbfbc8bfd056d8fd4697c6f95dd8e0ad"
            ]
          ]
        ]
        x-opam-monorepo-root-packages: ["gourn"]
        x-opam-monorepo-version: "0.3"
      '';

      tokens = [
        { t = "IDENT"; v = "opam-version"; }
        { t = "COLON"; }
        { t = "STRING"; v = "2.0"; }
        { t = "IDENT"; v = "synopsis"; }
        { t = "COLON"; }
        { t = "STRING"; v = "opam-monorepo generated lockfile"; }
        { t = "IDENT"; v = "maintainer"; }
        { t = "COLON"; }
        { t = "STRING"; v = "opam-monorepo"; }
        { t = "IDENT"; v = "depends"; }
        { t = "COLON"; }
        { t = "LBRACKET"; }
        { t = "STRING"; v = "base-bigarray"; }
        { t = "LBRACE"; }
        { t = "RELOP"; v = "="; }
        { t = "STRING"; v = "base"; }
        { t = "RBRACE"; }
        { t = "STRING"; v = "base-threads"; }
        { t = "LBRACE"; }
        { t = "RELOP"; v = "="; }
        { t = "STRING"; v = "base"; }
        { t = "RBRACE"; }
        { t = "STRING"; v = "base-unix"; }
        { t = "LBRACE"; }
        { t = "RELOP"; v = "="; }
        { t = "STRING"; v = "base"; }
        { t = "RBRACE"; }
        { t = "STRING"; v = "dune"; }
        { t = "LBRACE"; }
        { t = "RELOP"; v = "="; }
        { t = "STRING"; v = "3.4.1"; }
        { t = "RBRACE"; }
        { t = "STRING"; v = "ocaml"; }
        { t = "LBRACE"; }
        { t = "RELOP"; v = "="; }
        { t = "STRING"; v = "4.14.0"; }
        { t = "RBRACE"; }
        { t = "STRING"; v = "ocaml-base-compiler"; }
        { t = "LBRACE"; }
        { t = "RELOP"; v = "="; }
        { t = "STRING"; v = "4.14.0"; }
        { t = "RBRACE"; }
        { t = "STRING"; v = "ocaml-config"; }
        { t = "LBRACE"; }
        { t = "RELOP"; v = "="; }
        { t = "STRING"; v = "2"; }
        { t = "RBRACE"; }
        { t = "STRING"; v = "ocaml-options-vanilla"; }
        { t = "LBRACE"; }
        { t = "RELOP"; v = "="; }
        { t = "STRING"; v = "1"; }
        { t = "RBRACE"; }
        { t = "STRING"; v = "opam-file-format"; }
        { t = "LBRACE"; }
        { t = "RELOP"; v = "="; }
        { t = "STRING"; v = "2.1.4"; }
        { t = "AND"; }
        { t = "PFXOP"; v = "?"; }
        { t = "IDENT"; v = "vendor"; }
        { t = "RBRACE"; }
        { t = "RBRACKET"; }
        { t = "IDENT"; v = "pin-depends"; }
        { t = "COLON"; }
        { t = "LBRACKET"; }
        { t = "STRING"; v = "opam-file-format.2.1.4"; }
        { t = "STRING"; v = "https://github.com/ocaml/opam-file-format/archive/refs/tags/2.1.4.tar.gz"; }
        { t = "RBRACKET"; }
        { t = "IDENT"; v = "x-opam-monorepo-duniverse-dirs"; }
        { t = "COLON"; }
        { t = "LBRACKET"; }
        { t = "LBRACKET"; }
        { t = "STRING"; v = "https://github.com/ocaml/opam-file-format/archive/refs/tags/2.1.4.tar.gz"; }
        { t = "STRING"; v = "opam-file-format"; }
        { t = "LBRACKET"; }
        { t = "STRING"; v = "md5=cd9dac41c2153d07067c5f30cdcf77db"; }
        { t = "STRING"; v = "sha512=fb5e584080d65c5b5d04c7d2ac397b69a3fd077af3f51eb22967131be22583fea507390eb0d7e6f5c92035372a9e753adbfbc8bfd056d8fd4697c6f95dd8e0ad"; }
        { t = "RBRACKET"; }
        { t = "RBRACKET"; }
        { t = "RBRACKET"; }
        { t = "IDENT"; v = "x-opam-monorepo-root-packages"; }
        { t = "COLON"; }
        { t = "LBRACKET"; }
        { t = "STRING"; v = "gourn"; }
        { t = "RBRACKET"; }
        { t = "IDENT"; v = "x-opam-monorepo-version"; }
        { t = "COLON"; }
        { t = "STRING"; v = "0.3"; }
      ];
    in
    test file tokens;
}


