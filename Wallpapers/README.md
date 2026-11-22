# Wallpapers

Drop images here. On the COSMIC desktops (Romina, Midra) this folder is linked to
`~/Pictures/Wallpapers` (see `modules/home/desktop.nix`); pick one in
Settings → Appearance → Background → Add Picture.

The folder is copied into the Nix store on every rebuild, so keep it to the
images you actually use, and `git add` new ones — flakes only see tracked files.
