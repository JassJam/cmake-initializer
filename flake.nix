{
  description = "cmake-initializer: dev shells that configure per CMake preset";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        llvm = pkgs.llvmPackages_23;
        arch = if pkgs.stdenv.hostPlatform.isAarch64 then "arm64" else "x86_64";

        toolchains = {
          gcc = {
            stdenv = pkgs.gcc14Stdenv;
            extra = [ ];
          };
          clang = {
            stdenv = llvm.libcxxStdenv;
            extra = [ llvm.lldb ];
          };
          emscripten = {
            stdenv = pkgs.stdenv;
            extra = [
              pkgs.emscripten
              pkgs.nodejs
            ];
          };
        };

        allPresets = {
          "unixlike-x86_64-gcc-debug" = "gcc";
          "unixlike-x86_64-gcc-release" = "gcc";
          "unixlike-x86_64-clang-debug" = "clang";
          "unixlike-x86_64-clang-release" = "clang";
          "unixlike-arm64-clang-debug" = "clang";
          "unixlike-arm64-clang-release" = "clang";
          "emscripten-debug" = "emscripten";
          "emscripten-release" = "emscripten";
        };

        allAliases = {
          gcc-debug = "unixlike-x86_64-gcc-debug";
          gcc-release = "unixlike-x86_64-gcc-release";
          clang-debug = "unixlike-${arch}-clang-debug";
          clang-release = "unixlike-${arch}-clang-release";
          wasm-debug = "emscripten-debug";
          wasm-release = "emscripten-release";
        };

        presets = lib.filterAttrs (n: _: !(lib.hasInfix "gcc" n) || arch == "x86_64") allPresets;
        aliases = lib.filterAttrs (_: v: presets ? ${v}) allAliases;

        mkPresetShell =
          name: toolchain:
          let
            tc = toolchains.${toolchain};
            isEmscripten = toolchain == "emscripten";
            extraCmakeArgs = lib.optionalString isEmscripten "-DENABLE_EMSDK_AUTO_INSTALL=OFF";
          in
          (pkgs.mkShell.override { stdenv = tc.stdenv; }) {
            inherit name;

            nativeBuildInputs =
              with pkgs;
              [
                cmake
                ninja
                pkg-config
                git
                cacert
                ccache
              ]
              ++ tc.extra;

            CMAKE_PRESET = name;

            shellHook = ''
              export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            ''
            + lib.optionalString isEmscripten ''
              export EM_CACHE="$PWD/.emscripten_cache"
              mkdir -p "$EM_CACHE"
            ''
            + ''
              preset_configure() {
                cmake --preset "${name}" -B "build/${name}" ${extraCmakeArgs} "$@"
              }
              preset_build() {
                cmake --build "build/${name}" "$@"
              }

              echo "Preset: ${name}"
              echo "  preset_configure / preset_build"

              # Auto-configure on first entry (NO_AUTOCONFIGURE=1 to skip)
              if [ -z "$NO_AUTOCONFIGURE" ] && [ ! -f "build/${name}/CMakeCache.txt" ]; then
                preset_configure1
              fi
            '';
          };

        presetShells = lib.mapAttrs mkPresetShell presets;
        aliasShells = lib.mapAttrs (_: target: presetShells.${target}) aliases;

        requested = builtins.getEnv "PRESET";
        fallback = if arch == "x86_64" then "gcc-debug" else "clang-debug";
        defaultShell =
          if aliasShells ? ${requested} then
            aliasShells.${requested}
          else if presetShells ? ${requested} then
            presetShells.${requested}
          else
            aliasShells.${fallback};

        # `nix run .#pick` or `nix develop .#<preset-type>`
        pick = pkgs.writeShellApplication {
          name = "pick";
          text = ''
            PS3="Preset: "
            select choice in ${lib.escapeShellArgs (lib.attrNames aliases)}; do
              [ -n "$choice" ] && exec nix develop ".#$choice"
            done
          '';
        };
      in
      {
        devShells = presetShells // aliasShells // { default = defaultShell; };

        apps.pick = {
          type = "app";
          program = "${pick}/bin/pick";
        };

        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
