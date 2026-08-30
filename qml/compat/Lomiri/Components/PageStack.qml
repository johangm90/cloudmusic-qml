import QtQuick 2.7
import QtQuick.Controls 2.2 as QQC2

QQC2.StackView {
    id: root
    // Real Lomiri's PageStack always fills its parent by convention; this app's Main.qml
    // relies on that and never sets explicit anchors/size on its own `pagestack` instance.
    anchors.fill: parent
    readonly property Item currentPage: root.currentItem

    // Real Lomiri's PageStack forces the active page visible; several pages in this app
    // are pre-declared with `visible: false` (meant to stay hidden until pushed), which
    // a plain QQC2.StackView does not override on its own.
    // Real Lomiri's PageStack forces the active page visible and fills it to the stack's
    // full content area; several pages in this app are pre-declared with `visible: false`
    // and partial/no anchors (e.g. just anchors.left/right/bottom, relying on the real
    // PageStack to supply the rest), which a plain QQC2.StackView does not do on its own.
    onCurrentItemChanged: {
        if (currentItem) {
            currentItem.visible = true
            currentItem.anchors.fill = root
        }
    }
}
