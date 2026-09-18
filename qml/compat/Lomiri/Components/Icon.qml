import QtQuick 2.7
import "IconLookup.js" as IconLookup

Item {
    id: root
    property string name: ""
    property color color: Theme.textColor
    width: 24
    height: 24

    Text {
        anchors.centerIn: parent
        text: IconLookup.glyphFor(root.name)
        color: root.color
        font.pixelSize: Math.min(root.width, root.height) * 0.72
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
