import QtQuick 2.7
import QtQuick.Controls 2.2 as QQC2

QQC2.StackView {
    id: root
    // Real Lomiri's PageStack always fills its parent by convention; this app's Main.qml
    // relies on that and never sets explicit anchors/size on its own `pagestack` instance.
    anchors.fill: parent
    readonly property Item currentPage: root.currentItem

    // Real Lomiri's PageHeader auto-grows a leading "back" chevron whenever its page
    // isn't the bottom of the stack. This app's pages (NowPlaying, Queue, Artist, Album,
    // PlaylistDetail, Favorites, Recently Played) were written assuming that happens for
    // free and never declare their own leadingActionBar/back action, so without this a
    // pushed page has no way back at all. The single reusable Action below is (re)parented
    // onto whichever header needs it; root-level tab pages set their own leadingActionBar
    // (the hamburger tab switcher) and are always at depth 1, so they're untouched.
    property Component backActionComponent: Component {
        Action {
            iconName: "back"
            text: qsTr("Back")
            onTriggered: root.pop()
        }
    }

    function ensureBackAction(page) {
        if (!page || !page.header || !page.header.leadingActionBar) {
            return
        }
        var bar = page.header.leadingActionBar
        if (root.depth > 1 && bar.actions.length === 0) {
            bar.actions = [backActionComponent.createObject(bar)]
        }
    }

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
            ensureBackAction(currentItem)
        }
    }
}
