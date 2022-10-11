{
  description = "Base16-template builder for nix.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-22.05";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
  };

  outputs = { self, nixpkgs, flake-utils-plus }@inputs:
    flake-utils-plus.lib.mkFlake rec {
      inherit self inputs;
      supportedSystems = [
        "x86_64-linux" "aarch64-linux"
        "x86_64-darwin" "aarch64-darwin"
      ];

      channels.stable.input = nixpkgs;

      outputsBuilder = channels: let
        pkgs = channels.stable;
      in rec {
        packages.update-base16 = let
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

        defaultPackage = packages.update-base16;

        devShell = pkgs.mkShell {
          inputs = [ packages.update-base16 ];
        };
      };

      # Home-Manager Module
      hmModule = ./base16.nix;
    };
}
