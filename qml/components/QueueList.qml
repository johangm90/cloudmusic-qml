import QtQuick 2.12
import Lomiri.Components 1.3
import "../logic/Format.js" as Format

// Shared track-list rendering for the play queue: used both as the standalone
// Queue page and as NowPlaying's persistent side panel on wide windows, so
// there's one place that owns how a queue row looks and reacts to a tap.
Item {
    id: queueList
    property var appRoot: (typeof cloudMusic !== "undefined" ? cloudMusic : null)
    property var model: null
    property int currentIndex: -1
    property color rowTextColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color rowSecondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#666666"
    property color selectedColor: appRoot ? appRoot.selectedColor : "#5d5d5d"

    signal songActivated(int index)

    function scrollToCurrent() {
        internalList.positionViewAtIndex(queueList.currentIndex, ListView.Beginning)
    }

    ListView {
        id: internalList
        anchors.fill: parent
        clip: true
        model: queueList.model
        boundsBehavior: Flickable.StopAtBounds

        delegate: SongListItem {
            title: name
            subtitle: artist
            durationText: Format.durationToString(duration)
            coverSource: image
            albumId: album_id
            selected: queueList.currentIndex == index
            showMenu: false
            rowTextColor: queueList.rowTextColor
            rowSecondaryTextColor: queueList.rowSecondaryTextColor
            selectedColor: queueList.selectedColor
            onClicked: queueList.songActivated(index)
        }
    }

    Scrollbar {
        flickableItem: internalList
        align: Qt.AlignTrailing
    }
}
