#!/usr/bin/env bash
# =============================================================================
#  matrix-theme.sh — Muted green base · neon accents · white · /home/deathtollz  (v5)
# =============================================================================

set -euo pipefail

USER_HOME="/home/deathtollz"

# ── Palette ───────────────────────────────────────────────────────────────────
BG="#0C0C0C"
BG_ALT="#0F130F"
FG="#33AA33"            # muted phosphor green — body text
GREEN_BRIGHT="#00FF41"  # neon matrix green — highlights, focused borders, accents
GREEN_DIM="#1F7A1F"     # dim green — inactive / secondary
GREEN_MID="#2A8A2A"     # mid green — module backgrounds, separators
WHITE="#E8FFE8"         # soft white with the faintest green tint
ALERT="#AAFF44"         # lime — replaces red for alerts/errors
BLACK="#000000"
GREY="#111811"

# 256-color for p10k
C_BRIGHT=46    # #00ff00  ≈ GREEN_BRIGHT
C_FG=71        # #5faf5f  ≈ FG
C_MID=28       # #008700  ≈ GREEN_MID
C_DARK=22      # #005f00  ≈ GREEN_DIM/DARK
C_WHITE=195    # #dfffff  ≈ WHITE
C_BG=233       # #121212  ≈ BG

# ── Helpers ───────────────────────────────────────────────────────────────────
ok()    { echo -e "\e[32m[✔]\e[0m $*"; }
warn()  { echo -e "\e[33m[!]\e[0m $*"; }
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
alert          = ${ALERT}
green          = ${GREEN_BRIGHT}
yellow         = ${GREEN_BRIGHT}
orange         = ${FG}
red            = ${ALERT}
pink           = ${FG}
blue           = ${GREEN_MID}
cyan           = ${GREEN_BRIGHT}
white          = ${WHITE}
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
/* Muted green + neon accents + white */
* {
    background:                  ${BG};
    background-alt:              ${GREY};
    foreground:                  ${FG};
    foreground-alt:              ${GREEN_DIM};
    border-color:                ${GREEN_BRIGHT};
    selected-normal-background:  ${GREEN_MID};
    selected-normal-foreground:  ${WHITE};
    selected-urgent-background:  ${ALERT};
    selected-urgent-foreground:  ${BG};
    selected-active-background:  ${GREEN_BRIGHT};
    selected-active-foreground:  ${BG};
    urgent-foreground:           ${ALERT};
    active-foreground:           ${GREEN_BRIGHT};
}
EOF
        (( count++ )) || true
    done < <(find "$USER_HOME/.config/polybar" -name "colors.rasi" -print0)
    ok "Rofi: updated $count colors.rasi files."
}

# =============================================================================
# 3. KITTY
#    color15 (bright white) = WHITE
#    color7  (white)        = WHITE
#    neon green on the bright slots, muted on normal slots
# =============================================================================
apply_kitty() {
    local cfg="$USER_HOME/.config/kitty/kitty.conf"
    [[ -f "$cfg" ]] || { warn "kitty.conf not found."; return; }

    backup "$cfg"
    local tmp; tmp=$(mktemp)

    grep -Ev '^\s*(background|foreground|cursor|cursor_text_color|selection_background|selection_foreground|color[0-9]+)\s' \
        "$cfg" > "$tmp" || true

    cat >> "$tmp" << EOF

# ── Muted green + neon accents + white (v5) ───────────────────────────────────
background            ${BG}
foreground            ${FG}
cursor                ${GREEN_BRIGHT}
cursor_text_color     ${BG}
selection_background  ${GREEN_MID}
selection_foreground  ${WHITE}

# black / dark grey
color0   ${BLACK}
color8   ${GREY}

# "red" slots → lime alert (no red)
color1   #1F7A1F
color9   ${ALERT}

# green — muted normal, neon bright
color2   ${GREEN_MID}
color10  ${GREEN_BRIGHT}

# yellow → neon green (bright) / muted (normal)
color3   ${GREEN_DIM}
color11  ${GREEN_BRIGHT}

# blue → dark/mid green
color4   ${GREEN_DIM}
color12  ${GREEN_MID}

# magenta → muted green
color5   ${GREEN_MID}
color13  ${FG}

# cyan → neon
color6   ${FG}
color14  ${GREEN_BRIGHT}

# white — actual white
color7   ${WHITE}
color15  ${WHITE}
EOF

    mv "$tmp" "$cfg"
    ok "Kitty colors updated."
}

# =============================================================================
# 4. BSPWM borders — neon focused, dark inactive
# =============================================================================
apply_bspwm() {
    local cfg="$USER_HOME/.config/bspwm/bspwmrc"
    [[ -f "$cfg" ]] || { warn "bspwmrc not found."; return; }

    backup "$cfg"
    sed -i \
        -e "s|bspc config normal_border_color.*|bspc config normal_border_color   \"${GREEN_DIM}\"|"     \
        -e "s|bspc config active_border_color.*|bspc config active_border_color   \"${GREEN_MID}\"|"     \
        -e "s|bspc config focused_border_color.*|bspc config focused_border_color  \"${GREEN_BRIGHT}\"|" \
        -e "s|bspc config presel_feedback_color.*|bspc config presel_feedback_color \"${GREEN_BRIGHT}\"|"\
        "$cfg"

    grep -q "normal_border_color" "$cfg" || cat >> "$cfg" << EOF

bspc config normal_border_color   "${GREEN_DIM}"
bspc config active_border_color   "${GREEN_MID}"
bspc config focused_border_color  "${GREEN_BRIGHT}"
bspc config presel_feedback_color "${GREEN_BRIGHT}"
EOF
    ok "BSPWM border colors updated."
}

# =============================================================================
# 5. POWERLEVEL10K — neon accent on bright segments, white where white was
# =============================================================================
apply_p10k() {
    local cfg="$USER_HOME/.p10k.zsh"
    [[ -f "$cfg" ]] || { warn ".p10k.zsh not found."; return; }

    backup "$cfg"

    python3 - "$cfg" "$C_BG" "$C_DARK" "$C_MID" "$C_FG" "$C_BRIGHT" "$C_WHITE" << 'PYEOF'
import re, sys

path, C_BG, C_DARK, C_MID, C_FG, C_BRIGHT, C_WHITE = sys.argv[1:]

BLACK_GREY = set(range(232, 256)) | {0, 16}
GREENS     = {2,10,22,28,34,40,46,47,48,64,70,71,76,77,82,83,84,
              106,107,118,119,120,121,148,149,154,155,156,157,190,191,192,193,194}
WHITES     = {7, 15, 195, 231, 255, 253, 254, 252, 251, 250, 249, 248}

def replace_color(m):
    prefix = m.group(1)
    val    = m.group(2)
    is_bg  = 'BACKGROUND' in prefix

    try:
        n = int(val)
    except ValueError:
        keep = {'green', 'darkgreen', 'white'}
        if val.lower() in keep:
            return m.group(0)
        return prefix + (C_DARK if is_bg else C_FG)

    if n in BLACK_GREY or n in GREENS:
        return m.group(0)
    if n in WHITES:
        # keep white slots as white
        return prefix + C_WHITE

    # Everything else (purple, blue, red, yellow, orange...) → green
    return prefix + (C_DARK if is_bg else C_BRIGHT)

pattern = re.compile(r'(POWERLEVEL9K_\w+(?:BACKGROUND|FOREGROUND)=)(\S+)')

with open(path) as f:
    lines = f.readlines()

out = []
for line in lines:
    if line.lstrip().startswith('#'):
        out.append(line)
        continue
    out.append(pattern.sub(replace_color, line))

with open(path, 'w') as f:
    f.writelines(out)
PYEOF

    ok "Powerlevel10k updated — neon accents + white preserved."
}

# =============================================================================
# 6. RELOAD
# =============================================================================
reload_all() {
    local launch=""
    for c in "$USER_HOME/.config/polybar/launch.sh" \
              "$USER_HOME/.config/bspwm/scripts/polybar.sh"; do
        [[ -x "$c" ]] && launch="$c" && break
    done

    pkill -q polybar 2>/dev/null || true
    sleep 0.4
    [[ -n "$launch" ]] && bash "$launch" & ok "Polybar relaunched."
    command -v bspc &>/dev/null && \
        { bspc wm -r 2>/dev/null && ok "BSPWM reloaded." || warn "Press Win+Alt+R."; }
}

# =============================================================================
# MAIN
# =============================================================================
echo -e "\e[92m"
cat << 'BANNER'
  ██████╗ ██╗  ██╗ ██████╗ ███████╗██████╗
 ██╔════╝ ██║  ██║██╔═══██╗██╔════╝██╔══██╗
 ██║  ███╗███████║██║   ██║███████╗██████╔╝
 ██║   ██║██╔══██║██║   ██║╚════██║██╔══██╗
 ╚██████╔╝██║  ██║╚██████╔╝███████║██║  ██║
  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
      v5 · neon accents · white · no red
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
echo -e "║  Done.                                           ║"
echo -e "╚══════════════════════════════════════════════════╝\e[0m"
echo ""
echo -e "  \e[32mBSPWM:\e[0m   \e[1mWin + Alt + R\e[0m"
echo -e "  \e[32mKitty:\e[0m   open a new window"
echo -e "  \e[32mp10k:\e[0m    \e[1msource ~/.p10k.zsh\e[0m"
echo ""
