import QtQuick 2.7
import QtQuick.Controls 2.2 as QQC2
import Lomiri.Components 1.3

Row {
    id: root
    property ActionBar bar: null
    property string iconFor: "navigation-menu"

    readonly property int inlineSlots: bar ? bar.numberOfSlots : 0
    readonly property var actionsList: {
        var list = []
        var src = bar ? bar.actions : []
        for (var i = 0; i < src.length; i++) {
            list.push(src[i])
        }
        return list
    }
    readonly property var inlineActions: inlineSlots > 0 ? actionsList.slice(0, inlineSlots) : []
    readonly property var overflowActions: inlineSlots > 0 ? actionsList.slice(inlineSlots) : actionsList

    Repeater {
        model: root.inlineActions
        delegate: HeaderIconButton {
            iconName: modelData.iconName || modelData.name
            onClicked: modelData.trigger()
        }
    }

    HeaderIconButton {
        visible: root.overflowActions.length > 0
        iconName: root.iconFor
        onClicked: overflowMenu.open()
    }

    QQC2.Popup {
        id: overflowMenu
        y: 40
        x: parent.width - width
        width: 220
        modal: true
        focus: true
        closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
        background: Rectangle {
            color: Theme.cardColor
            border.color: Theme.borderColor
            border.width: 1
            radius: 8
        }
        contentItem: Column {
            Repeater {
                model: root.overflowActions
                delegate: QQC2.ItemDelegate {
                    width: 220
                    text: modelData.text
                    height: 48
                    background: Rectangle {
                        color: modelData.enabled ? "transparent" : Qt.rgba(0.9, 0.2, 0.28, 0.16)
                    }
                    contentItem: Row {
                        x: 12
                        spacing: 12
                        Icon {
                            width: 22
                            height: 22
                            anchors.verticalCenter: parent.verticalCenter
                            name: modelData.iconName || ""
                            color: Theme.accentColor
                            visible: name !== ""
                        }
                        Text {
                            width: 150
                            text: modelData.text
                            color: Theme.textColor
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }
                    onClicked: {
                        overflowMenu.close()
                        modelData.trigger()
                    }
                }
            }
        }
    }
}
