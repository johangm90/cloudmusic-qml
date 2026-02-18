import QtQuick 2.12
import Lomiri.Components 1.3
import QtGraphicalEffects 1.0
import "../logic/CoverCache.js" as CoverCache

ListItem {
    id: row
    property string title: ""
    property string subtitle: ""
    property string durationText: ""
    property string coverSource: ""
    property var albumId: 0
    property bool selected: false
    property bool showMenu: true
    property string leadingText: ""
    property color rowTextColor: "#1f1f1f"
    property color rowSecondaryTextColor: "#777777"
    property color selectedColor: "#dddddd"
    property color menuIconColor: rowSecondaryTextColor

    signal menuClicked(var caller)

    contentItem.anchors.leftMargin: units.gu(1.4)
    contentItem.anchors.rightMargin: units.gu(1.4)
    contentItem.anchors.topMargin: units.gu(0.9)
    contentItem.anchors.bottomMargin: units.gu(0.9)
    divider.visible: false
    color: selected ? selectedColor : "transparent"

    Rectangle {
        id: coverFrame
        width: units.gu(5)
        height: units.gu(5)
        radius: units.gu(0.6)
        color: "#222222"
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        clip: true

        Image {
            id: cover
            anchors.fill: parent
            source: CoverCache.resolve(row.albumId, row.coverSource, "../graphics/default.png")
            fillMode: Image.PreserveAspectCrop
            cache: true
            asynchronous: true
            smooth: true
            visible: false
        }

        OpacityMask {
            anchors.fill: parent
            source: cover
            cached: true
            maskSource: Rectangle {
                width: coverFrame.width
                height: coverFrame.height
                radius: coverFrame.radius
            }
        }
    }

    Label {
        id: leadLabel
        visible: leadingText !== ""
        text: leadingText
        width: units.gu(3)
        anchors.left: coverFrame.right
        anchors.leftMargin: units.gu(0.8)
        anchors.verticalCenter: parent.verticalCenter
        color: rowSecondaryTextColor
        fontSize: "small"
    }

    Label {
        id: titleLabel
        text: title
        elide: Text.ElideRight
        anchors.left: leadingText !== "" ? leadLabel.right : coverFrame.right
        anchors.leftMargin: units.gu(0.8)
        anchors.right: durationLabel.left
        color: rowTextColor
    }

    Label {
        id: subtitleLabel
        text: subtitle
        elide: Text.ElideRight
        anchors.left: leadingText !== "" ? leadLabel.right : coverFrame.right
        anchors.leftMargin: units.gu(0.8)
        anchors.right: durationLabel.left
        anchors.bottom: parent.bottom
        fontSize: "small"
        color: rowSecondaryTextColor
    }

    Label {
        id: durationLabel
        text: durationText
        width: units.gu(6)
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: showMenu ? itemMenu.left : parent.right
        horizontalAlignment: Text.AlignRight
        color: rowSecondaryTextColor
        fontSize: "small"
    }

    MouseArea {
        id: itemMenu
        visible: showMenu
        width: units.gu(5)
        height: parent.height
        anchors.right: parent.right
        onClicked: {
            row.menuClicked(itemMenu)
        }

        Icon {
            height: units.gu(3)
            width: height
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            name: "contextual-menu"
            color: menuIconColor
        }
    }
}
