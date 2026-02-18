import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.ListItems 1.0 as UListItem
import Lomiri.DownloadManager 1.2
import FileManager 1.0
import "../components"
import "../logic/Format.js" as Format
import "../logic/RequestBus.js" as RequestBus
import "../logic/Database.js" as Db

Item {
    id: playlist
    property var appRoot
    property color selectedColor: appRoot ? appRoot.selectedColor : "#5d5d5d"
    property color textColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color secondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#898B8C"
    property real spacingSmall: appRoot ? appRoot.spacingSmall : units.gu(0.8)
    property real spacingMedium: appRoot ? appRoot.spacingMedium : units.gu(1.2)
    property real layoutPlayerInset: appRoot ? appRoot.layoutPlayerInset : units.gu(7.25)
    property real compactSpacing: spacingSmall + units.gu(0.2)
    property string bodyTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.body : "medium"
    property int offlinePendingCount: 0
    property int offlineResolvedCount: 0
    property string offlineRequestContext: "playlist_offline_" + String(Date.now())

    function cargar(id) {
        Db.getPlaylist(id);
        songsList.currentId = id
    }

    function setStatus(status) {
        swdownload.isOffline = status
    }

    function downloadImageAt(index) {
        if (index < 0 || index >= downloadqueue.count) {
            return
        }
        imageDownloader.songId = downloadqueue.get(index).songId
        imageDownloader.download(downloadqueue.get(index).img)
    }

    function downloadSongAt(index) {
        if (index < 0 || index >= downloadqueue.count) {
            return
        }
        musicDownloader.songId = downloadqueue.get(index).songId
        musicDownloader.songName = downloadqueue.get(index).songName
        musicDownloader.download(downloadqueue.get(index).url)
    }

    function startOfflineDownloadQueue() {
        if (!appRoot || !appRoot.cloudApi) {
            return
        }
        RequestBus.cancelContext(offlineRequestContext)
        downloadqueue.clear()
        offlinePendingCount = 0
        offlineResolvedCount = 0
        imageDownloader.counter = 0
        musicDownloader.counter = 0
        var quality = (appRoot.settings && appRoot.settings.download_quality) ? appRoot.settings.download_quality : "96"
        for (var i = 0; i < songsModel.count; i++) {
            var song = songsModel.get(i)
            if (song.local) {
                continue
            }
            (function(songId, songName) {
                var requestId = RequestBus.createId("offline_url")
                offlinePendingCount += 1
                RequestBus.registerRequest(requestId, {
                    context: offlineRequestContext,
                    onSuccess: function(payload) {
                        if (payload && payload.url) {
                            downloadqueue.append({
                                songId: songId,
                                songName: songName,
                                url: payload.url,
                                img: payload.img || ""
                            })
                        } else {
                            console.error("Offline download payload invalid for request " + requestId)
                        }
                    },
                    onError: function(err) {
                        console.error("Offline download URL request failed: " + err)
                    },
                    onFinally: function() {
                        offlineResolvedCount += 1
                        if (offlinePendingCount > 0 && offlineResolvedCount >= offlinePendingCount) {
                            if (downloadqueue.count > 0) {
                                playlist.downloadSongAt(0)
                                playlist.downloadImageAt(0)
                            }
                        }
                    }
                })
                appRoot.cloudApi.downloadUrlAsync(String(songId), String(quality), requestId)
            })(song.song_id, song.name)
        }
    }

    Component.onDestruction: {
        RequestBus.cancelContext(offlineRequestContext)
    }

    Connections {
        target: appRoot ? appRoot.cloudApi : null
        onRequestFinished: function(requestId, ok, payloadJson, error) {
            RequestBus.dispatch(requestId, ok, payloadJson, error)
        }
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
            anchors.leftMargin: spacingMedium + spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            text: i18n.tr("Available offline")
            fontSize: bodyTextSize
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
                    playlist.downloadImageAt(counter);
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
                    playlist.downloadSongAt(counter);
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
            anchors.rightMargin: spacingMedium + spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            checked: (isOffline == 1) ? true : false
            onCheckedChanged: {
                if (swdownload.checked==true) {
                    Db.setOffline(songsList.currentId, 1)
                    musicDownloader.counter=0;
                    playlist.startOfflineDownloadQueue()
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
                leftMargin: spacingMedium + spacingSmall
                rightMargin: spacingMedium + spacingSmall
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
                anchors.leftMargin: spacingMedium + spacingSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        actions: ActionList {
            Action {
                text: i18n.tr("Download")
                name: "save"
                onTriggered: {
                    if (appRoot && appRoot.requestSongDownload) {
                        appRoot.requestSongDownload(
                            songsModel.get(songsList.index).song_id,
                            songsModel.get(songsList.index).name,
                            songsModel.get(songsList.index).artist
                        )
                    }
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
        spacing: compactSpacing
        anchors {
            bottomMargin: media_player.playbackState != 0 ? layoutPlayerInset : 0
            right: parent.right
            left: parent.left
            top: offlineView.bottom
            bottom: parent.bottom
        }

        UListItem.ThinDivider {
            anchors.top: lblOffline.botton
            anchors.topMargin: spacingMedium + spacingSmall
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
                    durationText: Format.durationToString(duration)
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
