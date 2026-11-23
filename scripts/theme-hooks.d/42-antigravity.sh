#!/usr/bin/env bash
# Hook: Antigravity IDE (and VS Code) dynamic theme generator
set -euo pipefail

PALETTE="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/zenith/colors.json}"
[[ -f "$PALETTE" ]] || exit 0

# Ensure flag to suppress "Try Antigravity 2.0" nudge button
mkdir -p "$HOME/.gemini"
touch "$HOME/.gemini/antigravity"

python3 - "$PALETTE" <<'EOF'
import json, os, sys, sqlite3

pal_path = sys.argv[1]
try:
    with open(pal_path, "r", encoding="utf-8") as f:
        p = json.load(f)
except Exception:
    sys.exit(0)

home = os.path.expanduser("~")
targets = [
    os.path.join(home, ".antigravity-ide", "User", "settings.json"),
    os.path.join(home, ".config", "Cursor", "User", "settings.json"),
    os.path.join(home, ".config", "Code", "User", "settings.json"),
]

bg = p.get('surface_container_lowest', p.get('background', '#140c0b'))
surf_low = p.get('surface_container_low', '#19120c')
surf = p.get('surface_container', '#241f17')
surf_high = p.get('surface_container_high', '#2e2921')
surf_highest = p.get('surface_container_highest', '#39332a')
fg = p.get('on_surface', '#f1dfdb')
fg_muted = p.get('on_surface_variant', '#d8c2be')
pri = p.get('primary', '#ffb4a7')
on_pri = p.get('on_primary', '#561e15')
sec = p.get('secondary', '#e7bdb5')
on_sec = p.get('on_secondary', '#442a25')
ter = p.get('tertiary', '#ddc48c')
on_ter = p.get('on_tertiary', '#3d2e04')
err = p.get('error', '#ffb4ab')
outl = p.get('outline', '#9a8f80')
outl_var = p.get('outline_variant', '#4e4639')
pri_cont = p.get('primary_container', '#503a24')
on_pri_cont = p.get('on_primary_container', '#ffd8e9')

# Dull, seamless borders that fade into background
dull_border = "#00000000"
subtle_border = f"{surf_high}30"

colors = {
    # Base
    "foreground": fg,
    "focusBorder": pri,
    "disabledForeground": f"{fg_muted}80",

    # Title Bar
    "titleBar.activeBackground": bg,
    "titleBar.activeForeground": fg,
    "titleBar.inactiveBackground": bg,
    "titleBar.inactiveForeground": fg_muted,
    "titleBar.border": dull_border,

    # Activity Bar
    "activityBar.background": bg,
    "activityBar.foreground": fg,
    "activityBar.inactiveForeground": fg_muted,
    "activityBar.activeBorder": pri,
    "activityBar.border": dull_border,
    "activityBarBadge.background": pri,
    "activityBarBadge.foreground": on_pri,

    # Side Bar (Same background as main body!)
    "sideBar.background": bg,
    "sideBar.foreground": fg,
    "sideBar.border": dull_border,
    "sideBarTitle.foreground": fg,
    "sideBarSectionHeader.background": bg,
    "sideBarSectionHeader.foreground": fg,
    "sideBarSectionHeader.border": dull_border,

    # Tabs & Editor Group Header
    "editorGroupHeader.tabsBackground": bg,
    "editorGroupHeader.tabsBorder": dull_border,
    "tab.activeBackground": surf,
    "tab.activeForeground": fg,
    "tab.activeBorderTop": pri,
    "tab.inactiveBackground": bg,
    "tab.inactiveForeground": fg_muted,
    "tab.border": dull_border,

    # Editor Core
    "editor.background": bg,
    "editor.foreground": fg,
    "editorCursor.foreground": pri,
    "editorLineNumber.foreground": outl,
    "editorLineNumber.activeForeground": pri,
    "editor.lineHighlightBackground": f"{surf_high}40",
    "editor.selectionBackground": f"{pri}33",
    "editor.inactiveSelectionBackground": f"{surf_high}66",
    "editor.selectionHighlightBackground": f"{pri}20",
    "editorWidget.background": surf,
    "editorWidget.border": subtle_border,
    "editorSuggestWidget.background": surf,
    "editorSuggestWidget.border": subtle_border,
    "editorSuggestWidget.selectedBackground": pri_cont,
    "editorSuggestWidget.highlightForeground": pri,

    # Status Bar
    "statusBar.background": bg,
    "statusBar.foreground": fg,
    "statusBar.border": dull_border,
    "statusBar.debuggingBackground": ter,
    "statusBar.debuggingForeground": on_ter,
    "statusBar.noFolderBackground": bg,
    "statusBarItem.remoteBackground": pri,
    "statusBarItem.remoteForeground": on_pri,
    "statusBarItem.hoverBackground": f"{surf_high}80",

    # Bottom Panel
    "panel.background": bg,
    "panel.border": dull_border,
    "panelTitle.activeForeground": pri,
    "panelTitle.activeBorder": pri,
    "panelTitle.inactiveForeground": fg_muted,

    # Integrated Terminal
    "terminal.background": bg,
    "terminal.foreground": fg,
    "terminalCursor.foreground": pri,
    "terminal.ansiBlack": bg,
    "terminal.ansiRed": err,
    "terminal.ansiGreen": ter,
    "terminal.ansiYellow": pri,
    "terminal.ansiBlue": sec,
    "terminal.ansiMagenta": pri,
    "terminal.ansiCyan": sec,
    "terminal.ansiWhite": fg,
    "terminal.ansiBrightBlack": outl,
    "terminal.ansiBrightRed": err,
    "terminal.ansiBrightGreen": ter,
    "terminal.ansiBrightYellow": pri,
    "terminal.ansiBrightBlue": sec,
    "terminal.ansiBrightMagenta": pri,
    "terminal.ansiBrightCyan": sec,
    "terminal.ansiBrightWhite": "#ffffff",

    # Buttons & Inputs
    "button.background": pri,
    "button.foreground": on_pri,
    "button.hoverBackground": pri_cont,
    "button.secondaryBackground": surf_high,
    "button.secondaryForeground": fg,
    "button.secondaryHoverBackground": pri_cont,
    "input.background": surf,
    "input.foreground": fg,
    "input.border": subtle_border,
    "input.placeholderForeground": f"{fg_muted}cc",
    "inputOption.activeBorder": pri,

    # Lists & Trees
    "list.activeSelectionBackground": pri_cont,
    "list.activeSelectionForeground": on_pri_cont,
    "list.inactiveSelectionBackground": f"{surf_high}80",
    "list.inactiveSelectionForeground": fg,
    "list.hoverBackground": f"{surf_high}60",
    "list.hoverForeground": fg,
    "list.focusBackground": pri_cont,
    "list.highlightForeground": pri,

    # Badges & Progress
    "badge.background": pri,
    "badge.foreground": on_pri,
    "progressBar.background": pri,
    "scrollbarSlider.background": f"{outl}33",
    "scrollbarSlider.hoverBackground": f"{outl}66",
    "scrollbarSlider.activeBackground": f"{outl}99",

    # Info & Highlights (Remove generic blue)
    "editorInfo.foreground": sec,
    "notificationsInfoIcon.foreground": sec,
    "problemsInfoIcon.foreground": sec,
    "textLink.foreground": pri,
    "textLink.activeForeground": on_pri_cont,
    "charts.blue": sec,
    "charts.lines": pri,
    "gitDecoration.modifiedResourceForeground": ter,
    "gitDecoration.stageModifiedResourceForeground": ter,
    "gitDecoration.untrackedResourceForeground": pri,
    "gitDecoration.addedResourceForeground": ter,
    "gitDecoration.deletedResourceForeground": err,
    "gitDecoration.ignoredResourceForeground": outl,
}

# Dynamic Syntax Highlighting (No blue variables/properties)
tokens = {
    "comments": outl,
    "functions": sec,
    "keywords": pri,
    "numbers": ter,
    "strings": ter,
    "types": pri,
    "variables": fg,
    "textMateRules": [
        {
            "scope": [
                "variable",
                "variable.other",
                "variable.parameter",
                "variable.language",
                "meta.attribute",
                "support.variable",
                "entity.name.variable"
            ],
            "settings": {
                "foreground": fg
            }
        },
        {
            "scope": [
                "entity.name.tag",
                "entity.other.attribute-name",
                "support.type.property-name",
                "variable.other.property",
                "variable.other.object.property"
            ],
            "settings": {
                "foreground": sec
            }
        },
        {
            "scope": [
                "keyword",
                "keyword.control",
                "keyword.operator.new",
                "keyword.other",
                "storage.type",
                "storage.modifier"
            ],
            "settings": {
                "foreground": pri
            }
        },
        {
            "scope": [
                "string",
                "string.quoted",
                "string.template",
                "constant.other.symbol"
            ],
            "settings": {
                "foreground": ter
            }
        },
        {
            "scope": [
                "constant.numeric",
                "constant.language",
                "constant.character"
            ],
            "settings": {
                "foreground": ter
            }
        },
        {
            "scope": [
                "entity.name.function",
                "support.function"
            ],
            "settings": {
                "foreground": sec
            }
        },
        {
            "scope": [
                "comment",
                "punctuation.definition.comment"
            ],
            "settings": {
                "foreground": outl,
                "fontStyle": "italic"
            }
        }
    ]
}

for s_path in targets:
    if not os.path.isfile(s_path):
        continue
    try:
        with open(s_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        data["workbench.colorCustomizations"] = colors
        data["editor.tokenColorCustomizations"] = tokens
        data["editor.fontWeight"] = "500"
        data["terminal.integrated.fontWeight"] = "500"
        data["terminal.integrated.fontWeightBold"] = "bold"
        data["workbench.fontAliasing"] = "antialiased"
        data["update.mode"] = "none"
        data["update.showReleaseNotes"] = False

        with open(s_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4)
    except Exception:
        pass

# Suppress "Update Available" and "Try Antigravity" state in SQLite storage
db_path = os.path.join(home, ".antigravity-ide", "User", "globalStorage", "state.vscdb")
if os.path.isfile(db_path):
    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        cur.execute("INSERT OR REPLACE INTO ItemTable (key, value) VALUES ('antigravity2.nudge.clicked', 'true')")
        cur.execute("DELETE FROM ItemTable WHERE key LIKE 'update/%'")
        conn.commit()
        conn.close()
    except Exception:
        pass
EOF
