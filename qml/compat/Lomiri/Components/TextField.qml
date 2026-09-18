import QtQuick 2.7
import QtQuick.Controls 2.2 as QQC2

QQC2.TextField {
    id: control
    selectByMouse: true
    color: Theme.textColor
    placeholderTextColor: Theme.textMutedColor
    background: Rectangle {
        implicitHeight: 36
        radius: 6
        color: Theme.sectionColor
        border.color: Theme.borderColor
        border.width: 1
    }
}
