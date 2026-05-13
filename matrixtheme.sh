#!/usr/bin/env bash
# =============================================================================
#  matrix-theme.sh — Apply a Matrix green color scheme to auto-bspwm
#  Targets: polybar, kitty, bspwm borders, rofi, powerlevel10k
# =============================================================================

set -euo pipefail

# ── Matrix palette ────────────────────────────────────────────────────────────
BG="#0D0D0D"          # near-black background
BG2="#0A1A0A"         # slightly green-tinted black (polybar bg)
FG="#00FF41"          # classic matrix bright green
GREEN_DIM="#00CC33"   # dimmer green
GREEN_MID="#008F11"   # mid green
GREEN_DARK="#003B00"  # dark green (borders, subtle elements)
GREEN_GLOW="#39FF14"  # neon glow green (focused borders, highlights)
BLACK="#000000"
GREY="#1A2E1A"        # dark greenish grey

# ── Helpers ───────────────────────────────────────────────────────────────────
info()    { echo -e "\e[32m[+]\e[0m $*"; }
warn()    { echo -e "\e[33m[!]\e[0m $*"; }
success() { echo -e "\e[92m[✔]\e[0m $*"; }
backup()  { [[ -f "$1" ]] && cp "$1" "$1.bak.$(date +%s)" && info "Backed up $1"; }

# =============================================================================
# 1. POLYBAR — ~/.config/polybar/colorblocks/colors.ini
# =============================================================================
apply_polybar() {
    local cfg="$HOME/.config/polybar/colorblocks/colors.ini"
    if [[ ! -f "$cfg" ]]; then
        warn "Polybar config not found at $cfg — skipping."
        return
    fi

    backup "$cfg"
    cat > "$cfg" << EOF
[color]
; Matrix Green Theme
background     = ${BG2}
background-alt = ${GREY}
foreground     = ${FG}
foreground-alt = ${GREEN_DIM}
primary        = ${FG}
secondary      = ${GREEN_MID}
alert          = #FF0000
green          = ${FG}
yellow         = ${GREEN_GLOW}
orange         = ${GREEN_DIM}
red            = #FF0000
pink           = ${GREEN_MID}
blue           = ${GREEN_MID}
cyan           = ${GREEN_GLOW}
white          = ${FG}
black          = ${BLACK}
EOF
    success "Polybar colors updated."
}

# =============================================================================
# 2. KITTY — ~/.config/kitty/kitty.conf
# =============================================================================
apply_kitty() {
    local cfg="$HOME/.config/kitty/kitty.conf"
    if [[ ! -f "$cfg" ]]; then
        warn "kitty.conf not found — skipping."
        return
    fi

    backup "$cfg"

    # Remove existing color lines then append the new palette
    local tmp
    tmp=$(mktemp)
    grep -Ev '^\s*(background|foreground|cursor|selection_background|selection_foreground|color[0-9]+)\s' "$cfg" > "$tmp" || true

    cat >> "$tmp" << EOF

# ── Matrix Green Theme ────────────────────────────────────────────────────────
background            ${BG}
foreground            ${FG}
cursor                ${FG}
selection_background  ${GREEN_DARK}
selection_foreground  ${FG}

# black
color0   #000000
color8   #1A2E1A

# red (kept red for error visibility)
color1   #CC0000
color9   #FF0000

# green (matrix greens)
color2   ${GREEN_MID}
color10  ${FG}

# yellow → bright green
color3   ${GREEN_DIM}
color11  ${GREEN_GLOW}

# blue → dark green
color4   ${GREEN_DARK}
color12  ${GREEN_MID}

# magenta → mid green
color5   ${GREEN_MID}
color13  ${GREEN_DIM}

# cyan → neon green
color6   ${GREEN_GLOW}
color14  ${FG}

# white → light green
color7   ${GREEN_DIM}
color15  ${FG}
EOF

    mv "$tmp" "$cfg"
    success "Kitty colors updated."
}

# =============================================================================
# 3. BSPWM — ~/.config/bspwm/bspwmrc (border colors)
# =============================================================================
apply_bspwm() {
    local cfg="$HOME/.config/bspwm/bspwmrc"
    if [[ ! -f "$cfg" ]]; then
        warn "bspwmrc not found — skipping."
        return
    fi

    backup "$cfg"

    sed -i "s|bspc config normal_border_color.*|bspc config normal_border_color   \"${GREEN_DARK}\"|" "$cfg"
    sed -i "s|bspc config active_border_color.*|bspc config active_border_color    \"${GREEN_MID}\"|"  "$cfg"
    sed -i "s|bspc config focused_border_color.*|bspc config focused_border_color  \"${GREEN_GLOW}\"|" "$cfg"
    sed -i "s|bspc config presel_feedback_color.*|bspc config presel_feedback_color \"${FG}\"|"        "$cfg"

    # If the lines don't exist yet, append them
    if ! grep -q "normal_border_color" "$cfg"; then
        cat >> "$cfg" << EOF

# Matrix Green border colors
bspc config normal_border_color   "${GREEN_DARK}"
bspc config active_border_color   "${GREEN_MID}"
bspc config focused_border_color  "${GREEN_GLOW}"
bspc config presel_feedback_color "${FG}"
EOF
    fi

    success "BSPWM border colors updated."
}

# =============================================================================
# 4. ROFI — first .rasi file found under ~/.config/rofi
# =============================================================================
apply_rofi() {
    local rasi
    rasi=$(find "$HOME/.config/rofi" -name "*.rasi" -print -quit 2>/dev/null || true)

    if [[ -z "$rasi" ]]; then
        warn "No rofi .rasi config found — skipping."
        return
    fi

    backup "$rasi"

    # Inject/replace the color block at the top
    local tmp
    tmp=$(mktemp)

    # Strip any existing * { } color block at the top
    awk 'BEGIN{skip=0} /^\s*\*\s*\{/{skip=1} skip && /\}/{skip=0; next} !skip' "$rasi" > "$tmp"

    # Prepend the new palette
    cat > "$rasi" << EOF
/* Matrix Green Theme */
* {
    bg:          ${BG};
    bg-alt:      ${GREY};
    fg:          ${FG};
    fg-alt:      ${GREEN_DIM};
    border:      ${GREEN_GLOW};
    selected:    ${GREEN_DARK};

    background-color:  @bg;
    text-color:        @fg;
}

EOF
    cat "$tmp" >> "$rasi"
    rm "$tmp"

    success "Rofi colors updated ($rasi)."
}

# =============================================================================
# 5. POWERLEVEL10K — ~/.p10k.zsh  (segment colors → 256-color codes)
#    Matrix palette nearest 256-color equivalents:
#      bright green  → 46   (#00ff00)
#      mid green     → 28   (#008700)
#      dark green    → 22   (#005f00)
#      neon green    → 118  (#87ff00)
#      black bg      → 232  (#080808)
# =============================================================================
apply_p10k() {
    local cfg="$HOME/.p10k.zsh"
    if [[ ! -f "$cfg" ]]; then
        warn ".p10k.zsh not found — skipping."
        return
    fi

    backup "$cfg"

    # Replace common foreground color codes with matrix greens
    # These cover the most visible prompt segments
    sed -i \
        -e "s/POWERLEVEL9K_OS_ICON_FOREGROUND=.*/POWERLEVEL9K_OS_ICON_FOREGROUND=46/"         \
        -e "s/POWERLEVEL9K_DIR_FOREGROUND=.*/POWERLEVEL9K_DIR_FOREGROUND=46/"                 \
        -e "s/POWERLEVEL9K_DIR_BACKGROUND=.*/POWERLEVEL9K_DIR_BACKGROUND=22/"                 \
        -e "s/POWERLEVEL9K_VCS_CLEAN_FOREGROUND=.*/POWERLEVEL9K_VCS_CLEAN_FOREGROUND=46/"     \
        -e "s/POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=.*/POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=28/" \
        -e "s/POWERLEVEL9K_VCS_BACKGROUND=.*/POWERLEVEL9K_VCS_BACKGROUND=22/"                 \
        -e "s/POWERLEVEL9K_STATUS_OK_FOREGROUND=.*/POWERLEVEL9K_STATUS_OK_FOREGROUND=46/"     \
        -e "s/POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=.*/POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=28/" \
        "$cfg"

    success "Powerlevel10k colors updated."
}

# =============================================================================
# 6. RELOAD everything
# =============================================================================
reload_all() {
    info "Reloading environments..."

    # Polybar — kill and relaunch via bspwm launch script if it exists
    if command -v polybar &>/dev/null; then
        pkill -q polybar || true
        local launch="$HOME/.config/polybar/launch.sh"
        if [[ -x "$launch" ]]; then
            bash "$launch" &
            success "Polybar restarted."
        else
            warn "No launch.sh found — start polybar manually or press Win+Alt+R."
        fi
    fi

    # BSPWM — reload config (non-fatal if not running inside bspwm)
    if command -v bspc &>/dev/null; then
        bspc wm -r 2>/dev/null && success "BSPWM reloaded." || warn "bspc reload failed (not in a bspwm session?)."
    fi

    echo ""
    echo -e "\e[92m╔══════════════════════════════════════════╗"
    echo -e "║      Matrix theme applied. Welcome back.  ║"
    echo -e "╚══════════════════════════════════════════╝\e[0m"
    echo ""
    echo -e "  \e[32mKitty:\e[0m  Restart kitty or open a new window."
    echo -e "  \e[32mRofi:\e[0m   Press Win+D to see the new colours."
    echo -e "  \e[32mp10k:\e[0m   Run \e[1msource ~/.p10k.zsh\e[0m in your shell."
    echo -e "  \e[32mFull:\e[0m   Press \e[1mWin+Alt+R\e[0m to reload bspwm fully."
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================
echo -e "\e[92m"
cat << 'BANNER'
  __  __      _        _      _____  _
 |  \/  |    | |      (_)    |_   _|| |
 | \  / | __ | |_ _ __ _ __  | |  | |__   ___ _ __ ___   ___
 | |\/| |/ _` | __| '__| \ \/ / |  | '_ \ / _ \ '_ ` _ \ / _ \
 | |  | | (_| | |_| |  | |>  < _| |_| | | |  __/ | | | | |  __/
 |_|  |_|\__,_|\__|_|  |_/_/\_\_____|_| |_|\___|_| |_| |_|\___|

            auto-bspwm  ·  Matrix Green Theme
BANNER
echo -e "\e[0m"

apply_polybar
apply_kitty
apply_bspwm
apply_rofi
apply_p10k
reload_all
