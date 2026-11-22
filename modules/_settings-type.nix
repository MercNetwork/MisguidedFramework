# Builds the type of `host.settings` from every `settings` block declared on
# an aspect (den's "aspect settings" pattern, docs: /guides/aspect-settings/).
# The leading underscore keeps import-tree from loading this file as a module.
#
# Paths mirror the aspect tree, and the `misguided` namespace is walked too, so
#   misguided.disk.settings.device = mkOption …
# is set on a host as
#   den.hosts.x86_64-linux.Romina.settings.misguided.disk.device = "/dev/nvme0n1";
{ den, lib }:
let
  inherit (lib) mkOption types;
  inherit (den.lib.aspects.fx.keyClassification) isStructuralKey;

  skipKey = k: isStructuralKey k || (den.classes or { }) ? ${k} || (den.quirks or { }) ? ${k};

  reshape = raw: if raw ? options || raw ? config || raw ? imports then raw else { options = raw; };

  hasSettingsDeep =
    node:
    builtins.isAttrs node
    && (
      node ? settings
      || lib.any (k: !(skipKey k) && hasSettingsDeep (node.${k} or null)) (builtins.attrNames node)
    );

  nodeModule =
    node:
    let
      own = reshape (node.settings or { });
      children = lib.filterAttrs (k: v: !(skipKey k) && builtins.isAttrs v && hasSettingsDeep v) node;
    in
    {
      imports = own.imports or [ ];
      config = own.config or { };
      options =
        (own.options or { })
        // lib.mapAttrs (
          name: child:
          mkOption {
            type = types.submodule (nodeModule child);
            default = { };
            description = "Settings under ${name}";
          }
        ) children;
    };
in
types.submodule (nodeModule ((den.aspects or { }) // (den.ful or { })))
