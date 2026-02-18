import QtQuick 2.12
import Lomiri.Components 1.3
import QtGraphicalEffects 1.0
import "../logic/CoverCache.js" as CoverCache

ListItem {
    id: row
    property var appRoot: (typeof cloudMusic !== "undefined" ? cloudMusic : null)
    property string title: ""
    property string subtitle: ""
    property string durationText: ""
    property string coverSource: ""
    property var albumId: 0
    property bool selected: false
    property bool showMenu: true
    property string leadingText: ""
    property color rowTextColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color rowSecondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#666666"
    property color selectedColor: appRoot ? appRoot.selectedColor : Qt.rgba(0.9, 0.2, 0.28, 0.16)
    property color menuIconColor: rowSecondaryTextColor
    property real spacingSmall: appRoot ? appRoot.spacingSmall : units.gu(0.8)
    property real spacingMedium: appRoot ? appRoot.spacingMedium : units.gu(1.2)
    property real compactSpacing: spacingSmall + units.gu(0.1)
    property real sideInset: spacingMedium + units.gu(0.2)
    property real coverSize: units.gu(5)
    property real coverRadius: appRoot ? appRoot.radiusSmall : units.gu(0.6)
    property real leadWidth: units.gu(3)
    property real textInset: spacingSmall
    property real durationWidth: units.gu(6)
    property real menuWidth: units.gu(5)
    property real menuIconSize: units.gu(3)
    property string smallTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.bodySmall : "small"

    signal menuClicked(var caller)

    contentItem.anchors.leftMargin: sideInset
    contentItem.anchors.rightMargin: sideInset
    contentItem.anchors.topMargin: compactSpacing
    contentItem.anchors.bottomMargin: compactSpacing
    divider.visible: false
    color: selected ? selectedColor : "transparent"

    Rectangle {
        id: coverFrame
        width: coverSize
        height: coverSize
        radius: coverRadius
        color: appRoot ? appRoot.sectionColor : "#ececec"
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
        width: leadWidth
        anchors.left: coverFrame.right
        anchors.leftMargin: textInset
        anchors.verticalCenter: parent.verticalCenter
        color: rowSecondaryTextColor
        fontSize: smallTextSize
    }

    Label {
        id: titleLabel
        text: title
        elide: Text.ElideRight
        anchors.left: leadingText !== "" ? leadLabel.right : coverFrame.right
        anchors.leftMargin: textInset
        anchors.right: durationLabel.left
        color: rowTextColor
    }

    Label {
        id: subtitleLabel
        text: subtitle
        elide: Text.ElideRight
        anchors.left: leadingText !== "" ? leadLabel.right : coverFrame.right
        anchors.leftMargin: textInset
        anchors.right: durationLabel.left
        anchors.bottom: parent.bottom
        fontSize: smallTextSize
        color: rowSecondaryTextColor
    }

    Label {
        id: durationLabel
        text: durationText
        width: durationWidth
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: showMenu ? itemMenu.left : parent.right
        horizontalAlignment: Text.AlignRight
        color: rowSecondaryTextColor
        fontSize: smallTextSize
    }

    MouseArea {
        id: itemMenu
        visible: showMenu
        width: menuWidth
        height: parent.height
        anchors.right: parent.right
        onClicked: {
            row.menuClicked(itemMenu)
        }

        Icon {
            height: menuIconSize
            width: height
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            name: "contextual-menu"
            color: menuIconColor
        }
    }
}
