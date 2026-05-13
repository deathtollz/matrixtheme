#!/usr/bin/env bash
# =============================================================================
#  matrix-theme.sh — Phosphor CRT green · /home/deathtollz
#  v3: aggressive p10k bulk color replacement, fixes purple segments
# =============================================================================

set -euo pipefail

USER_HOME="/home/deathtollz"

# ── Palette ───────────────────────────────────────────────────────────────────
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

# 256-color equivalents
C_BRIGHT=46      # #00ff00
C_FG=40          # #00d700  ≈ #00CC00
C_DIM=34         # #00af00
C_MID=28         # #008700
C_DARK=22        # #005f00
C_BG=232         # #080808
C_BG_ALT=233     # #121212
C_RED=9

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
/* Phosphor green theme */
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
# 3. KITTY
# =============================================================================
apply_kitty() {
    local cfg="$USER_HOME/.config/kitty/kitty.conf"
    [[ -f "$cfg" ]] || { warn "kitty.conf not found."; return; }

    backup "$cfg"
    local tmp; tmp=$(mktemp)

    grep -Ev '^\s*(background|foreground|cursor|cursor_text_color|selection_background|selection_foreground|color[0-9]+)\s' \
        "$cfg" > "$tmp" || true

    cat >> "$tmp" << EOF

# ── Phosphor CRT green ────────────────────────────────────────────────────────
background            ${BG}
foreground            ${FG}
cursor                ${GREEN_BRIGHT}
cursor_text_color     ${BG}
selection_background  ${GREEN_DARK}
selection_foreground  ${GREEN_BRIGHT}

color0   ${BLACK}
color8   ${GREY}
color1   #880000
color9   ${RED}
color2   ${GREEN_MID}
color10  ${GREEN_BRIGHT}
color3   ${GREEN_DIM}
color11  ${FG}
color4   ${GREEN_DARK}
color12  ${GREEN_MID}
color5   ${GREEN_MID}
color13  ${GREEN_DIM}
color6   ${FG}
color14  ${GREEN_BRIGHT}
color7   ${GREEN_DIM}
color15  ${FG}
EOF

    mv "$tmp" "$cfg"
    ok "Kitty colors updated."
}

# =============================================================================
# 4. BSPWM borders
# =============================================================================
apply_bspwm() {
    local cfg="$USER_HOME/.config/bspwm/bspwmrc"
    [[ -f "$cfg" ]] || { warn "bspwmrc not found."; return; }

    backup "$cfg"
    sed -i \
        -e "s|bspc config normal_border_color.*|bspc config normal_border_color   \"${GREEN_DARK}\"|"    \
        -e "s|bspc config active_border_color.*|bspc config active_border_color   \"${GREEN_MID}\"|"     \
        -e "s|bspc config focused_border_color.*|bspc config focused_border_color  \"${GREEN_BRIGHT}\"|" \
        -e "s|bspc config presel_feedback_color.*|bspc config presel_feedback_color \"${FG}\"|"          \
        "$cfg"

    grep -q "normal_border_color" "$cfg" || cat >> "$cfg" << EOF

bspc config normal_border_color   "${GREEN_DARK}"
bspc config active_border_color   "${GREEN_MID}"
bspc config focused_border_color  "${GREEN_BRIGHT}"
bspc config presel_feedback_color "${FG}"
EOF
    ok "BSPWM border colors updated."
}

# =============================================================================
# 5. POWERLEVEL10K — bulk replacement
#
#    Strategy: replace ALL *_BACKGROUND and *_FOREGROUND values that are NOT
#    already a red/black shade. This catches purple, blue, cyan, yellow, etc.
#    regardless of which segment they belong to.
#
#    Purple 256-color codes commonly used by p10k default themes:
#      57 63 93 99 129 135 165 171 201 207 → replaced with green
#    Blue codes: 4 12 17 18 19 20 21 24 25 26 27 31 32 33 etc.
#    Cyan codes: 6 14 37 38 39 43 44 45 51 80 81 etc.
#    Yellow/orange: 3 11 136 172 178 214 220 etc.
#    We keep: red (1 9 160 196), black/grey (0 232 233 234 235 236 237 238 239 240)
# =============================================================================
apply_p10k() {
    local cfg="$USER_HOME/.p10k.zsh"
    [[ -f "$cfg" ]] || { warn ".p10k.zsh not found."; return; }

    backup "$cfg"

    # ── Replace non-green BACKGROUND values ──────────────────────────────────
    # Any *_BACKGROUND= that isn't already a green or black/grey shade gets
    # mapped to a green. We do this by matching the numeric value ranges.

    python3 - "$cfg" << 'PYEOF'
import re, sys

path = sys.argv[1]
with open(path) as f:
    lines = f.readlines()

# 256-color sets
BLACK_GREY  = {0,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,16}
RED_SHADES  = {1,9,52,88,124,160,196,197,198,199,200,201,202,203,204,205,206,207}
GREENS      = {2,10,22,28,34,40,46,47,48,64,70,76,82,83,84,106,107,118,119,120,121,148,149,154,155,156,157,190,191,192,193,194}

# Map non-green, non-black, non-red → green shade
# Bright/foreground contexts → 40 (≈ #00CC00)
# Background contexts → 22 (dark green) or 28 (mid green)

def replace_color(m):
    prefix   = m.group(1)   # e.g. "POWERLEVEL9K_DIR_BACKGROUND="
    val      = m.group(2)   # e.g. "57" or "blue"
    is_bg    = 'BACKGROUND' in prefix

    # Try to parse as int
    try:
        n = int(val)
    except ValueError:
        # Named color — replace non-green names
        named_greens = {'green','darkgreen','lime'}
        named_keep   = {'red','darkred','black','grey','gray','white'}
        if val.lower() in named_greens or val.lower() in named_keep:
            return m.group(0)
        return prefix + ('22' if is_bg else '40')

    if n in BLACK_GREY or n in RED_SHADES or n in GREENS:
        return m.group(0)   # already fine, keep it

    # Replace with appropriate green
    replacement = '22' if is_bg else '40'
    return prefix + replacement

pattern = re.compile(r'(POWERLEVEL9K_\w+(?:BACKGROUND|FOREGROUND)=)(\S+)')
out = []
for line in lines:
    # Skip comments
    if line.lstrip().startswith('#'):
        out.append(line)
        continue
    out.append(pattern.sub(replace_color, line))

with open(path, 'w') as f:
    f.writelines(out)

print("  p10k: bulk color replacement done.")
PYEOF

    ok "Powerlevel10k colors updated (all non-green segments replaced)."
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

    [[ -n "$launch" ]] && bash "$launch" & ok "Polybar relaunched."

    if command -v bspc &>/dev/null; then
        bspc wm -r 2>/dev/null && ok "BSPWM reloaded." \
            || warn "bspc reload failed — press Win+Alt+R."
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
        v3 · Phosphor CRT Green · deathtollz
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
echo -e "║  Wake up, Neo.                                   ║"
echo -e "╚══════════════════════════════════════════════════╝\e[0m"
echo ""
echo -e "  \e[32mBSPWM:\e[0m   \e[1mWin + Alt + R\e[0m"
echo -e "  \e[32mKitty:\e[0m   open a new window"
echo -e "  \e[32mp10k:\e[0m    \e[1msource ~/.p10k.zsh\e[0m  ← fixes the prompt"
echo -e "  \e[32mRofi:\e[0m    \e[1mWin + D\e[0m"
echo ""
