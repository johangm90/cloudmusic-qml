import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.2
import "../logic/Api.js" as Api
import "../logic/Database.js" as Db
import "../components"

Item {
    id: artistContainer
    width: parent.width
    height: units.gu(120)
    property var appRoot
    property int activeTab: 0
    property bool contentReady: false
    property int tabAnimDuration: LomiriAnimation.FastDuration

    property bool isDarkTheme: appRoot ? appRoot.isDarkTheme : false
    property color cardColor: appRoot ? appRoot.cardColor : (isDarkTheme ? "#232323" : "#ffffff")
    property color cardBorder: appRoot ? appRoot.borderColor : (isDarkTheme ? "#3a3a3a" : "#d8d8d8")
    property color sectionColor: appRoot ? appRoot.sectionColor : (isDarkTheme ? "#1a1a1a" : "#ececec")
    property color mutedTextColor: appRoot ? appRoot.secondaryTextColor : (isDarkTheme ? "#b8b8b8" : "#666666")
    property color primaryTextColor: appRoot ? appRoot.textColor : (isDarkTheme ? "#f2f2f2" : "#1f1f1f")
    property color inverseTextColor: appRoot ? appRoot.inverseTextColor : "#ffffff"
    property color selectedColor: appRoot ? appRoot.selectedColor : Qt.rgba(0.9, 0.2, 0.28, 0.18)
    property color accentColor: appRoot ? appRoot.primaryColor : "#e53446"

    function cargar(id) {
        activeTab = 0
        contentReady = false
        Api.getArtistTopSongs(id, artistSongsContext())
        Api.getArtistAlbums(id, artistAlbumsContext())
    }

    function setArtistTitle(title) {
        artistPage.title = title
        artistPage.header.title = title
    }

    function artistSongsContext() {
        return {
            songsModel: songsModel,
            songsLoader: artist_songs_loader,
            setPageTitle: setArtistTitle,
            setPhoto: function(source) { photo.source = source },
            setVisible: is_visible
        }
    }

    function artistAlbumsContext() {
        return {
            albumsModel: albumsModel,
            albumsLoader: artist_albums_loader,
            setPageTitle: setArtistTitle,
            setPhoto: function(source) { photo.source = source },
            setVisible: is_visible
        }
    }

    ActivityIndicator {
        id: artist_songs_loader
        anchors.centerIn: parent
        z: 20
    }

    ActivityIndicator {
        id: artist_albums_loader
        anchors.centerIn: parent
        z: 20
    }

    function is_visible(value) {
        contentReady = value
    }

    ListModel {
        id: songsModel
    }

    ListModel {
        id: albumsModel
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
                    var quality = (appRoot && appRoot.settings) ? appRoot.settings.streaming_quality : "320"
                    var server = appRoot ? appRoot.server : ""
                    media_player.additem(server + "play/" + songsModel.get(songsList.index).id + "/" + quality)
                    playing_page.model_queue.append(songsModel.get(songsList.index))
                    context_menu.close()
                    messager.show_message(i18n.tr("Song added to queue"), 3)
                }
            }
            Action {
                text: (songsList.index >= 0 && Db.isLikedSong(songsModel.get(songsList.index).id))
                      ? i18n.tr("Remove from Favorites")
                      : i18n.tr("Add to Favorites")
                name: (songsList.index >= 0 && Db.isLikedSong(songsModel.get(songsList.index).id))
                      ? "like"
                      : "unlike"
                onTriggered: {
                    var liked = Db.toggleLikedSong(songsModel.get(songsList.index))
                    messager.show_message(liked ? i18n.tr("Added to Favorites") : i18n.tr("Removed from Favorites"), 3)
                    context_menu.close()
                }
            }
            Action {
                text: i18n.tr("Go to album")
                name: "slideshow"
                onTriggered: {
                    album_page.cargar(songsModel.get(songsList.index).album_id)
                    pagestack.push(albumPage)
                    context_menu.close()
                }
            }
        }
    }

    Flickable {
        id: artistFlick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: Math.max(height, mainLayout.implicitHeight + units.gu(2))

        GridLayout {
            id: mainLayout
            width: artistFlick.width
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 0
            columns: width < units.gu(90) ? 1 : 2
            rowSpacing: units.gu(1)
            columnSpacing: units.gu(1)

            Rectangle {
                id: image_layout
                visible: contentReady
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.row: 0
                Layout.column: 0
                Layout.preferredWidth: mainLayout.columns === 1 ? mainLayout.width : mainLayout.width / 3
                Layout.preferredHeight: mainLayout.columns === 1 ? units.gu(34) : units.gu(28)
                radius: units.gu(1)
                color: cardColor
                border.color: cardBorder
                border.width: 1
                clip: true

                Image {
                    id: photo_blur
                    anchors.fill: parent
                    source: photo.source
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                }

                FastBlur {
                    anchors.fill: parent
                    source: photo_blur
                    radius: 26
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.25) }
                        GradientStop { position: 0.8; color: Qt.rgba(0, 0, 0, 0.72) }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.82) }
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: units.gu(2)
                    spacing: units.gu(2)

                    Rectangle {
                        width: Math.min(units.gu(20), parent.height - units.gu(2))
                        height: width
                        radius: width / 2
                        color: "#202020"
                        border.color: Qt.rgba(1, 1, 1, 0.2)
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: photo
                            anchors.fill: parent
                            source: "../graphics/default.png"
                            fillMode: Image.PreserveAspectCrop
                            cache: true
                            smooth: true
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: photo
                            cached: true
                            maskSource: Rectangle {
                                width: photo.width
                                height: photo.height
                                radius: width / 2
                            }
                        }
                    }

                    Column {
                        width: Math.max(units.gu(12), parent.width - (parent.height - units.gu(2)) - units.gu(4))
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: units.gu(0.8)

                        Label {
                            text: artistPage.header.title
                            width: parent.width
                            elide: Text.ElideRight
                            fontSize: "large"
                            font.weight: Font.DemiBold
                            color: inverseTextColor
                        }

                        Label {
                            width: parent.width
                            text: i18n.tr("Artist profile")
                            fontSize: "small"
                            color: mutedTextColor
                        }

                        Row {
                            spacing: units.gu(1)

                            Rectangle {
                                radius: units.gu(0.8)
                                color: Qt.rgba(1, 1, 1, 0.15)
                                height: units.gu(3)
                                width: units.gu(14)

                                Label {
                                    anchors.centerIn: parent
                                    fontSize: "small"
                                    color: inverseTextColor
                                    text: i18n.tr("%1 tracks").arg(songsModel.count)
                                }
                            }

                            Rectangle {
                                radius: units.gu(0.8)
                                color: Qt.rgba(1, 1, 1, 0.15)
                                height: units.gu(3)
                                width: units.gu(14)

                                Label {
                                    anchors.centerIn: parent
                                    fontSize: "small"
                                    color: inverseTextColor
                                    text: i18n.tr("%1 albums").arg(albumsModel.count)
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: tabs_layout
                visible: contentReady
                Layout.fillWidth: true
                Layout.row: 1
                Layout.column: 0
                Layout.columnSpan: mainLayout.columns === 1 ? 1 : 2
                Layout.preferredHeight: units.gu(6)
                radius: units.gu(1)
                color: cardColor
                border.color: cardBorder
                border.width: 1
                clip: true

                Row {
                    anchors.fill: parent
                    anchors.margins: units.gu(0.6)
                    spacing: units.gu(0.6)

                    Rectangle {
                        width: (parent.width - units.gu(0.6)) / 2
                        height: parent.height
                        radius: units.gu(0.8)
                        color: activeTab === 0 ? accentColor : "transparent"
                        border.color: activeTab === 0 ? accentColor : cardBorder
                        border.width: 1

                        Label {
                            anchors.centerIn: parent
                            text: i18n.tr("Top Songs")
                            fontSize: "small"
                            font.weight: Font.DemiBold
                            color: activeTab === 0 ? inverseTextColor : primaryTextColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: activeTab = 0
                        }
                    }

                    Rectangle {
                        width: (parent.width - units.gu(0.6)) / 2
                        height: parent.height
                        radius: units.gu(0.8)
                        color: activeTab === 1 ? accentColor : "transparent"
                        border.color: activeTab === 1 ? accentColor : cardBorder
                        border.width: 1

                        Label {
                            anchors.centerIn: parent
                            text: i18n.tr("Albums")
                            fontSize: "small"
                            font.weight: Font.DemiBold
                            color: activeTab === 1 ? inverseTextColor : primaryTextColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: activeTab = 1
                        }
                    }
                }
            }

            Rectangle {
                id: songs_layout
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.row: 2
                Layout.column: 0
                Layout.columnSpan: mainLayout.columns === 1 ? 1 : 2
                Layout.preferredWidth: mainLayout.width
                Layout.preferredHeight: activeTab === 0 ? units.gu(66) : 0
                radius: units.gu(1)
                color: cardColor
                border.color: cardBorder
                border.width: 1
                clip: true
                visible: opacity > 0
                opacity: (contentReady && activeTab === 0) ? 1 : 0
                Behavior on opacity {
                    LomiriNumberAnimation { duration: tabAnimDuration }
                }

                Column {
                    anchors.fill: parent

                    Rectangle {
                        width: parent.width
                        height: units.gu(6)
                        color: sectionColor

                        Rectangle {
                            width: units.gu(0.6)
                            height: units.gu(3.2)
                            radius: width / 2
                            color: accentColor
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(2)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: i18n.tr("Top Songs")
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(3.4)
                            anchors.verticalCenter: parent.verticalCenter
                            fontSize: "medium"
                            font.weight: Font.DemiBold
                            color: primaryTextColor
                        }

                        Label {
                            text: i18n.tr("%1 total").arg(songsModel.count)
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(2)
                            anchors.verticalCenter: parent.verticalCenter
                            fontSize: "small"
                            color: mutedTextColor
                        }
                    }

                    Item {
                        id: songsView
                        width: parent.width
                        height: parent.height - units.gu(6)

                        ListView {
                            id: songsList
                            property int index: -1
                            anchors.fill: parent
                            anchors.leftMargin: units.gu(0.6)
                            anchors.rightMargin: units.gu(0.6)
                            clip: true
                            spacing: units.gu(0.2)
                            model: songsModel
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: SongListItem {
                                title: name
                                subtitle: artist
                                durationText: Api.durationToString(duration)
                                coverSource: image
                                albumId: album_id
                                leadingText: (index + 1) + "."
                                selected: songsList.index === index
                                rowTextColor: primaryTextColor
                                rowSecondaryTextColor: mutedTextColor
                                selectedColor: artistContainer.selectedColor
                                onMenuClicked: {
                                    if (songsList.index === index) {
                                        context_menu.close()
                                    } else {
                                        songsList.index = index
                                    }
                                    context_menu.caller = caller
                                    context_menu.show()
                                }
                                onClicked: {
                                    pagestack.push(playingPage)
                                    var songs = []
                                    var songs_ids = []
                                    playing_page.model_queue.clear()
                                    for (var i = 0; i < songsModel.count; i++) {
                                        var quality = (appRoot && appRoot.settings) ? appRoot.settings.streaming_quality : "320"
                                        var server = appRoot ? appRoot.server : ""
                                        songs.push(server + "play/" + songsModel.get(i).id + "/" + quality)
                                        songs_ids.push(songsModel.get(i).id)
                                        playing_page.model_queue.append(songsModel.get(i))
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
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.row: 2
                Layout.column: 0
                Layout.columnSpan: mainLayout.columns === 1 ? 1 : 2
                Layout.preferredWidth: mainLayout.width
                Layout.preferredHeight: activeTab === 1 ? units.gu(66) : 0
                radius: units.gu(1)
                color: cardColor
                border.color: cardBorder
                border.width: 1
                clip: true
                visible: opacity > 0
                opacity: (contentReady && activeTab === 1) ? 1 : 0
                Behavior on opacity {
                    LomiriNumberAnimation { duration: tabAnimDuration }
                }

                Column {
                    anchors.fill: parent

                    Rectangle {
                        width: parent.width
                        height: units.gu(6)
                        color: sectionColor

                        Rectangle {
                            width: units.gu(0.6)
                            height: units.gu(3.2)
                            radius: width / 2
                            color: accentColor
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(2)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: i18n.tr("Albums")
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(3.4)
                            anchors.verticalCenter: parent.verticalCenter
                            fontSize: "medium"
                            font.weight: Font.DemiBold
                            color: primaryTextColor
                        }

                        Label {
                            text: i18n.tr("%1 total").arg(albumsModel.count)
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(2)
                            anchors.verticalCenter: parent.verticalCenter
                            fontSize: "small"
                            color: mutedTextColor
                        }
                    }

                    GridView {
                        id: albumsView
                        width: parent.width
                        height: parent.height - units.gu(6)
                        clip: true
                        cellWidth: width > units.gu(25) ? (width / Math.ceil(width / units.gu(25))) : width
                        cellHeight: cellWidth + units.gu(7.5)
                        model: albumsModel
                        boundsBehavior: Flickable.StopAtBounds
                        cacheBuffer: 1000

                        delegate: MouseArea {
                            width: albumsView.cellWidth
                            height: albumsView.cellHeight

                            Column {
                                anchors.fill: parent
                                anchors.margins: units.gu(0.8)
                                spacing: units.gu(0.4)

                                Rectangle {
                                    width: parent.width
                                    height: parent.height - units.gu(5.2)
                                    radius: units.gu(0.8)
                                    color: "#202020"
                                    border.color: Qt.rgba(1, 1, 1, 0.1)
                                    border.width: 1
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: image
                                        cache: true
                                        smooth: true
                                        fillMode: Image.PreserveAspectCrop
                                    }
                                }

                                Label {
                                    text: name
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    fontSize: "small"
                                    font.weight: Font.DemiBold
                                    color: primaryTextColor
                                }

                                Label {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    fontSize: "small"
                                    color: mutedTextColor
                                    text: i18n.tr("%1 song", "%1 songs", size).arg(size)
                                }
                            }

                            onClicked: {
                                album_page.cargar(id)
                                pagestack.push(albumPage)
                            }
                        }
                    }
                }
            }
        }
    }
}
