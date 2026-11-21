import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Settings"
import "../components"
import "../../../" as Shell

ColumnLayout {
    spacing: 0
    
    Text { text: "Workspace Bar"; font.pixelSize: 18; font.bold: true; color: "white"; Layout.margins: 20; Layout.topMargin: 20 }
    
    SettingRow {
        label: "Background Style"
        description: "Visual container styling around workspaces ('pills' for individual chips or 'full' bar)"
        SelectionBox {
            model: ["pills", "full"]
            currentIndex: model.indexOf(WorkspaceSettings.backgroundStyle)
            onActivated: WorkspaceSettings.backgroundStyle = model[index]
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }
    
    SettingRow {
        label: "Display Style"
        description: "Choose whether workspace indicators display numerical digits or custom glyph icons"
        SelectionBox {
            model: ["numbers", "icons"]
            currentIndex: Math.max(0, model.indexOf(WorkspaceSettings.displayStyle))
            onActivated: WorkspaceSettings.displayStyle = model[index]
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }

    SettingRow {
        label: "Active Width"
        description: "Expanded horizontal width in pixels of the currently active workspace pill"
        NumberInput {
            from: 10; to: 100; step: 2
            value: WorkspaceSettings.activeWidth
            onValueModified: WorkspaceSettings.activeWidth = value
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }

    SettingRow {
        label: "Spacing"
        description: "Horizontal margin separation between adjacent workspace pills"
        NumberInput {
            from: 0; to: 20; step: 1
            value: WorkspaceSettings.spacing
            onValueModified: WorkspaceSettings.spacing = value
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }

    SettingRow {
        label: "Bar Margins"
        description: "Outer lateral offset margin for the workspace widget cluster"
        NumberInput {
            from: 0; to: 50; step: 1
            value: WorkspaceSettings.barMargins
            onValueModified: {
                WorkspaceSettings.barMargins = value;
                BarSettings.marginLeft = value;
                BarSettings.marginRight = value;
            }
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }

    Item { Layout.fillHeight: true }
}
