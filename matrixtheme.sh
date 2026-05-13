#!/usr/bin/env bash
# =============================================================================
#  matrix-theme.sh — Muted forest green · no red · /home/deathtollz  (v4)
# =============================================================================

set -euo pipefail

USER_HOME="/home/deathtollz"

# ── Palette (matched to image 2 — muted, dark, no neon, no red) ──────────────
#
#   BG           very dark near-black with a faint warm tint
#   FG           medium phosphor green — the main text colour in image 2
#   GREEN_BRIGHT slightly brighter green — highlights, focused borders
#   GREEN_DIM    dim green — secondary text, inactive elements
#   GREEN_MID    mid green — separators, module backgrounds
#   GREEN_DARK   very dark green — selection backgrounds, unfocused borders
#   ALERT        lime-green replaces red — still distinct, no red anywhere
#
BG="#0C0C0C"
BG_ALT="#0F130F"
FG="#33AA33"
GREEN_BRIGHT="#55CC55"
GREEN_DIM="#1F7A1F"
GREEN_MID="#2A8A2A"
GREEN_DARK="#0D3B0D"
BLACK="#000000"
GREY="#111811"
ALERT="#AAFF44"      # lime — visible without using red

# 256-color equivalents for p10k
C_BRIGHT=77          # #5fd75f  ≈ GREEN_BRIGHT
C_FG=71              # #5faf5f  ≈ FG
C_DIM=64             # #5f8700  ≈ GREEN_DIM
C_MID=28             # #008700  ≈ GREEN_MID
C_DARK=22            # #005f00  ≈ GREEN_DARK
C_BG=233             # #121212  ≈ BG
C_ALERT=154          # #afff00  ≈ ALERT

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
yellow         = ${FG}
orange         = ${GREEN_DIM}
red            = ${ALERT}
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
/* Muted forest green — no red */
* {
    background:                  ${BG};
    background-alt:              ${GREY};
    foreground:                  ${FG};
    foreground-alt:              ${GREEN_DIM};
    border-color:                ${GREEN_BRIGHT};
    selected-normal-background:  ${GREEN_DARK};
    selected-normal-foreground:  ${GREEN_BRIGHT};
    selected-urgent-background:  ${ALERT};
    selected-urgent-foreground:  ${BG};
    selected-active-background:  ${GREEN_MID};
    selected-active-foreground:  ${GREEN_BRIGHT};
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
#    Matches image 2: dark bg, muted #33AA33 text, no red in palette
# =============================================================================
apply_kitty() {
    local cfg="$USER_HOME/.config/kitty/kitty.conf"
    [[ -f "$cfg" ]] || { warn "kitty.conf not found."; return; }

    backup "$cfg"
    local tmp; tmp=$(mktemp)

    grep -Ev '^\s*(background|foreground|cursor|cursor_text_color|selection_background|selection_foreground|color[0-9]+)\s' \
        "$cfg" > "$tmp" || true

    cat >> "$tmp" << EOF

# ── Muted forest green (image 2 match) ───────────────────────────────────────
background            ${BG}
foreground            ${FG}
cursor                ${GREEN_BRIGHT}
cursor_text_color     ${BG}
selection_background  ${GREEN_DARK}
selection_foreground  ${GREEN_BRIGHT}

# black
color0   ${BLACK}
color8   ${GREY}

# "red" → lime alert (no red anywhere)
color1   #2A7A2A
color9   ${ALERT}

# green
color2   ${GREEN_MID}
color10  ${GREEN_BRIGHT}

# yellow → dim green
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

# white → foreground green
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
# 5. POWERLEVEL10K — bulk Python replacement, no red, muted greens
# =============================================================================
apply_p10k() {
    local cfg="$USER_HOME/.p10k.zsh"
    [[ -f "$cfg" ]] || { warn ".p10k.zsh not found."; return; }

    backup "$cfg"

    python3 - "$cfg" "$C_BG" "$C_DARK" "$C_MID" "$C_FG" "$C_BRIGHT" "$C_ALERT" << 'PYEOF'
import re, sys

path, C_BG, C_DARK, C_MID, C_FG, C_BRIGHT, C_ALERT = sys.argv[1:]

# 256-color groups to keep as-is
BLACK_GREY = set(range(232, 256)) | {0, 16}
GREENS     = {2,10,22,28,34,40,46,47,48,64,70,71,76,77,82,83,84,
              106,107,118,119,120,121,148,149,154,155,156,157,190,191,192,193,194}

def replace_color(m):
    prefix = m.group(1)
    val    = m.group(2)
    is_bg  = 'BACKGROUND' in prefix

    try:
        n = int(val)
    except ValueError:
        # Named colors — map everything non-green to green
        keep = {'green','darkgreen'}
        if val.lower() in keep:
            return m.group(0)
        return prefix + (C_DARK if is_bg else C_FG)

    if n in BLACK_GREY or n in GREENS:
        return m.group(0)

    # Replace with muted green (darker for backgrounds, mid for foregrounds)
    return prefix + (C_DARK if is_bg else C_FG)

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

print("  p10k: all non-green/non-black segments replaced.")
PYEOF

    ok "Powerlevel10k updated — all red/purple/blue segments replaced."
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
echo -e "\e[32m"
cat << 'BANNER'
  ██████╗ ██╗  ██╗ ██████╗ ███████╗██████╗
 ██╔════╝ ██║  ██║██╔═══██╗██╔════╝██╔══██╗
 ██║  ███╗███████║██║   ██║███████╗██████╔╝
 ██║   ██║██╔══██║██║   ██║╚════██║██╔══██╗
 ╚██████╔╝██║  ██║╚██████╔╝███████║██║  ██║
  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
        v4 · Muted Forest Green · no red
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
echo -e "║  Done. No red. Only green.                       ║"
echo -e "╚══════════════════════════════════════════════════╝\e[0m"
echo ""
echo -e "  \e[32mBSPWM:\e[0m   \e[1mWin + Alt + R\e[0m"
echo -e "  \e[32mKitty:\e[0m   open a new window"
echo -e "  \e[32mp10k:\e[0m    \e[1msource ~/.p10k.zsh\e[0m"
echo -e "  \e[32mRofi:\e[0m    \e[1mWin + D\e[0m"
echo ""
