import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.ListItems 1.0 as UListItem
import Lomiri.DownloadManager 1.2
import FileManager 1.0
import "../components"
import "../logic/Api.js" as Api
import "../logic/Database.js" as Db

Item {
    id: playlist
    property var appRoot
    property color selectedColor: appRoot ? appRoot.selectedColor : "#5d5d5d"
    property color textColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color secondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#898B8C"

    function cargar(id) {
        Db.getPlaylist(id);
        songsList.currentId = id
    }

    function setStatus(status) {
        swdownload.isOffline = status
    }

    ListModel {
        id: songsModel
    }

    Rectangle {
        id: offlineView
        color: "transparent"
        width: parent.width
        height: units.gu(5)

        Label {
            id: lblOffline
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            anchors.verticalCenter: parent.verticalCenter
            text: i18n.tr("Available offline")
            fontSize: "medium"
        }

        SingleDownload {
            id: imageDownloader
            property int counter;
            property string songId;
            onFinished: {
                counter=counter+1;
                var finalLocation = fileManager.saveDownload(path);
                Db.setlocalArt(finalLocation, songId);
                console.log("Downloaded Image: " + finalLocation);
                if(downloadqueue.count>counter){
                    Api.downloadImage(counter);
                }
            }
        }

        SingleDownload {
            id: musicDownloader
            property int counter;
            property string songId;
            property string songName;

            metadata: Metadata {
                showInIndicator: true
                title: musicDownloader.songName;
            }

            onFinished: {
                counter=counter+1;
                var finalLocation = fileManager.saveDownload(path);
                Db.setlocal(finalLocation, songId);
                console.log("Download Queue: " + downloadqueue.count);
                if (downloadqueue.count>counter) {
                    Api.downloadSong(counter);
                } else {
                    //progreso.value=0;
                    //progreso.visible=false;
                }
            }
        }

        ListModel {
            id: downloadqueue
        }

        Switch {
            id: swdownload
            property int isOffline: 0;
            anchors.right: parent.right
            anchors.rightMargin: units.gu(2)
            anchors.verticalCenter: parent.verticalCenter
            checked: (isOffline == 1) ? true : false
            onCheckedChanged: {
                if (swdownload.checked==true) {
                    Db.setOffline(songsList.currentId, 1)
                    musicDownloader.counter=0;
                    Api.adddownloads();
                } else {
                    Db.setOffline(songsList.currentId, 0)
                }
                console.log("Offline: " + isOffline)
            }
        }
    }

    ActionSelectionPopover {
        id: context_menu
        z: 999

        function close() {
            context_menu.hide()
            songsList.index = -1
        }

        delegate: ListItem {

            contentItem.anchors {
                leftMargin: units.gu(2)
                rightMargin: units.gu(2)
            }

            Icon {
                id: icon
                width: units.gu(3)
                height: width
                name: action.name
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                text: action.text
                anchors.left: icon.right
                anchors.leftMargin: units.gu(2)
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        actions: ActionList {
            Action {
                text: i18n.tr("Download")
                name: "save"
                onTriggered: {
                    Api.download(songsModel.get(songsList.index).song_id, songsModel.get(songsList.index).name)
                    context_menu.close()
                }
            }
            Action {
                text: i18n.tr("Remove")
                name: "close"
                onTriggered: {
                    Db.removeSong(songsModel.get(songsList.index).id)
                    Db.getPlaylist(songsModel.get(songsList.index).playlist_id)
                    context_menu.close()
                    messager.show_message(i18n.tr("Song removed"), 3)
                }
            }
            Action {
                text: i18n.tr("Add to queue")
                name: "navigation-menu"
                onTriggered: {
                    playing_page.songs_list.push(songsModel.get(songsList.index).id)
                    var quality = (appRoot && appRoot.settings) ? appRoot.settings.streaming_quality : "320"
                    var server = appRoot ? appRoot.server : ""
                    media_player.additem(server + 'play/' + songsModel.get(songsList.index).id + '/' + quality)
                    //media_player.additem(cloudMusic.server1 + 'url?id=' + songsModel.get(songsList.index).id + '&br=' + cloudMusic.settings.streaming_quality + '&raw')
                    playing_page.model_queue.append(songsModel.get(songsList.index))
                    context_menu.close()
                    messager.show_message(i18n.tr("Song added to queue"), 3)
                }
            }
            Action {
                text: i18n.tr("Go to album")
                name: "slideshow"
                onTriggered: {
                    album_page.cargar(songsModel.get(songsList.index).album_id);
                    pagestack.push(albumPage);
                    context_menu.close()
                }
            }
            Action {
                text: i18n.tr("Go to artist")
                name: "contact"
                onTriggered: {
                    artist_page.cargar(songsModel.get(songsList.index).artist_id);
                    pagestack.push(artistPage);
                    context_menu.close()
                }
            }
        }
    }

    Column {
        id: playlist_wrapper
        spacing: units.gu(1)
        anchors {
            bottomMargin: media_player.playbackState != 0 ? units.gu(7.25) : 0
            right: parent.right
            left: parent.left
            top: offlineView.bottom
            bottom: parent.bottom
        }

        UListItem.ThinDivider {
            anchors.top: lblOffline.botton
            anchors.topMargin: units.gu(2)
        }

        Item {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            ListView {
                id: songsList
                property int index: -1
                property int currentId: 0
                clip: true
                model: songsModel
                width: playlist_wrapper.width
                height: parent.height
                boundsBehavior: Flickable.StopAtBounds
                delegate: SongListItem {
                    title: name
                    subtitle: artist
                    durationText: Api.durationToString(duration)
                    coverSource: image
                    albumId: album_id
                    selected: songsList.index == index
                    rowTextColor: textColor
                    rowSecondaryTextColor: secondaryTextColor
                    selectedColor: playlist.selectedColor
                    onMenuClicked: {
                        if (songsList.index == index) {
                            context_menu.close()
                        } else {
                            songsList.index = index
                        }
                        context_menu.caller = caller
                        context_menu.show()
                    }
                    onClicked: {
                        pagestack.push(playingPage)
                        var songs = [];
                        var songs_ids = [];
                        playing_page.model_queue.clear();
                        for (var i = 0; i < songsModel.count; i++) {
                            if (songsModel.get(i).local) {
                                songs.push(Qt.resolvedUrl(songsModel.get(i).local))
                            } else {
                                var quality = (appRoot && appRoot.settings) ? appRoot.settings.streaming_quality : "320"
                                var server = appRoot ? appRoot.server : ""
                                songs.push(server + 'play/' + songsModel.get(i).song_id + '/' + quality);
                            }
                            songs_ids.push(songsModel.get(i).song_id);
                            playing_page.model_queue.append(songsModel.get(i));
                        }
                        playing_page.songs_list = songs_ids
                        media_player.setPlaylist(songs, index)
                    }
                    onPressAndHold: ListView.view.ViewItems.dragMode = !ListView.view.ViewItems.dragMode
                }
                ViewItems.onDragUpdated: {
                    if (event.status == ListItemDrag.Moving) {
                        event.accept = false
                    } else if (event.status == ListItemDrag.Dropped) {
                        model.move(event.from, event.to, 1);
                        for (var i = 0; i < songsModel.count; i++) {
                            Db.updateSong(i+1, songsModel.get(i).id)
                            console.log("Reordering: " + i)
                        }
                        Db.getPlaylist(songsModel.get(0).playlistId);
                    }
                }

                moveDisplaced: Transition {
                    LomiriNumberAnimation {
                        property: "y"
                    }
                }
            }
            Scrollbar {
                flickableItem: songsList
                align: Qt.AlignTrailing
            }
        }
    }
}
