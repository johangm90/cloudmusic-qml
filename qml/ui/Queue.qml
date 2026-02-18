import QtQuick 2.12
import Lomiri.Components 1.3
import "../logic/Api.js" as Api
import "../components"

Page {
    id: queuePage
    property var appRoot
    property color selectedColor: appRoot ? appRoot.selectedColor : "#5d5d5d"
    property color textColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color secondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#898B8C"

    header: PageHeader {
        title: i18n.tr("Queue")
    }

    Rectangle {
        id: songs_view
        color: "transparent"
        anchors {
            top: queuePage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: media_player.playbackState != 0 ? units.gu(7.25) : 0
        }

        Item {
            width: parent.width
            height: parent.height

            ListView {
                id: queue_list
                clip: true
                model: playing_page.model_queue
                width: parent.width
                height: parent.height
                boundsBehavior: Flickable.StopAtBounds

                Component.onCompleted: {
                    queue_list.positionViewAtIndex(playing_page.current_index, ListView.Beginning)
                }

                delegate: SongListItem {
                    title: name
                    subtitle: artist
                    durationText: Api.durationToString(duration)
                    coverSource: image
                    albumId: album_id
                    selected: playing_page.current_index == index
                    showMenu: false
                    rowTextColor: textColor
                    rowSecondaryTextColor: secondaryTextColor
                    selectedColor: queuePage.selectedColor
                    onClicked: {
                        media_player.setIndex(index)
                    }
                }
            }
            Scrollbar {
                flickableItem: queue_list
                align: Qt.AlignTrailing
            }
        }
    }
}
