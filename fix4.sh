#!/usr/bin/env bash
# =============================================================================
#  matrix-polybar-rebuild.sh
#  Wipes all old polybar configs and rebuilds from scratch in Matrix green.
#  Layout matches the screenshot: IP | VPN | workspaces | scope | % | time | power
# =============================================================================

set -euo pipefail

USER_HOME="/home/deathtollz"
POLYBAR_DIR="$USER_HOME/.config/polybar"
ROFI_DIR="$USER_HOME/.config/rofi"
SCRIPT_DIR="$POLYBAR_DIR/scripts"

# ── Colors ────────────────────────────────────────────────────────────────────
BG="#050805"
BG_MOD="#0A100A"       # slightly lighter — module pill backgrounds
BG_SEP="#0F180F"       # separator shade
FG="#88FF88"
GREEN="#00FF41"
GREEN_SOFT="#44CC44"
GREEN_DARK="#2FAF2F"
GREEN_DIM="#1A331A"
WHITE="#E8FFE8"
ALERT="#AAFF44"

echo ""
echo -e "\e[32m╔══════════════════════════════════════════════════════╗"
echo -e "║       MATRIX POLYBAR REBUILD                         ║"
echo -e "╚══════════════════════════════════════════════════════╝\e[0m"
echo ""

# =============================================================================
# STEP 1 — KILL & WIPE
# =============================================================================
echo -e "\e[32m[1/6]\e[0m Killing old polybar and wiping config..."
pkill -9 polybar 2>/dev/null || true
sleep 1
rm -rf "$POLYBAR_DIR"
rm -rf "$USER_HOME/.cache/polybar"
rm -rf "$USER_HOME/.local/share/polybar"
mkdir -p "$POLYBAR_DIR" "$SCRIPT_DIR"
echo "     Done."

# =============================================================================
# STEP 2 — DEPENDENCIES
# =============================================================================
echo -e "\e[32m[2/6]\e[0m Checking dependencies..."
PKGS=(polybar rofi jq curl xclip redshift)
MISSING=()
for pkg in "${PKGS[@]}"; do
    command -v "$pkg" &>/dev/null || MISSING+=("$pkg")
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "     Installing: ${MISSING[*]}"
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y "${MISSING[@]}" 2>/dev/null || true
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --needed --noconfirm "${MISSING[@]}" 2>/dev/null || true
    fi
fi

# Ensure a Nerd Font is present
if ! fc-list | grep -qi "Hack Nerd\|NerdFont\|Nerd Font"; then
    echo "     Installing Hack Nerd Font..."
    FONT_DIR="$USER_HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz" \
        -o /tmp/HackNF.tar.xz 2>/dev/null && \
    tar -xf /tmp/HackNF.tar.xz -C "$FONT_DIR" 2>/dev/null && \
    fc-cache -fv "$FONT_DIR" &>/dev/null || echo "     Font install failed — install Hack Nerd Font manually."
fi
echo "     Done."

# =============================================================================
# STEP 3 — HELPER SCRIPTS
# =============================================================================
echo -e "\e[32m[3/6]\e[0m Writing helper scripts..."

# Internet status
cat > "$SCRIPT_DIR/internet-status.sh" << 'EOF'
#!/usr/bin/env bash
if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
    echo "%{F#00FF41}  ONLINE%{F-}"
else
    echo "%{F#AAFF44}  OFFLINE%{F-}"
fi
EOF

# VPN status — shows IP if connected, DISCONNECTED if not
cat > "$SCRIPT_DIR/vpn-status.sh" << 'EOF'
#!/usr/bin/env bash
VPN_IP=$(ip addr show tun0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
if [[ -n "$VPN_IP" ]]; then
    echo "%{F#00FF41}  $VPN_IP%{F-}"
else
    echo "%{F#88FF88}  DISCONNECTED%{F-}"
fi
EOF

# Local IP — click to copy
cat > "$SCRIPT_DIR/local-ip.sh" << 'EOF'
#!/usr/bin/env bash
IP=$(hostname -I | awk '{print $1}')
case "$1" in
    show)  echo "%{F#E8FFE8} $IP%{F-}" ;;
    copy)  echo "$IP" | xclip -selection clipboard ;;
esac
EOF

# Copy VPN IP
cat > "$SCRIPT_DIR/copy-vpn-ip.sh" << 'EOF'
#!/usr/bin/env bash
ip addr show tun0 2>/dev/null | grep "inet " | awk '{print $2}' | \
    cut -d/ -f1 | xclip -selection clipboard
EOF

# Scope / target tracker
cat > "$SCRIPT_DIR/scope-status.sh" << 'EOF'
#!/usr/bin/env bash
SCOPE_FILE="/tmp/matrix_scope"
[[ ! -f "$SCOPE_FILE" ]] && echo "NO TARGET" > "$SCOPE_FILE"
TARGET=$(cat "$SCOPE_FILE")
if [[ "$TARGET" == "NO TARGET" ]]; then
    echo "%{F#88FF88} NO TARGET%{F-}"
else
    echo "%{F#00FF41} $TARGET%{F-}"
fi
EOF

# Set scope via rofi
cat > "$SCRIPT_DIR/set-scope.sh" << 'EOF'
#!/usr/bin/env bash
SCOPE_FILE="/tmp/matrix_scope"
TARGET=$(echo "" | rofi -no-config \
    -theme ~/.config/rofi/themes/matrix.rasi \
    -dmenu -p " TARGET IP" \
    -theme-str 'window {width: 400px;}')
[[ -n "$TARGET" ]] && echo "$TARGET" > "$SCOPE_FILE" \
    || echo "NO TARGET" > "$SCOPE_FILE"
EOF

# Volume percentage for right side display
cat > "$SCRIPT_DIR/volume.sh" << 'EOF'
#!/usr/bin/env bash
VOL=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | \
    grep -oP '\d+%' | head -1 | tr -d '%')
MUTED=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -c "yes" || true)
if [[ "$MUTED" -gt 0 ]]; then
    echo "%{F#44CC44}  MUTE%{F-}"
elif [[ -n "$VOL" ]]; then
    echo "%{F#88FF88}  ${VOL}%%%{F-}"
else
    echo "%{F#88FF88}  --%{F-}"
fi
EOF

# Color temperature
cat > "$SCRIPT_DIR/color-temp.sh" << 'EOF'
#!/usr/bin/env bash
TEMP_FILE="/tmp/matrix_temp"
[[ ! -f "$TEMP_FILE" ]] && echo "4500" > "$TEMP_FILE"
TEMP=$(cat "$TEMP_FILE")
case "$1" in
    show)      echo "%{F#88FF88} ${TEMP}K%{F-}" ;;
    increase)  TEMP=$((TEMP + 100)); echo "$TEMP" > "$TEMP_FILE"
               redshift -P -O "$TEMP" >/dev/null 2>&1 ;;
    decrease)  TEMP=$((TEMP - 100)); echo "$TEMP" > "$TEMP_FILE"
               redshift -P -O "$TEMP" >/dev/null 2>&1 ;;
    reset)     redshift -x >/dev/null 2>&1 ;;
esac
EOF

chmod +x "$SCRIPT_DIR"/*.sh
echo "     Done — $(ls "$SCRIPT_DIR"/*.sh | wc -l) scripts written."

# =============================================================================
# STEP 4 — ROFI MATRIX THEME
# =============================================================================
echo -e "\e[32m[4/6]\e[0m Writing Rofi matrix theme..."
mkdir -p "$ROFI_DIR/themes" "$ROFI_DIR/launcher" "$ROFI_DIR/power-menu"

# ── Main theme ────────────────────────────────────────────────────────────────
cat > "$ROFI_DIR/themes/matrix.rasi" << EOF
/* ============================================================
   Rofi Matrix Theme — matches polybar palette
   ============================================================ */

* {
    bg:       ${BG};
    bg-mod:   ${BG_MOD};
    fg:       ${FG};
    green:    ${GREEN};
    soft:     ${GREEN_SOFT};
    dim:      ${GREEN_DIM};
    white:    ${WHITE};
    alert:    ${ALERT};

    background-color: transparent;
    text-color:       @fg;
    border-color:     @green;
}

window {
    background-color: @bg;
    border:           2px;
    border-color:     @green;
    border-radius:    0px;
    padding:          0;
    width:            480px;
}

mainbox {
    background-color: @bg;
    padding:          8px;
    spacing:          8px;
}

inputbar {
    background-color: @bg-mod;
    border:           0 0 1px 0;
    border-color:     @dim;
    padding:          8px 12px;
    children:         [ prompt, entry ];
    spacing:          8px;
}

prompt {
    background-color: transparent;
    text-color:       @green;
    font:             "Hack Nerd Font 11";
}

entry {
    background-color: transparent;
    text-color:       @white;
    placeholder:      "type to filter...";
    placeholder-color: @dim;
}

listview {
    background-color: @bg;
    padding:          4px 0;
    spacing:          2px;
    lines:            8;
    scrollbar:        false;
}

element {
    background-color: transparent;
    padding:          8px 14px;
    border-radius:    0px;
    spacing:          10px;
    orientation:      horizontal;
}

element-icon {
    size:             22px;
    background-color: transparent;
}

element-text {
    background-color: transparent;
    text-color:       @fg;
    vertical-align:   0.5;
}

element selected.normal {
    background-color: @dim;
    border-left:      3px solid @green;
}

element selected.normal element-text {
    text-color: @green;
}

element normal.urgent,
element alternate.urgent {
    text-color: @alert;
}

element selected.urgent {
    background-color: @alert;
    text-color:       @bg;
}

message {
    background-color: @bg-mod;
    padding:          6px 12px;
}

textbox {
    text-color: @soft;
}
EOF

# ── Launcher script ───────────────────────────────────────────────────────────
cat > "$ROFI_DIR/launcher/launcher.sh" << 'EOF'
#!/usr/bin/env bash
rofi -no-config \
     -theme ~/.config/rofi/themes/matrix.rasi \
     -show drun \
     -drun-display-format "{name}" \
     -display-drun " LAUNCH"
EOF
chmod +x "$ROFI_DIR/launcher/launcher.sh"

# ── Power menu script ─────────────────────────────────────────────────────────
cat > "$ROFI_DIR/power-menu/power-menu.sh" << 'EOF'
#!/usr/bin/env bash
chosen=$(printf " LOCK\n SLEEP\n LOGOUT\n RESTART\n SHUTDOWN" | \
    rofi -no-config \
         -theme ~/.config/rofi/themes/matrix.rasi \
         -dmenu -i \
         -p " POWER" \
         -theme-str 'window {width: 280px;} listview {lines: 5;}')

case "$chosen" in
    *LOCK)     betterlockscreen -l 2>/dev/null || i3lock -c 050805 ;;
    *SLEEP)    systemctl suspend ;;
    *LOGOUT)   bspc quit ;;
    *RESTART)  systemctl reboot ;;
    *SHUTDOWN) systemctl poweroff ;;
esac
EOF
chmod +x "$ROFI_DIR/power-menu/power-menu.sh"

echo "     Done."

# =============================================================================
# STEP 5 — POLYBAR CONFIG
# =============================================================================
echo -e "\e[32m[5/6]\e[0m Writing polybar config..."

# ── colors.ini ────────────────────────────────────────────────────────────────
cat > "$POLYBAR_DIR/colors.ini" << EOF
[colors]
background   = ${BG}
bg-mod       = ${BG_MOD}
bg-sep       = ${BG_SEP}
foreground   = ${FG}
green        = ${GREEN}
green-soft   = ${GREEN_SOFT}
green-dark   = ${GREEN_DARK}
green-dim    = ${GREEN_DIM}
white        = ${WHITE}
alert        = ${ALERT}
EOF

# ── config.ini ────────────────────────────────────────────────────────────────
cat > "$POLYBAR_DIR/config.ini" << 'POLYEOF'
include-file = ~/.config/polybar/colors.ini

; ─────────────────────────────────────────────────────────────────────────────
; BAR
; ─────────────────────────────────────────────────────────────────────────────
[bar/primary]
width              = 100%
height             = 28
offset-x           = 0
offset-y           = 0
radius             = 0
fixed-center       = true
bottom             = false

background         = ${colors.background}
foreground         = ${colors.foreground}

line-size          = 2
border-size        = 0
padding-left       = 0
padding-right      = 0
module-margin-left = 0
module-margin-right= 0

; Nerd Font (text) + Nerd Font large (icons)
font-0 = "Hack Nerd Font:style=Regular:size=10;3"
font-1 = "Hack Nerd Font:style=Regular:size=14;4"

modules-left   = launcher separator local_ip separator vpn separator
modules-center = xworkspaces
modules-right  = separator scope separator volume separator date separator power_menu

cursor-click  = pointer
enable-ipc    = true
wm-restack    = bspwm

; ─────────────────────────────────────────────────────────────────────────────
; SEPARATOR — thin vertical dim-green bar between modules
; ─────────────────────────────────────────────────────────────────────────────
[module/separator]
type             = custom/text
format           = "%{F#1A331A}|%{F-}"
format-padding   = 0

; ─────────────────────────────────────────────────────────────────────────────
; LAUNCHER
; ─────────────────────────────────────────────────────────────────────────────
[module/launcher]
type             = custom/text
format           = " %{F#E8FFE8}%{F-} "
format-font      = 2
click-left       = ~/.config/rofi/launcher/launcher.sh

; ─────────────────────────────────────────────────────────────────────────────
; LOCAL IP
; ─────────────────────────────────────────────────────────────────────────────
[module/local_ip]
type             = custom/script
exec             = bash ~/.config/polybar/scripts/local-ip.sh show
interval         = 10
click-left       = bash ~/.config/polybar/scripts/local-ip.sh copy
format-padding   = 1

; ─────────────────────────────────────────────────────────────────────────────
; VPN STATUS
; ─────────────────────────────────────────────────────────────────────────────
[module/vpn]
type             = custom/script
exec             = ~/.config/polybar/scripts/vpn-status.sh
interval         = 5
click-left       = ~/.config/polybar/scripts/copy-vpn-ip.sh
format-padding   = 1

; ─────────────────────────────────────────────────────────────────────────────
; WORKSPACES
; ─────────────────────────────────────────────────────────────────────────────
[module/xworkspaces]
type                    = internal/xworkspaces
pin-workspaces          = false
enable-click            = true
enable-scroll           = false

; active workspace — filled diamond, neon green underline
label-active            = "●"
label-active-font       = 2
label-active-foreground = ${colors.green}
label-active-underline  = ${colors.green}
label-active-padding    = 1

; occupied (has windows) — smaller dot
label-occupied          = "○"
label-occupied-font     = 2
label-occupied-foreground = ${colors.green-soft}
label-occupied-padding  = 1

; empty — dim dot
label-empty             = "○"
label-empty-font        = 2
label-empty-foreground  = ${colors.green-dim}
label-empty-padding     = 1

; ─────────────────────────────────────────────────────────────────────────────
; SCOPE / TARGET
; ─────────────────────────────────────────────────────────────────────────────
[module/scope]
type             = custom/script
exec             = ~/.config/polybar/scripts/scope-status.sh
interval         = 3
click-left       = ~/.config/polybar/scripts/set-scope.sh
format-padding   = 1

; ─────────────────────────────────────────────────────────────────────────────
; VOLUME
; ─────────────────────────────────────────────────────────────────────────────
[module/volume]
type             = custom/script
exec             = ~/.config/polybar/scripts/volume.sh
interval         = 2
scroll-up        = pactl set-sink-volume @DEFAULT_SINK@ +2%
scroll-down      = pactl set-sink-volume @DEFAULT_SINK@ -2%
click-left       = pactl set-sink-mute @DEFAULT_SINK@ toggle
format-padding   = 1

; ─────────────────────────────────────────────────────────────────────────────
; DATE / TIME
; ─────────────────────────────────────────────────────────────────────────────
[module/date]
type             = internal/date
interval         = 1
date             = %H:%M
label            = " %{F#E8FFE8} %date%%{F-} "

; ─────────────────────────────────────────────────────────────────────────────
; POWER MENU
; ─────────────────────────────────────────────────────────────────────────────
[module/power_menu]
type             = custom/text
format           = " %{F#AAFF44}%{F-} "
format-font      = 2
click-left       = ~/.config/rofi/power-menu/power-menu.sh

; ─────────────────────────────────────────────────────────────────────────────
[settings]
screenchange-reload = true
pseudo-transparency = true
POLYEOF

# ── launch.sh ─────────────────────────────────────────────────────────────────
cat > "$POLYBAR_DIR/launch.sh" << 'EOF'
#!/usr/bin/env bash
pkill -9 polybar 2>/dev/null || true
sleep 0.5
if type "xrandr" > /dev/null 2>&1; then
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        MONITOR=$m polybar --reload primary &
    done
else
    polybar --reload primary &
fi
EOF
chmod +x "$POLYBAR_DIR/launch.sh"

echo "     Done."

# =============================================================================
# STEP 6 — LAUNCH
# =============================================================================
echo -e "\e[32m[6/6]\e[0m Launching polybar..."
bash "$POLYBAR_DIR/launch.sh"
sleep 1

# ── Hook into bspwmrc if not already there ────────────────────────────────────
BSPWMRC="$USER_HOME/.config/bspwm/bspwmrc"
if [[ -f "$BSPWMRC" ]] && ! grep -q "polybar/launch.sh" "$BSPWMRC"; then
    echo "" >> "$BSPWMRC"
    echo "# Matrix polybar" >> "$BSPWMRC"
    echo "~/.config/polybar/launch.sh &" >> "$BSPWMRC"
    echo "     Hooked launch.sh into bspwmrc."
fi

echo ""
echo -e "\e[32m╔══════════════════════════════════════════════════════╗"
echo -e "║  MATRIX POLYBAR INSTALLED                            ║"
echo -e "╚══════════════════════════════════════════════════════╝\e[0m"
echo ""
echo -e "  Layout:  MENU | LOCAL IP | VPN  ──●○○──  SCOPE | VOL | TIME | PWR"
echo ""
echo -e "  \e[32mClick modules:\e[0m"
echo -e "    Local IP     → copies IP to clipboard"
echo -e "    VPN          → copies VPN IP to clipboard"
echo -e "    Scope        → rofi prompt to set target IP"
echo -e "    Volume       → mute/unmute  |  scroll to adjust"
echo -e "    ☰ icon       → rofi app launcher"
echo -e "    ⏻ icon       → rofi power menu"
echo ""
echo -e "  Restart manually:  \e[1m~/.config/polybar/launch.sh\e[0m"
echo ""
