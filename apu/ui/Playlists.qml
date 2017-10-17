import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import "../components"
import "../logic/Api.js" as Api
import "../logic/Database.js" as Db

Page {
    id: playlistsPage

    onVisibleChanged: {
        if (visible) {
            Db.updateRecords()
        }
    }

    Component.onCompleted: {
        Db.updateRecords()
    }

    TabsList {
        id: tabsList
    }

    header: PageHeader {
        title: i18n.tr("Playlists")
        leadingActionBar {
            numberOfSlots: 0
            actions: tabsList.actions
        }
        trailingActionBar.actions: [
            Action{
                id: addPlaylistAction
                text: i18n.tr("Add Playlist")
                iconName: "add"
                onTriggered: PopupUtils.open(newplaylist)
            }
        ]
    }

    ListModel {
        id: modelo_playlists
    }

    Component {
        id: newplaylist
        Dialog {
            id: create_playlist
            title: i18n.tr("New playlist")

            TextField {
                id: txt_playlist
                placeholderText: i18n.tr("Enter playlist name")
                inputMethodHints: Qt.ImhNoPredictiveText
                onVisibleChanged: {
                    if (visible) {
                        forceActiveFocus()
                    }
                }
            }
            Button {
                text: i18n.tr("Create")
                color: UbuntuColors.green
                onClicked: {
                    Db.insertPlaylist(txt_playlist.text)
                    Db.updateRecords()
                    PopupUtils.close(create_playlist)
                }
            }

            Button {
                text: i18n.tr("Cancel")
                color: UbuntuColors.darkGrey
                onClicked: {
                    PopupUtils.close(create_playlist)
                }
            }
        }
    }

    Component {
        id: editplaylist
        Dialog {
            id: edit_playlist
            title: i18n.tr("Edit playlist")

            TextField {
                id: txt_name
                text: playlist_lista.current
                placeholderText: i18n.tr("Edit playlist name")
                inputMethodHints: Qt.ImhNoPredictiveText
                onVisibleChanged: {
                    if (visible) {
                        forceActiveFocus()
                        selectAll()
                    }
                }
            }
            Button {
                text: i18n.tr("Save")
                color: UbuntuColors.green
                onClicked: {
                    Db.updatePlaylist(playlist_lista.currentId, txt_name.text)
                    Db.updateRecords()
                    PopupUtils.close(edit_playlist)
                }
            }

            Button {
                text: i18n.tr("Cancel")
                color: UbuntuColors.darkGrey
                onClicked: {
                    PopupUtils.close(edit_playlist)
                }
            }
        }
    }

    Component {
        id: delplaylist

        Dialog {
            id: delete_playlist
            title: i18n.tr("Delete playlist")
            text: i18n.tr("This cannot be undone")

            Button {
                text: i18n.tr("Delete")
                color: UbuntuColors.red
                onClicked: {
                    Db.removePlaylist(playlist_lista.currentId)
                    Db.updateRecords()
                    PopupUtils.close(delete_playlist)
                }
            }

            Button {
                text: i18n.tr("Cancel")
                color: UbuntuColors.darkGrey
                onClicked: {
                    PopupUtils.close(delete_playlist)
                }
            }
        }
    }

    Column{
        id: playlists_wrapper
        spacing: units.gu(1)
        anchors {
            top: playlistsPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: media_player.playbackState != 0 ? units.gu(7.25) : 0
        }

        Item {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            ListView {
                id: playlist_lista
                property int currentId: 0
                property string current: ""
                clip: true
                model: modelo_playlists
                width: playlists_wrapper.width
                height: parent.height
                boundsBehavior: Flickable.StopAtBounds
                delegate: ListItem {
                    contentItem.anchors {
                        leftMargin: units.gu(2)
                        rightMargin: units.gu(2)
                        topMargin: units.gu(1)
                        bottomMargin: units.gu(1)
                    }
                    leadingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "delete"
                                onTriggered: {
                                    playlist_lista.currentId = playlistId
                                    PopupUtils.open(delplaylist)
                                }
                            }
                        ]
                    }
                    trailingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "edit"
                                onTriggered: {
                                    playlist_lista.current = playlistName
                                    playlist_lista.currentId = playlistId
                                    PopupUtils.open(editplaylist)
                                }
                            }
                        ]
                    }

                    Label {
                        id: lbl_name
                        text: playlistName
                        elide: Text.ElideRight
                        anchors.left: parent.left
                    }

                    Label {
                        id: lbl_count
                        // TRANSLATORS: %1 refers to the amount of songs in playlist
                        text: i18n.tr("%1 song", "%1 songs", playlistCount).arg(playlistCount)
                        fontSize: "small"
                        elide: Text.ElideRight
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        color: "#898B8C"
                    }

                    onClicked: {
                        playlistDetailPage.title = playlistName
                        playlistDetailPage.header.title = playlistName
                        playlist_detail_page.cargar(playlistId)
                        playlist_detail_page.setStatus(isOffline)
                        pagestack.push(playlistDetailPage)
                    }
                }
            }
            Scrollbar {
                flickableItem: playlist_lista
                align: Qt.AlignTrailing
            }
        }
    }
}
