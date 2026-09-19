import QtQuick 2.12
import Lomiri.Components 1.3

// Full sidebar for expanded (desktop) widths: same action model as
// BottomNavigation/NavigationRail, rendered as icon+label rows with a
// persistent brand mark, the way a desktop window has room for.
Rectangle {
    id: sidebar
    property var appRoot: (typeof cloudMusic !== "undefined" ? cloudMusic : null)
    property var model: []
    property color backgroundColor: appRoot ? appRoot.cardColor : "#ffffff"
    property color borderColor: appRoot ? appRoot.borderColor : "#d8d8d8"
    property color activeColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color activeSurfaceColor: appRoot ? appRoot.selectedColor : Qt.rgba(0.9, 0.2, 0.28, 0.16)
    property color hoverColor: appRoot ? appRoot.surfaceHoverColor : Qt.rgba(0, 0, 0, 0.035)
    property color textColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color inactiveColor: appRoot ? appRoot.secondaryTextColor : "#666666"
    property real itemHeight: units.gu(5.8)
    property real iconSize: units.gu(2.4)
    property real itemRadius: appRoot ? appRoot.radiusMedium : units.gu(1.2)
    property real sidePadding: units.gu(1.6)
    property string labelTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.body : "medium"
    property string brandTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.title : "large"

    color: backgroundColor

    Rectangle {
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: 1
        color: sidebar.borderColor
    }

    Row {
        id: brand
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors.margins: sidebar.sidePadding
        height: units.gu(6)
        spacing: units.gu(1)

        Rectangle {
            width: units.gu(4)
            height: width
            radius: units.gu(1.2)
            anchors.verticalCenter: parent.verticalCenter
            color: sidebar.activeColor

            VectorIcon {
                anchors.fill: parent
                anchors.margins: units.gu(0.8)
                iconName: "volume-2"
                color: "white"
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: units.gu(0.1)

            Label {
                text: "CloudMusic"
                fontSize: sidebar.brandTextSize
                font.weight: Font.DemiBold
                color: sidebar.textColor
            }

            Label {
                text: i18n.tr("Your music space")
                fontSize: "small"
                color: sidebar.inactiveColor
            }
        }
    }

    Column {
        anchors { top: brand.bottom; left: parent.left; right: parent.right; topMargin: units.gu(1.5) }
        spacing: units.gu(0.2)

        Repeater {
            model: sidebar.model

            delegate: Item {
                width: sidebar.width
                height: sidebar.itemHeight

                readonly property bool isActive: !modelData.enabled

                Rectangle {
                    id: itemSurface
                    anchors.fill: parent
                    anchors.leftMargin: sidebar.sidePadding
                    anchors.rightMargin: sidebar.sidePadding
                    radius: sidebar.itemRadius
                    color: isActive ? sidebar.activeSurfaceColor : (itemMouse.containsMouse ? sidebar.hoverColor : "transparent")

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1.4)
                        spacing: units.gu(1.4)

                        VectorIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: sidebar.iconSize
                            height: sidebar.iconSize
                            iconName: modelData.iconName === "find" ? "search" : (modelData.iconName === "slideshow" ? "library" : (modelData.iconName === "contact-group" ? "circle-help" : (modelData.iconName === "stock_music" ? "list-music" : (modelData.iconName === "settings" ? "settings" : "circle-help"))))
                            color: isActive ? sidebar.activeColor : sidebar.inactiveColor
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.text
                            fontSize: sidebar.labelTextSize
                            font.weight: isActive ? Font.DemiBold : Font.Normal
                            color: isActive ? sidebar.activeColor : sidebar.textColor
                        }
                    }
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
