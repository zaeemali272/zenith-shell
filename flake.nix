{
  description = "Zenith Shell - A modern, modular desktop shell for Hyprland built with Quickshell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, quickshell }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.${system} or (import nixpkgs { inherit system; });
          qsPkg = quickshell.packages.${system}.default;
          pythonEnv = pkgs.python3.withPackages (ps: with ps; [ pillow ijson psutil requests ]);
          runtimeDeps = with pkgs; [
            qsPkg
            pythonEnv
            bash
            coreutils
            jq
            gnugrep
            gawk
            procps
            findutils
            ffmpeg
            playerctl
            wireplumber
            networkmanager
            bluez
            libnotify
          ];
        in
        {
          default = self.packages.${system}.zenith-shell;

          zenith-shell = pkgs.stdenv.mkDerivation {
            pname = "zenith-shell";
            version = "0.1.0";

            src = ./.;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/share/zenith-shell $out/bin
              cp -r . $out/share/zenith-shell

              makeWrapper $out/share/zenith-shell/launch.sh $out/bin/zenith-shell \
                --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps} \
                --set ZENITH_ROOT "$out/share/zenith-shell"

              makeWrapper $out/share/zenith-shell/launch.sh $out/bin/zenith-launch \
                --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps} \
                --set ZENITH_ROOT "$out/share/zenith-shell"

              runHook postInstall
            '';
          };
        }
      );

      homeManagerModules.default = self.homeManagerModules.zenith-shell;
      
      homeManagerModules.zenith-shell = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.zenith-shell;
          system = pkgs.stdenv.hostPlatform.system;
        in
        {
          options.programs.zenith-shell = {
            enable = lib.mkEnableOption "Zenith Shell for Hyprland";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${system}.zenith-shell;
              description = "The zenith-shell package to use.";
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];
            
            # Symlink Zenith Shell files into ~/.config/quickshell
            xdg.configFile."quickshell".source = "${cfg.package}/share/zenith-shell";
          };
        };
    };
}
