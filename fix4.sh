#!/usr/bin/env bash
# =============================================================================
# MATRIX POLYBAR REBUILD (FULL CLEAN INSTALL)
# Completely removes old Polybar configs and builds a fresh Matrix setup
# =============================================================================

set -euo pipefail

USER_HOME="/home/deathtollz"

POLYBAR_DIR="$USER_HOME/.config/polybar"
ROFI_DIR="$USER_HOME/.config/rofi"
SCRIPT_DIR="$ROFI_DIR/scripts"

echo "=================================================="
echo " MATRIX POLYBAR FULL REBUILD"
echo "=================================================="

sleep 2

# =============================================================================
# BACKUP OLD CONFIG
# =============================================================================

if [[ -d "$POLYBAR_DIR" ]]; then
    echo "[*] Backing up old Polybar..."
    mv "$POLYBAR_DIR" "$POLYBAR_DIR.bak.$(date +%s)"
fi

# =============================================================================
# CLEAN INSTALL
# =============================================================================

mkdir -p "$POLYBAR_DIR"
mkdir -p "$SCRIPT_DIR"

# =============================================================================
# COLORS
# =============================================================================

cat > "$POLYBAR_DIR/colors.ini" << 'EOF'
[colors]

background = #CC050805
background-alt = #111111

foreground = #88FF88
foreground-alt = #44CC44

primary = #00FF41
secondary = #44CC44
alert = #AAFF44

white = #E8FFE8
black = #000000
EOF

# =============================================================================
# POWERMENU SCRIPT
# =============================================================================

cat > "$SCRIPT_DIR/powermenu.sh" << 'EOF'
#!/usr/bin/env bash

chosen=$(printf " Lock\n Sleep\n Logout\n Restart\n Shutdown" | \
rofi \
-no-config \
-theme ~/.config/rofi/themes/matrix.rasi \
-dmenu \
-i \
-p "󰣇 Power")

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

chmod +x "$SCRIPT_DIR/powermenu.sh"

# =============================================================================
# LAUNCHER SCRIPT
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
# POLYBAR CONFIG
# =============================================================================

cat > "$POLYBAR_DIR/config.ini" << 'EOF'
include-file = ~/.config/polybar/colors.ini

[bar/main]

width = 100%
height = 34

radius = 0

fixed-center = true

background = ${colors.background}
foreground = ${colors.foreground}

line-size = 0
border-size = 0

padding-left = 2
padding-right = 2

module-margin = 1

font-0 = "JetBrainsMono Nerd Font:size=11;3"
font-1 = "JetBrainsMono Nerd Font:size=16;4"

modules-left = launcher bspwm
modules-center = date
modules-right = cpu memory pulseaudio network powermenu

cursor-click = pointer
cursor-scroll = ns-resize

enable-ipc = true

wm-restack = bspwm

; =============================================================================
; LAUNCHER
; =============================================================================

[module/launcher]
type = custom/text

content = "󰣇"

content-font = 2
content-padding = 2

content-foreground = ${colors.primary}

click-left = ~/.config/rofi/scripts/launcher.sh

; =============================================================================
; BSPWM
; =============================================================================

[module/bspwm]
type = internal/bspwm

pin-workspaces = true
inline-mode = false

format = <label-state>

label-focused = %name%
label-focused-background = ${colors.primary}
label-focused-foreground = ${colors.black}
label-focused-padding = 2

label-occupied = %name%
label-occupied-padding = 2

label-empty = %name%
label-empty-foreground = ${colors.foreground-alt}
label-empty-padding = 2

; =============================================================================
; CPU
; =============================================================================

[module/cpu]
type = internal/cpu

interval = 2

format-prefix = "󰍛 "
format-prefix-foreground = ${colors.primary}

label = %percentage%%

; =============================================================================
; MEMORY
; =============================================================================

[module/memory]
type = internal/memory

interval = 2

format-prefix = "󰑭 "
format-prefix-foreground = ${colors.primary}

label = %percentage_used%%

; =============================================================================
; AUDIO
; =============================================================================

[module/pulseaudio]
type = internal/pulseaudio

format-volume-prefix = "󰕾 "
format-volume-prefix-foreground = ${colors.primary}

label-volume = %percentage%%

label-muted = muted
label-muted-foreground = ${colors.foreground-alt}

; =============================================================================
; NETWORK
; =============================================================================

[module/network]
type = internal/network

interface-type = wireless

interval = 3

format-connected-prefix = "󰖩 "
format-connected-prefix-foreground = ${colors.primary}

label-connected = %essid%

label-disconnected = offline
label-disconnected-foreground = ${colors.foreground-alt}

; =============================================================================
; DATE
; =============================================================================

[module/date]
type = internal/date

interval = 1

date = %Y-%m-%d%
time = %H:%M

label = 󰥔 %date%  %time%

label-foreground = ${colors.white}

; =============================================================================
; POWERMENU
; =============================================================================

[module/powermenu]
type = custom/text

content = "⏻"

content-font = 2
content-padding = 2

content-foreground = ${colors.primary}

click-left = ~/.config/rofi/scripts/powermenu.sh
EOF

# =============================================================================
# LAUNCH SCRIPT
# =============================================================================

cat > "$POLYBAR_DIR/launch.sh" << 'EOF'
#!/usr/bin/env bash

pkill polybar 2>/dev/null || true

sleep 1

polybar main &
EOF

chmod +x "$POLYBAR_DIR/launch.sh"

# =============================================================================
# RESTART
# =============================================================================

echo "[*] Restarting Polybar..."

pkill polybar 2>/dev/null || true

sleep 1

"$POLYBAR_DIR/launch.sh"

echo ""
echo "=================================================="
echo " MATRIX POLYBAR INSTALLED"
echo "=================================================="
echo ""
echo "FEATURES:"
echo ""
echo " • Matrix green cyber theme"
echo " • Rofi launcher"
echo " • Matrix power menu"
echo " • BSPWM workspaces"
echo " • CPU"
echo " • RAM"
echo " • Audio"
echo " • WiFi"
echo " • Clock"
echo ""
echo "KEYBINDS:"
echo ""
echo " SUPER + D            → Rofi"
echo " SUPER + SHIFT + E    → Powermenu"
echo ""
echo "If Polybar does not appear:"
echo ""
echo "    ~/.config/polybar/launch.sh"
echo ""
