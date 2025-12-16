# This flake file is community maintained
{
  description = "Niri: A scrollable-tiling Wayland compositor.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # NOTE: This is not necessary for end users
    # You can omit it with `inputs.rust-overlay.follows = ""`
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
    }:

    let
      niri-package =
        { lib, cairo, dbus, libGL, libdisplay-info, libinput, seatd,
          libxkbcommon, libgbm, pango, pipewire, pkg-config, rustPlatform,
          systemd, wayland, installShellFiles, withDbus ? true, withSystemd ? true,
          withScreencastSupport ? true, withDinit ? false }:

        rustPlatform.buildRustPackage {
          pname = "niri";
          version = self.shortRev or self.dirtyShortRev or "unknown";

          src = lib.fileset.toSource {
            root = ./.;
            fileset = lib.fileset.unions [
              ./niri-config
              ./niri-ipc
              ./niri-visual-tests
              ./resources
              ./src
              ./Cargo.toml
              ./Cargo.lock
            ];
          };

          postPatch = ''
            patchShebangs resources/niri-session
            substituteInPlace resources/niri.service \
              --replace-fail '/usr/bin' "$out/bin"
          '';

          cargoLock = { allowBuiltinFetchGit = true; lockFile = ./Cargo.lock; };
          strictDeps = true;

          nativeBuildInputs = [ rustPlatform.bindgenHook pkg-config installShellFiles ];

          buildInputs = [
            cairo dbus libGL libdisplay-info libinput seatd libxkbcommon
            libgbm pango wayland
          ]
          ++ lib.optional (withDbus || withScreencastSupport || withSystemd) dbus
          ++ lib.optional withScreencastSupport pipewire
          ++ lib.optional withSystemd systemd;

          buildFeatures = lib.optional withDbus "dbus"
                          ++ lib.optional withDinit "dinit"
                          ++ lib.optional withScreencastSupport "xdp-gnome-screencast"
                          ++ lib.optional withSystemd "systemd";

          buildNoDefaultFeatures = true;

          preCheck = 'export XDG_RUNTIME_DIR="$(mktemp -d)"';

          checkFlags = [ "--skip=::egl" ];

          postInstall = ''
            installShellCompletion --cmd niri \
              --bash <($out/bin/niri completions bash) \
              --fish <($out/bin/niri completions fish) \
              --nushell <($out/bin/niri completions nushell) \
              --zsh <($out/bin/niri completions zsh)

            install -Dm644 resources/niri.desktop -t $out/share/wayland-sessions
            install -Dm644 resources/niri-portals.conf -t $out/share/xdg-desktop-portal
          '' + lib.optionalString withSystemd ''
            install -Dm755 resources/niri-session $out/bin/niri-session
            install -Dm644 resources/niri{.service,-shutdown.target} -t $out/share/systemd/user
          '';

          env = {
            RUSTFLAGS = toString (
              map (arg: "-C link-arg=" + arg) [ "-Wl,--push-state,--no-as-needed" "-lEGL" "-lwayland-client" "-Wl,--pop-state" ]
            );
          };

          passthru = { providedSessions = [ "niri" ]; };

          meta = {
            description = "Scrollable-tiling Wayland compositor";
            homepage = "https://github.com/YaLTeR/niri";
            license = lib.licenses.gpl3Only;
            mainProgram = "niri";
            platforms = lib.platforms.linux;
          };
        };

      inherit (nixpkgs) lib;
      systems = lib.intersectLists lib.systems.flakeExposed lib.platforms.linux;
      forAllSystems = lib.genAttrs systems;
      nixpkgsFor = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in
    {
      #######################
      # ADDED: NixOS System #
      #######################
      # This is necessary for `nixos-rebuild --flake /etc/nixos#nahian` to work
      nixosConfigurations = {
        nahian = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            # Optionally, you can add a module to pull in niri package automatically
            # (if you want niri to be available system-wide)
            { environment.systemPackages = [ self.packages.x86_64-linux.niri ]; }
          ];
        };
      };

      ########################
      # EXISTING NIRI PACKAGE
      ########################
      checks = forAllSystems (system: { inherit (self.packages.${system}) niri-debug; });

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          rust-bin = rust-overlay.lib.mkRustBin { } pkgs;
          inherit (self.packages.${system}) niri;
        in
        {
          default = pkgs.mkShell {
            packages = [
              (rust-bin.selectLatestNightlyWith (
                toolchain:
                toolchain.default.override {
                  extensions = [
                    "rust-analyzer" "rust-src" "rustfmt-preview" "clippy-preview"
                  ];
                }
              ))
              pkgs.cargo-insta
            ];
            nativeBuildInputs = [ pkgs.rustPlatform.bindgenHook pkgs.pkg-config pkgs.wrapGAppsHook4 ];
            buildInputs = niri.buildInputs ++ [ pkgs.libadwaita ];
            env = { CARGO_BUILD_RUSTFLAGS = niri.RUSTFLAGS; };
          };
        }
      );

      formatter = forAllSystems (system: nixpkgsFor.${system}.nixfmt-rfc-style);

      packages = forAllSystems (
        system:
        let niri = nixpkgsFor.${system}.callPackage niri-package { };
        in { inherit niri; niri-debug = niri.overrideAttrs (newAttrs: oldAttrs: {
              pname = oldAttrs.pname + "-debug";
              cargoBuildType = "debug";
              cargoCheckType = newAttrs.cargoBuildType;
              dontStrip = true;
            });
            default = niri;
        }
      );

      overlays.default = final: _: { niri = final.callPackage niri-package { }; };
    };
}