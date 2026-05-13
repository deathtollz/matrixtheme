#!/usr/bin/env bash
# =============================================================================
# polybar-matrix-powermenu-fix.sh
#
# FORCE replaces ALL XFCE logout/power actions in Polybar
# with the Matrix Rofi power menu.
# =============================================================================

set -euo pipefail

USER_HOME="/home/deathtollz"

POLYBAR_DIR="$USER_HOME/.config/polybar"
ROFI_DIR="$USER_HOME/.config/rofi"
SCRIPT_DIR="$ROFI_DIR/scripts"

POWER_SCRIPT="$SCRIPT_DIR/powermenu.sh"

mkdir -p "$SCRIPT_DIR"

echo "[*] Installing Matrix powermenu..."

# =============================================================================
# CREATE POWERMENU
# =============================================================================

cat > "$POWER_SCRIPT" << 'EOF'
#!/usr/bin/env bash

OPTIONS=" Lock
 Sleep
 Logout
 Restart
 Shutdown"

chosen=$(echo "$OPTIONS" | rofi \
    -no-config \
    -theme ~/.config/rofi/themes/matrix.rasi \
    -dmenu \
    -i \
    -p "󰣇 Power")

case "$chosen" in

    *Lock)
        if command -v betterlockscreen >/dev/null 2>&1; then
            betterlockscreen -l
        elif command -v i3lock >/dev/null 2>&1; then
            i3lock
        else
            notify-send "No lockscreen installed"
        fi
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

echo "[✔] Powermenu installed"

# =============================================================================
# PATCH ALL POLYBAR FILES
# =============================================================================

echo "[*] Searching Polybar configs..."

find "$POLYBAR_DIR" -type f \( -name "*.ini" -o -name "*.conf" \) | while read -r file; do

    echo "    -> Patching: $file"

    cp "$file" "$file.bak.$(date +%s)"

    # Replace common logout commands
    sed -i \
        -e 's|xfce4-session-logout|~/.config/rofi/scripts/powermenu.sh|g' \
        -e 's|systemctl poweroff|~/.config/rofi/scripts/powermenu.sh|g' \
        -e 's|systemctl reboot|~/.config/rofi/scripts/powermenu.sh|g' \
        -e 's|bspc quit|~/.config/rofi/scripts/powermenu.sh|g' \
        -e 's|openbox --exit|~/.config/rofi/scripts/powermenu.sh|g' \
        -e 's|i3-msg exit|~/.config/rofi/scripts/powermenu.sh|g' \
        "$file"

done

# =============================================================================
# FORCE CREATE A POWER MODULE
# =============================================================================

MODULE_FILE="$POLYBAR_DIR/matrix_powermenu.ini"

cat > "$MODULE_FILE" << 'EOF'
[module/matrix-powermenu]
type = custom/text

content = ⏻
content-font = 2
content-padding = 2

content-foreground = #00FF41

click-left = ~/.config/rofi/scripts/powermenu.sh
EOF

echo "[✔] Matrix Polybar module created"

# =============================================================================
# RESTART POLYBAR
# =============================================================================

echo "[*] Restarting Polybar..."

pkill polybar 2>/dev/null || true

sleep 1

if [[ -x "$POLYBAR_DIR/launch.sh" ]]; then
    bash "$POLYBAR_DIR/launch.sh" &
else
    polybar main &
fi

echo ""
echo "==============================================="
echo " POLYBAR MATRIX POWERMENU FIXED"
echo "==============================================="
echo ""
echo "If your old power button still appears:"
echo ""
echo "1. Remove the old module from your bar:"
echo ""
echo "   modules-right = ..."
echo ""
echo "2. Add:"
echo ""
echo "   matrix-powermenu"
echo ""
echo "EXAMPLE:"
echo ""
echo "modules-right = wlan battery matrix-powermenu"
echo ""
echo "Then reload Polybar:"
echo ""
echo "    bspc wm -r"
echo ""
