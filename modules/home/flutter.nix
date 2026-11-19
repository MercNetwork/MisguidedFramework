# Flutter + Dart. `flutter` bundles the Dart SDK and its language server
# (`dart language-server`), which Zed's dart extension uses.
#
#   flutter doctor        check the toolchain
#   flutter create app && cd app && flutter run -d linux
#
# Linux desktop targets only — no Android SDK or Chrome is installed, so
# `flutter doctor` will list those as missing; that's expected.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.misguided.flutter;
in {
  options.misguided.flutter.enable = lib.mkEnableOption "Flutter and Dart";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.flutter];
  };
}
