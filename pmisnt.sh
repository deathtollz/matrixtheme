#!/usr/bin/env bash
# =============================================================================
# matrix-powermenu-installer.sh
# Installs a Matrix-themed Rofi power menu for BSPWM
# =============================================================================

set -euo pipefail

USER_HOME="/home/deathtollz"

ROFI_DIR="$USER_HOME/.config/rofi"
SCRIPT_DIR="$ROFI_DIR/scripts"

SXHKD="$USER_HOME/.config/sxhkd/sxhkdrc"

mkdir -p "$SCRIPT_DIR"

echo "[*] Installing Matrix power menu..."

# =============================================================================
# CREATE POWERMENU SCRIPT
# =============================================================================

cat > "$SCRIPT_DIR/powermenu.sh" << 'EOF'
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

chmod +x "$SCRIPT_DIR/powermenu.sh"

echo "[✔] Powermenu script installed"

# =============================================================================
# ADD SXHKD KEYBIND
# =============================================================================

mkdir -p "$(dirname "$SXHKD")"

touch "$SXHKD"

if ! grep -q "powermenu.sh" "$SXHKD"; then

cat >> "$SXHKD" << 'EOF'

# =============================================================================
# MATRIX POWER MENU
# =============================================================================

super + shift + e
    ~/.config/rofi/scripts/powermenu.sh
EOF

    echo "[✔] SXHKD keybind added"
else
    echo "[*] Keybind already exists"
fi

# =============================================================================
# RELOAD SXHKD
# =============================================================================

pkill -USR1 -x sxhkd 2>/dev/null || true

echo ""
echo "=============================================="
echo " MATRIX POWER MENU INSTALLED"
echo "=============================================="
echo ""
echo "KEYBIND:"
echo ""
echo "    SUPER + SHIFT + E"
echo ""
echo "OR RUN:"
echo ""
echo "    ~/.config/rofi/scripts/powermenu.sh"
echo ""
