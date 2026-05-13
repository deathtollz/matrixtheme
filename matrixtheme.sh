#!/usr/bin/env bash
# =============================================================================
#  matrix-theme.sh — Matrix green theme for auto-bspwm (deathtollz)
#  Targets ALL polybar themes + rofi colors, kitty, bspwm borders, p10k
# =============================================================================

set -euo pipefail

USER_HOME="/home/deathtollz"

# ── Matrix palette ────────────────────────────────────────────────────────────
BG="#0D0D0D"
BG_ALT="#0A1A0A"
FG="#00FF41"
GREEN_DIM="#00CC33"
GREEN_MID="#008F11"
GREEN_DARK="#003B00"
GREEN_GLOW="#39FF14"
BLACK="#000000"
GREY="#1A2E1A"
RED="#FF0000"

# ── Helpers ───────────────────────────────────────────────────────────────────
info()  { echo -e "\e[32m[+]\e[0m $*"; }
warn()  { echo -e "\e[33m[!]\e[0m $*"; }
ok()    { echo -e "\e[92m[✔]\e[0m $*"; }
backup(){ [[ -f "$1" ]] && cp "$1" "$1.bak.$(date +%s)"; }

# =============================================================================
# 1. ALL POLYBAR colors.ini
# =============================================================================
apply_polybar_colors() {
    local count=0
    while IFS= read -r -d '' cfg; do
        backup "$cfg"
        cat > "$cfg" << EOF
[color]
background     = ${BG}
background-alt = ${GREY}
foreground     = ${FG}
foreground-alt = ${GREEN_DIM}
primary        = ${FG}
secondary      = ${GREEN_MID}
alert          = ${RED}
green          = ${FG}
yellow         = ${GREEN_GLOW}
orange         = ${GREEN_DIM}
red            = ${RED}
pink           = ${GREEN_MID}
blue           = ${GREEN_MID}
cyan           = ${GREEN_GLOW}
white          = ${FG}
black          = ${BLACK}
EOF
        (( count++ )) || true
    done < <(find "$USER_HOME/.config/polybar" -name "colors.ini" -print0)
    ok "Polybar: updated $count colors.ini files."
}

# =============================================================================
# 2. ALL ROFI colors.rasi
# =============================================================================
apply_rofi_colors() {
    local count=0
    while IFS= read -r -d '' cfg; do
        backup "$cfg"
        cat > "$cfg" << EOF
/* Matrix Green Theme */
* {
    background:                  ${BG};
    background-alt:              ${GREY};
    foreground:                  ${FG};
    foreground-alt:              ${GREEN_DIM};
    border-color:                ${GREEN_GLOW};
    selected-normal-background:  ${GREEN_DARK};
    selected-normal-foreground:  ${FG};
    selected-urgent-background:  ${RED};
    selected-urgent-foreground:  ${BG};
    selected-active-background:  ${GREEN_MID};
    selected-active-foreground:  ${BG};
    urgent-foreground:           ${RED};
    active-foreground:           ${GREEN_GLOW};
}
EOF
        (( count++ )) || true
    done < <(find "$USER_HOME/.config/polybar" -name "colors.rasi" -print0)
    ok "Rofi: updated $count colors.rasi files."
}

# =============================================================================
# 3. KITTY — ~/.config/kitty/kitty.conf
# =============================================================================
apply_kitty() {
    local cfg="$USER_HOME/.config/kitty/kitty.conf"
    if [[ ! -f "$cfg" ]]; then
        warn "kitty.conf not found — skipping."
        return
    fi

    backup "$cfg"
    local tmp; tmp=$(mktemp)

    # Strip existing color definitions
    grep -Ev '^\s*(background|foreground|cursor|selection_background|selection_foreground|color[0-9]+)\s' \
        "$cfg" > "$tmp" || true

    cat >> "$tmp" << EOF

# ── Matrix Green Theme ────────────────────────────────────────────────────────
background            ${BG}
foreground            ${FG}
cursor                ${FG}
selection_background  ${GREEN_DARK}
selection_foreground  ${FG}

color0   ${BLACK}
color8   ${GREY}
color1   #CC0000
color9   ${RED}
color2   ${GREEN_MID}
color10  ${FG}
color3   ${GREEN_DIM}
color11  ${GREEN_GLOW}
color4   ${GREEN_DARK}
color12  ${GREEN_MID}
color5   ${GREEN_MID}
color13  ${GREEN_DIM}
color6   ${GREEN_GLOW}
color14  ${FG}
color7   ${GREEN_DIM}
color15  ${FG}
EOF

    mv "$tmp" "$cfg"
    ok "Kitty colors updated."
}

# =============================================================================
# 4. BSPWM border colors — ~/.config/bspwm/bspwmrc
# =============================================================================
apply_bspwm() {
    local cfg="$USER_HOME/.config/bspwm/bspwmrc"
    if [[ ! -f "$cfg" ]]; then
        warn "bspwmrc not found — skipping."
        return
    fi

    backup "$cfg"

    sed -i \
        -e "s|bspc config normal_border_color.*|bspc config normal_border_color   \"${GREEN_DARK}\"|"  \
        -e "s|bspc config active_border_color.*|bspc config active_border_color   \"${GREEN_MID}\"|"   \
        -e "s|bspc config focused_border_color.*|bspc config focused_border_color  \"${GREEN_GLOW}\"|" \
        -e "s|bspc config presel_feedback_color.*|bspc config presel_feedback_color \"${FG}\"|"        \
        "$cfg"

    grep -q "normal_border_color" "$cfg" || cat >> "$cfg" << EOF

# Matrix Green border colors
bspc config normal_border_color   "${GREEN_DARK}"
bspc config active_border_color   "${GREEN_MID}"
bspc config focused_border_color  "${GREEN_GLOW}"
bspc config presel_feedback_color "${FG}"
EOF

    ok "BSPWM border colors updated."
}

# =============================================================================
# 5. POWERLEVEL10K — ~/.p10k.zsh
# =============================================================================
apply_p10k() {
    local cfg="$USER_HOME/.p10k.zsh"
    if [[ ! -f "$cfg" ]]; then
        warn ".p10k.zsh not found — skipping."
        return
    fi

    backup "$cfg"

    sed -i \
        -e "s/POWERLEVEL9K_OS_ICON_FOREGROUND=.*/POWERLEVEL9K_OS_ICON_FOREGROUND=46/"               \
        -e "s/POWERLEVEL9K_OS_ICON_BACKGROUND=.*/POWERLEVEL9K_OS_ICON_BACKGROUND=232/"              \
        -e "s/POWERLEVEL9K_DIR_FOREGROUND=.*/POWERLEVEL9K_DIR_FOREGROUND=46/"                       \
        -e "s/POWERLEVEL9K_DIR_BACKGROUND=.*/POWERLEVEL9K_DIR_BACKGROUND=22/"                       \
        -e "s/POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=.*/POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=28/"   \
        -e "s/POWERLEVEL9K_VCS_CLEAN_FOREGROUND=.*/POWERLEVEL9K_VCS_CLEAN_FOREGROUND=46/"           \
        -e "s/POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=.*/POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=28/"   \
        -e "s/POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=.*/POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=118/"    \
        -e "s/POWERLEVEL9K_VCS_BACKGROUND=.*/POWERLEVEL9K_VCS_BACKGROUND=22/"                       \
        -e "s/POWERLEVEL9K_STATUS_OK_FOREGROUND=.*/POWERLEVEL9K_STATUS_OK_FOREGROUND=46/"           \
        -e "s/POWERLEVEL9K_STATUS_ERROR_FOREGROUND=.*/POWERLEVEL9K_STATUS_ERROR_FOREGROUND=9/"      \
        -e "s/POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=.*/POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=28/" \
        -e "s/POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=.*/POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=232/" \
        -e "s/POWERLEVEL9K_TIME_FOREGROUND=.*/POWERLEVEL9K_TIME_FOREGROUND=46/"                     \
        -e "s/POWERLEVEL9K_TIME_BACKGROUND=.*/POWERLEVEL9K_TIME_BACKGROUND=22/"                     \
        "$cfg"

    ok "Powerlevel10k colors updated."
}

# =============================================================================
# 6. RELOAD
# =============================================================================
reload_all() {
    info "Reloading..."

    # Polybar — find and run launch script
    local launch=""
    for candidate in \
        "$USER_HOME/.config/polybar/launch.sh" \
        "$USER_HOME/.config/bspwm/scripts/polybar.sh"
    do
        [[ -x "$candidate" ]] && launch="$candidate" && break
    done

    if [[ -n "$launch" ]]; then
        pkill -q polybar 2>/dev/null || true
        sleep 0.4
        bash "$launch" &
        ok "Polybar relaunched via $launch."
    else
        pkill -q polybar 2>/dev/null || true
        ok "Polybar killed — it will restart when bspwm reloads."
    fi

    # BSPWM reload
    if command -v bspc &>/dev/null; then
        bspc wm -r 2>/dev/null && ok "BSPWM reloaded." \
            || warn "bspc reload failed — press Win+Alt+R manually."
    fi
}

# =============================================================================
# MAIN
# =============================================================================
echo -e "\e[92m"
cat << 'BANNER'
  __  __       _        _      _____  _
 |  \/  |     | |      (_)    |_   _|| |
 | \  / | __ _| |_ _ __ _ __  | |  | |__   ___ _ __ ___   ___
 | |\/| |/ _` | __| '__| \ \/ / |  | '_ \ / _ \ '_ ` _ \ / _ \
 | |  | | (_| | |_| |  | |>  < _| |_| | | |  __/ | | | | |  __/
 |_|  |_|\__,_|\__|_|  |_/_/\_\_____|_| |_|\___|_| |_| |_|\___|

            auto-bspwm · Matrix Green · /home/deathtollz
BANNER
echo -e "\e[0m"

apply_polybar_colors
apply_rofi_colors
apply_kitty
apply_bspwm
apply_p10k
reload_all

echo ""
echo -e "\e[92m╔══════════════════════════════════════════════════╗"
echo -e "║  All themes patched. Enter the Matrix.           ║"
echo -e "╚══════════════════════════════════════════════════╝\e[0m"
echo ""
echo -e "  \e[32mPolybar/BSPWM:\e[0m  press \e[1mWin + Alt + R\e[0m to fully reload"
echo -e "  \e[32mKitty:\e[0m          open a new window"
echo -e "  \e[32mp10k:\e[0m           run \e[1msource ~/.p10k.zsh\e[0m"
echo -e "  \e[32mRofi:\e[0m           press \e[1mWin + D\e[0m"
echo ""
echo -e "  Backups: \e[2m<original_file>.bak.<unix_timestamp>\e[0m"
echo ""
