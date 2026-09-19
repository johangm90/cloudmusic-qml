import QtQuick 2.12
import Lomiri.Components 1.3
import "../components"

Page {
    id: queuePage
    property var appRoot
    property color pageColor: appRoot ? appRoot.pageColor : "#f5f5f5"
    property color selectedColor: appRoot ? appRoot.selectedColor : "#5d5d5d"
    property color textColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color secondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#898B8C"
    property real layoutPlayerInset: appRoot ? appRoot.layoutPlayerInset : units.gu(7.25)

    header: PageHeader {
        title: i18n.tr("Queue")
    }

    Rectangle {
        id: songs_view
        color: pageColor
        anchors {
            top: queuePage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: media_player.playbackState != 0 ? layoutPlayerInset : 0
        }

        QueueList {
            id: queueListView
            anchors.fill: parent
            model: playing_page.model_queue
            currentIndex: playing_page.current_index
            rowTextColor: textColor
            rowSecondaryTextColor: secondaryTextColor
            selectedColor: queuePage.selectedColor
            onSongActivated: media_player.setIndex(index)
            Component.onCompleted: scrollToCurrent()
        }
    }
}
