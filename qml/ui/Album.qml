import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.2
import "../logic/Api.js" as Api
import "../components"

Item {
    id: albumContainer
    width: parent.width
    height: units.gu(80)
    property var appRoot

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
        Api.getAlbumDetail(id, albumApiContext())
    }

    function albumApiContext() {
        return {
            albumModel: albumModel,
            loader: album_loader,
            setVisible: is_visible,
            setPhoto: function(source) { photo.source = source },
            setAlbumTitle: function(title) { lbl_album_title.text = title },
            setAlbumDate: function(dateText) { lbl_album_date.text = dateText }
        }
    }

    function is_visible(value) {
        image_layout.visible = value
        songs_layout.visible = value
    }

    ActivityIndicator {
        id: album_loader
        anchors.centerIn: parent
        z: 20
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
        for (var i = 0; i < albumModel.count; i++) {
            song_dialog.model_song.append(albumModel.get(i))
        }
        song_dialog.open_dialog()
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
                    Api.download(albumModel.get(albumList.index).id, albumModel.get(albumList.index).name, albumModel.get(albumList.index).artist)
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
                    var quality = (appRoot && appRoot.settings) ? appRoot.settings.streaming_quality : "320"
                    var server = appRoot ? appRoot.server : ""
                    media_player.additem(server + "play/" + albumModel.get(albumList.index).id + "/" + quality)
                    playing_page.model_queue.append(albumModel.get(albumList.index))
                    context_menu.close()
                    messager.show_message(i18n.tr("Song added to queue"), 3)
                }
            }
            Action {
                text: i18n.tr("Go to artist")
                name: "contact"
                onTriggered: {
                    artist_page.cargar(albumModel.get(albumList.index).artist_id)
                    pagestack.push(artistPage)
                    context_menu.close()
                }
            }
        }
    }

    Flickable {
        id: albumFlick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: Math.max(height, mainLayout.implicitHeight + units.gu(2))

        GridLayout {
            id: mainLayout
            width: albumFlick.width
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 0
            columns: width < units.gu(90) ? 1 : 2
            rowSpacing: units.gu(1)
            columnSpacing: units.gu(1)

            Rectangle {
                id: image_layout
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: mainLayout.columns === 1 ? mainLayout.width : mainLayout.width / 3
                Layout.preferredHeight: mainLayout.columns === 1 ? units.gu(35) : Math.max(units.gu(44), albumContainer.height - units.gu(2))
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
                    radius: 28
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.25) }
                        GradientStop { position: 0.8; color: Qt.rgba(0, 0, 0, 0.75) }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85) }
                    }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: units.gu(2)
                    spacing: units.gu(1.5)

                    Rectangle {
                        width: Math.min(parent.width - units.gu(4), units.gu(22))
                        height: width
                        radius: units.gu(0.8)
                        color: "#202020"
                        border.color: Qt.rgba(1, 1, 1, 0.15)
                        border.width: 1
                        anchors.horizontalCenter: parent.horizontalCenter

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
                                radius: units.gu(0.8)
                            }
                        }
                    }

                    Label {
                        id: lbl_album_title
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        fontSize: "large"
                        color: inverseTextColor
                        font.weight: Font.DemiBold
                    }

                    Label {
                        id: lbl_album_date
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        fontSize: "small"
                        color: mutedTextColor
                    }

                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        fontSize: "small"
                        color: mutedTextColor
                        text: i18n.tr("%1 song", "%1 songs", albumModel.count).arg(albumModel.count)
                    }
                }
            }

            Rectangle {
                id: songs_layout
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: mainLayout.columns === 1 ? mainLayout.width : (mainLayout.width / 3) * 2
                Layout.preferredHeight: mainLayout.columns === 1 ? units.gu(70) : Math.max(units.gu(44), albumContainer.height - units.gu(2))
                radius: units.gu(1)
                color: cardColor
                border.color: cardBorder
                border.width: 1
                clip: true

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
                            text: i18n.tr("Tracks")
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(3.4)
                            anchors.verticalCenter: parent.verticalCenter
                            fontSize: "medium"
                            font.weight: Font.DemiBold
                            color: primaryTextColor
                        }

                        Label {
                            text: i18n.tr("%1 total").arg(albumModel.count)
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(2)
                            anchors.verticalCenter: parent.verticalCenter
                            fontSize: "small"
                            color: mutedTextColor
                        }
                    }

                    Item {
                        id: albumView
                        width: parent.width
                        height: parent.height - units.gu(6)

                        ListView {
                            id: albumList
                            property int index: -1
                            anchors.fill: parent
                            anchors.leftMargin: units.gu(0.6)
                            anchors.rightMargin: units.gu(0.6)
                            clip: true
                            spacing: units.gu(0.2)
                            model: albumModel
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: ListItem {
                                contentItem.anchors {
                                    leftMargin: units.gu(1.2)
                                    rightMargin: units.gu(1.2)
                                    topMargin: units.gu(0.9)
                                    bottomMargin: units.gu(0.9)
                                }
                                divider.visible: false
                                color: albumList.index === index ? selectedColor : "transparent"

                                Label {
                                    id: track_index
                                    width: units.gu(3)
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    horizontalAlignment: Text.AlignLeft
                                    fontSize: "small"
                                    color: mutedTextColor
                                    text: (index + 1) + "."
                                }

                                Label {
                                    id: lbl_name
                                    text: name
                                    elide: Text.ElideRight
                                    anchors.left: track_index.right
                                    anchors.leftMargin: units.gu(0.6)
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: lbl_duration.left
                                    anchors.rightMargin: units.gu(1)
                                    color: primaryTextColor
                                }

                                Label {
                                    id: lbl_duration
                                    text: Api.durationToString(duration)
                                    width: units.gu(6)
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: item_menu.left
                                    anchors.rightMargin: units.gu(0.2)
                                    horizontalAlignment: Text.AlignRight
                                    fontSize: "small"
                                    color: mutedTextColor
                                }

                                MouseArea {
                                    id: item_menu
                                    width: units.gu(5)
                                    height: parent.height
                                    anchors.right: parent.right
                                    onClicked: {
                                        if (albumList.index === index) {
                                            context_menu.close()
                                        } else {
                                            albumList.index = index
                                        }
                                        context_menu.caller = item_menu
                                        context_menu.show()
                                    }

                                    Icon {
                                        height: units.gu(2.6)
                                        width: height
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: "contextual-menu"
                                        color: mutedTextColor
                                    }
                                }

                                onClicked: {
                                    var songs = []
                                    var songs_ids = []
                                    playing_page.model_queue.clear()
                                    for (var i = 0; i < albumModel.count; i++) {
                                        var quality = (appRoot && appRoot.settings) ? appRoot.settings.streaming_quality : "320"
                                        var server = appRoot ? appRoot.server : ""
                                        songs.push(server + "play/" + albumModel.get(i).id + "/" + quality)
                                        songs_ids.push(albumModel.get(i).id)
                                        playing_page.model_queue.append(albumModel.get(i))
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

                        Label {
                            id: zero_songs_info
                            visible: albumList.count === 0
                            anchors.centerIn: parent
                            width: parent.width - units.gu(6)
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            fontSize: "small"
                            color: mutedTextColor
                            text: i18n.tr("I'm sorry, list is empty because none of the songs included in this album are of a supported format :(")
                        }
                    }
                }
            }
        }
    }
}
