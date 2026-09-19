pragma Singleton
import QtQuick 2.7

// Live color tokens for the desktop compat shim. Main.qml binds these to the
// app's real theme (DesignTokens.js) so every shim widget (PageHeader, Label,
// Icon, ListItem, ...) reacts to the user's light/dark theme choice instead
// of hardcoding colors, without each shim needing its own appRoot plumbing.
QtObject {
    property string name: ""
    property bool dark: false
    property color pageColor: "#f5f5f5"
    property color cardColor: "#ffffff"
    property color borderColor: "#d8d8d8"
    property color sectionColor: "#ececec"
    property color textColor: "#1f1f1f"
    property color textMutedColor: "#666666"
    property color inverseTextColor: "#ffffff"
    property color accentColor: "#e53446"
    // Additive pointer-only affordance: rows/cards tint with this on hover.
    // Never required to see or reach anything -- touch behavior is unaffected.
    property color surfaceHoverColor: Qt.rgba(0, 0, 0, 0.035)
}
