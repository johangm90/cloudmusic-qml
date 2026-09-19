import QtQuick 2.7
import QtQuick.Controls 2.2

Button {
    id: control
    property color color: "#cccccc"
    property string iconName: ""
    implicitHeight: 44
    hoverEnabled: true
    background: Rectangle {
        implicitHeight: 44
        radius: 12
        color: control.enabled ? (control.pressed ? Qt.darker(control.color, 1.08) : (control.hovered ? Qt.lighter(control.color, 1.06) : control.color)) : Qt.darker(control.color, 1.3)
        opacity: control.enabled ? 1.0 : 0.55
        Behavior on opacity { NumberAnimation { duration: 80 } }
    }
    contentItem: Text {
        text: control.text
        color: control.color.r + control.color.g + control.color.b > 1.9 ? "#211f1e" : "white"
        font.pixelSize: 14
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
