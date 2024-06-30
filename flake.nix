{
  description = "Hydra Doom";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    hydra.url = "github:input-output-hk/hydra/0.17.0";
    cardano-node.url = "github:intersectmbo/cardano-node/8.9.4";
    flake-parts.url = "github:hercules-ci/flake-parts";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";

  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [
      inputs.process-compose-flake.flakeModule
    ];
    flake = {
      # Put your original flake attributes here.
    };
    systems = [
      # systems for which you want to build the `perSystem` attributes
      "x86_64-linux"
      # ...
    ];
    perSystem = { config, system, pkgs, lib, ... }: let
      hydraDataDir = "state-hydra";
    in {
      packages = {
        inherit (inputs.hydra.packages.${system}) hydra-cluster hydra-tui;
        inherit (inputs.cardano-node.packages.${system}) cardano-node cardano-cli bech32;
        hydra-cluster-wrapper = pkgs.writeShellApplication {
          name = "hydra-cluster-wrapper";
          runtimeInputs = [config.packages.cardano-node config.packages.cardano-cli];
          text = ''
            rm -rf "${hydraDataDir}"
            ${lib.getExe config.packages.hydra-cluster} --devnet --publish-hydra-scripts --state-directory ${hydraDataDir}
          '';
        };
        hydra-doom-wrapper = pkgs.writeShellApplication {
          name = "hydra-doom-wrapper";
          runtimeInputs = [config.packages.bech32 pkgs.jq pkgs.git pkgs.nodejs];
          text = ''
            WALLET_SK="$(jq -r .cborHex state-hydra/wallet.sk| cut -c 5- | bech32 ed25519_sk)"
            git checkout HEAD src/hydra.ts
            sed -i "s/ed25519_sk1t7dezxnrv3u7mqa6vqwvljaq4wd9tqnfmsvlm653p5n7tndmtlyqk9sww8/$WALLET_SK/" src/hydra.ts
            npm start
          '';
        };
        hydra-tui-wrapper = pkgs.writeShellApplication {
          name = "hydra-tui-wrapper";
          runtimeInputs = [config.packages.hydra-tui];
          text = ''
            hydra-tui -k state-hydra/wallet.sk
          '';
        };
      };
      devShells.default = pkgs.mkShell
        {
          buildInputs = [
            config.packages.hydra-cluster
            config.packages.hydra-tui
            config.packages.cardano-node
            config.packages.cardano-cli
            config.packages.bech32
            config.packages.hydra-cluster-wrapper
            config.packages.hydra-doom-wrapper
            pkgs.nodejs
            pkgs.jq
          ];
        };
      process-compose."default" =
          {
            # httpServer.enable = true;
            settings = {
              #environment = {
              #};

              processes = {
                hydra-cluster = {
                  command = config.packages.hydra-cluster-wrapper;
                };
                hydra-doom = {
                  command = config.packages.hydra-doom-wrapper;
                };
                hydra-tui = {
                  command = config.packages.hydra-tui-wrapper;
                };

                # If a process is named 'test', it will be ignored. But a new
                # flake check will be created that runs it so as to test the
                # other processes.
                #test = {
                #  command = pkgs.writeShellApplication {
                #    name = "hydra-doom-tests";
                #    runtimeInputs = [ pkgs.curl ];
                #    text = ''
                #      curl -v http://localhost:${builtins.toString port}/
                #    '';
                #  };
                #  depends_on."sqlite-web".condition = "process_healthy";
                #};
              };
            };
          };

    };
  };
}
