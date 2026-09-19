import QtQuick 2.7
import QtGraphicalEffects 1.0
import "IconLookup.js" as IconLookup

Item {
    id: root
    property string iconName: ""
    signal clicked()
    width: 40
    height: 40

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: width / 2
        color: Theme.textColor
        opacity: mouseArea.pressed ? 0.18 : (mouseArea.containsMouse ? 0.1 : 0)
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    Image {
        id: vectorSource
        anchors.centerIn: parent
        width: 20
        height: 20
        source: IconLookup.assetFor(root.iconName) ? ("qrc:/qml/graphics/icons/" + IconLookup.assetFor(root.iconName) + ".svg") : ""
        visible: false
    }
    ColorOverlay {
        anchors.fill: vectorSource
        source: vectorSource
        color: Theme.textColor
        visible: vectorSource.status === Image.Ready
    }
    Text {
        anchors.centerIn: parent
        text: IconLookup.glyphFor(root.iconName)
        color: Theme.textColor
        font.pixelSize: 18
        visible: vectorSource.status !== Image.Ready
    }
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
