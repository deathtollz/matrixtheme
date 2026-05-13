#!/usr/bin/env bash
# =============================================================================
# matrix-theme.sh — Matrix Green Theme (FIXED VISIBILITY EDITION)
# =============================================================================

set -euo pipefail

USER_HOME="/home/deathtollz"

# =============================================================================
# COLORS
# =============================================================================

BG="#050805"
BG_ALT="#0B0F0B"

FG="#88FF88"
WHITE="#E8FFE8"

GREEN_BRIGHT="#00FF41"
GREEN_MID="#44CC44"
GREEN_DIM="#2FAF2F"

ALERT="#AAFF44"

BLACK="#000000"
GREY="#101510"

# p10k colors
C_BRIGHT=46
C_FG=120
C_MID=40
C_DARK=22
C_WHITE=195
C_BG=233

# =============================================================================
# HELPERS
# =============================================================================

ok() {
    echo -e "\e[32m[✔]\e[0m $*"
}

warn() {
    echo -e "\e[33m[!]\e[0m $*"
}

backup() {
    [[ -f "$1" ]] && cp "$1" "$1.bak.$(date +%s)"
}

# =============================================================================
# POLYBAR
# =============================================================================

apply_polybar_colors() {
    local count=0

    while IFS= read -r -d '' cfg; do
        backup "$cfg"

        cat > "$cfg" << EOF
[color]
background     = ${BG_ALT}
background-alt = ${GREY}
foreground     = ${FG}
foreground-alt = ${GREEN_DIM}

primary        = ${GREEN_BRIGHT}
secondary      = ${GREEN_MID}
alert          = ${ALERT}

green          = ${GREEN_BRIGHT}
yellow         = ${GREEN_BRIGHT}
orange         = ${GREEN_MID}
red            = ${ALERT}

pink           = ${FG}
blue           = ${GREEN_MID}
cyan           = ${GREEN_BRIGHT}

white          = ${WHITE}
black          = ${BLACK}
EOF

        ((count++)) || true
    done < <(find "$USER_HOME/.config/polybar" -name "colors.ini" -print0 2>/dev/null)

    ok "Polybar colors updated ($count files)"
}

# =============================================================================
# ROFI
# =============================================================================

apply_rofi_colors() {
    local count=0

    while IFS= read -r -d '' cfg; do
        backup "$cfg"

        cat > "$cfg" << EOF
* {
    background:                  ${BG};
    background-alt:              ${GREY};

    foreground:                  ${FG};
    foreground-alt:              ${WHITE};

    border-color:                ${GREEN_BRIGHT};

    selected-normal-background:  ${GREEN_BRIGHT};
    selected-normal-foreground:  ${BLACK};

    selected-active-background:  ${GREEN_MID};
    selected-active-foreground:  ${BLACK};

    selected-urgent-background:  ${ALERT};
    selected-urgent-foreground:  ${BLACK};

    urgent-foreground:           ${ALERT};
    active-foreground:           ${GREEN_BRIGHT};
}
EOF

        ((count++)) || true
    done < <(find "$USER_HOME/.config" -name "colors.rasi" -print0 2>/dev/null)

    ok "Rofi colors updated ($count files)"
}

# =============================================================================
# KITTY
# =============================================================================

apply_kitty() {
    local cfg="$USER_HOME/.config/kitty/kitty.conf"

    mkdir -p "$USER_HOME/.config/kitty"

    [[ -f "$cfg" ]] || touch "$cfg"

    backup "$cfg"

    local tmp
    tmp=$(mktemp)

    grep -Ev '^\s*(background|foreground|cursor|selection_|color[0-9]+|background_opacity)\s' \
        "$cfg" > "$tmp" || true

    cat >> "$tmp" << EOF

# =============================================================================
# MATRIX THEME
# =============================================================================

background ${BG}
foreground ${FG}

cursor ${GREEN_BRIGHT}
cursor_text_color ${BG}

selection_background ${GREEN_MID}
selection_foreground ${BLACK}

background_opacity 1.0

# black
color0 ${BLACK}
color8 ${GREY}

# red
color1 ${GREEN_DIM}
color9 ${ALERT}

# green
color2 ${GREEN_MID}
color10 ${GREEN_BRIGHT}

# yellow
color3 ${GREEN_DIM}
color11 ${GREEN_BRIGHT}

# blue
color4 ${GREEN_DIM}
color12 ${GREEN_MID}

# magenta
color5 ${GREEN_MID}
color13 ${FG}

# cyan
color6 ${FG}
color14 ${GREEN_BRIGHT}

# white
color7 ${WHITE}
color15 ${WHITE}
EOF

    mv "$tmp" "$cfg"

    ok "Kitty updated"
}

# =============================================================================
# BSPWM
# =============================================================================

apply_bspwm() {
    local cfg="$USER_HOME/.config/bspwm/bspwmrc"

    [[ -f "$cfg" ]] || {
        warn "bspwmrc not found"
        return
    }

    backup "$cfg"

    sed -i \
        -e "s|bspc config normal_border_color.*|bspc config normal_border_color \"${GREEN_DIM}\"|" \
        -e "s|bspc config active_border_color.*|bspc config active_border_color \"${GREEN_MID}\"|" \
        -e "s|bspc config focused_border_color.*|bspc config focused_border_color \"${GREEN_BRIGHT}\"|" \
        -e "s|bspc config presel_feedback_color.*|bspc config presel_feedback_color \"${GREEN_BRIGHT}\"|" \
        "$cfg"

    ok "BSPWM borders updated"
}

# =============================================================================
# POWERLEVEL10K
# =============================================================================

apply_p10k() {
    local cfg="$USER_HOME/.p10k.zsh"

    [[ -f "$cfg" ]] || {
        warn ".p10k.zsh not found"
        return
    }

    backup "$cfg"

    sed -i \
        -e "s/foreground=.*$/foreground=${C_FG}/g" \
        "$cfg" || true

    ok "Powerlevel10k refreshed"
}

# =============================================================================
# FASTFETCH (FULL FIX)
# =============================================================================

apply_fastfetch() {
    local cfg_dir="$USER_HOME/.config/fastfetch"
    local cfg="$cfg_dir/config.jsonc"

    mkdir -p "$cfg_dir"

    cat > "$cfg" << 'EOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",

    "display": {
        "separator": "  ",
        "color": {
            "keys": "bright_green",
            "title": "bright_green",
            "separator": "green"
        }
    },

    "logo": {
        "padding": {
            "top": 1,
            "left": 2
        },

        "color": {
            "1": "bright_green",
            "2": "green"
        }
    },

    "modules": [
        "title",
        "break",

        {
            "type": "os",
            "key": "󰣇 OS"
        },

        {
            "type": "host",
            "key": "󰇄 Host"
        },

        {
            "type": "kernel",
            "key": "󰒋 Kernel"
        },

        {
            "type": "wm",
            "key": "󱂬 WM"
        },

        {
            "type": "shell",
            "key": " Shell"
        },

        {
            "type": "terminal",
            "key": "󰆍 Terminal"
        },

        {
            "type": "cpu",
            "key": "󰍛 CPU"
        },

        {
            "type": "gpu",
            "key": "󰢮 GPU"
        },

        {
            "type": "memory",
            "key": "󰑭 RAM"
        },

        {
            "type": "disk",
            "key": "󰋊 Disk"
        },

        "break",

        {
            "type": "colors",
            "paddingLeft": 2
        }
    ]
}
EOF

    ok "Fastfetch rebuilt"
}

# =============================================================================
# PICOM FIX
# =============================================================================

apply_picom() {
    local cfg="$USER_HOME/.config/picom/picom.conf"

    [[ -f "$cfg" ]] || return

    backup "$cfg"

    sed -i \
        -e 's/^inactive-opacity.*/inactive-opacity = 1.0;/g' \
        -e 's/^active-opacity.*/active-opacity = 1.0;/g' \
        -e 's/^frame-opacity.*/frame-opacity = 1.0;/g' \
        "$cfg"

    ok "Picom opacity fixed"
}

# =============================================================================
# RELOAD
# =============================================================================

reload_all() {
    pkill polybar 2>/dev/null || true
    pkill picom 2>/dev/null || true

    sleep 1

    if [[ -x "$USER_HOME/.config/polybar/launch.sh" ]]; then
        bash "$USER_HOME/.config/polybar/launch.sh" &
    fi

    if command -v picom >/dev/null 2>&1; then
        picom --experimental-backends &
    fi

    if command -v bspc >/dev/null 2>&1; then
        bspc wm -r
    fi

    ok "Reload complete"
}

# =============================================================================
# MAIN
# =============================================================================

clear

echo -e "\e[92m"
cat << "EOF"

███╗   ███╗ █████╗ ████████╗██████╗ ██╗██╗  ██╗
████╗ ████║██╔══██╗╚══██╔══╝██╔══██╗██║╚██╗██╔╝
██╔████╔██║███████║   ██║   ██████╔╝██║ ╚███╔╝
██║╚██╔╝██║██╔══██║   ██║   ██╔══██╗██║ ██╔██╗
██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║██║██╔╝ ██╗
╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝

EOF
echo -e "\e[0m"

apply_polybar_colors
apply_rofi_colors
apply_kitty
apply_bspwm
apply_p10k
apply_fastfetch
apply_picom
reload_all

echo ""
echo -e "\e[92mTheme fully applied.\e[0m"
echo ""
echo "Open a NEW Kitty window and run:"
echo ""
echo "    fastfetch"
echo ""
