#!/usr/bin/env bash
# =============================================================================
# POLYBAR REBUILD — matches screenshot layout exactly
# Matrix green theme • dot workspaces • pentesting "No target" module
# =============================================================================
set -euo pipefail

USER_HOME="/home/deathtollz"
POLYBAR_DIR="$USER_HOME/.config/polybar"
CACHE_DIR="$USER_HOME/.cache/polybar"
ROFI_DIR="$USER_HOME/.config/rofi"
SCRIPT_DIR="$ROFI_DIR/scripts"
THEME_DIR="$ROFI_DIR/themes"

echo "=================================================="
echo " POLYBAR REBUILD — MATRIX GREEN / PENTEST THEME"
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

# =============================================================================
# CREATE DIRECTORIES
# =============================================================================
echo "[*] Creating directories..."
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
        ttf-font-awesome \
        bspwm \
        i3lock
elif command -v apt >/dev/null 2>&1; then
    sudo apt install -y \
        polybar \
        rofi \
        network-manager \
        pulseaudio \
        pavucontrol \
        fonts-noto \
        bspwm
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
# TARGET FILE — used by "No target" module (HTB/CTF style)
# Write an IP to this file to show it: echo "10.10.11.1" > ~/.target
# Clear it to show "No target": echo "" > ~/.target
# =============================================================================
TARGET_FILE="$USER_HOME/.target"
if [[ ! -f "$TARGET_FILE" ]]; then
    touch "$TARGET_FILE"
fi

# =============================================================================
# SCRIPTS
# =============================================================================

# --- Target module script ---
cat > "$POLYBAR_DIR/target.sh" << 'TARGETEOF'
#!/usr/bin/env bash
TARGET_FILE="$HOME/.target"
if [[ -f "$TARGET_FILE" ]]; then
    TARGET=$(cat "$TARGET_FILE" | tr -d '[:space:]')
    if [[ -n "$TARGET" ]]; then
        echo " $TARGET"
    else
        echo " No target"
    fi
else
    echo " No target"
fi
TARGETEOF
chmod +x "$POLYBAR_DIR/target.sh"

# --- Set/clear target script (click to set) ---
cat > "$POLYBAR_DIR/set_target.sh" << 'SETTARGETEOF'
#!/usr/bin/env bash
TARGET_FILE="$HOME/.target"
CURRENT=$(cat "$TARGET_FILE" 2>/dev/null | tr -d '[:space:]')
if [[ -n "$CURRENT" ]]; then
    # If a target is set, clear it on click
    echo "" > "$TARGET_FILE"
else
    # Otherwise prompt for new target via rofi
    NEW=$(echo "" | rofi -dmenu -p "Set target IP:" -theme ~/.config/rofi/themes/pentest.rasi 2>/dev/null || true)
    if [[ -n "$NEW" ]]; then
        echo "$NEW" > "$TARGET_FILE"
    fi
fi
SETTARGETEOF
chmod +x "$POLYBAR_DIR/set_target.sh"

# --- Rofi theme (Matrix green) ---
cat > "$THEME_DIR/pentest.rasi" << 'EOF'
* {
    bg:     #050805;
    bg-alt: #101510;
    fg:     #00FF41;
    ac:     #00FF41;
    background-color: @bg;
    text-color:       @fg;
    border-color:     @ac;
    font: "JetBrainsMono Nerd Font Bold 10";
}
window {
    width: 28%;
    border: 1px;
    padding: 12px;
    background-color: @bg;
}
inputbar {
    padding: 8px;
    margin: 6px;
    border: 1px;
    border-color: @ac;
    background-color: @bg-alt;
}
listview {
    margin: 4px;
}
element {
    padding: 7px;
}
element selected {
    background-color: @ac;
    text-color: @bg;
}
EOF

# --- Rofi launcher script ---
cat > "$SCRIPT_DIR/launcher.sh" << 'EOF'
#!/usr/bin/env bash
rofi \
    -no-config \
    -theme ~/.config/rofi/themes/pentest.rasi \
    -show drun
EOF
chmod +x "$SCRIPT_DIR/launcher.sh"

# --- Power menu script ---
cat > "$SCRIPT_DIR/powermenu.sh" << 'EOF'
#!/usr/bin/env bash
chosen=$(printf "LOCK\nSLEEP\nLOGOUT\nRESTART\nSHUTDOWN" | \
    rofi \
    -no-config \
    -theme ~/.config/rofi/themes/pentest.rasi \
    -dmenu \
    -i \
    -p " POWER")
case "$chosen" in
    LOCK)     i3lock ;;
    SLEEP)    systemctl suspend ;;
    LOGOUT)   bspc quit 2>/dev/null || pkill -KILL -u "$USER" ;;
    RESTART)  systemctl reboot ;;
    SHUTDOWN) systemctl poweroff ;;
esac
EOF
chmod +x "$SCRIPT_DIR/powermenu.sh"

# =============================================================================
# POLYBAR CONFIG
# Layout (matches screenshot):
#   LEFT:   [⠿ menu] [IP address] [shield Disconnected]
#   CENTER: [● ○ ○ ○ ○ ○ ○ ○ ○ ○]  <- bspwm workspaces as dots
#   RIGHT:  [⊙ No target] [♪ 40%] [⏱ 10:21 PM] [⏻]
# =============================================================================
cat > "$POLYBAR_DIR/config.ini" << EOF
; =============================================================================
; COLORS — Matrix green on deep black
; =============================================================================
[color]
bg          = #050805
bg-mod      = #101510
bg-right    = #101510
fg          = #88FF88
fg-dim      = #44CC44
fg-muted    = #2A6B2A
green       = #00FF41
green-soft  = #44CC44
green-dark  = #2FAF2F
white       = #E8FFE8
alert       = #AAFF44
sep-col     = #1A3A1A

; =============================================================================
; BAR
; =============================================================================
[bar/main]
monitor           =
width             = 100%
height            = 26
offset-x          = 0
offset-y          = 0
radius            = 0
fixed-center      = true

background        = \${color.bg}
foreground        = \${color.fg}

line-size         = 0
border-size       = 0

padding-left      = 0
padding-right     = 0
module-margin-left  = 0
module-margin-right = 0

; Nerd Font for icons + regular glyphs
font-0 = "JetBrainsMono Nerd Font:style=Bold:size=9;3"
font-1 = "Noto Sans:style=Bold:size=9;3"
font-2 = "JetBrainsMono Nerd Font:style=Regular:size=11;3"

modules-left   = menu space ip sep1 vpn-status
modules-center = bspwm
modules-right  = sep2 target sep3 volume sep4 date sep5 power

separator      =
enable-ipc     = true
cursor-click   = pointer
tray-position  = none

; =============================================================================
; LEFT — MENU (grid icon, clickable launcher)
; =============================================================================
[module/menu]
type                = custom/text
content             = " ⠿ "
content-foreground  = \${color.green}
content-background  = \${color.bg-mod}
click-left          = ~/.config/rofi/scripts/launcher.sh &

; =============================================================================
; LEFT — SPACER
; =============================================================================
[module/space]
type                = custom/text
content             = " "
content-background  = \${color.bg}

; =============================================================================
; LEFT — IP ADDRESS
; =============================================================================
[module/ip]
type     = custom/script
exec     = ip -4 addr show | awk '/inet / && !/127.0.0.1/ {print \$2}' | cut -d/ -f1 | head -n1
interval = 10
format-padding     = 1
format-foreground  = \${color.white}
format-background  = \${color.bg}

; =============================================================================
; LEFT — SEPARATOR 1
; =============================================================================
[module/sep1]
type               = custom/text
content            = "  "
content-background = \${color.bg}

; =============================================================================
; LEFT — VPN / NETWORK STATUS  (shield icon + Disconnected / Connected)
; Shows VPN if tun0 is up, else shows wifi/eth status
; =============================================================================
[module/vpn-status]
type     = custom/script
interval = 5
exec     = bash -c '
if ip link show tun0 2>/dev/null | grep -q "state UP"; then
    VPN_IP=$(ip -4 addr show tun0 2>/dev/null | awk "/inet / {print \$2}" | cut -d/ -f1)
    echo " Connected ${VPN_IP}"
else
    # Check if any non-loopback interface is UP with an IP
    ONLINE=$(ip -4 route show default 2>/dev/null | head -n1)
    if [[ -n "$ONLINE" ]]; then
        echo " Disconnected"
    else
        echo " Disconnected"
    fi
fi'
format-padding     = 1
format-foreground  = \${color.fg-dim}
format-background  = \${color.bg}

; =============================================================================
; CENTER — BSPWM WORKSPACES (dot style matching screenshot)
; ● = focused/active  ● = occupied  ○ = empty
; =============================================================================
[module/bspwm]
type            = internal/bspwm
pin-workspaces  = false
enable-click    = true
enable-scroll   = false

; Active/focused workspace — filled dot, bright
label-focused             = ●
label-focused-foreground  = \${color.green}
label-focused-background  = \${color.bg}
label-focused-padding     = 1

; Occupied (has windows) — filled dot, dim
label-occupied            = ●
label-occupied-foreground = \${color.green-soft}
label-occupied-background = \${color.bg}
label-occupied-padding    = 1

; Urgent workspace — alert colour
label-urgent              = ●
label-urgent-foreground   = \${color.alert}
label-urgent-background   = \${color.bg}
label-urgent-padding      = 1

; Empty — hollow dot, muted
label-empty               = ○
label-empty-foreground    = \${color.fg-muted}
label-empty-background    = \${color.bg}
label-empty-padding       = 1

; =============================================================================
; RIGHT SEPARATORS (thin coloured dividers)
; =============================================================================
[module/sep2]
type               = custom/text
content            = " "
content-background = \${color.bg}

[module/sep3]
type               = custom/text
content            = "  "
content-foreground = \${color.sep-col}
content-background = \${color.bg-right}

[module/sep4]
type               = custom/text
content            = "  "
content-foreground = \${color.sep-col}
content-background = \${color.bg-right}

[module/sep5]
type               = custom/text
content            = "  "
content-foreground = \${color.sep-col}
content-background = \${color.bg-right}

; =============================================================================
; RIGHT — TARGET (HTB/CTF pentest module)
; Shows "No target" until ~/.target contains an IP
; Left-click: set target | Right-click: clear target
; =============================================================================
[module/target]
type               = custom/script
exec               = ~/.config/polybar/target.sh
interval           = 3
format-background  = \${color.bg-right}
format-foreground  = \${color.green}
format-padding     = 1
click-left         = ~/.config/polybar/set_target.sh &
click-right        = echo "" > ~/.target

; =============================================================================
; RIGHT — VOLUME (PulseAudio)
; =============================================================================
[module/volume]
type                       = internal/pulseaudio
use-ui-max                 = false
interval                   = 2

format-volume-background   = \${color.bg-right}
format-volume-foreground   = \${color.fg}
format-volume-padding      = 1
label-volume               = " %percentage%%"

format-muted-background    = \${color.bg-right}
format-muted-foreground    = \${color.fg-muted}
format-muted-padding       = 1
label-muted                = " muted"

click-right                = pavucontrol &

; =============================================================================
; RIGHT — DATE / TIME  (matching "10:21 PM" format)
; =============================================================================
[module/date]
type               = internal/date
interval           = 1
time               = " %I:%M %p"
format-background  = \${color.bg-right}
format-foreground  = \${color.fg}
format-padding     = 1
label              = %time%

; =============================================================================
; RIGHT — POWER BUTTON (circle icon, far right)
; =============================================================================
[module/power]
type               = custom/text
content            = " ⏻ "
content-foreground = \${color.green-dark}
content-background = \${color.bg-right}
click-left         = ~/.config/rofi/scripts/powermenu.sh &
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
mkdir -p ~/.cache/polybar
polybar -c ~/.config/polybar/config.ini main \
    >~/.cache/polybar/main.log 2>&1 &
echo "[*] Polybar launched (PID $!)"
EOF
chmod +x "$POLYBAR_DIR/launch.sh"

# =============================================================================
# LAUNCH
# =============================================================================
echo "[*] Launching Polybar..."
"$POLYBAR_DIR/launch.sh"
sleep 2

# Verify it started
if pgrep -x polybar >/dev/null; then
    echo ""
    echo "=================================================="
    echo " POLYBAR RUNNING"
    echo "=================================================="
else
    echo ""
    echo "[!] Polybar failed — check log:"
    cat ~/.cache/polybar/main.log 2>/dev/null || true
    exit 1
fi

echo ""
echo " Layout:"
echo "  LEFT:   ⠿ menu  |  IP address  |  shield + Disconnected/Connected"
echo "  CENTER: ● ○ ○ ○ ○ ○ ○ ○ ○ ○   (bspwm dot workspaces)"
echo "  RIGHT:  ⊙ No target  |  ♪ vol%  |  ⏱ time  |  ⏻ power"
echo ""
echo " Target module:"
echo "  Left-click  → prompt for IP  (echo '10.10.11.1' > ~/.target)"
echo "  Right-click → clear target   (echo '' > ~/.target)"
echo ""
echo " Log: ~/.cache/polybar/main.log"
echo ""
