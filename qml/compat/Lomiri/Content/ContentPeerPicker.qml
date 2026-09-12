import QtQuick 2.7

// Real Lomiri.Content shows a system picker for which app should receive the content.
// There is no desktop equivalent, so this immediately reports a peer, letting the caller's
// onPeerSelected handler run (which is what actually finishes the download/save flow in
// this app -- see DownloadDialog.qml / TransferFileDialog.qml).
Item {
    id: root
    property int handler: 0
    property int contentType: 0

    signal peerSelected(var peer)
    signal cancelPressed()

    Component.onCompleted: {
        var peerObj = contentPeerComponent.createObject(root, { "handler": root.handler, "contentType": root.contentType })
        root.peerSelected(peerObj)
    }

    Component {
        id: contentPeerComponent
        ContentPeer {}
    }
}
