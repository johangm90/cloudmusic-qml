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
    x: (parent ? parent.width - width : 0) / 2
    y: (parent ? parent.height - height : 0) / 2
    closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

    function show() { root.open() }
    function hide() { root.close() }

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
