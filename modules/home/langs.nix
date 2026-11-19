# Language support: each language brings its LSP, formatter and
# linter onto PATH, where Zed (and anything else) picks them up.
#
#   misguided.langs.<name>.enable = true;      one language
#   misguided.langs.all.enable = true;         every language below
#
# Dart / Flutter lives in modules/home/flutter.nix (the SDK ships its own LSP).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.misguided.langs;

  names = [
    "bash"
    "cpp"
    "docker"
    "go"
    "java"
    "js"
    "latex"
    "lua"
    "markdown"
    "nginx"
    "nix"
    "python"
    "qml"
    "rust"
    "toml"
    "typst"
    "web"
    "yaml"
  ];

  packagesFor = with pkgs; {
    bash = [bash-language-server shellcheck shfmt];
    cpp = [clang-tools]; # clangd + clang-format
    docker = [dockerfile-language-server docker-compose-language-service hadolint];
    go = [go gopls gotools go-tools golangci-lint];
    java = [jdt-language-server google-java-format];
    js = [vtsls prettierd];
    latex = [texlab texlivePackages.latexindent proselint];
    lua = [lua lua-language-server stylua selene];
    markdown = [marksman mdx-language-server markdownlint-cli2 prettierd];
    nginx = [nginx-language-server];
    nix = [nixd alejandra statix deadnix];
    python = [python3 uv ruff ty];
    qml = [kdePackages.qtdeclarative]; # qmlls, qmlformat
    # rustup manages the toolchain: `rustup default stable && rustup component add rust-analyzer`
    rust = [rustup gcc];
    toml = [taplo];
    typst = [typst tinymist typstyle];
    web = [vscode-langservers-extracted svelte-language-server vue-language-server prettierd];
    yaml = [yaml-language-server prettierd];
  };
in {
  options.misguided.langs =
    {all.enable = lib.mkEnableOption "every language module";}
    // lib.genAttrs names (name: {
      enable = lib.mkEnableOption "${name} language support";
    });

  config = lib.mkMerge [
    (lib.mkIf cfg.all.enable {
      misguided.langs = lib.genAttrs names (_: {enable = lib.mkDefault true;});
    })
    {
      home.packages = lib.unique (lib.concatMap
        (name: lib.optionals cfg.${name}.enable packagesFor.${name})
        names);

      # Python: use Nix's interpreters, don't let uv download its own.
      home.sessionVariables = lib.mkIf cfg.python.enable {UV_PYTHON_DOWNLOADS = "never";};
    }
  ];
}
