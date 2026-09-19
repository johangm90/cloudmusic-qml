import QtQuick 2.7

Item {
    id: root
    width: parent ? parent.width : implicitWidth
    height: containerHeight
    property var model: null
    property Component delegate: null
    property real containerHeight: 200
    property int selectedIndex: 0

    onModelChanged: scheduleRebuild()
    onDelegateChanged: scheduleRebuild()

    Connections {
        target: root.model
        function onCountChanged() { root.scheduleRebuild() }
    }

    // Item.destroy() defers actual removal to the next event loop turn; coalesce any
    // number of rebuild triggers within one tick into a single rebuild() (see the same
    // fix/comment in ListItems/ItemSelector.qml for why).
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
            // ListModel row objects don't expose their roles via `for...in`; `playlistName`
            // is the only role this app's OptionSelectorDelegate templates bind to.
            var props = {}
            if (row.playlistName !== undefined) props.playlistName = row.playlistName
            var logic = root.delegate.createObject(rows, props)
            visualRow.createObject(rows, { "rowIndex": j, "logic": logic, "width": Qt.binding(function() { return rows.width }) })
        }
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: rows.implicitHeight
        Column {
            id: rows
            width: parent.width
        }
    }

    Component {
        id: visualRow
        Rectangle {
            property int rowIndex: -1
            property QtObject logic: null
            height: 40
            color: root.selectedIndex === rowIndex ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, Theme.dark ? 0.22 : 0.16) : "transparent"
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 8
                text: logic ? logic.text : ""
                color: Theme.textColor
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.selectedIndex = rowIndex
            }
        }
    }
}
