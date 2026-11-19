# Git + GitHub CLI (with the git credential helper) + lazygit.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.misguided.git;
in {
  options.misguided.git = {
    enable = lib.mkEnableOption "Git";

    userName = lib.mkOption {
      type = lib.types.str;
      description = "Name on commits.";
    };

    userEmail = lib.mkOption {
      type = lib.types.str;
      description = "Email on commits.";
    };

    signByDefault = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Sign commits with your SSH key (from ssh-agent).";
    };

    allowedSigners = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Content of ~/.ssh/allowed_signers (for verifying signed commits).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [git-lfs lazygit];

    programs.git = {
      enable = true;
      lfs.enable = true;

      signing = {
        format = "ssh";
        inherit (cfg) signByDefault;
      };

      settings = {
        user = {
          name = cfg.userName;
          email = cfg.userEmail;
        };
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        core.editor =
          if config.misguided.zed.enable
          then "zeditor --wait"
          else "nano";
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

    home.file.".ssh/allowed_signers" = lib.mkIf (cfg.allowedSigners != "") {
      text = cfg.allowedSigners;
    };
  };
}
