# mercury's Home Manager config — what every machine gets (NixOS and macOS).
# Hosts add to it through `misguided.user.home` (e.g. Romina turns on Zed and Flutter).
# Every toggle below lives in modules/home/.
{...}: {
  imports = [./modules/home];

  home.stateVersion = "26.05";

  misguided = {
    # zsh + starship, eza, bat, fzf, zoxide, tmux, fastfetch, direnv…
    shell.enable = true;

    # curl, wget, jq, btop, archives, dnsutils… (see modules/home/cli.nix)
    cli.enable = true;

    git = {
      enable = true;
      userName = "MercNetwork";
      userEmail = "hxnterwelch@icloud.com";
    };

    # Languages used to maintain Misguided Framework itself: LSP + formatter + linter each.
    langs = {
      bash.enable = true;
      lua.enable = true;
      markdown.enable = true;
      nix.enable = true;
      toml.enable = true;
      yaml.enable = true;
    };
  };
}
