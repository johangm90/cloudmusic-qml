import QtQuick 2.12
import QtGraphicalEffects 1.0

Item {
    id: root
    property string iconName: "circle-help"
    property color color: "white"
    property real sourceSize: Math.min(width, height)

    Image {
        id: iconImage
        anchors.centerIn: parent
        width: root.sourceSize
        height: root.sourceSize
        source: Qt.resolvedUrl("../graphics/icons/" + root.iconName + ".svg")
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: false
    }

    ColorOverlay {
        anchors.fill: iconImage
        source: iconImage
        color: root.color
        visible: iconImage.status === Image.Ready
    }
}
