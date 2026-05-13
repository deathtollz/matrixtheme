#!/usr/bin/env bash

set -e

USER_HOME="/home/deathtollz"

POLYBAR="$USER_HOME/.config/polybar"
CONFIG="$POLYBAR/config.ini"

mkdir -p "$POLYBAR"

# =============================================================================
# CREATE POWERMENU SCRIPT
# =============================================================================

mkdir -p ~/.config/rofi/scripts

cat > ~/.config/rofi/scripts/powermenu.sh << 'EOF'
#!/usr/bin/env bash

chosen=$(printf " Lock\n Sleep\n Logout\n Restart\n Shutdown" | \
rofi \
-no-config \
-theme ~/.config/rofi/themes/matrix.rasi \
-dmenu \
-i \
-p "Power")

case "$chosen" in
    *Lock)
        betterlockscreen -l 2>/dev/null || i3lock
        ;;
    *Sleep)
        systemctl suspend
        ;;
    *Logout)
        bspc quit
        ;;
    *Restart)
        systemctl reboot
        ;;
    *Shutdown)
        systemctl poweroff
        ;;
esac
EOF

chmod +x ~/.config/rofi/scripts/powermenu.sh

# =============================================================================
# CREATE CLEAN MODULE
# =============================================================================

cat > "$POLYBAR/powermenu.ini" << 'EOF'
[module/powermenu]
type = custom/text

content = ⏻
content-font = 2
content-padding = 2

content-foreground = #00FF41

click-left = ~/.config/rofi/scripts/powermenu.sh
EOF

# =============================================================================
# FORCE IMPORT MODULE
# =============================================================================

grep -q "powermenu.ini" "$CONFIG" || \
echo "include-file = ~/.config/polybar/powermenu.ini" >> "$CONFIG"

# =============================================================================
# FORCE BAR TO USE IT
# =============================================================================

sed -i \
's/modules-right = .*/modules-right = cpu memory wlan pulseaudio powermenu/g' \
"$CONFIG"

# =============================================================================
# REMOVE XFCE LOGOUTS
# =============================================================================

find "$POLYBAR" -type f | while read -r file; do
    sed -i \
        's/xfce4-session-logout/#removed/g' \
        "$file"
done

# =============================================================================
# RESTART
# =============================================================================

pkill polybar
sleep 1

if [[ -x ~/.config/polybar/launch.sh ]]; then
    ~/.config/polybar/launch.sh &
else
    polybar main &
fi

echo ""
echo "====================================="
echo " MATRIX POWERMENU INSTALLED"
echo "====================================="
echo ""
echo "Your RIGHT side modules were replaced with:"
echo ""
echo "cpu memory wlan pulseaudio powermenu"
echo ""
echo "If your bar disappears:"
echo ""
echo "polybar main"
echo ""
