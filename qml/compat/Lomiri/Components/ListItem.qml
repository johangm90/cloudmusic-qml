import QtQuick 2.7

Item {
    id: root
    width: parent ? parent.width : implicitWidth
    height: 48
    property color color: "transparent"
    property var leadingActions: null
    property var trailingActions: null
    property ListItemDivider divider: ListItemDivider {}

    signal clicked()
    signal pressAndHold()

    property alias contentItem: contentArea
    default property alias listItemData: contentArea.data

    Rectangle {
        anchors.fill: parent
        color: root.color
    }

    // Pointer-only hover wash, shown only when the row isn't already tinted
    // (selected/pressed) by the caller's own `color` binding. Purely additive --
    // touch interaction never depends on it.
    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceHoverColor
        visible: hoverArea.containsMouse && root.color.a === 0
    }

    // This whole-row click catcher must sit BEHIND `contentArea` (declared next), not
    // after it: a MouseArea declared later paints on top and wins hit-testing first, which
    // would silently swallow clicks meant for interactive children placed in contentArea
    // (e.g. SongListItem's per-row "..." context-menu button) before they ever see them.
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onPressAndHold: root.pressAndHold()
    }

    Item {
        id: contentArea
        anchors.fill: parent
    }

    Rectangle {
        visible: root.divider.visible
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.divider.anchors.leftMargin
        anchors.rightMargin: root.divider.anchors.rightMargin
        height: root.divider.height
        color: Theme.borderColor
    }
}
