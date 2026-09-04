import QtQuick 2.7

Item {
    id: root
    anchors.fill: parent ? parent : undefined
    visible: false
    z: 1000

    function show() { root.visible = true }
    function hide() { root.visible = false }
}
