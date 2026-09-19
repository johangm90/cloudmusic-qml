import QtQuick 2.7
import QtQuick.Controls 2.2

Button {
    id: control
    property color color: "#cccccc"
    property string iconName: ""
    implicitHeight: 40
    background: Rectangle {
        implicitHeight: 40
        radius: 9
        color: control.enabled ? control.color : Qt.darker(control.color, 1.3)
        opacity: control.pressed ? 0.8 : 1.0
        Behavior on opacity { NumberAnimation { duration: 80 } }
    }
    contentItem: Text {
        text: control.text
        color: "white"
        font.pixelSize: 14
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
