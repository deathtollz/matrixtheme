#!/usr/bin/env bash
# =============================================================================
# MATRIX POLYBAR FULL REBUILD
# Clean Matrix-style Polybar with bold green MENU + POWER
# =============================================================================

set -euo pipefail

USER_HOME="/home/deathtollz"

POLYBAR_DIR="$USER_HOME/.config/polybar"
CACHE_DIR="$USER_HOME/.cache/polybar"
LOCAL_DIR="$USER_HOME/.local/share/polybar"

ROFI_DIR="$USER_HOME/.config/rofi"
SCRIPT_DIR="$ROFI_DIR/scripts"
THEME_DIR="$ROFI_DIR/themes"

echo "=================================================="
echo " MATRIX POLYBAR FULL REBUILD"
echo "=================================================="

sleep 1

# =============================================================================
# STOP POLYBAR
# =============================================================================

echo "[*] Killing existing Polybar instances..."

pkill -x polybar 2>/dev/null || true

while pgrep -x polybar >/dev/null; do
    sleep 0.5
done

# =============================================================================
# REMOVE OLD CONFIGS
# =============================================================================

echo "[*] Removing old Polybar configs..."

rm -rf "$POLYBAR_DIR"
rm -rf "$CACHE_DIR"
rm -rf "$LOCAL_DIR"

rm -rf "$USER_HOME/.config/polybar.old"
rm -rf "$USER_HOME/.config/polybar.bak"

# =============================================================================
# CREATE DIRECTORIES
# =============================================================================

echo "[*] Creating clean directories..."

mkdir -p "$POLYBAR_DIR"
mkdir -p "$SCRIPT_DIR"
mkdir -p "$THEME_DIR"

# =============================================================================
# INSTALL PACKAGES
# =============================================================================

echo "[*] Installing dependencies..."

if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm \
        polybar \
        rofi \
        networkmanager \
        network-manager-applet \
        pulseaudio \
        pavucontrol \
        noto-fonts \
        ttf-jetbrains-mono-nerd \
        kitty \
        thunar \
        firefox \
        i3lock
fi

# =============================================================================
# AUTO DETECT NETWORK INTERFACE
# =============================================================================

NET_INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)

if [[ -z "${NET_INTERFACE:-}" ]]; then
    NET_INTERFACE="wlan0"
fi

echo "[*] Detected interface: $NET_INTERFACE"

# =============================================================================
# ROFI THEME
# =============================================================================

cat > "$THEME_DIR/matrix.rasi" << 'EOF'
* {
    bg: #050805;
    bg-alt: #101510;
    fg: #00FF41;

    background-color: @bg;
    text-color: @fg;

    border-color: #00FF41;

    font: "JetBrainsMono Nerd Font Bold 11";
}

window {
    width: 30%;
    border: 2px;
    padding: 15px;
}

inputbar {
    padding: 10px;
    margin: 10px;
}

element {
    padding: 8px;
}

element selected {
    background-color: #00FF41;
    text-color: #000000;
}
EOF

# =============================================================================
# ROFI LAUNCHER
# =============================================================================

cat > "$SCRIPT_DIR/launcher.sh" << 'EOF'
#!/usr/bin/env bash

rofi \
-no-config \
-theme ~/.config/rofi/themes/matrix.rasi \
-show drun
EOF

chmod +x "$SCRIPT_DIR/launcher.sh"

# =============================================================================
# ROFI POWERMENU
# =============================================================================

cat > "$SCRIPT_DIR/powermenu.sh" << 'EOF'
#!/usr/bin/env bash

chosen=$(printf "LOCK\nSLEEP\nLOGOUT\nRESTART\nSHUTDOWN" | \
rofi \
-no-config \
-theme ~/.config/rofi/themes/matrix.rasi \
-dmenu \
-i \
-p "POWER")

case "$chosen" in

    LOCK)
        i3lock
        ;;

    SLEEP)
        systemctl suspend
        ;;

    LOGOUT)
        bspc quit 2>/dev/null || pkill -KILL -u "$USER"
        ;;

    RESTART)
        systemctl reboot
        ;;

    SHUTDOWN)
        systemctl poweroff
        ;;
esac
EOF

chmod +x "$SCRIPT_DIR/powermenu.sh"

# =============================================================================
# POLYBAR CONFIG
# =============================================================================

cat > "$POLYBAR_DIR/config.ini" << EOF
[global/wm]
margin-top = 0
margin-bottom = 0

; =============================================================================
; COLORS
; =============================================================================

[color]

bg = #050805
bg-alt = #101510

fg = #88FF88
fg-alt = #44CC44

green = #00FF41
green-soft = #44CC44
green-dark = #2FAF2F

white = #E8FFE8
black = #000000

alert = #AAFF44

; =============================================================================
; BAR
; =============================================================================

[bar/main]

width = 100%
height = 30

background = \${color.bg}
foreground = \${color.fg}

radius = 0

padding = 0

module-margin-left = 0
module-margin-right = 0

font-0 = "JetBrainsMono Nerd Font Bold:size=11;3"
font-1 = "Noto Sans Bold:size=10;3"

modules-left = menu sep2 term web files
modules-center = date
modules-right = sep cpu memory alsa battery network sep sysmenu

separator =

enable-ipc = true

cursor-click = pointer
cursor-scroll = ns-resize

tray-position = right
tray-padding = 2

; =============================================================================
; MENU
; =============================================================================

[module/menu]
type = custom/text

content = " MENU "

content-background = \${color.bg-alt}
content-foreground = \${color.green}
content-padding = 2

click-left = ~/.config/rofi/scripts/launcher.sh

; =============================================================================
; POWER
; =============================================================================

[module/sysmenu]
type = custom/text

content = " POWER "

content-background = \${color.bg-alt}
content-foreground = \${color.green}
content-padding = 2

click-left = ~/.config/rofi/scripts/powermenu.sh

; =============================================================================
; SEPARATORS
; =============================================================================

[module/sep]
type = custom/text

content = |
content-foreground = \${color.green-dark}
content-background = \${color.bg-alt}
content-padding = 1

[module/sep2]
type = custom/text

content = |
content-foreground = \${color.bg}
content-background = \${color.bg}
content-padding = 1

; =============================================================================
; APPS
; =============================================================================

[module/term]
type = custom/text

content = TERM
content-foreground = \${color.green}
content-padding = 3

click-left = kitty &

[module/web]
type = custom/text

content = WEB
content-foreground = \${color.green-soft}
content-padding = 3

click-left = firefox &

[module/files]
type = custom/text

content = FILES
content-foreground = \${color.green}
content-padding = 3

click-left = thunar &

; =============================================================================
; CPU
; =============================================================================

[module/cpu]
type = internal/cpu

interval = 2

format-background = \${color.bg-alt}
format-padding = 2

label = CPU %percentage%%

; =============================================================================
; MEMORY
; =============================================================================

[module/memory]
type = internal/memory

interval = 2

format-background = \${color.bg-alt}
format-padding = 2

label = RAM %percentage_used%%

; =============================================================================
; AUDIO
; =============================================================================

[module/alsa]
type = internal/pulseaudio

use-ui-max = true
interval = 2

format-volume-background = \${color.bg-alt}
format-volume-padding = 2

label-volume = VOL %percentage%%

label-muted = MUTED
label-muted-foreground = \${color.fg-alt}

; =============================================================================
; BATTERY
; =============================================================================

[module/battery]
type = internal/battery

battery = BAT0
adapter = AC

poll-interval = 2
full-at = 99

format-charging-background = \${color.bg-alt}
format-charging-padding = 2

format-discharging-background = \${color.bg-alt}
format-discharging-padding = 2

format-full-background = \${color.bg-alt}
format-full-padding = 2

label-charging = CHG %percentage%%
label-discharging = BAT %percentage%%
label-full = FULL

; =============================================================================
; NETWORK
; =============================================================================

[module/network]
type = internal/network

interface = $NET_INTERFACE

interval = 2

format-connected-background = \${color.bg-alt}
format-connected-padding = 2

format-disconnected-background = \${color.bg-alt}
format-disconnected-padding = 2

label-connected = ONLINE %local_ip%

label-disconnected = OFFLINE
label-disconnected-foreground = \${color.alert}

; =============================================================================
; DATE
; =============================================================================

[module/date]
type = internal/date

interval = 1

time = %I:%M %p

format-background = \${color.bg-alt}
format-padding = 2

label = %time%
EOF

# =============================================================================
# LAUNCH SCRIPT
# =============================================================================

cat > "$POLYBAR_DIR/launch.sh" << 'EOF'
#!/usr/bin/env bash

pkill -x polybar 2>/dev/null || true

while pgrep -x polybar >/dev/null; do
    sleep 0.5
done

polybar -c ~/.config/polybar/config.ini main \
    >~/.cache/polybar.log 2>&1 &
EOF

chmod +x "$POLYBAR_DIR/launch.sh"

# =============================================================================
# START POLYBAR
# =============================================================================

echo "[*] Launching Matrix Polybar..."

"$POLYBAR_DIR/launch.sh"

sleep 2

echo ""
echo "=================================================="
echo " MATRIX POLYBAR INSTALLED SUCCESSFULLY"
echo "=================================================="
echo ""
echo " Features:"
echo ""
echo "  • Bold green MENU"
echo "  • Bold green POWER"
echo "  • Green FILES module"
echo "  • IP address display"
echo "  • Online/offline status"
echo "  • Matrix green theme"
echo "  • Fully rebuilt Polybar"
echo ""
echo " Polybar log:"
echo " ~/.cache/polybar.log"
echo ""
