import QtQuick 2.7
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Layouts 1.3

QQC2.TextField {
    id: control
    // Stretch to fill whenever placed inside a Layout (e.g. Dialog's
    // ColumnLayout) instead of sitting at its small text-metrics-based
    // implicitWidth. No-op if the parent isn't a Layout.
    Layout.fillWidth: true
    selectByMouse: true
    color: Theme.textColor
    placeholderTextColor: Theme.textMutedColor
    background: Rectangle {
        implicitHeight: 36
        radius: 6
        color: Theme.sectionColor
        border.color: Theme.borderColor
        border.width: 1
    }
}
