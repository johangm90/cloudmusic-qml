import QtQuick 2.7
import QtGraphicalEffects 1.0
import "IconLookup.js" as IconLookup

Item {
    id: root
    property string name: ""
    property color color: Theme.textColor
    width: 24
    height: 24

    Image {
        id: vectorSource
        anchors.centerIn: parent
        width: Math.min(root.width, root.height)
        height: width
        source: IconLookup.assetFor(root.name) ? ("qrc:/qml/graphics/icons/" + IconLookup.assetFor(root.name) + ".svg") : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: false
    }

    ColorOverlay {
        anchors.fill: vectorSource
        source: vectorSource
        color: root.color
        visible: vectorSource.status === Image.Ready
    }

    Text {
        anchors.centerIn: parent
        text: IconLookup.glyphFor(root.name)
        color: root.color
        font.pixelSize: Math.min(root.width, root.height) * 0.72
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        visible: vectorSource.status !== Image.Ready
    }
}
