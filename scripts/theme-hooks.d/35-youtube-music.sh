#!/usr/bin/env bash
# Hook: YouTube Music client dynamic theme generator
# Applies a single, ultra-dark solid color across all components (navbar, sidebar, main body, miniplayer)
# Fixes player slider: full visible track, buffered line, sleek accent fill, and interactive knob.
set -euo pipefail

PALETTE="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/zenith/colors.json}"
[[ -f "$PALETTE" ]] || exit 0

YTM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/YouTube Music"
CSS_OUT="$YTM_DIR/custom-style.css"
mkdir -p "$YTM_DIR"

python3 - "$PALETTE" "$CSS_OUT" <<'EOF'
import json, sys, os

pal_path, css_path = sys.argv[1], sys.argv[2]
try:
    with open(pal_path) as f:
        p = json.load(f)
except Exception:
    sys.exit(0)

# Derive ultra-dark solid background ("darker even darker close to black but not too close")
base_bg = p.get('surface_container_lowest', p.get('background', '#120d0f')).lstrip('#')
base_rgb = [int(base_bg[i:i+2], 16) for i in (0, 2, 4)]
# Target ~3.5% - 4.5% luminance: rich velvet dark tone preserving theme undertone
solid_rgb = [max(8, min(15, int(c * 0.55))) for c in base_rgb]
solid_bg = f"#{solid_rgb[0]:02x}{solid_rgb[1]:02x}{solid_rgb[2]:02x}"

pri = p.get('primary', '#feafd7')
on_pri = p.get('on_primary', '#531c3d')
pri_container = p.get('primary_container', '#c27ba0')
sec = p.get('secondary', '#e3bccd')
fg = p.get('on_surface', '#ecdfe3')
fg_muted = p.get('on_surface_variant', '#d5c2c8')
outl = p.get('outline', '#9d8c93')

def hex_to_rgb(hex_str):
    h = hex_str.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

pri_r, pri_g, pri_b = hex_to_rgb(pri)
outl_r, outl_g, outl_b = hex_to_rgb(outl)

css_content = f"""/* ==========================================================================
   Zenith Material Design 3 Theme for YouTube Music
   Uniform Ultra-Dark Canvas: Navbar, Sidebar, Body, and Miniplayer in {solid_bg}
   ========================================================================== */

:root {{
    --ytmusic-color-primary: {pri} !important;
    --ytmusic-color-primary-variant: {pri_container} !important;
    --ytmusic-color-secondary: {sec} !important;
    --ytmusic-color-white1-rgb: 241, 223, 219 !important;
    --ytmusic-color-black1-rgb: 10, 10, 12 !important;

    /* Single uniform ultra-dark background everywhere */
    --ytmusic-brand-background-solid: {solid_bg} !important;
    --ytmusic-brand-background-primary: {solid_bg} !important;
    --ytmusic-brand-background-secondary: {solid_bg} !important;
    --ytmusic-general-background-a: {solid_bg} !important;
    --ytmusic-general-background-b: {solid_bg} !important;
    --ytmusic-general-background-c: {solid_bg} !important;
    --ytmusic-overlay-background-brand: {solid_bg} !important;
    --ytmusic-player-bar-background: {solid_bg} !important;
    --ytmusic-player-page-background: {solid_bg} !important;

    /* Typography */
    --ytmusic-text-primary: {fg} !important;
    --ytmusic-text-secondary: {fg_muted} !important;

    /* Borders & dividers: completely transparent */
    --ytmusic-divider: transparent !important;
    --ytmusic-guide-border-color: transparent !important;
}}

/* ==========================================================================
   1. UNIFIED ULTRA-DARK SOLID COLOR ACROSS ALL SURFACES (NO GRADIENT)
   ========================================================================== */
html,
body,
ytmusic-app,
ytmusic-app-layout,
ytmusic-player-page,
#player-page.ytmusic-player-page,
#main-panel.ytmusic-player-page,
#side-panel.ytmusic-player-page,
#queue.ytmusic-player-page,
ytmusic-player-queue,
#contents.ytmusic-player-queue,
#content.ytmusic-app-layout,
#player-bar-background,
ytmusic-player-bar,
ytmusic-miniplayer,
ytmusic-miniplayer.ytmusic-app,
#miniplayer {{
    background-color: {solid_bg} !important;
    background: {solid_bg} !important;
    background-image: none !important;
}}

/* Accent-themed dynamic background on Home / Browse pages (blends seamlessly into {solid_bg}) */
#browse-page,
ytmusic-browse-response {{
    background-color: {solid_bg} !important;
    background-image: radial-gradient(ellipse 90% 45% at 50% 0%, rgba({pri_r}, {pri_g}, {pri_b}, 0.18) 0%, rgba({pri_r}, {pri_g}, {pri_b}, 0.05) 45%, {solid_bg} 80%) !important;
}}

/* Transparent Navbar & Sidebar so page/ambient background flows behind them */
ytmusic-nav-bar,
#nav-bar-background,
#nav-bar-background.ytmusic-app-layout,
#guide-wrapper.ytmusic-app,
#guide-wrapper,
ytmusic-guide-renderer,
#guide-inner-content.ytmusic-guide-renderer,
#mini-guide-background,
ytmusic-app-layout[is-bauhaus-sidenav-enabled] #mini-guide-background.ytmusic-app-layout,
tp-yt-app-drawer,
tp-yt-app-drawer #contentContainer,
#scrim.tp-yt-app-drawer {{
    background-color: transparent !important;
    background: transparent !important;
    background-image: none !important;
}}

/* Eliminate YouTube's built-in canvas blur & browse hero background gradient */
#background.ytmusic-player-page,
ytmusic-player-page #background,
ytmusic-player-page canvas,
ytmusic-browse-response .background-gradient,
#browse-page .background-gradient,
ytmusic-fullbleed-thumbnail-renderer,
#header-background.ytmusic-browse-response,
ytmusic-background-promo-renderer .background-gradient {{
    display: none !important;
    opacity: 0 !important;
    visibility: hidden !important;
}}

/* ==========================================================================
   2. TOTAL ELIMINATION OF BORDERS & DIVIDERS ACROSS ALL PANELS
   ========================================================================== */
#nav-bar-divider,
#guide-spacer,
#nav-bar-background,
.ytmusic-guide-section-renderer #divider,
#contents.ytmusic-item-section-renderer > *.ytmusic-item-section-renderer,
ytmusic-responsive-list-item-renderer,
tp-yt-paper-dialog,
#chips-wrapper.ytmusic-chip-cloud-renderer,
#guide-builder-banner,
ytmusic-guide-signin-promo-renderer,
ytmusic-player-bar {{
    border: none !important;
    border-top: none !important;
    border-bottom: none !important;
    border-left: none !important;
    border-right: none !important;
    box-shadow: none !important;
}}

/* ==========================================================================
   3. SIDEBAR / GUIDE NAVIGATION
   ========================================================================== */
ytmusic-guide-entry-renderer tp-yt-paper-item {{
    border-radius: 12px !important;
    margin: 2px 8px !important;
    transition: background-color 0.2s ease !important;
}}

ytmusic-guide-entry-renderer:hover tp-yt-paper-item {{
    background-color: rgba(255, 255, 255, 0.05) !important;
}}

ytmusic-guide-entry-renderer[active] tp-yt-paper-item {{
    background-color: rgba({pri_r}, {pri_g}, {pri_b}, 0.16) !important;
    color: {pri} !important;
}}

ytmusic-guide-entry-renderer[active] yt-icon {{
    color: {pri} !important;
}}

/* ==========================================================================
   4. SLEEK TOP NAVBAR
   ========================================================================== */
ytmusic-nav-bar {{
    display: flex !important;
    justify-content: flex-start !important;
    align-items: center !important;
    box-shadow: none !important;
    border: none !important;
    transition: transform 0.3s ease !important;
}}

ytmusic-nav-bar > *:not(.left-content) {{
    opacity: 0 !important;
    pointer-events: none !important;
    transition: opacity 0.3s ease !important;
}}

ytmusic-nav-bar .left-content {{
    display: flex !important;
    align-items: center !important;
    padding-left: 12px !important;
}}

ytmusic-nav-bar .left-content > * {{
    margin-right: 0.5rem !important;
}}

ytmusic-nav-bar:hover > *:not(.left-content) {{
    opacity: 1 !important;
    pointer-events: auto !important;
}}

/* ==========================================================================
   5. PLAYER SLIDER & PROGRESS BAR (FIXED & HIGH VISIBILITY)
   ========================================================================== */
ytmusic-player-bar,
#player-bar-background,
ytmusic-app-layout #player-bar-background {{
    overflow: visible !important;
}}

ytmusic-player-bar .left-controls,
ytmusic-player-bar .middle-controls,
ytmusic-player-bar .right-controls {{
    background: transparent !important;
}}

/* Progress bar container variables */
#progress-bar.ytmusic-player-bar,
ytmusic-player-bar tp-yt-paper-slider,
ytmusic-player-bar tp-yt-paper-progress {{
    --paper-slider-height: 3px !important;
    --paper-slider-active-color: {pri} !important;
    --paper-slider-secondary-color: rgba({pri_r}, {pri_g}, {pri_b}, 0.4) !important;
    --paper-slider-container-color: rgba(255, 255, 255, 0.25) !important;
    --paper-slider-knob-color: {pri} !important;
    --paper-slider-knob-start-color: {pri} !important;
    --paper-slider-knob-start-border-color: {pri} !important;
    --paper-slider-pin-color: {pri} !important;

    --paper-progress-active-color: {pri} !important;
    --paper-progress-secondary-color: rgba({pri_r}, {pri_g}, {pri_b}, 0.4) !important;
    --paper-progress-container-color: rgba(255, 255, 255, 0.25) !important;
}}

#progress-bar.ytmusic-player-bar {{
    position: absolute !important;
    top: 4px !important;
    left: 18px !important;
    right: 18px !important;
    width: auto !important;
    height: 12px !important;
    margin: 0px !important;
    padding: 0px !important;
    background: transparent !important;
    display: flex !important;
    align-items: center !important;
    cursor: pointer !important;
    z-index: 100 !important;
}}

#sliderContainer.tp-yt-paper-slider {{
    margin-left: 0px !important;
    margin-right: 0px !important;
    width: 100% !important;
}}

/* Ensure unplayed track line is clearly visible across the entire 100% width */
#progress-bar.ytmusic-player-bar #progressContainer.tp-yt-paper-progress {{
    background-color: rgba(255, 255, 255, 0.25) !important;
}}

/* Draggable thumb / knob */
#progress-bar.ytmusic-player-bar #sliderKnob.tp-yt-paper-slider .slider-knob-inner,
#progress-bar.ytmusic-player-bar #sliderKnob.tp-yt-paper-slider {{
    background-color: {pri} !important;
    border-color: {pri} !important;
}}

/* Smooth expansion when hovering the timeline */
#progress-bar.ytmusic-player-bar:hover {{
    --paper-slider-height: 5px !important;
}}

#progress-bar.ytmusic-player-bar:hover #sliderKnob.tp-yt-paper-slider .slider-knob-inner {{
    transform: scale(1.3) !important;
}}

/* Volume Slider */
tp-yt-paper-slider#volume-slider {{
    --paper-slider-active-color: {pri} !important;
    --paper-slider-knob-color: {pri} !important;
    --paper-slider-container-color: rgba(255, 255, 255, 0.22) !important;
}}

/* ==========================================================================
   6. FLOATING MINIPLAYER (MATCHING SOLID COLOR, BORDERLESS)
   ========================================================================== */
ytmusic-miniplayer,
ytmusic-miniplayer.ytmusic-app,
#miniplayer,
#player.ytmusic-miniplayer {{
    background-color: {solid_bg} !important;
    background: {solid_bg} !important;
    border: 1px solid rgba(255, 255, 255, 0.08) !important;
    border-radius: 14px !important;
    box-shadow: 0 12px 36px rgba(0, 0, 0, 0.7) !important;
    overflow: hidden !important;
}}

ytmusic-miniplayer #song-image,
ytmusic-miniplayer #video,
ytmusic-miniplayer .thumbnail-image {{
    border-radius: 10px !important;
    border: none !important;
}}

ytmusic-miniplayer [is-mini-player] {{
    background: transparent !important;
    border: none !important;
    box-shadow: none !important;
}}

/* ==========================================================================
   7. QUEUE ITEMS, CHIPS & SCROLLBAR ACCENTS
   ========================================================================== */
ytmusic-player-queue-item {{
    border: none !important;
    border-bottom: none !important;
    border-radius: 10px !important;
    margin: 2px 0 !important;
    transition: background-color 0.15s ease !important;
}}

ytmusic-player-queue-item:hover {{
    background-color: rgba(255, 255, 255, 0.05) !important;
}}

ytmusic-player-queue-item[selected] {{
    background-color: rgba({pri_r}, {pri_g}, {pri_b}, 0.14) !important;
}}

/* Tabs (Up Next, Lyrics, Comments, Related) */
tp-yt-paper-tab.iron-selected {{
    color: {pri} !important;
}}

paper-tabs #selectionBar {{
    background-color: {pri} !important;
}}

/* Play button */
ytmusic-play-button-shape {{
    --ytmusic-play-button-icon-color: {on_pri} !important;
    --ytmusic-play-button-background-color: {pri} !important;
}}

/* Chips (single crisp pill, no double-layered .gradient-box ghosting) */
ytmusic-chip-cloud-chip-renderer {{
    background: transparent !important;
    border: none !important;
    height: auto !important;
    min-height: 0 !important;
    align-self: center !important;
}}

ytmusic-chip-cloud-chip-renderer .gradient-box.ytmusic-chip-cloud-chip-renderer {{
    background: transparent !important;
    border: none !important;
    padding: 0 !important;
    margin: 0 !important;
    box-shadow: none !important;
}}

ytmusic-chip-cloud-chip-renderer a.ytmusic-chip-cloud-chip-renderer {{
    background: rgba(255, 255, 255, 0.08) !important;
    border: none !important;
    border-radius: 8px !important;
    height: 32px !important;
    min-height: 32px !important;
    padding: 0 12px !important;
    display: inline-flex !important;
    align-items: center !important;
}}

ytmusic-chip-cloud-chip-renderer[chip-style="STYLE_PRIMARY"] a.ytmusic-chip-cloud-chip-renderer,
ytmusic-chip-cloud-chip-renderer[selected] a.ytmusic-chip-cloud-chip-renderer {{
    background-color: {pri} !important;
    color: {on_pri} !important;
    border: none !important;
}}

/* Minimalist Scrollbar */
::-webkit-scrollbar {{
    width: 6px !important;
    height: 6px !important;
}}

::-webkit-scrollbar-track {{
    background: transparent !important;
}}

::-webkit-scrollbar-thumb {{
    background: rgba({outl_r}, {outl_g}, {outl_b}, 0.25) !important;
    border-radius: 999px !important;
}}

::-webkit-scrollbar-thumb:hover {{
    background: {pri} !important;
}}
"""

with open(css_path, 'w') as f:
    f.write(css_content)

print(f"Updated YouTube Music theme at {css_path} with solid background {solid_bg}")
EOF
