import QtQuick 2.7
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Layouts 1.3

QQC2.Popup {
    id: root
    property string title: ""
    property string text: ""
    default property alias dialogData: columnLayout.data

    modal: true
    focus: true
    x: (parent ? parent.width - width : 0) / 2
    y: (parent ? parent.height - height : 0) / 2
    width: Math.min(parent ? parent.width * 0.85 : 400, 420)
    contentWidth: columnLayout.implicitWidth
    height: columnLayout.implicitHeight + topPadding + bottomPadding
    closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

    background: Rectangle {
        color: Theme.cardColor
        border.color: Theme.borderColor
        border.width: 1
        radius: 8
    }

    ColumnLayout {
        id: columnLayout
        width: root.availableWidth
        spacing: 8

        Text {
            Layout.fillWidth: true
            visible: root.title.length > 0
            text: root.title
            color: Theme.textColor
            font.pixelSize: 18
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.fillWidth: true
            visible: root.text.length > 0
            text: root.text
            color: Theme.textMutedColor
            wrapMode: Text.WordWrap
        }
    }
}
