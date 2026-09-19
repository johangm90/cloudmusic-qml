import QtQuick 2.7
import QtQuick.Controls 2.2 as QQC2

// The default Basic-style QQC2.Switch renders with a fixed OS-gray track/thumb
// that ignores the app's theme entirely. Give it a themed indicator instead,
// consistent with the accent-filled toggle look used elsewhere in the app.
QQC2.Switch {
    id: control
    indicator: Rectangle {
        implicitWidth: 44
        implicitHeight: 24
        x: control.leftPadding
        y: control.height / 2 - height / 2
        radius: height / 2
        color: control.checked ? Theme.accentColor : Theme.borderColor
        border.color: control.checked ? Theme.accentColor : Theme.borderColor

        Rectangle {
            x: control.checked ? parent.width - width - 2 : 2
            y: 2
            width: 20
            height: 20
            radius: 10
            color: Theme.cardColor
            Behavior on x { NumberAnimation { duration: 120 } }
        }
    }
}
