# misguided.git — Git + GitHub CLI (with the git credential helper) + lazygit.
# Name and email are set by the user (aspects/mercury.nix):
#   homeManager.programs.git.settings.user = { name = …; email = …; };
#
# Signing commits with your SSH key: programs.git.signing.signByDefault = true;
# and put your key in ~/.ssh/allowed_signers (home.file.".ssh/allowed_signers".text).
{
  misguided.git.homeManager =
    { lib, pkgs, ... }:
    {
      home.packages = with pkgs; [
        git-lfs
        lazygit
      ];

      programs.git = {
        enable = true;
        lfs.enable = true;

        signing = {
          format = "ssh";
          signByDefault = lib.mkDefault false;
        };

        settings = {
          init.defaultBranch = "main";
          push.autoSetupRemote = true;
          core.editor = lib.mkDefault "nano"; # misguided.zed overrides this
          gpg = {
            format = "ssh";
            ssh = {
              allowedSignersFile = "~/.ssh/allowed_signers";
              defaultKeyCommand = "ssh-add -L";
            };
          };
        };
      };

      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
      };
    };
}
