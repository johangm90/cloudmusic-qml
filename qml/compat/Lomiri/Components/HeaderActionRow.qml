import QtQuick 2.7
import QtQuick.Controls 2.2 as QQC2

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
        contentItem: Column {
            Repeater {
                model: root.overflowActions
                delegate: QQC2.ItemDelegate {
                    width: 220
                    text: modelData.text
                    onClicked: {
                        overflowMenu.close()
                        modelData.trigger()
                    }
                }
            }
        }
    }
}
