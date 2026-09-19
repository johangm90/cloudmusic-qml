import QtQuick 2.7
import Lomiri.Components 1.3

Column {
    id: root
    width: parent ? parent.width : implicitWidth
    property string text: ""
    property var model: null
    property Component delegate: null
    property int selectedIndex: 0

    onModelChanged: scheduleRebuild()
    onDelegateChanged: scheduleRebuild()

    // ListModel row objects returned by .get() don't expose their roles via a plain
    // `for...in` loop (they're not enumerable own properties), so roles actually used by
    // this app's delegates (name/key) are copied across explicitly. `.append()` also
    // happens after this component is constructed for some callers, so `count` itself
    // (a real bindable property) drives rebuilds too, not just model identity changes.
    Connections {
        target: root.model
        function onCountChanged() { root.scheduleRebuild() }
    }

    // Item.destroy() defers actual removal to the next event loop turn, so calling
    // rebuild() more than once per tick (model + count both changing at startup, or
    // multiple .append() calls) would double-render rows still pending destruction.
    // Qt.callLater coalesces any number of calls within one tick into a single rebuild().
    property bool rebuildPending: false
    function scheduleRebuild() {
        if (rebuildPending) return
        rebuildPending = true
        Qt.callLater(function() {
            root.rebuildPending = false
            root.rebuild()
        })
    }

    function rebuild() {
        for (var i = rows.children.length - 1; i >= 0; i--) {
            rows.children[i].destroy()
        }
        if (!root.delegate || !root.model) {
            return
        }
        for (var j = 0; j < root.model.count; j++) {
            var row = root.model.get(j)
            // `name`/`key` are the only roles any delegate in this app actually binds to
            // (see qml/ui/SettingsPage.qml) -- passed explicitly since ListModel row
            // objects don't expose their roles via `for...in`.
            var props = {}
            if (row.name !== undefined) props.name = row.name
            if (row.key !== undefined) props.key = row.key
            var logic = root.delegate.createObject(rows, props)
            visualRow.createObject(rows, { "rowIndex": j, "logic": logic, "width": Qt.binding(function() { return rows.width }) })
        }
    }

    Text {
        text: root.text
        font.pixelSize: 13
        color: Theme.textMutedColor
    }
    Column {
        id: rows
        width: parent.width
    }

    Component {
        id: visualRow
        Rectangle {
            property int rowIndex: -1
            property QtObject logic: null
            height: 36
            color: root.selectedIndex === rowIndex ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, Theme.dark ? 0.22 : 0.16) : "transparent"
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 8
                text: logic ? logic.text : ""
                color: Theme.textColor
                font.weight: root.selectedIndex === rowIndex ? Font.DemiBold : Font.Normal
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.selectedIndex === rowIndex ? "✓" : ""
                color: Theme.accentColor
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.selectedIndex = rowIndex
                    if (logic) {
                        logic.clicked()
                    }
                }
            }
        }
    }
}
