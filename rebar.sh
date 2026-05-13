#!/usr/bin/env bash
# =============================================================================
# POLYBAR REBUILD — Matrix green theme, Kali-compatible
# Layout: [⠿ IP ⛨ status] [● dots] [⊙ target ♪ vol ⏱ time ⏻]
# Fix: VPN_IP unbound variable moved to external script (no heredoc expansion)
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
mkdir -p "$CACHE_DIR"
mkdir -p "$SCRIPT_DIR"
mkdir -p "$THEME_DIR"

# =============================================================================
# INSTALL PACKAGES
# Kali Linux = apt; Arch = pacman
# =============================================================================
echo "[*] Installing dependencies..."
if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm \
        polybar rofi networkmanager network-manager-applet \
        pulseaudio pavucontrol noto-fonts ttf-jetbrains-mono-nerd \
        ttf-font-awesome bspwm sxhkd i3lock

elif command -v apt >/dev/null 2>&1; then
    sudo apt install -y \
        polybar rofi network-manager \
        pulseaudio pulseaudio-utils pavucontrol \
        fonts-noto fonts-noto-extra \
        bspwm sxhkd i3lock curl

    # JetBrainsMono Nerd Font (not in apt — install manually to ~/.local/share/fonts)
    if ! fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then
        echo "[*] Installing JetBrainsMono Nerd Font..."
        FONT_DIR="$USER_HOME/.local/share/fonts"
        mkdir -p "$FONT_DIR"
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
        TMP_FONT="/tmp/JetBrainsMono.tar.xz"
        if curl -fsSL "$FONT_URL" -o "$TMP_FONT" 2>/dev/null; then
            tar -xf "$TMP_FONT" -C "$FONT_DIR" --wildcards "*.ttf" 2>/dev/null || true
            fc-cache -fv "$FONT_DIR" >/dev/null 2>&1
            rm -f "$TMP_FONT"
            echo "[*] Nerd Font installed."
        else
            echo "[!] Could not download Nerd Font — icons may not render correctly."
        fi
    else
        echo "[*] JetBrainsMono Nerd Font already installed."
    fi
fi

# =============================================================================
# AUTO DETECT NETWORK INTERFACE
# =============================================================================
NET_INTERFACE=$(ip route 2>/dev/null | awk '/default/ {print $5}' | head -n1 || true)
if [[ -z "${NET_INTERFACE:-}" ]]; then
    NET_INTERFACE="eth0"
fi
echo "[*] Detected interface: $NET_INTERFACE"

# =============================================================================
# TARGET FILE (HTB/CTF)
# echo "10.10.11.1" > ~/.target   -> shows IP
# echo ""           > ~/.target   -> shows "No target"
# =============================================================================
TARGET_FILE="$USER_HOME/.target"
[[ -f "$TARGET_FILE" ]] || touch "$TARGET_FILE"

# =============================================================================
# EXTERNAL SCRIPTS
# All use single-quoted heredocs ('EOF') so shell variables inside
# are NOT expanded by this script — this was the root cause of the
# "VPN_IP: unbound variable" crash when using set -euo pipefail.
# =============================================================================

# --- VPN / network status ---
cat > "$POLYBAR_DIR/vpn.sh" << 'VPNEOF'
#!/usr/bin/env bash
if ip link show tun0 2>/dev/null | grep -q "state UP"; then
    VPN_IP=$(ip -4 addr show tun0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
    echo " ${VPN_IP:-VPN}"
else
    DEFAULT=$(ip -4 route show default 2>/dev/null | head -n1)
    if [[ -n "$DEFAULT" ]]; then
        echo " Disconnected"
    else
        echo " Disconnected"
    fi
fi
VPNEOF
chmod +x "$POLYBAR_DIR/vpn.sh"

# --- Target display ---
cat > "$POLYBAR_DIR/target.sh" << 'TARGETEOF'
#!/usr/bin/env bash
TARGET_FILE="$HOME/.target"
if [[ -f "$TARGET_FILE" ]]; then
    TARGET=$(tr -d '[:space:]' < "$TARGET_FILE")
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

# --- Set / clear target on click ---
cat > "$POLYBAR_DIR/set_target.sh" << 'SETEOF'
#!/usr/bin/env bash
TARGET_FILE="$HOME/.target"
CURRENT=$(tr -d '[:space:]' < "$TARGET_FILE" 2>/dev/null || true)
if [[ -n "$CURRENT" ]]; then
    echo "" > "$TARGET_FILE"
else
    NEW=$(echo "" | rofi -dmenu -p " Set target IP:" \
        -theme ~/.config/rofi/themes/pentest.rasi 2>/dev/null || true)
    [[ -n "$NEW" ]] && echo "$NEW" > "$TARGET_FILE"
fi
SETEOF
chmod +x "$POLYBAR_DIR/set_target.sh"

# --- Rofi Matrix theme ---
cat > "$THEME_DIR/pentest.rasi" << 'ROFIEOF'
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
listview { margin: 4px; }
element { padding: 7px; }
element selected {
    background-color: @ac;
    text-color: @bg;
}
ROFIEOF

# --- Rofi app launcher ---
cat > "$SCRIPT_DIR/launcher.sh" << 'LAUNCHEOF'
#!/usr/bin/env bash
rofi -no-config -theme ~/.config/rofi/themes/pentest.rasi -show drun
LAUNCHEOF
chmod +x "$SCRIPT_DIR/launcher.sh"

# --- Power menu ---
cat > "$SCRIPT_DIR/powermenu.sh" << 'POWEREOF'
#!/usr/bin/env bash
chosen=$(printf "LOCK\nSLEEP\nLOGOUT\nRESTART\nSHUTDOWN" | \
    rofi -no-config \
         -theme ~/.config/rofi/themes/pentest.rasi \
         -dmenu -i -p " POWER")
case "$chosen" in
    LOCK)     i3lock ;;
    SLEEP)    systemctl suspend ;;
    LOGOUT)   bspc quit 2>/dev/null || pkill -KILL -u "$USER" ;;
    RESTART)  systemctl reboot ;;
    SHUTDOWN) systemctl poweroff ;;
esac
POWEREOF
chmod +x "$SCRIPT_DIR/powermenu.sh"

# =============================================================================
# POLYBAR CONFIG
# This heredoc is unquoted (EOF not 'EOF') so $NET_INTERFACE expands correctly.
# All polybar variables use \${...} to prevent the outer shell expanding them.
# =============================================================================
cat > "$POLYBAR_DIR/config.ini" << EOF
; =============================================================================
; COLORS — Matrix green on deep black
; =============================================================================
[color]
bg         = #050805
bg-mod     = #101510
bg-right   = #101510
fg         = #88FF88
fg-dim     = #44CC44
fg-muted   = #2A6B2A
green      = #00FF41
green-soft = #44CC44
green-dark = #2FAF2F
white      = #E8FFE8
alert      = #AAFF44
sep-col    = #1A3A1A

; =============================================================================
; BAR
; =============================================================================
[bar/main]
monitor          =
width            = 100%
height           = 26
offset-x         = 0
offset-y         = 0
radius           = 0
fixed-center     = true

background       = \${color.bg}
foreground       = \${color.fg}

line-size        = 0
border-size      = 0
padding-left     = 0
padding-right    = 0
module-margin-left  = 0
module-margin-right = 0

font-0 = "JetBrainsMono Nerd Font:style=Bold:size=9;3"
font-1 = "Noto Sans:style=Bold:size=9;3"
font-2 = "JetBrainsMono Nerd Font:style=Regular:size=11;3"

modules-left   = menu space ip sep1 vpn-status
modules-center = bspwm
modules-right  = sep2 target sep3 volume sep4 date sep5 power

separator     =
enable-ipc    = true
cursor-click  = pointer
tray-position = none

; =============================================================================
; LEFT — MENU (click to open rofi launcher)
; =============================================================================
[module/menu]
type               = custom/text
content            = " ⠿ "
content-foreground = \${color.green}
content-background = \${color.bg-mod}
click-left         = ~/.config/rofi/scripts/launcher.sh &

; =============================================================================
; LEFT — SPACER
; =============================================================================
[module/space]
type               = custom/text
content            = " "
content-background = \${color.bg}

; =============================================================================
; LEFT — IP ADDRESS (auto-detected interface: $NET_INTERFACE)
; =============================================================================
[module/ip]
type           = custom/script
exec           = ip -4 addr show $NET_INTERFACE 2>/dev/null | awk '/inet / {print \$2}' | cut -d/ -f1 | head -n1
interval       = 10
format-padding    = 1
format-foreground = \${color.white}
format-background = \${color.bg}

; =============================================================================
; LEFT — SEPARATOR
; =============================================================================
[module/sep1]
type               = custom/text
content            = "  "
content-background = \${color.bg}

; =============================================================================
; LEFT — VPN / NETWORK STATUS
; External script avoids the "unbound variable" crash from the prior version.
; =============================================================================
[module/vpn-status]
type           = custom/script
exec           = ~/.config/polybar/vpn.sh
interval       = 5
format-padding    = 1
format-foreground = \${color.fg-dim}
format-background = \${color.bg}

; =============================================================================
; CENTER — BSPWM WORKSPACES  ● focused  ● occupied  ○ empty
; =============================================================================
[module/bspwm]
type           = internal/bspwm
pin-workspaces = false
enable-click   = true
enable-scroll  = false

label-focused             = ●
label-focused-foreground  = \${color.green}
label-focused-background  = \${color.bg}
label-focused-padding     = 1

label-occupied            = ●
label-occupied-foreground = \${color.green-soft}
label-occupied-background = \${color.bg}
label-occupied-padding    = 1

label-urgent              = ●
label-urgent-foreground   = \${color.alert}
label-urgent-background   = \${color.bg}
label-urgent-padding      = 1

label-empty               = ○
label-empty-foreground    = \${color.fg-muted}
label-empty-background    = \${color.bg}
label-empty-padding       = 1

; =============================================================================
; RIGHT — SEPARATORS
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
; RIGHT — TARGET (HTB/CTF)
; Left-click: prompt for IP  |  Right-click: clear
; =============================================================================
[module/target]
type           = custom/script
exec           = ~/.config/polybar/target.sh
interval       = 3
format-background = \${color.bg-right}
format-foreground = \${color.green}
format-padding    = 1
click-left        = ~/.config/polybar/set_target.sh &
click-right       = echo "" > ~/.target

; =============================================================================
; RIGHT — VOLUME (PulseAudio)
; =============================================================================
[module/volume]
type                     = internal/pulseaudio
use-ui-max               = false
interval                 = 2

format-volume-background = \${color.bg-right}
format-volume-foreground = \${color.fg}
format-volume-padding    = 1
label-volume             = " %percentage%%"

format-muted-background  = \${color.bg-right}
format-muted-foreground  = \${color.fg-muted}
format-muted-padding     = 1
label-muted              = " muted"

click-right              = pavucontrol &

; =============================================================================
; RIGHT — TIME
; =============================================================================
[module/date]
type              = internal/date
interval          = 1
time              = " %I:%M %p"
format-background = \${color.bg-right}
format-foreground = \${color.fg}
format-padding    = 1
label             = %time%

; =============================================================================
; RIGHT — POWER BUTTON
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
cat > "$POLYBAR_DIR/launch.sh" << 'LEOF'
#!/usr/bin/env bash
pkill -x polybar 2>/dev/null || true
while pgrep -x polybar >/dev/null; do
    sleep 0.5
done
mkdir -p ~/.cache/polybar
polybar -c ~/.config/polybar/config.ini main \
    >~/.cache/polybar/main.log 2>&1 &
echo "[*] Polybar launched (PID $!)"
LEOF
chmod +x "$POLYBAR_DIR/launch.sh"

# =============================================================================
# LAUNCH
# =============================================================================
echo "[*] Launching Polybar..."
"$POLYBAR_DIR/launch.sh"
sleep 2

if pgrep -x polybar >/dev/null; then
    echo ""
    echo "=================================================="
    echo " POLYBAR RUNNING"
    echo "=================================================="
    echo ""
    echo " Layout:"
    echo "  LEFT:   ⠿  $NET_INTERFACE IP  ⛨ Disconnected/Connected"
    echo "  CENTER: ● ○ ○ ○ ○ ○ ○ ○ ○ ○  (bspwm dots)"
    echo "  RIGHT:  ⊙ No target | ♪ vol% | ⏱ time | ⏻"
    echo ""
    echo " Target module:"
    echo "  Left-click  → prompt for IP via rofi"
    echo "  Right-click → clear"
    echo "  Manual:  echo '10.10.11.1' > ~/.target"
    echo ""
    echo " Log: ~/.cache/polybar/main.log"
else
    echo ""
    echo "[!] Polybar failed to start. Log:"
    cat "$CACHE_DIR/main.log" 2>/dev/null || true
    exit 1
fi
