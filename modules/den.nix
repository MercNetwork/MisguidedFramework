# The fleet: one line per machine. Each machine's details (its aspect,
# disk settings, hardware) live in modules/hosts/<Host>/default.nix.
{ den, lib, ... }:
{
  den.hosts.x86_64-linux.Romina.users.mercury = { }; # dev laptop (Intel + NVIDIA)
  den.hosts.x86_64-linux.Midra.users.mercury = { }; # desktop (AMD + Intel Arc), gaming
  den.hosts.x86_64-linux.Metyr.users.mercury = { }; # homelab / self-hosting server
  den.hosts.aarch64-linux.Malenia.users.mercury = { }; # Raspberry Pi 5 — microvm host
  den.hosts.aarch64-darwin.Rellana.users.mercury = { }; # Mac (Apple Silicon)

  # Every user gets Home Manager.
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  # Hosts receive what their users provide them (`provides.to-hosts`, see
  # aspects/mercury.nix).
  den.schema.host.includes = [ den.batteries.mutual-provider ];
}
