import QtQuick 2.12
import Lomiri.Components 1.3

// Icon-only navigation rail for medium (tablet) widths: same action model as
// BottomNavigation/Sidebar, just a narrower, vertical rendering with room for
// pointer affordances (hover) that a touch-only bottom bar doesn't need.
Rectangle {
    id: rail
    property var appRoot: (typeof cloudMusic !== "undefined" ? cloudMusic : null)
    property var model: []
    property color backgroundColor: appRoot ? appRoot.cardColor : "#ffffff"
    property color borderColor: appRoot ? appRoot.borderColor : "#d8d8d8"
    property color activeColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color activeSurfaceColor: appRoot ? appRoot.selectedColor : Qt.rgba(0.9, 0.2, 0.28, 0.16)
    property color hoverColor: appRoot ? appRoot.surfaceHoverColor : Qt.rgba(0, 0, 0, 0.035)
    property color inactiveColor: appRoot ? appRoot.secondaryTextColor : "#666666"
    property real itemHeight: units.gu(8)
    property real iconSize: units.gu(2.8)
    property real itemRadius: appRoot ? appRoot.radiusMedium : units.gu(1.2)
    property real itemInset: units.gu(1)

    color: backgroundColor

    Rectangle {
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: 1
        color: rail.borderColor
    }

    Column {
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: units.gu(2) }

        Repeater {
            model: rail.model

            delegate: Item {
                width: rail.width
                height: rail.itemHeight

                readonly property bool isActive: !modelData.enabled

                Rectangle {
                    id: itemSurface
                    anchors.fill: parent
                    anchors.margins: rail.itemInset
                    radius: rail.itemRadius
                    color: isActive ? rail.activeSurfaceColor : (itemMouse.containsMouse ? rail.hoverColor : "transparent")
                }

                VectorIcon {
                    anchors.centerIn: itemSurface
                    width: rail.iconSize
                    height: rail.iconSize
                    iconName: modelData.iconName === "find" ? "search" : (modelData.iconName === "slideshow" ? "library" : (modelData.iconName === "contact-group" ? "circle-help" : (modelData.iconName === "stock_music" ? "list-music" : (modelData.iconName === "settings" ? "settings" : "circle-help"))))
                    color: isActive ? rail.activeColor : rail.inactiveColor
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: modelData.trigger()
                }
            }
        }
    }
}
