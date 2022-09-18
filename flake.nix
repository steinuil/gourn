{
  description = "Build dune projects with ez";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixt.url = "github:nix-community/nixt";

  outputs = { self, nixpkgs, flake-utils, nixt }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = (import nixpkgs) { inherit system; };
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            opam
            pkg-config
            openssl
            rnix-lsp
            nixt.packages.${system}.nixt
          ];

          shellHook = "eval $(opam env)";
        };
      });
}
