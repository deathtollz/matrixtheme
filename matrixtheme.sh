#!/usr/bin/env bash
# =============================================================================
#  matrix-theme.sh — Classic phosphor CRT green theme (matches screenshot)
#  /home/deathtollz — auto-bspwm
# =============================================================================

set -euo pipefail

USER_HOME="/home/deathtollz"

# ── Palette (matched from screenshot) ─────────────────────────────────────────
#
#   BG          pure black — the dark terminal background
#   BG_ALT      very slightly green-tinted black — for bar/panel backgrounds
#   FG          classic phosphor green — primary text
#   GREEN_BRIGHT pure bright green — highlights, focused elements, chart bars
#   GREEN_DIM   muted green — secondary/dimmer text (like the ls output)
#   GREEN_MID   mid green — module separators, inactive elements
#   GREEN_DARK  dark green — selection backgrounds, borders
#   BLACK       pure black
#   GREY        very dark greenish — subtle backgrounds
#   RED         kept red for alerts only
#
BG="#080808"
BG_ALT="#0A0F0A"
FG="#00CC00"
GREEN_BRIGHT="#00FF00"
GREEN_DIM="#009900"
GREEN_MID="#007700"
GREEN_DARK="#003300"
BLACK="#000000"
GREY="#0D150D"
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
; Classic phosphor green theme
background     = ${BG_ALT}
background-alt = ${GREY}
foreground     = ${FG}
foreground-alt = ${GREEN_DIM}
primary        = ${GREEN_BRIGHT}
secondary      = ${GREEN_MID}
alert          = ${RED}
green          = ${GREEN_BRIGHT}
yellow         = ${FG}
orange         = ${GREEN_DIM}
red            = ${RED}
pink           = ${GREEN_MID}
blue           = ${GREEN_MID}
cyan           = ${GREEN_BRIGHT}
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
/* Classic phosphor green theme */
* {
    background:                  ${BG};
    background-alt:              ${GREY};
    foreground:                  ${FG};
    foreground-alt:              ${GREEN_DIM};
    border-color:                ${GREEN_BRIGHT};
    selected-normal-background:  ${GREEN_DARK};
    selected-normal-foreground:  ${GREEN_BRIGHT};
    selected-urgent-background:  ${RED};
    selected-urgent-foreground:  ${BG};
    selected-active-background:  ${GREEN_MID};
    selected-active-foreground:  ${GREEN_BRIGHT};
    urgent-foreground:           ${RED};
    active-foreground:           ${GREEN_BRIGHT};
}
EOF
        (( count++ )) || true
    done < <(find "$USER_HOME/.config/polybar" -name "colors.rasi" -print0)
    ok "Rofi: updated $count colors.rasi files."
}

# =============================================================================
# 3. KITTY — ~/.config/kitty/kitty.conf
#    Matched to screenshot: black bg, classic #00CC00 text, pure #00FF00 bright
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
    grep -Ev '^\s*(background|foreground|cursor|cursor_text_color|selection_background|selection_foreground|color[0-9]+)\s' \
        "$cfg" > "$tmp" || true

    cat >> "$tmp" << EOF

# ── Classic phosphor CRT green ─────────────────────────────────────────────
background            ${BG}
foreground            ${FG}
cursor                ${GREEN_BRIGHT}
cursor_text_color     ${BG}
selection_background  ${GREEN_DARK}
selection_foreground  ${GREEN_BRIGHT}

# black / dark grey
color0   ${BLACK}
color8   ${GREY}

# red (errors only)
color1   #880000
color9   ${RED}

# green — the main event
color2   ${GREEN_MID}
color10  ${GREEN_BRIGHT}

# yellow → phosphor green variants
color3   ${GREEN_DIM}
color11  ${FG}

# blue → dark green
color4   ${GREEN_DARK}
color12  ${GREEN_MID}

# magenta → mid green
color5   ${GREEN_MID}
color13  ${GREEN_DIM}

# cyan → bright green
color6   ${FG}
color14  ${GREEN_BRIGHT}

# white → phosphor green
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
        -e "s|bspc config normal_border_color.*|bspc config normal_border_color   \"${GREEN_DARK}\"|"    \
        -e "s|bspc config active_border_color.*|bspc config active_border_color   \"${GREEN_MID}\"|"     \
        -e "s|bspc config focused_border_color.*|bspc config focused_border_color  \"${GREEN_BRIGHT}\"|" \
        -e "s|bspc config presel_feedback_color.*|bspc config presel_feedback_color \"${FG}\"|"          \
        "$cfg"

    grep -q "normal_border_color" "$cfg" || cat >> "$cfg" << EOF

# Classic phosphor green border colors
bspc config normal_border_color   "${GREEN_DARK}"
bspc config active_border_color   "${GREEN_MID}"
bspc config focused_border_color  "${GREEN_BRIGHT}"
bspc config presel_feedback_color "${FG}"
EOF

    ok "BSPWM border colors updated."
}

# =============================================================================
# 5. POWERLEVEL10K — ~/.p10k.zsh
#    256-color map:
#      28  = #008700  ≈ GREEN_MID
#      34  = #00af00  ≈ GREEN_DIM/FG
#      40  = #00d700  ≈ FG (#00CC00)
#      46  = #00ff00  = GREEN_BRIGHT
#      232 = #080808  = BG
#      233 = #121212  ≈ BG_ALT
#      22  = #005f00  ≈ GREEN_DARK
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
        -e "s/POWERLEVEL9K_DIR_FOREGROUND=.*/POWERLEVEL9K_DIR_FOREGROUND=40/"                       \
        -e "s/POWERLEVEL9K_DIR_BACKGROUND=.*/POWERLEVEL9K_DIR_BACKGROUND=22/"                       \
        -e "s/POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=.*/POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=28/"   \
        -e "s/POWERLEVEL9K_VCS_CLEAN_FOREGROUND=.*/POWERLEVEL9K_VCS_CLEAN_FOREGROUND=46/"           \
        -e "s/POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=.*/POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=34/"   \
        -e "s/POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=.*/POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=40/"     \
        -e "s/POWERLEVEL9K_VCS_BACKGROUND=.*/POWERLEVEL9K_VCS_BACKGROUND=22/"                       \
        -e "s/POWERLEVEL9K_STATUS_OK_FOREGROUND=.*/POWERLEVEL9K_STATUS_OK_FOREGROUND=46/"           \
        -e "s/POWERLEVEL9K_STATUS_ERROR_FOREGROUND=.*/POWERLEVEL9K_STATUS_ERROR_FOREGROUND=9/"      \
        -e "s/POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=.*/POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=34/" \
        -e "s/POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=.*/POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=232/" \
        -e "s/POWERLEVEL9K_TIME_FOREGROUND=.*/POWERLEVEL9K_TIME_FOREGROUND=40/"                     \
        -e "s/POWERLEVEL9K_TIME_BACKGROUND=.*/POWERLEVEL9K_TIME_BACKGROUND=22/"                     \
        "$cfg"

    ok "Powerlevel10k colors updated."
}

# =============================================================================
# 6. RELOAD
# =============================================================================
reload_all() {
    info "Reloading..."

    local launch=""
    for candidate in \
        "$USER_HOME/.config/polybar/launch.sh" \
        "$USER_HOME/.config/bspwm/scripts/polybar.sh"
    do
        [[ -x "$candidate" ]] && launch="$candidate" && break
    done

    pkill -q polybar 2>/dev/null || true
    sleep 0.4

    if [[ -n "$launch" ]]; then
        bash "$launch" &
        ok "Polybar relaunched via $launch."
    fi

    if command -v bspc &>/dev/null; then
        bspc wm -r 2>/dev/null && ok "BSPWM reloaded." \
            || warn "bspc reload failed — press Win+Alt+R manually."
    fi
}

# =============================================================================
# MAIN
# =============================================================================
echo -e "\e[32m"
cat << 'BANNER'

  ██████╗ ██╗  ██╗ ██████╗ ███████╗██████╗
 ██╔════╝ ██║  ██║██╔═══██╗██╔════╝██╔══██╗
 ██║  ███╗███████║██║   ██║███████╗██████╔╝
 ██║   ██║██╔══██║██║   ██║╚════██║██╔══██╗
 ╚██████╔╝██║  ██║╚██████╔╝███████║██║  ██║
  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

        Phosphor CRT Green · /home/deathtollz
BANNER
echo -e "\e[0m"

apply_polybar_colors
apply_rofi_colors
apply_kitty
apply_bspwm
apply_p10k
reload_all

echo ""
echo -e "\e[32m╔══════════════════════════════════════════════════╗"
echo -e "║  Wake up, Neo. The Matrix has you.               ║"
echo -e "╚══════════════════════════════════════════════════╝\e[0m"
echo ""
echo -e "  \e[32mBSPWM:\e[0m   \e[1mWin + Alt + R\e[0m to fully reload"
echo -e "  \e[32mKitty:\e[0m   open a new terminal window"
echo -e "  \e[32mp10k:\e[0m    \e[1msource ~/.p10k.zsh\e[0m"
echo -e "  \e[32mRofi:\e[0m    \e[1mWin + D\e[0m"
echo ""
echo -e "  Backups: \e[2m<file>.bak.<unix_timestamp>\e[0m"
echo ""
