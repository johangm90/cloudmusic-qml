import QtQuick 2.12
import Lomiri.Components 1.3
import QtGraphicalEffects 1.0
import "../logic/CoverCache.js" as CoverCache

ListItem {
    id: row
    property var appRoot: (typeof cloudMusic !== "undefined" ? cloudMusic : null)
    property string title: ""
    property string subtitle: ""
    property string metaText: ""
    property string coverSource: ""
    property var albumId: 0
    property bool selected: false
    property color rowTextColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color rowSecondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#666666"
    property color selectedColor: appRoot ? appRoot.selectedColor : Qt.rgba(0.9, 0.2, 0.28, 0.16)
    property real spacingSmall: appRoot ? appRoot.spacingSmall : units.gu(0.8)
    property real spacingMedium: appRoot ? appRoot.spacingMedium : units.gu(1.2)
    property real compactSpacing: spacingSmall + units.gu(0.1)
    property real sideInset: spacingMedium + units.gu(0.2)
    property real coverSize: units.gu(5)
    property real coverRadius: appRoot ? appRoot.radiusSmall : units.gu(0.6)
    property real textInset: spacingSmall
    property real metaWidth: units.gu(8)
    property string smallTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.bodySmall : "small"

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
        id: titleLabel
        text: title
        elide: Text.ElideRight
        anchors.left: coverFrame.right
        anchors.leftMargin: textInset
        anchors.right: metaLabel.left
        color: rowTextColor
    }

    Label {
        id: subtitleLabel
        text: subtitle
        elide: Text.ElideRight
        anchors.left: coverFrame.right
        anchors.leftMargin: textInset
        anchors.right: metaLabel.left
        anchors.bottom: parent.bottom
        fontSize: smallTextSize
        color: rowSecondaryTextColor
    }

    Label {
        id: metaLabel
        text: metaText
        width: metaWidth
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        horizontalAlignment: Text.AlignRight
        color: rowSecondaryTextColor
        fontSize: smallTextSize
    }
}
