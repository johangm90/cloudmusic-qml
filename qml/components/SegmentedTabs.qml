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
    property color borderColor: appRoot ? appRoot.borderColor : "#d8d8d8"
    property color backgroundColor: appRoot ? appRoot.cardColor : "#ffffff"
    property real cornerRadius: appRoot ? appRoot.radiusMedium : units.gu(1)
    property real innerRadius: appRoot ? appRoot.radiusSmall : units.gu(0.8)
    property real innerMargin: appRoot ? (appRoot.spacingSmall * 0.75) : units.gu(0.6)
    property string bodySmallTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.bodySmall : "small"

    signal selected(int index)

    color: backgroundColor
    border.color: borderColor
    border.width: 1
    radius: segmentedTabs.cornerRadius
    clip: true

    Row {
        anchors.fill: parent
        anchors.margins: segmentedTabs.innerMargin
        spacing: segmentedTabs.innerMargin

        Repeater {
            model: segmentedTabs.labels ? segmentedTabs.labels.length : 0
            delegate: Rectangle {
                width: (parent.width - ((segmentedTabs.labels.length - 1) * segmentedTabs.innerMargin)) / Math.max(1, segmentedTabs.labels.length)
                height: parent.height
                radius: segmentedTabs.innerRadius
                color: index === segmentedTabs.currentIndex ? segmentedTabs.activeColor : "transparent"
                border.color: index === segmentedTabs.currentIndex ? segmentedTabs.activeColor : segmentedTabs.borderColor
                border.width: 1

                Label {
                    anchors.centerIn: parent
                    text: segmentedTabs.labels[index]
                    color: index === segmentedTabs.currentIndex ? segmentedTabs.activeTextColor : segmentedTabs.textColor
                    fontSize: segmentedTabs.bodySmallTextSize
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: segmentedTabs.selected(index)
                }
            }
        }
    }
}
