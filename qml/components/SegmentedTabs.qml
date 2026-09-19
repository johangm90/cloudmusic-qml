import QtQuick 2.12
import Lomiri.Components 1.3

Rectangle {
    id: segmentedTabs
    property var appRoot: (typeof cloudMusic !== "undefined" ? cloudMusic : null)
    property var labels: []
    property int currentIndex: 0
    property color activeColor: appRoot ? appRoot.primaryColor : "#e53446"
    property color textColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color activeTextColor: appRoot ? appRoot.inverseTextColor : "#ffffff"
    property color selectedColor: appRoot ? appRoot.selectedColor : Qt.rgba(0, 0, 0, 0.06)
    property color hoverColor: appRoot ? appRoot.surfaceHoverColor : Qt.rgba(0, 0, 0, 0.035)
    property color borderColor: appRoot ? appRoot.borderColor : "#d8d8d8"
    property color backgroundColor: appRoot ? appRoot.cardColor : "#ffffff"
    property real cornerRadius: appRoot ? appRoot.radiusMedium : units.gu(1)
    property real innerRadius: appRoot ? appRoot.radiusSmall : units.gu(0.8)
    property real innerMargin: appRoot ? (appRoot.spacingSmall * 0.75) : units.gu(0.6)
    property real indicatorHeight: units.gu(0.35)
    property string bodySmallTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.bodySmall : "small"

    signal selected(int index)

    color: backgroundColor
    border.width: 0
    radius: 0

    Row {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: segmentedTabs.labels ? segmentedTabs.labels.length : 0
            delegate: Rectangle {
                width: parent.width / Math.max(1, segmentedTabs.labels.length)
                height: parent.height
                color: tabMouse.containsMouse ? segmentedTabs.hoverColor : "transparent"

                Label {
                    anchors.centerIn: parent
                    text: segmentedTabs.labels[index]
                    color: index === segmentedTabs.currentIndex ? segmentedTabs.activeTextColor : segmentedTabs.textColor
                    fontSize: segmentedTabs.bodySmallTextSize
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: segmentedTabs.indicatorHeight
                    color: segmentedTabs.activeColor
                    visible: index === segmentedTabs.currentIndex
                }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    onClicked: segmentedTabs.selected(index)
                }
            }
        }
    }
}
