# Developer tools beyond the languages: container helpers,
# throwaway dev environments, and the GUI database / API clients.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.misguided.devtools;
in {
  options.misguided.devtools = {
    containers.enable = lib.mkEnableOption "lazydocker, docker LSPs/linters, distrobox";
    devbox.enable = lib.mkEnableOption "devbox (per-project Nix shells without writing Nix)";
    dbeaver.enable = lib.mkEnableOption "DBeaver database client";
    postman.enable = lib.mkEnableOption "Postman API client";
  };

  config = {
    home.packages =
      lib.optionals cfg.containers.enable (with pkgs; [
        lazydocker
        docker-credential-helpers
        docker-language-server
        docker-compose-language-service
        hadolint
        distrobox
      ])
      ++ lib.optionals cfg.devbox.enable [pkgs.devbox]
      ++ lib.optionals cfg.dbeaver.enable [pkgs.dbeaver-bin]
      ++ lib.optionals cfg.postman.enable [pkgs.postman];
  };
}
