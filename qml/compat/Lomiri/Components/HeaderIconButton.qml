import QtQuick 2.7
import "IconLookup.js" as IconLookup

Item {
    property string iconName: ""
    signal clicked()
    width: 40
    height: 40
    Text {
        anchors.centerIn: parent
        text: IconLookup.glyphFor(parent.iconName)
        font.pixelSize: 18
    }
    MouseArea {
        anchors.fill: parent
        onClicked: parent.clicked()
    }
}
