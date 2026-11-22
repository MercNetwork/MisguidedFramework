# misguided.langs.<name> — language support: each language brings its LSP,
# formatter and linter onto PATH (where Zed and anything else picks them up),
# and tells misguided.zed which extension it wants (the `zedExtensions` quirk).
#
#   includes = [ misguided.langs.go ];      one language
#   includes = [ misguided.langs.all ];     every language below
#
# Dart / Flutter is misguided.flutter (the SDK ships its own LSP).
{ lib, misguided, ... }:
let
  # name = { packages; zed extensions it asks for }
  langs = {
    bash = {
      pkgs = p: [ p.bash-language-server p.shellcheck p.shfmt ];
      zed = [ "basher" ];
    };
    cpp = {
      pkgs = p: [ p.clang-tools ]; # clangd + clang-format
    };
    docker = {
      pkgs = p: [ p.dockerfile-language-server p.docker-compose-language-service p.hadolint ];
      zed = [ "dockerfile" "docker-compose" ];
    };
    go = {
      pkgs = p: [ p.go p.gopls p.gotools p.go-tools p.golangci-lint ];
    };
    java = {
      pkgs = p: [ p.jdt-language-server p.google-java-format ];
      zed = [ "java" ];
    };
    js = {
      pkgs = p: [ p.vtsls p.prettierd ];
    };
    latex = {
      pkgs = p: [ p.texlab p.texlivePackages.latexindent p.proselint ];
      zed = [ "latex" ];
    };
    lua = {
      pkgs = p: [ p.lua p.lua-language-server p.stylua p.selene ];
      zed = [ "lua" ];
    };
    markdown = {
      pkgs = p: [ p.marksman p.mdx-language-server p.markdownlint-cli2 p.prettierd ];
    };
    nginx = {
      pkgs = p: [ p.nginx-language-server ];
      zed = [ "nginx" ];
    };
    nix = {
      pkgs = p: [ p.nixd p.alejandra p.statix p.deadnix ];
    };
    python = {
      pkgs = p: [ p.python3 p.uv p.ruff p.ty ];
      # Use Nix's interpreters, don't let uv download its own.
      extra.home.sessionVariables.UV_PYTHON_DOWNLOADS = "never";
    };
    qml = {
      pkgs = p: [ p.kdePackages.qtdeclarative ]; # qmlls, qmlformat
      zed = [ "qml" ];
    };
    rust = {
      # rustup manages the toolchain: `rustup default stable && rustup component add rust-analyzer`
      pkgs = p: [ p.rustup p.gcc ];
    };
    toml = {
      pkgs = p: [ p.taplo ];
    };
    typst = {
      pkgs = p: [ p.typst p.tinymist p.typstyle ];
      zed = [ "typst" ];
    };
    web = {
      pkgs = p: [ p.vscode-langservers-extracted p.svelte-language-server p.vue-language-server p.prettierd ];
      zed = [ "html" "svelte" "vue" ];
    };
    yaml = {
      pkgs = p: [ p.yaml-language-server p.prettierd ];
    };
  };

  mkLang = _name: lang: {
    zedExtensions = lang.zed or [ ];
    homeManager =
      { pkgs, ... }:
      lib.recursiveUpdate { home.packages = lang.pkgs pkgs; } (lang.extra or { });
  };
in
{
  misguided.langs = lib.mapAttrs mkLang langs // {
    all.includes = map (name: misguided.langs.${name}) (lib.attrNames langs);
  };
}
