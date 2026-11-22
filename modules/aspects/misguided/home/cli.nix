# misguided.cli — plain command-line tools. `misguided.cli` is the everyday set;
# the extras are nested aspects a host includes on top:
#
#   includes = [ misguided.cli.openssl misguided.cli.iperf misguided.cli.nmap ];
#
# Available extras: aria2, iperf, nmap, openssl, pdfgrep, vulnix.
{
  misguided.cli = {
    # sqlite + sqls below -> Zed's SQL extension.
    zedExtensions = [ "sql" ];

    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages =
          with pkgs;
          [
            zip # archives: zip, 7z, ouch (one tool for every archive format)
            p7zip
            ouch
            btop # system monitor
            curl
            dnsutils # dig, nslookup
            file
            glow # render Markdown in the terminal
            jq
            passage # pass, but with age keys
            ripgrep
            sqlite # sqlite + sqls (SQL LSP)
            sqls
            tree
            wget
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [ usbutils ]; # lsusb
      };

    aria2.homeManager = { pkgs, ... }: { home.packages = [ pkgs.aria2 ]; }; # fast multi-connection downloads
    iperf.homeManager = { pkgs, ... }: { home.packages = [ pkgs.iperf ]; }; # network throughput tests
    nmap.homeManager = { pkgs, ... }: { home.packages = [ pkgs.nmap pkgs.rustscan ]; };
    openssl.homeManager = { pkgs, ... }: { home.packages = [ pkgs.openssl ]; };
    pdfgrep.homeManager = { pkgs, ... }: { home.packages = [ pkgs.pdfgrep ]; };
    vulnix.homeManager = { pkgs, ... }: { home.packages = [ pkgs.vulnix ]; }; # scan the system closure for CVEs
  };
}
