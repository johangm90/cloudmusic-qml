import QtQuick 2.7

Item {
    id: root
    anchors.fill: parent
    property string title: ""
    property Item header: null

    // `header` must be a genuine sibling of the page's own content children (declared
    // directly in subclasses, e.g. `Page { Rectangle { anchors.top: somePage.header.bottom } }`)
    // for that extremely common anchoring pattern to work -- QML anchors require a
    // parent/child or sibling relationship. So content children stay on Item's own
    // inherited default `data` property (no redirection to a separate contentArea), and
    // `header` is simply reparented into the same `root` they already live in.
    onHeaderChanged: {
        if (header) {
            header.parent = root
            header.anchors.left = root.left
            header.anchors.right = root.right
            header.anchors.top = root.top
        }
    }
}
