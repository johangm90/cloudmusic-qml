import QtQuick 2.7
import Qt.labs.platform 1.1
import Downloader 1.0

Item {
    id: root
    property bool autoStart: true
    property real progress: 0
    property string path: ""
    property QtObject metadata: null

    signal finished()

    function download(url) {
        var dest = Qt.resolvedUrl(root.destinationPath(url)).toString().replace("file://", "")
        internal.requestId = "dl-" + Date.now() + "-" + Math.floor(Math.random() * 100000)
        internal.backend.download(url, dest, internal.requestId)
    }

    function cancel() {
        internal.backend.cancel()
    }

    // Real SingleDownload lets the download manager pick the destination; we just save
    // into the app's writable data location under the source file's own name.
    function destinationPath(url) {
        var name = url.toString().split("/").pop().split("?")[0]
        if (name.length === 0) {
            name = "download.bin"
        }
        return StandardPaths.writableLocation(StandardPaths.DownloadLocation) + "/" + name
    }

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: internal.backend.pumpDownloads()
    }

    QtObject {
        id: internal
        property string requestId: ""
        property Downloader backend: Downloader {
            onProgress: {
                if (internal.requestId === request_id) {
                    root.progress = total > 0 ? received / total : 0
                }
            }
            onFinished: {
                if (internal.requestId !== request_id) {
                    return
                }
                if (ok) {
                    root.path = path
                }
                root.finished()
            }
        }
    }
}
