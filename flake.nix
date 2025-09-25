{
  description = "An unoffical development flake for bun";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";

    zig.url = "github:mitchellh/zig-overlay";
    zig.inputs.nixpkgs.follows = "nixpkgs";

    # Used for as a nix formatting check when commiting.
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

    # Used for Shell.nix and default.nix compat
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs =
    inputs@{ nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem =
        {
          config,
          self',
          pkgs,
          system,
          ...
        }:
        {
          formatter = pkgs.nixfmt-rfc-style;
          _module.args.pkgs = import nixpkgs {
            inherit system;
            overlays = [
              (final: prev: {
                zig = inputs.zig.packages.${prev.system};
              })
            ];
          };

          checks = {
            pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                nixfmt-rfc-style.enable = true;
              };
            };
          };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs =
              with pkgs;
              [
                automake
                zig.master
                ccache
                cmake
                coreutils-full
                gnused
                go
                libiconv
                libtool
                ninja
                pkg-config
                ruby
                rustc
                cargo
                bun
                llvmPackages_18.lldb
                llvmPackages_18.libstdcxxClang
                llvmPackages_18.libllvm
                llvmPackages_18.libcxx
                lld
                clang-tools
                clang
                autoconf
                icu
              ]
              ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
                pkgs.apple-sdk_15
              ];

            shellHook = ''
              						echo "thanks for using my shell, please consider to staring it so bun finally listens! \n If you want to build bun please note the traditional way will not work since patches are required. \n If you want to build run `nix build github:eveeiyeve/bun-flake` to build bun for your changes"
              					'';
          };
        };
    };
}
