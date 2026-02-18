import QtQuick 2.12

Item {
    id: root
    property string name: ""
    property color color: "white"
    property real sourceSize: Math.min(width, height)
    property int basePixelSize: 24

    width: basePixelSize
    height: width

    Image {
        id: iconImage
        anchors.centerIn: parent
        width: root.sourceSize
        height: root.sourceSize
        source: root.name ? ("image://theme/" + root.name) : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: source !== ""
    }

    // Fallback if theme icon is missing
    Rectangle {
        anchors.centerIn: parent
        width: root.sourceSize
        height: root.sourceSize
        radius: width / 2
        color: root.color
        opacity: iconImage.status === Image.Error || iconImage.status === Image.Null ? 0.25 : 0
        visible: opacity > 0
    }
}