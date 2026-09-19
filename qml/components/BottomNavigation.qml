import QtQuick 2.12
import Lomiri.Components 1.3

// Persistent primary-navigation bar for compact widths. Renders whatever
// action list it's given (see TabsList) so the nav surface itself has no
// opinion about the app's information architecture -- it just presents it.
Rectangle {
    id: bottomNav
    property var appRoot: (typeof cloudMusic !== "undefined" ? cloudMusic : null)
    property var model: []
    property color backgroundColor: appRoot ? appRoot.cardColor : "#ffffff"
    property color borderColor: appRoot ? appRoot.borderColor : "#d8d8d8"
    property color activeColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color inactiveColor: appRoot ? appRoot.secondaryTextColor : "#666666"
    property string labelTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.caption : "x-small"
    property real iconSize: units.gu(2.6)

    color: backgroundColor

    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 1
        color: bottomNav.borderColor
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: bottomNav.model

            delegate: Item {
                width: bottomNav.width / Math.max(1, bottomNav.model.length)
                height: bottomNav.height

                readonly property bool isActive: !modelData.enabled

                Column {
                    anchors.centerIn: parent
                    spacing: units.gu(0.2)

                    VectorIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: bottomNav.iconSize
                        height: bottomNav.iconSize
                        iconName: modelData.iconName === "find" ? "search" : (modelData.iconName === "slideshow" ? "library" : (modelData.iconName === "contact-group" ? "circle-help" : (modelData.iconName === "stock_music" ? "list-music" : (modelData.iconName === "settings" ? "settings" : "circle-help"))))
                        color: isActive ? bottomNav.activeColor : bottomNav.inactiveColor
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.text
                        fontSize: bottomNav.labelTextSize
                        color: isActive ? bottomNav.activeColor : bottomNav.inactiveColor
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: modelData.trigger()
                }
            }
        }
    }
}
