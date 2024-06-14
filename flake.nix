{
  description = "Base16-template builder for nix.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux" "aarch64-linux"
        "x86_64-darwin" "aarch64-darwin"
      ];
      perSystem = { config, system, ... }:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in rec {
          packages = {
            update-base16 = let
              binPath = with pkgs; lib.makeBinPath [ curl nix-prefetch-git gnused jq ];
            in pkgs.writeShellScriptBin "update-base16" ''
              PATH="$PATH:${binPath}"
              generate_sources () {
                out=$1
                curl "https://raw.githubusercontent.com/chriskempson/base16-$out-source/master/list.yaml"\
                | sed -nE "s~^([-_[:alnum:]]+): *(.*)~\1 \2~p"\
                | while read name src; do
                    echo "{\"key\":\"$name\",\"value\":"
                    nix-prefetch-git $src
                    echo "}"
                  done\
                | jq -s ".|del(.[].value.date)|from_entries"\
                > $out.json
              }
              generate_sources templates &
              generate_sources schemes &
              wait
            '';
            default = packages.update-base16;
          };
          devShells.default = pkgs.mkShell {
            packages = [ packages.update-base16 ];
          };
        };

        hmModule = ./base16.nix;
    };
}
