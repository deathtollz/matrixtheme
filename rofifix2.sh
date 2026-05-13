#!/usr/bin/env bash

set -e

USER_HOME="/home/deathtollz"

ROFI_DIR="$USER_HOME/.config/rofi"

mkdir -p "$ROFI_DIR"

echo "[*] Removing broken rofi configs..."

rm -rf "$ROFI_DIR/config.rasi"
rm -rf "$ROFI_DIR/theme.rasi"
rm -rf "$ROFI_DIR/themes"

mkdir -p "$ROFI_DIR/themes"

cat > "$ROFI_DIR/themes/matrix.rasi" << 'EOF'
configuration {
    modi: "drun,run,window";
    show-icons: true;
    icon-theme: "Papirus";
    display-drun: "󰀻 Apps";
    drun-display-format: "{name}";
    font: "JetBrainsMono Nerd Font 11";
}

* {
    bg: #050805EE;
    bg-alt: #0B0F0BEE;

    fg: #88FF88;
    fg-alt: #44CC44;

    green: #00FF41;
    green2: #44CC44;

    black: #000000;
    white: #E8FFE8;

    border: #00FF41;

    background-color: transparent;
    text-color: @fg;
}

window {
    location: center;
    anchor: center;

    width: 40%;
    border: 3px;
    border-color: @border;
    border-radius: 18px;

    background-color: @bg;
}

mainbox {
    spacing: 15px;
    padding: 25px;

    background-color: transparent;
}

inputbar {
    background-color: @bg-alt;

    border: 2px;
    border-radius: 12px;
    border-color: @green;

    padding: 12px;
    spacing: 10px;

    children: [ prompt, entry ];
}

prompt {
    text-color: @green;
    background-color: transparent;
}

entry {
    text-color: @white;
    background-color: transparent;
}

listview {
    lines: 10;
    columns: 1;

    spacing: 8px;
    scrollbar: false;

    background-color: transparent;
}

element {
    padding: 10px;
    spacing: 10px;

    border-radius: 10px;

    background-color: transparent;
    text-color: @fg;
}

element selected.normal {
    background-color: #00FF4122;
    border: 2px;
    border-color: @green;

    text-color: @white;
}

element-icon {
    size: 24px;
    background-color: transparent;
}

element-text {
    background-color: transparent;
    text-color: inherit;
}
EOF

cat > "$ROFI_DIR/config.rasi" << 'EOF'
@theme "~/.config/rofi/themes/matrix.rasi"
EOF

pkill rofi 2>/dev/null || true

echo ""
echo "[✔] Rofi fully rebuilt."
echo ""
echo "TEST WITH:"
echo ""
echo 'rofi -show drun'
echo ""
