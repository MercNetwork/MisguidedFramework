# Power menu: Mod+X and waybar's power button (installed as niri-power-menu).
# Lock goes through logind, which COSMIC's lock screen listens to.
choice=$(printf ' Lock\n Logout\n Reboot\n Shutdown\n' | fuzzel -l 4 --dmenu --prompt 'Power: ')
case "$choice" in
    " Lock") loginctl lock-session ;;
    " Logout") niri msg action quit --skip-confirmation ;;
    " Reboot") systemctl reboot ;;
    " Shutdown") systemctl poweroff ;;
esac
