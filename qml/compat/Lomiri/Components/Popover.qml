import QtQuick 2.7
import QtQuick.Controls 2.2 as QQC2

QQC2.Popup {
    id: root
    property real callerMargin: 0

    modal: true
    focus: true
    width: contentWidth > 0 ? contentWidth : 200
    height: Math.min(contentHeight > 0 ? contentHeight : implicitHeight, (parent ? parent.height : 400) - 40)
    x: (parent ? parent.width - width : 0) / 2
    y: (parent ? parent.height - height : 0) / 2
    closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

    background: Rectangle {
        color: Theme.cardColor
        border.color: Theme.borderColor
        border.width: 1
        radius: 8
    }
}
