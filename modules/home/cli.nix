# Plain command-line tools. `misguided.cli.enable` turns on the
# ones marked `true` below; flip any of them per host with
# `misguided.cli.<name>.enable = true/false;`.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.misguided.cli;

  # name = on by default?
  defaults = {
    archives = true; # zip, 7z, ouch (one tool for every archive format)
    btop = true; # system monitor
    curl = true;
    dnsutils = true; # dig, nslookup
    file = true;
    glow = true; # render Markdown in the terminal
    jq = true;
    passage = true; # pass, but with age keys
    ripgrep = true;
    sqlite = true; # sqlite + sqls (SQL LSP)
    tree = true;
    usbutils = true; # lsusb (Linux only)
    wget = true;

    aria2 = false; # fast multi-connection downloads
    iperf = false; # network throughput tests
    nmap = false; # nmap, rustscan
    openssl = false;
    pdfgrep = false;
    vulnix = false; # scan the system closure for CVEs
  };

  packagesFor = with pkgs; {
    archives = [zip p7zip ouch];
    btop = [btop];
    curl = [curl];
    dnsutils = [dnsutils];
    file = [file];
    glow = [glow];
    jq = [jq];
    passage = [passage];
    ripgrep = [ripgrep];
    sqlite = [sqlite sqls];
    tree = [tree];
    usbutils = lib.optionals stdenv.hostPlatform.isLinux [usbutils];
    wget = [wget];
    aria2 = [aria2];
    iperf = [iperf];
    nmap = [nmap rustscan];
    openssl = [openssl];
    pdfgrep = [pdfgrep];
    vulnix = [vulnix];
  };
in {
  options.misguided.cli =
    {enable = lib.mkEnableOption "the Misguided Framework CLI toolbox";}
    // lib.mapAttrs (name: on: {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = on;
        description = "Install ${name} (when misguided.cli.enable is on).";
      };
    })
    defaults;

  config = lib.mkIf cfg.enable {
    home.packages = lib.concatLists (lib.mapAttrsToList
      (name: pkgList: lib.optionals cfg.${name}.enable pkgList)
      packagesFor);
  };
}
