import QtQuick 2.7

Item {
    id: root
    anchors.fill: parent
    property Text title: titleText
    property Text subtitle: subtitleText
    property Text summary: summaryText

    Column {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        Text {
            id: titleText
            width: parent.width
            color: Theme.textColor
            elide: Text.ElideRight
        }
        Text {
            id: subtitleText
            width: parent.width
            visible: text.length > 0
            elide: Text.ElideRight
            font.pixelSize: 12
            color: Theme.textMutedColor
        }
        Text {
            id: summaryText
            width: parent.width
            visible: text.length > 0
            elide: Text.ElideRight
            font.pixelSize: 12
            color: Theme.textMutedColor
        }
    }
}
