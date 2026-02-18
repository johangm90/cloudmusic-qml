import QtQuick 2.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Content 1.3

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
                console.log("File transfer started. File URL: " + fileUrl)
                
                // Validate file URL
                if (!fileUrl || fileUrl === "") {
                    console.error("Transfer error: file URL is empty")
                    PopupUtils.close(transferFileDialog)
                    return
                }
                
                // Ensure proper file:// URL scheme
                var properUrl = fileUrl
                if (!properUrl.startsWith("file://")) {
                    properUrl = "file://" + properUrl
                }
                
                console.log("Using URL for transfer: " + properUrl)
                
                activeTransfer = peer.request()
                if (activeTransfer.state === ContentTransfer.InProgress) {
                    // Create content item with the file
                    try {
                        var contentItem = contentItemComponent.createObject(transferFileDialog, {"url": properUrl})
                        activeTransfer.items = [contentItem]
                        activeTransfer.state = ContentTransfer.Charged
                        console.log("File transfer charged successfully")
                    } catch (e) {
                        console.error("Error during file transfer: " + e)
                    }
                } else {
                    console.error("ContentTransfer not in InProgress state: " + activeTransfer.state)
                }
                PopupUtils.close(transferFileDialog)
            }

            onCancelPressed: {
                console.log("File transfer cancelled")
                PopupUtils.close(transferFileDialog)
            }
        }

        Component {
            id: contentItemComponent
            ContentItem {}
        }
    }
}
