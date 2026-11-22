# The `misguided` aspect namespace: every reusable feature of the framework
# lives under it (misguided.cosmic, misguided.tailscale, misguided.langs.nix …).
# `true` = also exported as flake.denful.misguided, so another flake can
# import these aspects.
#
# Hosts and the user live in den.aspects (den.aspects.Romina, den.aspects.mercury);
# features live in the namespace. That split is the whole layout.
{ inputs, den, ... }:
{
  imports = [ (inputs.den.namespace "misguided" true) ];

  # Enables den's angle-bracket syntax (<den/primary-user>) in modules that
  # take `__findFile` as an argument. This repo spells batteries out as
  # den.batteries.* instead, but the line keeps the template's option open.
  _module.args.__findFile = den.lib.__findFile;
}
