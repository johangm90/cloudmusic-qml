import QtQuick 2.12
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Layouts 1.0
import "../logic/Api.js" as Api
import "../logic/Database.js" as Db

Item {

    function open_dialog() {
        PopupUtils.open(addsong)
    }

    function get_playlists() {
        modelo_playlists.clear()
        var records = Db.getPlaylists()
        for ( var i = 0; i < records.length; i++) {
            modelo_playlists.append({'playlistId': records[i].id, 'playlistName': records[i].name, 'playlistCount': records[i].count, 'isOffline': records[i].offline})
        }
    }

    function add_song(pid) {
        for(var i=0; i<song_model.count; i++){
            var sid = song_model.get(i).id
            var name = song_model.get(i).name
            var artist_id = song_model.get(i).artist_id
            var artist = song_model.get(i).artist
            var album_id = song_model.get(i).album_id
            var album = song_model.get(i).album
            var duration = song_model.get(i).duration
            var playlist = pid
            var song = [sid, name, artist_id, artist, album_id, album, duration, playlist]
            Db.insertSong(song)
        }
        if(song_model.count>1){
            messager.show_message(i18n.tr("Album added to playlist"), 3)
            album_name = ""
        }else{
            messager.show_message(i18n.tr("Song added to playlist"), 3)
        }
    }

    property ListModel model_song: ListModel{
        id: song_model
    }

    property string album_name: ""

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
                text: album_name != "" ? txt_playlist.text = album_name : ""
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
                    Db.getLastPlaylist()
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
        id: addsong

        Dialog {
            id: addto
            title: i18n.tr("Add to playlist")
            text: i18n.tr("Select one playlist to add")

            ListItem {

                Icon {
                    id: icon
                    width: units.gu(3)
                    height: width
                    name: "add"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Label {
                    text: i18n.tr("Create new playlist")
                    anchors.left: icon.right
                    anchors.leftMargin: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                }

                onClicked: {
                    PopupUtils.close(addto)
                    PopupUtils.open(newplaylist)
                }
            }

            OptionSelector {
                id: playlistSelector
                model: modelo_playlists
                containerHeight: itemHeight * 4
                delegate: delegator
            }

            Component {
                id: delegator
                OptionSelectorDelegate {
                    text: playlistName
                }
            }

            Button {
                text: i18n.tr("Add")
                color: UbuntuColors.green
                onClicked: {
                    var pid = modelo_playlists.get(playlistSelector.selectedIndex).playlistId
                    add_song(pid)
                    PopupUtils.close(addto)
                }
            }

            Button {
                text: i18n.tr("Cancel")
                color: UbuntuColors.darkGrey
                onClicked: {
                    PopupUtils.close(addto)
                }
            }
        }
    }
}

