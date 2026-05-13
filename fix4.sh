#!/usr/bin/env bash
# =============================================================================
# COMPLETE MATRIX POLYBAR PURGE + REBUILD
# FULLY removes ALL existing Polybar configs/cache/processes
# then installs a fresh Adi1090x-style Matrix Polybar
# =============================================================================

set -euo pipefail

USER_HOME="/home/deathtollz"

POLYBAR_DIR="$USER_HOME/.config/polybar"
CACHE_DIR="$USER_HOME/.cache/polybar"
LOCAL_DIR="$USER_HOME/.local/share/polybar"

ROFI_DIR="$USER_HOME/.config/rofi"
SCRIPT_DIR="$ROFI_DIR/scripts"

echo "=================================================="
echo " COMPLETE MATRIX POLYBAR REBUILD"
echo "=================================================="

sleep 2

# =============================================================================
# STOP ALL POLYBAR INSTANCES
# =============================================================================

echo "[*] Killing Polybar..."

pkill -9 polybar 2>/dev/null || true

sleep 1

# =============================================================================
# REMOVE OLD CONFIGS
# =============================================================================

echo "[*] Removing old Polybar files..."

rm -rf "$POLYBAR_DIR"
rm -rf "$CACHE_DIR"
rm -rf "$LOCAL_DIR"

# Remove possible stray configs
rm -rf "$USER_HOME/.config/bspwm/polybar"
rm -rf "$USER_HOME/.config/polybar.old"
rm -rf "$USER_HOME/.config/polybar.bak"

# Remove launch scripts that may restart old bars
find "$USER_HOME/.config" -type f \( \
-name "launch.sh" -o \
-name "polybar.sh" \
\) -exec rm -f {} \; 2>/dev/null || true

# =============================================================================
# CREATE CLEAN STRUCTURE
# =============================================================================

echo "[*] Creating fresh config..."

mkdir -p "$POLYBAR_DIR"
mkdir -p "$SCRIPT_DIR"

# =============================================================================
# INSTALL REQUIRED PACKAGES
# =============================================================================

echo "[*] Installing required packages..."

if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm \
        polybar \
        rofi \
        networkmanager \
        network-manager-applet \
        pulseaudio \
        pavucontrol \
        ttf-jetbrains-mono-nerd \
        noto-fonts \
        kitty \
        thunar
fi

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

chmod +x "$SCRIPT_DIR/powermenu.sh"

# =============================================================================
# MAIN CONFIG
# =============================================================================

cat > "$POLYBAR_DIR/config.ini" << 'EOF'
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

offset-x = 0
offset-y = 0

background = ${color.bg}
foreground = ${color.fg}

radius-top = 0
radius-bottom = 0

padding = 0

module-margin-left = 0
module-margin-right = 0

font-0 = "Noto Sans:size=9;3"
font-1 = "JetBrainsMono Nerd Font:size=12;3"
font-2 = "JetBrainsMono Nerd Font:size=16;4"

modules-left = menu sep2 term web files settings
modules-center = date
modules-right = sep cpu memory alsa battery network sep sysmenu

separator =

wm-restack = bspwm
enable-ipc = true

cursor-click = pointer

tray-position = none

; =============================================================================
; MENU
; =============================================================================

[module/menu]
type = custom/text

content = "MENU"

content-background = ${color.green}
content-foreground = ${color.black}
content-padding = 3

click-left = ~/.config/rofi/scripts/launcher.sh

; =============================================================================
; POWER
; =============================================================================

[module/sysmenu]
type = custom/text

content = "POWER"

content-background = ${color.bg-alt}
content-foreground = ${color.green}
content-padding = 3

click-left = ~/.config/rofi/scripts/powermenu.sh

; =============================================================================
; SEPARATORS
; =============================================================================

[module/sep]
type = custom/text

content = |
content-foreground = ${color.green-dark}
content-background = ${color.bg-alt}
content-padding = 1

[module/sep2]
type = custom/text

content = |
content-foreground = ${color.bg}
content-background = ${color.bg}
content-padding = 1

; =============================================================================
; APPS
; =============================================================================

[module/term]
type = custom/text

content = TERM
content-foreground = ${color.green}
content-padding = 3

click-left = kitty &

[module/web]
type = custom/text

content = WEB
content-foreground = ${color.green-soft}
content-padding = 3

click-left = firefox &

[module/files]
type = custom/text

content = FILES
content-foreground = ${color.white}
content-padding = 3

click-left = thunar &

[module/settings]
type = custom/text

content = CFG
content-foreground = ${color.alert}
content-padding = 3

click-left = xfce4-settings-manager &

; =============================================================================
; CPU
; =============================================================================

[module/cpu]
type = internal/cpu

interval = 2

format-background = ${color.bg-alt}
format-padding = 2

label = CPU %percentage%%

; =============================================================================
; MEMORY
; =============================================================================

[module/memory]
type = internal/memory

interval = 2

format-background = ${color.bg-alt}
format-padding = 2

label = RAM %percentage_used%%

; =============================================================================
; AUDIO
; =============================================================================

[module/alsa]
type = internal/pulseaudio

format-volume-background = ${color.bg-alt}
format-volume-padding = 2

label-volume = VOL %percentage%%

label-muted = MUTED
label-muted-foreground = ${color.fg-alt}

; =============================================================================
; BATTERY
; =============================================================================

[module/battery]
type = internal/battery

battery = BAT0
adapter = AC

poll-interval = 2
full-at = 99

format-charging-background = ${color.bg-alt}
format-charging-padding = 2

format-discharging-background = ${color.bg-alt}
format-discharging-padding = 2

format-full-background = ${color.bg-alt}
format-full-padding = 2

label-charging = CHG %percentage%%
label-discharging = BAT %percentage%%
label-full = FULL

; =============================================================================
; NETWORK
; =============================================================================

[module/network]
type = internal/network

interface-type = wireless

interval = 1

format-connected-background = ${color.bg-alt}
format-connected-padding = 2

format-disconnected-background = ${color.bg-alt}
format-disconnected-padding = 2

label-connected = ONLINE
label-disconnected = OFFLINE

; =============================================================================
; DATE
; =============================================================================

[module/date]
type = internal/date

interval = 1

time = %I:%M %p

format-background = ${color.bg-alt}
format-padding = 2

label = %time%
EOF

# =============================================================================
# LAUNCH SCRIPT
# =============================================================================

cat > "$POLYBAR_DIR/launch.sh" << 'EOF'
#!/usr/bin/env bash

pkill -9 polybar 2>/dev/null || true

sleep 1

polybar main &
EOF

chmod +x "$POLYBAR_DIR/launch.sh"

# =============================================================================
# START BAR
# =============================================================================

echo "[*] Starting Matrix Polybar..."

"$POLYBAR_DIR/launch.sh"

echo ""
echo "=================================================="
echo " MATRIX POLYBAR SUCCESSFULLY INSTALLED"
echo "=================================================="
echo ""
echo "Everything old was removed:"
echo ""
echo " • old configs"
echo " • old modules"
echo " • old launchers"
echo " • old powermenus"
echo " • old cache"
echo " • old broken themes"
echo ""
echo "Fresh Matrix bar is now active."
echo ""
