import QtQuick 2.7
import QtQuick.Controls 2.2 as QQC2

QQC2.ScrollBar {
    id: root
    property Flickable flickableItem: null
    property int align: Qt.AlignTrailing

    parent: flickableItem ? flickableItem.parent : null
    anchors.top: flickableItem ? flickableItem.top : undefined
    anchors.bottom: flickableItem ? flickableItem.bottom : undefined
    anchors.right: flickableItem ? flickableItem.right : undefined
    orientation: Qt.Vertical
    policy: QQC2.ScrollBar.AsNeeded
    size: flickableItem && flickableItem.contentHeight > 0
          ? Math.min(1.0, flickableItem.height / flickableItem.contentHeight)
          : 1.0
    position: flickableItem && flickableItem.contentHeight > flickableItem.height
              ? flickableItem.contentY / (flickableItem.contentHeight - flickableItem.height)
              : 0.0
}
