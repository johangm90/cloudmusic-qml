import QtQuick 2.7
import QtQuick.Layouts 1.3

Rectangle {
    id: root
    height: 64
    color: Theme.pageColor

    property string title: ""
    property Item contents: null
    property ActionBar leadingActionBar: ActionBar {}
    property ActionBar trailingActionBar: ActionBar {}
    property alias extension: extensionLoader.sourceComponent

    // `contents` (e.g. a search TextField) replaces only the title slot, not the whole
    // row -- it must never cover the leading/trailing action buttons (back button, tab
    // switcher, overflow menu), or they become invisible and unreachable.
    onContentsChanged: {
        if (contents) {
            contents.parent = titleSlot
            contents.anchors.fill = titleSlot
        }
    }

    RowLayout {
        id: titleRow
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 8

        // Real Lomiri's numberOfSlots controls how many actions show inline before the
        // rest collapse into an overflow menu; this app always uses numberOfSlots: 0
        // (everything overflows), so a single menu button is enough for "functional, not
        // pixel-perfect" fidelity.
        HeaderActionRow {
            bar: root.leadingActionBar
            iconFor: "navigation-menu"
        }

        Item {
            id: titleSlot
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.fill: parent
                visible: !root.contents
                text: root.title
                color: Theme.textColor
                elide: Text.ElideRight
                font.pixelSize: 22
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            }
        }

        HeaderActionRow {
            bar: root.trailingActionBar
            iconFor: "contextual-menu"
            layoutDirection: Qt.RightToLeft
        }
    }

    Loader {
        id: extensionLoader
        anchors.top: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
    }
}
