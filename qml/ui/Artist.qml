import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.2
import Ubuntu.Components.ListItems 1.3 as ListItems
import "../logic/Api.js" as Api
import "../components"

Item {
    id: artistContainer
    width: parent.width
    height: units.gu(120)

    function cargar(id) {
        Api.getArtistTopSongs(id);
        Api.getArtistAlbums(id)
    }

    ActivityIndicator {
        id: artist_songs_loader
        anchors.centerIn: parent
        z: 1
    }

    ActivityIndicator {
        id: artist_albums_loader
        anchors.centerIn: parent
        z: 1
    }

    function is_visible(value){
        image_layout.visible = value;
        songs_layout.visible = value;
        albums_layout.visible = value;
    }

    ListModel {
        id: songsModel
    }

    ListModel {
        id: albumsModel
    }
    
    Flickable {
          clip: true
          anchors.fill: parent
          contentWidth: width
          contentHeight: units.gu(150)

    GridLayout {
        id: layouts
        anchors.fill: parent
        columns: layouts.width <= units.gu(50) ? 1 : 2
        columnSpacing: 1
        rowSpacing: 1

        Rectangle {
            id: image_layout
            color: "transparent"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.row: 0
            Layout.column: 0
            Layout.preferredWidth: layouts.columns == 1 ? parent.width : parent.width/3
            Layout.preferredHeight: layouts.columns == 1 ? units.gu(25) : layouts.width < units.gu(100) ? parent.height : units.gu(15)
            Layout.rowSpan: layouts.columns == 1 ? 1 : layouts.width < units.gu(100) ? 2 : 1

            Rectangle {
                id: photo_overlay
                anchors.fill: parent
                color: "#000"
                opacity: 0.8
                z: 2
            }

            Image {
                id: photo_blur
                source: photo.source
                width: parent.width
                height: parent.height
                fillMode: Image.PreserveAspectCrop
                smooth: true
                z: 1
            }

            FastBlur {
                width: parent.width
                height: parent.height
                source: photo_blur
                radius: 32
            }

            Rectangle {
                id: photoContainer
                color: "transparent"
                width: parent.width
                height: parent.height
                z: 3

                Image {
                    id: photo
                    property real escalay: parent.height/photo.sourceSize.height
                    property real escalax: parent.width/photo.sourceSize.width
                    source: "../graphics/default.png"
                    width: photo.sourceSize.width*escalax
                    height: photo.sourceSize.height*escalay
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                    clip: true
                    cache: true
                    smooth: true
                }
            }
        }

        Rectangle {
            id: songs_layout
            color: "transparent"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.row: layouts.columns == 1 ? 1 : layouts.width < units.gu(100) ? 0 : 1
            Layout.column: layouts.columns == 1 ? 0 : layouts.width < units.gu(100) ? 1 : 0
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: layouts.width < units.gu(100) ? units.gu(40) : (parent.height - units.gu(15))

            Rectangle {
                id: songs_title
                color: "#333333"
                width: parent.width
                height: units.gu(5)
                Label{
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(1)
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n.tr("Top Songs")
                    fontSize: "large"
                    color: "#fff"
                }
            }

            SongDialog {
                id: song_dialog
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
                            Api.download(songsModel.get(songsList.index).id, songsModel.get(songsList.index).name, songsModel.get(songsList.index).artist)
                            context_menu.close()
                        }
                    }
                    Action {
                        text: i18n.tr("Add to playlist")
                        name: "add-to-playlist"
                        onTriggered: {
                            song_dialog.get_playlists()
                            song_dialog.model_song.clear()
                            song_dialog.model_song.append(songsModel.get(songsList.index))
                            song_dialog.open_dialog()
                            context_menu.close()
                        }
                    }
                    Action {
                        text: i18n.tr("Add to queue")
                        name: "navigation-menu"
                        onTriggered: {
                            playing_page.songs_list.push(songsModel.get(songsList.index).id)
                            media_player.additem(cloudMusic.server + 'play/' + songsModel.get(songsList.index).id + '/' + cloudMusic.settings.streaming_quality)
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
                }
            }

            Rectangle {
                id: songs_view
                color: "transparent"
                anchors.top: songs_title.bottom
                anchors.bottom: parent.bottom
                width: parent.width

                Item {
                    id: songsView
                    width: parent.width
                    height: parent.height
                    z:2
                    ListView {
                        id: songsList
                        property int index: -1
                        clip: true
                        model: songsModel
                        width: parent.width
                        height: parent.height
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: ListItem {
                            contentItem.anchors {
                                leftMargin: units.gu(2)
                                rightMargin: units.gu(2)
                                topMargin: units.gu(1)
                                bottomMargin: units.gu(1)
                            }

                            color: songsList.index == index ? "#5d5d5d" : "transparent"

                            Label {
                                id: lbl_name
                                text: name
                                elide: Text.ElideRight
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: lbl_duration.left
                            }

                            Label {
                                id: lbl_duration
                                text: Api.durationToString(duration)
                                width: units.gu(5)
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: item_menu.left
                                horizontalAlignment: Text.AlignRight
                            }

                            MouseArea {
                                id: item_menu
                                width: units.gu(5)
                                height: parent.height
                                anchors.right: parent.right
                                onClicked: {
                                    if(songsList.index == index) {
                                        context_menu.close()
                                    }else {
                                        songsList.index = index
                                    }

                                    context_menu.caller = item_menu
                                    context_menu.show()
                                }

                                Icon {
                                    height: units.gu(3)
                                    width: height
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: "contextual-menu"
                                }
                            }

                            onClicked: {
                                pagestack.push(playingPage)
                                var songs = [];
                                var songs_ids = [];
                                playing_page.model_queue.clear();
                                for(var i = 0; i < songsModel.count; i++) {
                                    songs.push(cloudMusic.server + 'play/' + songsModel.get(i).id + '/' + cloudMusic.settings.streaming_quality);
                                    songs_ids.push(songsModel.get(i).id);
                                    playing_page.model_queue.append(songsModel.get(i));
                                }
                                playing_page.songs_list = songs_ids
                                media_player.setPlaylist(songs, index)
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

        Rectangle {
            id: albums_layout
            color: "transparent"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.row: layouts.columns == 1 ? 2 : layouts.width < units.gu(100) ? 1 : 0
            Layout.column: layouts.columns == 1 ? 0 : layouts.width < units.gu(100) ? 1 : 1
            Layout.preferredWidth: layouts.columns == 1 ? parent.width : layouts.width < units.gu(100) ? parent.width : (parent.width/3)*2
            Layout.preferredHeight: layouts.columns == 1 ? units.gu(55) : layouts.width < units.gu(100) ? units.gu(55) : parent.height
            Layout.rowSpan: layouts.width < units.gu(100) ? 1 : 2

            Rectangle {
                id: albums_title
                color: "#333333"
                width: parent.width
                height: units.gu(5)
                Label{
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(1)
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n.tr("Albums")
                    fontSize: "large"
                    color: "#fff"
                }
            }

            Rectangle {
                color: "transparent"
                anchors.top: albums_title.bottom
                anchors.bottom: parent.bottom
                width: parent.width
                clip: true

                GridView {
                    id: albumsView
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    z: 1
                    width: parent.width
                    height: parent.height
                    cellWidth: cloudMusic.width > units.gu(25) ? (parent.width/Math.ceil(parent.width/units.gu(25))) : (parent.width)
                    cellHeight: cellWidth + units.gu(6)
                    model: albumsModel
                    cacheBuffer: 1000

                    delegate: MouseArea {
                        id: item
                        width: albumsView.cellWidth
                        height: albumsView.cellHeight
                        Column {
                            id: delegateitem
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            Image {
                                id: wimage
                                width: parent.width
                                height: parent.height - units.gu(6)
                                source: image
                                clip: true
                                cache: true
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                            }
                            Rectangle{
                                color: "#333"
                                width: albumsView.cellWidth
                                height: units.gu(3)
                                Label {
                                    text: name
                                    width: albumsView.cellWidth
                                    height: units.gu(3)
                                    horizontalAlignment: Label.AlignHCenter
                                    verticalAlignment: Label.AlignBottom
                                    elide: Label.ElideRight
                                    fontSize: "medium"
                                    color: "#fff"
                                }
                            }
                            Rectangle{
                                color: "#333"
                                width: albumsView.cellWidth
                                height: units.gu(3)
                                Label {
                                    // TRANSLATORS: %1 refers to the amount of songs in album
                                    text: i18n.tr("%1 song", "%1 songs", size).arg(size)
                                    width: albumsView.cellWidth
                                    height: units.gu(4)
                                    horizontalAlignment: Label.AlignHCenter
                                    verticalAlignment: Label.AlignTop
                                    elide: Label.ElideRight
                                    fontSize: "small"
                                    color: "#898B8C"
                                }
                            }
                        }
                        onClicked: {
                            //albumPage.title = name;
                            album_page.cargar(id);
                            pagestack.push(albumPage);
                        }
                    }
                }
            }
        }
    }
    }
}
