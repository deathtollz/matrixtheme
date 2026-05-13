#!/usr/bin/env bash
# =============================================================================
# rofi-matrix-fix.sh
# Fully rebuilds Rofi to match Matrix/BSPWM green cyber theme
# =============================================================================

set -euo pipefail

USER_HOME="/home/deathtollz"

ROFI_DIR="$USER_HOME/.config/rofi"
THEME="$ROFI_DIR/matrix-green.rasi"
CONFIG="$ROFI_DIR/config.rasi"

mkdir -p "$ROFI_DIR"

echo "[*] Building Matrix Rofi theme..."

cat > "$THEME" << 'EOF'
/* =============================================================================
   MATRIX GREEN ROFI THEME
============================================================================= */

* {
    font: "JetBrainsMono Nerd Font 11";

    bg:             #050805;
    bg-alt:         #0B0F0B;

    fg:             #88FF88;
    fg-alt:         #44CC44;

    black:          #000000;

    green:          #00FF41;
    green-soft:     #44CC44;
    green-dark:     #2FAF2F;

    white:          #E8FFE8;

    selected:       #00FF41;
    active:         #44CC44;
    urgent:         #AAFF44;

    border-colour:  #00FF41;

    width: 850;
}

/* =============================================================================
   WINDOW
============================================================================= */

window {
    transparency: "real";
    location: center;
    anchor: center;

    fullscreen: false;

    width: 42%;
    height: 58%;

    x-offset: 0;
    y-offset: 0;

    enabled: true;

    border-radius: 18px;
    border: 3px;
    border-color: @border-colour;

    background-color: rgba (5, 8, 5, 92%);
}

/* =============================================================================
   MAIN CONTAINER
============================================================================= */

mainbox {
    enabled: true;
    spacing: 14px;

    background-color: transparent;

    children: [ "inputbar", "message", "listview" ];

    padding: 24px;
}

/* =============================================================================
   INPUT BAR
============================================================================= */

inputbar {
    enabled: true;

    spacing: 12px;

    background-color: rgba (0, 255, 65, 10%);
    text-color: @fg;

    border: 2px;
    border-radius: 14px;
    border-color: @green;

    padding: 14px;

    children: [ "prompt", "entry" ];
}

prompt {
    enabled: true;

    background-color: transparent;
    text-color: @green;

    font: "JetBrainsMono Nerd Font Bold 12";

    str: "󱓞";
}

entry {
    enabled: true;

    background-color: transparent;
    text-color: @white;

    placeholder: "Search...";
    placeholder-color: @fg-alt;
}

/* =============================================================================
   LISTVIEW
============================================================================= */

listview {
    enabled: true;

    columns: 1;
    lines: 10;

    cycle: true;
    dynamic: true;

    scrollbar: false;

    layout: vertical;

    spacing: 8px;

    background-color: transparent;

    padding: 4px;
}

/* =============================================================================
   ELEMENTS
============================================================================= */

element {
    enabled: true;

    background-color: transparent;
    text-color: @fg;

    border-radius: 12px;

    padding: 10px;

    spacing: 12px;
}

element normal.normal {
    background-color: transparent;
    text-color: @fg;
}

element selected.normal {
    background-color: rgba (0, 255, 65, 18%);
    text-color: @white;

    border: 2px;
    border-color: @green;
}

element selected.active {
    background-color: rgba (68, 204, 68, 20%);
    text-color: @white;
}

element selected.urgent {
    background-color: rgba (170, 255, 68, 20%);
    text-color: @black;
}

element-icon {
    size: 26px;
    background-color: transparent;
}

element-text {
    background-color: transparent;
    text-color: inherit;

    vertical-align: 0.5;
    horizontal-align: 0.0;
}

/* =============================================================================
   MESSAGE
============================================================================= */

message {
    background-color: transparent;
}

textbox {
    background-color: transparent;
    text-color: @fg-alt;
}
EOF

echo "[*] Building config..."

cat > "$CONFIG" << EOF
@theme "$THEME"
EOF

echo "[*] Killing existing Rofi instances..."
pkill rofi 2>/dev/null || true

echo ""
echo "[✔] Matrix Rofi theme installed."
echo ""
echo "Launch with:"
echo ""
echo "    rofi -show drun"
echo ""
echo "or restart BSPWM:"
echo ""
echo "    bspc wm -r"
echo ""
