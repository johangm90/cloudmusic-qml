import QtQuick 2.7
import QtQuick.Layouts 1.3

Rectangle {
    id: root
    height: 56
    color: "#f5f5f5"

    property string title: ""
    property Item contents: null
    property ActionBar leadingActionBar: ActionBar {}
    property ActionBar trailingActionBar: ActionBar {}
    property alias extension: extensionLoader.sourceComponent

    onContentsChanged: {
        if (contents) {
            contents.parent = root
            contents.anchors.fill = titleRow
            contents.anchors.margins = 4
        }
    }

    RowLayout {
        id: titleRow
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 4

        // Real Lomiri's numberOfSlots controls how many actions show inline before the
        // rest collapse into an overflow menu; this app always uses numberOfSlots: 0
        // (everything overflows), so a single menu button is enough for "functional, not
        // pixel-perfect" fidelity.
        HeaderActionRow {
            bar: root.leadingActionBar
            iconFor: "navigation-menu"
        }

        Text {
            Layout.fillWidth: true
            text: root.title
            elide: Text.ElideRight
            font.pixelSize: 20
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
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
