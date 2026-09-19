import QtQuick 2.7
import QtQuick.Controls 2.2 as QQC2

QQC2.Popup {
    id: root
    property Component delegate: null
    property QtObject actions: null
    property Item caller: null

    modal: true
    focus: true
    width: 220
    height: Math.min(list.contentHeight, 320)
    // Context menus should follow the control that opened them.  The previous
    // centered position made a song's menu appear detached from its row,
    // especially in long lists.
    x: 0
    y: 0
    closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

    background: Rectangle {
        color: Theme.cardColor
        border.color: Theme.borderColor
        border.width: 1
        radius: 8
    }

    function reposition() {
        if (!root.parent || !root.caller) {
            return
        }
        var point = root.caller.mapToItem(root.parent, 0, 0)
        var margin = 8
        var rightAligned = point.x + root.caller.width - root.width
        var maxX = Math.max(margin, root.parent.width - root.width - margin)
        root.x = Math.max(margin, Math.min(rightAligned, maxX))

        var below = point.y + root.caller.height + margin
        var above = point.y - root.height - margin
        root.y = below + root.height <= root.parent.height - margin
                     ? below
                     : Math.max(margin, above)
    }

    function show() {
        root.open()
        Qt.callLater(root.reposition)
    }

    onOpened: reposition()
    onWidthChanged: if (visible) reposition()
    onHeightChanged: if (visible) reposition()
    // Every call site also declares its own `function close()` on this same instance
    // (to reset its own selection state alongside dismissing the popup), which shadows
    // QQC2.Popup's built-in close() by name. Going through `root.close()` here would
    // resolve back to that same shadowing override and recurse forever, so drop straight
    // to the underlying `visible` state instead -- equivalent for a non-animated popup.
    function hide() { root.visible = false }

    // Real Lomiri's ActionSelectionPopover injects `action` into each delegate instance
    // via a per-item QQmlContext. The only reliable way to reproduce that with pure QML
    // is Qt's own model-role injection (the same mechanism a ListView gives ListModel
    // roles), so each action is copied into a ListModel row under an "action" role.
    ListModel {
        id: actionModel
    }

    function rebuild() {
        actionModel.clear()
        if (!root.actions) {
            return
        }
        var list = root.actions.actions
        for (var i = 0; i < list.length; i++) {
            actionModel.append({ "action": list[i] })
        }
    }

    onActionsChanged: rebuild()

    contentItem: ListView {
        id: list
        clip: true
        model: actionModel
        delegate: root.delegate
    }
}
