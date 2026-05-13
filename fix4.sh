#!/usr/bin/env bash
# =============================================================================
# MATRIX POLYBAR REBUILD
# Based on the provided modern Polybar config
# FULLY removes old Polybar configs/files and rebuilds from scratch
# =============================================================================

set -euo pipefail

USER_HOME="/home/deathtollz"

POLYBAR_DIR="$USER_HOME/.config/polybar"
ROFI_DIR="$USER_HOME/.config/rofi"

SCRIPT_DIR="$POLYBAR_DIR/scripts"

echo "=================================================="
echo " MATRIX POLYBAR MODERN REBUILD"
echo "=================================================="

sleep 2

# =============================================================================
# REMOVE EVERYTHING OLD
# =============================================================================

echo "[*] Killing old Polybar..."

pkill -9 polybar 2>/dev/null || true

sleep 1

echo "[*] Removing ALL old Polybar files..."

rm -rf "$POLYBAR_DIR"
rm -rf "$USER_HOME/.cache/polybar"
rm -rf "$USER_HOME/.local/share/polybar"

mkdir -p "$POLYBAR_DIR"
mkdir -p "$SCRIPT_DIR"

# =============================================================================
# INSTALL DEPENDENCIES
# =============================================================================

if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm \
        polybar \
        rofi \
        networkmanager \
        network-manager-applet \
        pulseaudio \
        pavucontrol \
        jq \
        curl \
        xclip \
        ttf-hack-nerd \
        redshift
fi

# =============================================================================
# MATRIX COLORS
# =============================================================================

cat > "$POLYBAR_DIR/colors.ini" << 'EOF'
[colors]

background = #050805
foreground = #88FF88

disabled = #1A331A

green = #00FF41
green_soft = #44CC44
green_dark = #2FAF2F

white = #E8FFE8

alert = #AAFF44
warning = #88FF88
accent = #00FF41
EOF

# =============================================================================
# INTERNET STATUS SCRIPT
# =============================================================================

cat > "$SCRIPT_DIR/internet-status.sh" << 'EOF'
#!/usr/bin/env bash

if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "ONLINE"
else
    echo "OFFLINE"
fi
EOF

chmod +x "$SCRIPT_DIR/internet-status.sh"

# =============================================================================
# VPN STATUS SCRIPT
# =============================================================================

cat > "$SCRIPT_DIR/vpn-status.sh" << 'EOF'
#!/usr/bin/env bash

if ip a | grep -qi tun0; then
    echo "VPN ON"
else
    echo "VPN OFF"
fi
EOF

chmod +x "$SCRIPT_DIR/vpn-status.sh"

# =============================================================================
# SCOPE STATUS SCRIPT
# =============================================================================

cat > "$SCRIPT_DIR/scope-status.sh" << 'EOF'
#!/usr/bin/env bash

echo "MATRIX"
EOF

chmod +x "$SCRIPT_DIR/scope-status.sh"

# =============================================================================
# COLOR TEMPERATURE SCRIPT
# =============================================================================

cat > "$SCRIPT_DIR/color-temperature-control.sh" << 'EOF'
#!/usr/bin/env bash

TEMP_FILE="/tmp/matrix_temp"

[[ ! -f "$TEMP_FILE" ]] && echo 4500 > "$TEMP_FILE"

TEMP=$(cat "$TEMP_FILE")

case "$1" in

    temperature)
        echo "TEMP ${TEMP}K"
        ;;

    increase)
        TEMP=$((TEMP + 100))
        echo "$TEMP" > "$TEMP_FILE"
        redshift -P -O "$TEMP" >/dev/null 2>&1
        ;;

    decrease)
        TEMP=$((TEMP - 100))
        echo "$TEMP" > "$TEMP_FILE"
        redshift -P -O "$TEMP" >/dev/null 2>&1
        ;;

    toggle)
        redshift -x >/dev/null 2>&1
        ;;
esac
EOF

chmod +x "$SCRIPT_DIR/color-temperature-control.sh"

# =============================================================================
# COPY LOCAL IP
# =============================================================================

cat > "$SCRIPT_DIR/copy-local-ip.sh" << 'EOF'
#!/usr/bin/env bash

hostname -I | awk '{print $1}' | xclip -selection clipboard
EOF

chmod +x "$SCRIPT_DIR/copy-local-ip.sh"

# =============================================================================
# COPY VPN IP
# =============================================================================

cat > "$SCRIPT_DIR/copy-vpn-ip.sh" << 'EOF'
#!/usr/bin/env bash

ip addr show tun0 2>/dev/null | \
grep "inet " | awk '{print $2}' | cut -d/ -f1 | \
xclip -selection clipboard
EOF

chmod +x "$SCRIPT_DIR/copy-vpn-ip.sh"

# =============================================================================
# ROFI POWER MENU
# =============================================================================

mkdir -p "$ROFI_DIR/power-menu"

cat > "$ROFI_DIR/power-menu/power-menu.sh" << 'EOF'
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
        betterlockscreen -l 2>/dev/null || i3lock
        ;;

    SLEEP)
        systemctl suspend
        ;;

    LOGOUT)
        bspc quit
        ;;

    RESTART)
        systemctl reboot
        ;;

    SHUTDOWN)
        systemctl poweroff
        ;;
esac
EOF

chmod +x "$ROFI_DIR/power-menu/power-menu.sh"

# =============================================================================
# ROFI LAUNCHER
# =============================================================================

mkdir -p "$ROFI_DIR/launcher"

cat > "$ROFI_DIR/launcher/launcher.sh" << 'EOF'
#!/usr/bin/env bash

rofi \
-no-config \
-theme ~/.config/rofi/themes/matrix.rasi \
-show drun
EOF

chmod +x "$ROFI_DIR/launcher/launcher.sh"

# =============================================================================
# MAIN POLYBAR CONFIG
# =============================================================================

cat > "$POLYBAR_DIR/config.ini" << EOF
include-file = ~/.config/polybar/colors.ini

[bar/primary]

width = 100%
height = 32

background = \${colors.background}
foreground = \${colors.foreground}

line-size = 2

padding-left = 0
padding-right = 0

module-margin = 0

separator = ""

font-0 = "Hack Nerd Font:size=13;3"
font-1 = "Hack Nerd Font:size=17;3"

modules-left = launcher internet_status vpn scope_manager
modules-center = xworkspaces
modules-right = pulseaudio date color_temperature power_menu

cursor-click = pointer
cursor-scroll = pointer

enable-ipc = true

wm-restack = bspwm

pseudo-transparency = true

; =============================================================================
; WORKSPACES
; =============================================================================

[module/xworkspaces]
type = internal/xworkspaces

label-active = "◆"
label-active-font = 2
label-active-padding = 1
label-active-underline = \${colors.green}

label-occupied = "❖"
label-occupied-font = 2
label-occupied-padding = 1

label-empty = "◇"
label-empty-font = 2
label-empty-padding = 1
label-empty-foreground = \${colors.white}

; =============================================================================
; AUDIO
; =============================================================================

[module/pulseaudio]
type = internal/pulseaudio

use-ui-max = false

format-volume = "<label-volume><bar-volume> %{F#1A331A}|"

label-volume = "  VOL "
label-volume-foreground = \${colors.green}

format-muted-prefix = "  MUTED "
format-muted-foreground = \${colors.green_soft}

label-muted = "%{F#E8FFE8}Muted %{F#1A331A}|"

interval = 5

bar-volume-width = 11
bar-volume-foreground-0 = \${colors.green}

bar-volume-gradient = false

bar-volume-indicator = ""
bar-volume-fill = "━"
bar-volume-empty = "━"

bar-volume-empty-foreground = \${colors.white}

; =============================================================================
; DATE
; =============================================================================

[module/date]
type = internal/date

interval = 1

date = %H:%M

label = " TIME %date% "

label-foreground = \${colors.green_soft}

; =============================================================================
; INTERNET
; =============================================================================

[module/internet_status]
type = custom/script

interval = 5

exec = ~/.config/polybar/scripts/internet-status.sh

click-left = ~/.config/polybar/scripts/copy-local-ip.sh

format = " %output% "

; =============================================================================
; VPN
; =============================================================================

[module/vpn]
type = custom/script

interval = 5

exec = ~/.config/polybar/scripts/vpn-status.sh

click-left = ~/.config/polybar/scripts/copy-vpn-ip.sh

format = " %output% "

; =============================================================================
; SCOPE
; =============================================================================

[module/scope_manager]
type = custom/script

interval = 5

exec = ~/.config/polybar/scripts/scope-status.sh

format = " %output% "

; =============================================================================
; LAUNCHER
; =============================================================================

[module/launcher]
type = custom/text

format = " MENU "

format-foreground = \${colors.white}

click-left = ~/.config/rofi/launcher/launcher.sh

; =============================================================================
; POWER MENU
; =============================================================================

[module/power_menu]
type = custom/text

format = " POWER "

format-foreground = \${colors.alert}

click-left = ~/.config/rofi/power-menu/power-menu.sh

; =============================================================================
; COLOR TEMP
; =============================================================================

[module/color_temperature]
type = custom/script

exec = bash -c "~/.config/polybar/scripts/color-temperature-control.sh temperature"

click-left = bash -c "~/.config/polybar/scripts/color-temperature-control.sh toggle"

scroll-up = bash -c "~/.config/polybar/scripts/color-temperature-control.sh increase"

scroll-down = bash -c "~/.config/polybar/scripts/color-temperature-control.sh decrease"

interval = 1

[settings]

screenchange-reload = true
pseudo-transparency = true
EOF

# =============================================================================
# LAUNCH SCRIPT
# =============================================================================

cat > "$POLYBAR_DIR/launch.sh" << 'EOF'
#!/usr/bin/env bash

pkill -9 polybar 2>/dev/null || true

sleep 1

polybar primary &
EOF

chmod +x "$POLYBAR_DIR/launch.sh"

# =============================================================================
# START POLYBAR
# =============================================================================

echo "[*] Starting Matrix Polybar..."

"$POLYBAR_DIR/launch.sh"

echo ""
echo "=================================================="
echo " MATRIX POLYBAR INSTALLED"
echo "=================================================="
echo ""
echo "FEATURES:"
echo ""
echo " • Modern clean layout"
echo " • Matrix green theme"
echo " • Animated volume bar"
echo " • Workspace diamonds"
echo " • VPN status"
echo " • Internet status"
echo " • Color temperature control"
echo " • Matrix Rofi launcher"
echo " • Matrix power menu"
echo ""
echo "RUN MANUALLY:"
echo ""
echo "    ~/.config/polybar/launch.sh"
echo ""
