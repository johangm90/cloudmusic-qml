import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../logic/Api.js" as Api
import "../logic/Database.js" as Db
import "../components"

Item {
    id: librarySongsContainer
    property var appRoot
    property string mode: "favorites" // favorites | recent
    property color pageColor: appRoot ? appRoot.pageColor : "#f5f5f5"
    property color cardColor: appRoot ? appRoot.cardColor : "#ffffff"
    property color borderColor: appRoot ? appRoot.borderColor : "#d8d8d8"
    property color textColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color secondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#898B8C"
    property color selectedColor: appRoot ? appRoot.selectedColor : "#5d5d5d"
    property int selectedIndex: -1
    property string query: ""

    ListModel {
        id: songsModel
    }

    ListModel {
        id: filteredSongsModel
    }

    function refreshData() {
        songsModel.clear()
        var records = mode === "recent" ? Db.getRecentlyPlayed(200) : Db.getLikedSongs(200)
        for (var i = 0; i < records.length; i++) {
            songsModel.append(records[i])
        }
        applyFilter()
    }

    function setQuery(value) {
        query = value || ""
        applyFilter()
    }

    function clearQuery() {
        setQuery("")
    }

    function applyFilter() {
        filteredSongsModel.clear()
        var text = (query || "").toLowerCase().trim()
        for (var i = 0; i < songsModel.count; i++) {
            var row = songsModel.get(i)
            if (!text ||
                (row.name && row.name.toLowerCase().indexOf(text) !== -1) ||
                (row.artist && row.artist.toLowerCase().indexOf(text) !== -1) ||
                (row.album && row.album.toLowerCase().indexOf(text) !== -1)) {
                filteredSongsModel.append(row)
            }
        }
        selectedIndex = -1
    }

    function playFromIndex(index) {
        if (index < 0 || index >= filteredSongsModel.count) {
            return
        }
        var songs = []
        var songsIds = []
        var quality = (appRoot && appRoot.settings) ? appRoot.settings.streaming_quality : "320"
        var server = appRoot ? appRoot.server : ""
        playing_page.model_queue.clear()
        for (var i = 0; i < filteredSongsModel.count; i++) {
            songs.push(server + "play/" + filteredSongsModel.get(i).song_id + "/" + quality)
            songsIds.push(filteredSongsModel.get(i).song_id)
            playing_page.model_queue.append(filteredSongsModel.get(i))
        }
        playing_page.songs_list = songsIds
        pagestack.push(playingPage)
        media_player.setPlaylist(songs, index)
    }

    Component.onCompleted: refreshData()

    ActionSelectionPopover {
        id: context_menu
        z: 999

        function close() {
            context_menu.hide()
            selectedIndex = -1
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
                text: i18n.tr("Add to queue")
                name: "navigation-menu"
                onTriggered: {
                    if (selectedIndex < 0) return
                    var song = filteredSongsModel.get(selectedIndex)
                    playing_page.songs_list.push(song.song_id)
                    var quality = (appRoot && appRoot.settings) ? appRoot.settings.streaming_quality : "320"
                    var server = appRoot ? appRoot.server : ""
                    media_player.additem(server + "play/" + song.song_id + "/" + quality)
                    playing_page.model_queue.append(song)
                    messager.show_message(i18n.tr("Song added to queue"), 3)
                    context_menu.close()
                }
            }
            Action {
                text: (selectedIndex >= 0 && Db.isLikedSong(filteredSongsModel.get(selectedIndex).song_id, filteredSongsModel.get(selectedIndex).source))
                      ? i18n.tr("Remove from Favorites")
                      : i18n.tr("Add to Favorites")
                name: (selectedIndex >= 0 && Db.isLikedSong(filteredSongsModel.get(selectedIndex).song_id, filteredSongsModel.get(selectedIndex).source))
                      ? "like"
                      : "unlike"
                onTriggered: {
                    if (selectedIndex < 0) return
                    var liked = Db.toggleLikedSong({
                        id: filteredSongsModel.get(selectedIndex).song_id,
                        source: filteredSongsModel.get(selectedIndex).source,
                        name: filteredSongsModel.get(selectedIndex).name,
                        artist_id: filteredSongsModel.get(selectedIndex).artist_id,
                        artist: filteredSongsModel.get(selectedIndex).artist,
                        album_id: filteredSongsModel.get(selectedIndex).album_id,
                        album: filteredSongsModel.get(selectedIndex).album,
                        duration: filteredSongsModel.get(selectedIndex).duration
                    })
                    messager.show_message(liked ? i18n.tr("Added to Favorites") : i18n.tr("Removed from Favorites"), 3)
                    if (mode === "favorites" && !liked) {
                        refreshData()
                    }
                    context_menu.close()
                }
            }
            Action {
                text: i18n.tr("Go to album")
                name: "slideshow"
                onTriggered: {
                    if (selectedIndex < 0) return
                    album_page.cargar(filteredSongsModel.get(selectedIndex).album_id)
                    pagestack.push(albumPage)
                    context_menu.close()
                }
            }
            Action {
                text: i18n.tr("Go to artist")
                name: "contact"
                onTriggered: {
                    if (selectedIndex < 0) return
                    artist_page.cargar(filteredSongsModel.get(selectedIndex).artist_id)
                    pagestack.push(artistPage)
                    context_menu.close()
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: pageColor

        Rectangle {
            anchors.fill: parent
            color: cardColor
            border.color: borderColor
            border.width: 1

            Label {
                visible: filteredSongsModel.count === 0
                anchors.centerIn: parent
                text: query.trim() !== ""
                      ? i18n.tr("No matches found")
                      : (mode === "recent" ? i18n.tr("No recent songs yet") : i18n.tr("No favorites yet"))
                color: secondaryTextColor
            }

            ListView {
                visible: filteredSongsModel.count > 0
                anchors.fill: parent
                clip: true
                model: filteredSongsModel
                boundsBehavior: Flickable.StopAtBounds
                delegate: SongListItem {
                    title: name
                    subtitle: artist
                    durationText: Api.durationToString(duration)
                    coverSource: image ? image : "../graphics/default.png"
                    albumId: album_id
                    selected: selectedIndex === index
                    rowTextColor: textColor
                    rowSecondaryTextColor: secondaryTextColor
                    selectedColor: librarySongsContainer.selectedColor
                    onMenuClicked: {
                        if (selectedIndex == index) {
                            context_menu.close()
                        } else {
                            selectedIndex = index
                        }
                        context_menu.caller = caller
                        context_menu.show()
                    }
                    onClicked: {
                        playFromIndex(index)
                    }
                }
            }
        }
    }
}
