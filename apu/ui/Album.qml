import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtGraphicalEffects 1.0
import Ubuntu.Layouts 1.0
import "../logic/Api.js" as Api
import "../components"

Item {
    id: albumContainer
    width: parent.width
    height: units.gu(80)

    function cargar(id) {
        Api.getAlbumDetail(id);
    }

    function is_visible(value) {
        image_layout.visible = value
        songs_layout.visible = value
    }

    ActivityIndicator {
        id: album_loader
        anchors.centerIn: parent
        z: 1
    }

    ListModel {
        id: albumModel
    }

    SongDialog {
        id: song_dialog
    }

    function add_to_playlist() {
        song_dialog.album_name = lbl_album_title.text
        song_dialog.get_playlists()
        song_dialog.model_song.clear()
        for(var i = 0; i < albumModel.count; i++) {
            song_dialog.model_song.append(albumModel.get(i));
        }
        song_dialog.open_dialog()
    }

    Layouts {
        id: layouts
        anchors.fill: parent

        layouts: [
            ConditionalLayout {
                name: "column"
                when: layouts.width <= units.gu(50)

                Flickable {
                    clip: true
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: units.gu(80)

                    Column {
                        anchors.fill: parent

                        ItemLayout {
                            item: "layout_image"
                            width: parent.width
                            height: units.gu(25)
                        }

                        ItemLayout {
                            item: "layout_songs"
                            width: parent.width
                            height: parent.height - units.gu(25)
                        }
                    }
                }
            },
            ConditionalLayout {
                name: "row"
                when: layouts.width > units.gu(50)

                Row {
                    anchors.fill: parent

                    ItemLayout {
                        item: "layout_image"
                        width: parent.width/3
                        height: parent.height
                    }

                    ItemLayout {
                        item: "layout_songs"
                        width: (parent.width/3)*2
                        height: parent.height
                    }
                }
            }
        ]

        Rectangle {
            id: image_layout
            color: "transparent"
            Layouts.item: "layout_image"
            width: parent.width
            height: parent.height

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
            Layouts.item: "layout_songs"
            width: parent.width
            height: parent.height

            Rectangle {
                id: album_title
                color: "#333333"
                //anchors.top: photo.bottom
                width: parent.width
                height: units.gu(5)
                Label{
                    id: lbl_album_title
                    width: parent.width
                    height: units.gu(2.5)
                    anchors.margins: units.gu(1)
                    horizontalAlignment: Label.AlignHCenter
                    verticalAlignment: Label.AlignBottom
                    elide: Label.ElideRight
                    fontSize: "medium"
                    color: "#fff"
                }
                Label{
                    id: lbl_album_date
                    width: parent.width
                    //height: units.gu(2.5)
                    anchors.top: lbl_album_title.bottom
                    anchors.bottomMargin: units.gu(2)
                    horizontalAlignment: Label.AlignHCenter
                    verticalAlignment: Label.AlignTop
                    elide: Label.ElideRight
                    fontSize: "small"
                    color: "#898B8C"
                }
            }

            ActionSelectionPopover {
                id: context_menu
                z: 999

                function close() {
                    context_menu.hide()
                    albumList.index = -1
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
                            Api.download(albumModel.get(albumList.index).id, albumModel.get(albumList.index).name)
                            context_menu.close()
                        }
                    }
                    Action {
                        text: i18n.tr("Add to playlist")
                        name: "add-to-playlist"
                        onTriggered: {
                            song_dialog.get_playlists()
                            song_dialog.model_song.clear()
                            song_dialog.model_song.append(albumModel.get(albumList.index))
                            song_dialog.open_dialog()
                            context_menu.close()
                        }
                    }
                    Action {
                        text: i18n.tr("Add to queue")
                        name: "navigation-menu"
                        onTriggered: {
                            playing_page.songs_list.push(albumModel.get(albumList.index).id)
                            media_player.additem(cloudMusic.server + 'play/' + albumModel.get(albumList.index).id + '/' + cloudMusic.settings.streaming_quality)
                            //media_player.additem(cloudMusic.server1 + 'url?id=' + albumModel.get(albumList.index).id + '&br=' + cloudMusic.settings.streaming_quality + '&raw')
                            playing_page.model_queue.append(albumModel.get(albumList.index))
                            context_menu.close()
                            messager.show_message(i18n.tr("Song added to queue"), 3)
                        }
                    }
                    Action {
                        text: i18n.tr("Go to artist")
                        name: "contact"
                        onTriggered: {
                            artist_page.cargar(albumModel.get(albumList.index).artist_id);
                            pagestack.push(artistPage);
                            context_menu.close()
                        }
                    }
                }
            }

            Rectangle {
                id: album_view
                color: "transparent"
                anchors.top: album_title.bottom
                anchors.bottom: parent.bottom
                width: parent.width

                Item {
                    id: albumView
                    width: parent.width
                    height: parent.height
                    z:2
                    ListView {
                        id: albumList
                        property int index: -1
                        clip: true
                        model: albumModel
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

                            color: albumList.index == index ? "#5d5d5d" : "transparent"

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
                                    if(albumList.index == index) {
                                        context_menu.close()
                                    }else {
                                        albumList.index = index
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
                                var songs = [];
                                var songs_ids = [];
                                playing_page.model_queue.clear()
                                for(var i = 0; i < albumModel.count; i++) {
                                    songs.push(cloudMusic.server + 'play/' + albumModel.get(i).id + '/' + cloudMusic.settings.streaming_quality);
                                    //songs.push(cloudMusic.server1 + 'url?id=' + albumModel.get(i).id + '&br=' + cloudMusic.settings.streaming_quality + '&raw');
                                    songs_ids.push(albumModel.get(i).id);
                                    playing_page.model_queue.append(albumModel.get(i));
                                }
                                pagestack.push(playingPage)
                                playing_page.songs_list = songs_ids
                                media_player.setPlaylist(songs, index)
                            }
                        }
                    }
                    Scrollbar {
                        flickableItem: albumList
                        align: Qt.AlignTrailing
                    }
                }
            }
        }
    }
}

