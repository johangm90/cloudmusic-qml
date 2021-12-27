import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.3

PopupBase {
    id: transferFileDialog
    anchors.fill: parent
    property var activeTransfer
    property string fileUrl
    property alias contentType: peerPicker.contentType

    Rectangle {
        anchors.fill: parent
        ContentPeerPicker {
            id: peerPicker
            handler: ContentHandler.Destination
            visible: parent.visible

            onPeerSelected: {
                      activeTransfer = peer.request()
                      if (activeTransfer.state === ContentTransfer.InProgress) {
                          activeTransfer.items = [contentItemComponent.createObject(transferFileDialog, {"url": fileUrl})]
                          activeTransfer.state = ContentTransfer.Charged
                      }
                      PopupUtils.close(transferFileDialog)
            }

            onCancelPressed: {
                PopupUtils.close(transferFileDialog)
            }
        }

        Component {
            id: contentItemComponent
            ContentItem {}
        }
    }
}
