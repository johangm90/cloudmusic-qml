import QtQuick 2.7
import Ubuntu.Components 1.3
import "../logic/Api.js" as Api

Page {
    id: queuePage

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

                delegate: ListItem {
                    contentItem.anchors {
                        leftMargin: units.gu(2)
                        rightMargin: units.gu(2)
                        topMargin: units.gu(1)
                        bottomMargin: units.gu(1)
                    }

                    color: playing_page.current_index == index ? "#5d5d5d" : "transparent"

                    Label {
                        id: lbl_name
                        text: name
                        elide: Label.ElideRight
                        anchors.left: parent.left
                        anchors.right: lbl_duration.left
                    }

                    Label {
                        id: lbl_artist
                        text: artist
                        fontSize: "small"
                        color: "#898B8C"
                        elide: Label.ElideRight
                        anchors.left: parent.left
                        anchors.right: lbl_duration.left
                        anchors.bottom: parent.bottom
                    }

                    Label {
                        id: lbl_duration
                        text: Api.durationToString(duration)
                        width: units.gu(5)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        horizontalAlignment: Text.AlignRight
                    }

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
