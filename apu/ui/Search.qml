import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Layouts 1.0
import "../logic/Api.js" as Api
import "../logic/Database.js" as Db
import "../components"

Page {
    id: searchPage

    header: PageHeader {
        title: i18n.tr("Search")
        contents: TextField {
            id: search_query
            inputMethodHints: Qt.ImhNoPredictiveText
            placeholderText: i18n.tr("Search")
            onVisibleChanged: {
                if (visible) {
                    forceActiveFocus()
                }
            }
            anchors.fill: parent
            anchors.rightMargin: units.gu(2)
            anchors.topMargin: units.gu(1)
            anchors.bottomMargin: units.gu(1)
            Keys.onReturnPressed: {
                if(search_query.text!=''){
                    Api.apiSearch(search_query.text, 0, 50)
                    search_query.focus=false
                }else{
                    console.log('parametro de busqueda vacio')
                }
            }
        }
    }

    Component.onCompleted: is_visible(false);

    function is_visible(value){
        songs_layout.visible = value;
        albums_layout.visible = value;
        artists_layout.visible = value;
    }

    SongDialog {
        id: song_dialog
    }

    ActivityIndicator {
        id: search_songs_loader
        anchors.centerIn: parent
        z: 1
    }
    ActivityIndicator {
        id: search_albums_loader
        anchors.centerIn: parent
        z: 1
    }
    ActivityIndicator {
        id: search_artists_loader
        anchors.centerIn: parent
        z: 1
    }

    ListModel {
        id: searchSongsModel
    }

    ListModel {
        id: searchAlbumsModel
    }

    ListModel {
        id: searchArtistsModel
    }

    Rectangle {
        color: "transparent"
        anchors {
            top: searchPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: media_player.playbackState != 0 ? units.gu(7.25) : 0
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
                        contentHeight: units.gu(150)

                        Column {
                            anchors.fill: parent

                            ItemLayout {
                                item: "layout_songs"
                                width: parent.width
                                height: units.gu(50)
                            }

                            ItemLayout {
                                item: "layout_albums"
                                width: parent.width
                                height: units.gu(50)
                            }

                            ItemLayout {
                                item: "layout_artists"
                                width: parent.width
                                height: units.gu(50)
                            }
                        }
                    }
                },
                ConditionalLayout {
                    name: "row-small"
                    when: layouts.width > units.gu(50) && layouts.width < units.gu(100)

                    Row {
                        anchors.fill: parent

                        Flickable {
                            clip: true
                            width: (parent.width/3)*2
                            height: parent.height
                            contentWidth: width
                            contentHeight: units.gu(100)

                            Column {
                                anchors.fill: parent

                                ItemLayout {
                                    item: "layout_songs"
                                    width: parent.width
                                    height: units.gu(50)
                                }

                                ItemLayout {
                                    item: "layout_albums"
                                    width: parent.width
                                    height: units.gu(50)
                                }
                            }
                        }

                        ItemLayout {
                            item: "layout_artists"
                            width: parent.width/3
                            height: parent.height
                        }
                    }
                },
                ConditionalLayout {
                    name: "row"
                    when: layouts.width >= units.gu(100)

                    Row {
                        anchors.fill: parent

                        ItemLayout {
                            item: "layout_songs"
                            width: parent.width/3
                            height: parent.height
                        }

                        ItemLayout {
                            item: "layout_albums"
                            width: parent.width/3
                            height: parent.height
                        }

                        ItemLayout {
                            item: "layout_artists"
                            width: parent.width/3
                            height: parent.height
                        }
                    }
                }
            ]

            Rectangle {
                id: songs_layout
                color: "transparent"
                Layouts.item: "layout_songs"
                width: parent.width
                height: parent.height

                Rectangle {
                    id: songs_title
                    color: "#333"
                    //anchors.top: parent.top
                    width: parent.width
                    height: units.gu(5)
                    Label{
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.verticalCenter: parent.verticalCenter
                        text: i18n.tr("Songs")
                        fontSize: "large"
                        color: "#fff"
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
                                Api.download(searchSongsModel.get(songsList.index).id, searchSongsModel.get(songsList.index).name)
                                context_menu.close()
                            }
                        }
                        Action {
                            text: i18n.tr("Add to playlist")
                            name: "add-to-playlist"
                            onTriggered: {
                                song_dialog.get_playlists()
                                song_dialog.model_song.clear()
                                song_dialog.model_song.append(searchSongsModel.get(songsList.index))
                                song_dialog.open_dialog()
                                context_menu.close()
                            }
                        }
                        Action {
                            text: i18n.tr("Add to queue")
                            name: "navigation-menu"
                            onTriggered: {
                                playing_page.songs_list.push(searchSongsModel.get(songsList.index).id)
                                media_player.additem(cloudMusic.server + 'play/' + searchSongsModel.get(songsList.index).id + '/' + cloudMusic.settings.streaming_quality)
                                //media_player.additem(cloudMusic.server1 + 'url?id=' + searchSongsModel.get(songsList.index).id + '&br=' + cloudMusic.settings.streaming_quality + '&raw')
                                playing_page.model_queue.append(searchSongsModel.get(songsList.index))
                                context_menu.close()
                                messager.show_message(i18n.tr("Song added to queue"), 3)
                            }
                        }
                        Action {
                            text: i18n.tr("Go to album")
                            name: "slideshow"
                            onTriggered: {
                                album_page.cargar(searchSongsModel.get(songsList.index).album_id);
                                pagestack.push(albumPage);
                                context_menu.close()
                            }
                        }
                        Action {
                            text: i18n.tr("Go to artist")
                            name: "contact"
                            onTriggered: {
                                artist_page.cargar(searchSongsModel.get(songsList.index).artist_id);
                                pagestack.push(artistPage);
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
                        width: parent.width
                        height: parent.height
                        ListView {
                            id: songsList
                            property int index: -1
                            clip: true
                            model: searchSongsModel
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
                                    var songs = [];
                                    var songs_ids = [];
                                    playing_page.model_queue.clear()
                                    for(var i = 0; i < searchSongsModel.count; i++) {
                                        songs.push(cloudMusic.server + 'play/' + searchSongsModel.get(i).id + '/' + cloudMusic.settings.streaming_quality);
                                        //songs.push(cloudMusic.server1 + 'url?id=' + searchSongsModel.get(i).id + '&br=' + cloudMusic.settings.streaming_quality + '&raw');
                                        songs_ids.push(searchSongsModel.get(i).id);
                                        playing_page.model_queue.append(searchSongsModel.get(i));
                                    }
                                    pagestack.push(playingPage);
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
                Layouts.item: "layout_albums"
                width: parent.width
                height: parent.height

                Rectangle {
                    id: albums_title
                    color: "#333"
                    //anchors.top: songs_view.bottom
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
                    id: albums_view
                    color: "transparent"
                    anchors.top: albums_title.bottom
                    anchors.bottom: parent.bottom
                    width: parent.width
                    Item {
                        width: parent.width
                        height: parent.height
                        ListView {
                            id: albums_list
                            property int index: 0
                            clip: true
                            model: searchAlbumsModel
                            width: parent.width
                            height: parent.height
                            boundsBehavior: Flickable.StopAtBounds
                            delegate: ListItem {
                                id: albumlist
                                contentItem.anchors {
                                    leftMargin: units.gu(2)
                                    rightMargin: units.gu(2)
                                    topMargin: units.gu(1)
                                    bottomMargin: units.gu(1)
                                }
                                Label {
                                    id: lbl__album_name
                                    text: name
                                    elide: Label.ElideRight
                                    anchors.left: parent.left
                                    anchors.right: lbl__album_size.left
                                }

                                Label {
                                    id: lbl__album_artist
                                    text: artist
                                    fontSize: "small"
                                    color: "#898B8C"
                                    elide: Label.ElideRight
                                    anchors.left: parent.left
                                    anchors.right: lbl__album_size.left
                                    anchors.bottom: parent.bottom
                                }

                                Label {
                                    id: lbl__album_size
                                    text: size
                                    width: units.gu(5)
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                    horizontalAlignment: Text.AlignRight
                                }

                                onClicked: {
                                    album_page.cargar(id);
                                    pagestack.push(albumPage);
                                }
                            }
                        }
                        Scrollbar {
                            flickableItem: albums_list
                            align: Qt.AlignTrailing
                        }
                    }
                }
            }

            Rectangle {
                id: artists_layout
                color: "transparent"
                Layouts.item: "layout_artists"
                width: parent.width
                height: parent.height

                Rectangle {
                    id: artists_title
                    color: "#333"
                    //anchors.top: albums_view.bottom
                    width: parent.width
                    height: units.gu(5)
                    Label{
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.verticalCenter: parent.verticalCenter
                        text: i18n.tr("Artists")
                        fontSize: "large"
                        color: "#fff"
                    }
                }

                Rectangle {
                    id: artists_view
                    color: "transparent"
                    anchors.top: artists_title.bottom
                    anchors.bottom: parent.bottom
                    width: parent.width
                    clip: true

                    GridView {
                        id: artistsView
                        anchors {
                            margins: 0
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
                        cellHeight: cellWidth + units.gu(4)
                        model: searchArtistsModel
                        cacheBuffer: 1000

                        delegate: MouseArea {
                            width: artistsView.cellWidth
                            height: artistsView.cellHeight
                            Column {
                                id: delegateitem
                                anchors.fill: parent
                                Image {
                                    id: wimage
                                    width: parent.width
                                    height: parent.height - units.gu(4)
                                    source: image ? image : "../graphics/default.png"
                                    clip: true
                                    cache: true
                                    fillMode: Image.PreserveAspectCrop
                                    //smooth: true
                                }
                                Rectangle{
                                    color: "#333"
                                    width: artistsView.cellWidth
                                    height: units.gu(4)
                                    Label {
                                        text: name
                                        width: artistsView.cellWidth
                                        anchors.margins: units.gu(2)
                                        horizontalAlignment: Text.AlignHCenter
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                        fontSize: "medium"
                                        color: "#fff"
                                    }
                                }
                            }

                            onClicked: {
                                artist_page.cargar(id);
                                pagestack.push(artistPage);
                            }
                        }
                    }
                }
            }
        }
    }
}
