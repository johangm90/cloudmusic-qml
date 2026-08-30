import QtQuick 2.7

Item {
    id: root
    property string radius: "medium"
    property Item image: null

    onImageChanged: {
        if (image) {
            image.parent = clipRect
            image.anchors.fill = clipRect
        }
    }

    Rectangle {
        id: clipRect
        anchors.fill: parent
        radius: {
            switch (root.radius) {
                case "small": return 6
                case "medium": return 12
                case "large": return 20
                default: return 12
            }
        }
        color: "#eeeeee"
        clip: true
    }
}
