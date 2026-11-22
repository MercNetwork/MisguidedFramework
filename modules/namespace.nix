# The `misguided` aspect namespace: every reusable feature of the framework
# lives under it (misguided.cosmic, misguided.tailscale, misguided.langs.nix …).
# Hosts and the user live in den.aspects (den.aspects.Romina, den.aspects.mercury);
# features live in the namespace. That split is the whole layout.
{ inputs, ... }:
{
  # false = not exported as a flake output; only this flake uses it.
  imports = [ (inputs.den.namespace "misguided" false) ];
}
