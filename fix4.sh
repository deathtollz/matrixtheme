#!/usr/bin/env bash
# =============================================================================
# FORCE FIX POLYBAR POWER BUTTON
# =============================================================================

set -e

USER_HOME="/home/deathtollz"

POLYBAR_DIR="$USER_HOME/.config/polybar"

POWER_SCRIPT="$USER_HOME/.config/rofi/scripts/powermenu.sh"

echo "[*] Creating Matrix power menu script..."

mkdir -p "$(dirname "$POWER_SCRIPT")"

cat > "$POWER_SCRIPT" << 'EOF'
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

chmod +x "$POWER_SCRIPT"

echo "[✔] Powermenu script created"

echo ""
echo "[*] Scanning ALL Polybar configs..."
echo ""

find "$POLYBAR_DIR" -type f \( -name "*.ini" -o -name "*.conf" \) | while read -r file; do

    echo "Checking: $file"

    cp "$file" "$file.bak"

    # Replace ALL known logout/power commands
    sed -i \
        -e 's|click-left *= *.*xfce4-session-logout.*|click-left = ~/.config/rofi/scripts/powermenu.sh|g' \
        -e 's|click-left *= *.*systemctl poweroff.*|click-left = ~/.config/rofi/scripts/powermenu.sh|g' \
        -e 's|click-left *= *.*systemctl reboot.*|click-left = ~/.config/rofi/scripts/powermenu.sh|g' \
        -e 's|click-left *= *.*bspc quit.*|click-left = ~/.config/rofi/scripts/powermenu.sh|g' \
        -e 's|exec *= *.*xfce4-session-logout.*|exec = echo ⏻|g' \
        "$file"

done

echo ""
echo "[*] Restarting Polybar..."

pkill polybar
sleep 1

if [[ -x "$POLYBAR_DIR/launch.sh" ]]; then
    bash "$POLYBAR_DIR/launch.sh" &
else
    polybar main &
fi

echo ""
echo "========================================="
echo " POLYBAR POWER BUTTON FORCE-FIXED"
echo "========================================="
echo ""
echo "If it STILL does not work:"
echo ""
echo "Your power icon is probably NOT Polybar."
echo ""
echo "It may be:"
echo "  • eww"
echo "  • xfce panel"
echo "  • polywins"
echo "  • a custom script"
echo ""
echo "To confirm:"
echo ""
echo "CTRL + RIGHT CLICK the power button."
echo ""
echo "If no Polybar menu appears,"
echo "it is NOT a Polybar module."
echo ""
