# misguided.docker — rootful Docker with buildx. The host's user joins the docker group.
{ misguided, ... }:
{
  misguided.docker = {
    includes = [ misguided.docker.user-group ];

    persist.directories = [ "/var/lib/docker" ];

    nixos =
      { pkgs, ... }:
      {
        virtualisation.docker = {
          enable = true;
          extraPackages = [ pkgs.docker-buildx ];
          daemon.settings.ipv6 = false;
        };
        environment.systemPackages = [ pkgs.docker-buildx ];
      };

    user-group.nixos =
      { user, ... }:
      {
        users.users.${user.userName}.extraGroups = [ "docker" ];
      };
  };
}
