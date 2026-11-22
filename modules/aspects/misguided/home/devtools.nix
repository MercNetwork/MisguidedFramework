# misguided.devtools.<name> — developer tools beyond the languages.
#
#   containers   lazydocker, docker LSPs/linters, distrobox
#   devbox       per-project Nix shells without writing Nix
#   dbeaver      DBeaver database client
#   postman      Postman API client
{
  misguided.devtools = {
    containers.homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          lazydocker
          docker-credential-helpers
          docker-language-server
          docker-compose-language-service
          hadolint
          distrobox
        ];
      };
    devbox.homeManager = { pkgs, ... }: { home.packages = [ pkgs.devbox ]; };
    dbeaver.homeManager = { pkgs, ... }: { home.packages = [ pkgs.dbeaver-bin ]; };
    postman.homeManager = { pkgs, ... }: { home.packages = [ pkgs.postman ]; };
  };
}
