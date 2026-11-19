# Every Misguided Framework Home Manager module. Each one only declares `misguided.*`
# options; home.nix and the hosts' `misguided.user.home` switch them on.
{
  imports = [
    ./shell.nix
    ./cli.nix
    ./git.nix
    ./langs.nix
    ./zed.nix
    ./flutter.nix
    ./devtools.nix
    ./desktop.nix
  ];
}
