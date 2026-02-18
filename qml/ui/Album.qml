import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.2
import "../logic/Format.js" as Format
import "../logic/RequestBus.js" as RequestBus
import "../logic/Database.js" as Db
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
    property real spacingSmall: appRoot ? appRoot.spacingSmall : units.gu(0.8)
    property real spacingMedium: appRoot ? appRoot.spacingMedium : units.gu(1.2)
    property real radiusSmall: appRoot ? appRoot.radiusSmall : units.gu(0.8)
    property real radiusMedium: appRoot ? appRoot.radiusMedium : units.gu(1.2)
    property real layoutGap: spacingSmall + units.gu(0.2)
    property real sectionHeaderHeight: units.gu(6)
    property real sectionAccentWidth: units.gu(0.6)
    property real sectionAccentHeight: units.gu(3.2)
    property real gridBreakpoint: units.gu(90)
    property string titleTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.title : "large"
    property string bodyTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.body : "medium"
    property string bodySmallTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.bodySmall : "small"
    property string requestContext: "album_" + String(Date.now())

    function cargar(id) {
        if (!appRoot || !appRoot.cloudApi) {
            return
        }
        RequestBus.cancelContext(requestContext)
        var activeRequestId = RequestBus.createId("album_detail")
        album_loader.running = true
        is_visible(false)
        albumModel.clear()
        photo.source = "../graphics/default.png"
        lbl_album_title.text = ""
        lbl_album_date.text = ""
        RequestBus.registerRequest(activeRequestId, {
            context: requestContext,
            onSuccess: function(data) {
                if (!data || !data.album) {
                    is_visible(true)
                    return
                }
                photo.source = data.album.big_image ? data.album.big_image : "../graphics/default.png"
                lbl_album_title.text = data.album.name ? data.album.name : ""
                var publishTime = data.album.publish_time ? data.album.publish_time : 0
                lbl_album_date.text = i18n.tr("Release Date:") + " " + formatDate(new Date(publishTime))
                if (data.songs) {
                    for (var i = 0; i < data.songs.length; i++) {
                        albumModel.append(data.songs[i])
                    }
                }
                is_visible(true)
            },
            onError: function(err) {
                console.log(err)
                is_visible(true)
            },
            onFinally: function() {
                album_loader.running = false
            }
        })
        appRoot.cloudApi.getAlbumDetailAsync(String(id), activeRequestId)
    }

    Component.onDestruction: {
        RequestBus.cancelContext(requestContext)
    }

    function formatDate(date) {
        var y = date.getFullYear()
        var m = date.getMonth() + 1
        var d = date.getDate()
        return y + "-" + (m < 10 ? ("0" + m) : m) + "-" + (d < 10 ? ("0" + d) : d)
    }

    Connections {
        target: appRoot && appRoot.cloudApi ? appRoot.cloudApi : null
        onRequestFinished: function(requestId, ok, payloadJson, error) {
            RequestBus.dispatch(requestId, ok, payloadJson, error)
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
                            albumModel.get(albumList.index).id,
                            albumModel.get(albumList.index).name,
                            albumModel.get(albumList.index).artist
                        )
                    }
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
                text: (albumList.index >= 0 && Db.isLikedSong(albumModel.get(albumList.index).id, albumModel.get(albumList.index).source))
                      ? i18n.tr("Remove from Favorites")
                      : i18n.tr("Add to Favorites")
                name: (albumList.index >= 0 && Db.isLikedSong(albumModel.get(albumList.index).id, albumModel.get(albumList.index).source))
                      ? "like"
                      : "unlike"
                onTriggered: {
                    var liked = Db.toggleLikedSong(albumModel.get(albumList.index))
                    messager.show_message(liked ? i18n.tr("Added to Favorites") : i18n.tr("Removed from Favorites"), 3)
                    context_menu.close()
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
        contentHeight: Math.max(height, mainLayout.implicitHeight + spacingMedium + spacingSmall)

        GridLayout {
            id: mainLayout
            width: albumFlick.width
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 0
            columns: width < gridBreakpoint ? 1 : 2
            rowSpacing: layoutGap
            columnSpacing: layoutGap

            Rectangle {
                id: image_layout
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: mainLayout.columns === 1 ? mainLayout.width : mainLayout.width / 3
                Layout.preferredHeight: mainLayout.columns === 1 ? units.gu(35) : Math.max(units.gu(44), albumContainer.height - units.gu(2))
                radius: radiusMedium
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
                    anchors.margins: spacingMedium + spacingSmall
                    spacing: spacingMedium + layoutGap

                    Rectangle {
                        width: Math.min(parent.width - (spacingMedium + spacingSmall) * 2, units.gu(22))
                        height: width
                        radius: radiusSmall
                        color: sectionColor
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
                                radius: radiusSmall
                            }
                        }
                    }

                    Label {
                        id: lbl_album_title
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        fontSize: titleTextSize
                        color: inverseTextColor
                        font.weight: Font.DemiBold
                    }

                    Label {
                        id: lbl_album_date
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        fontSize: bodySmallTextSize
                        color: mutedTextColor
                    }

                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        fontSize: bodySmallTextSize
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
                radius: radiusMedium
                color: cardColor
                border.color: cardBorder
                border.width: 1
                clip: true

                Column {
                    anchors.fill: parent

                    Rectangle {
                        width: parent.width
                        height: sectionHeaderHeight
                        color: sectionColor

                        Rectangle {
                            width: sectionAccentWidth
                            height: sectionAccentHeight
                            radius: width / 2
                            color: accentColor
                            anchors.left: parent.left
                            anchors.leftMargin: spacingMedium + spacingSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: i18n.tr("Tracks")
                            anchors.left: parent.left
                            anchors.leftMargin: spacingMedium + spacingSmall + units.gu(1.4)
                            anchors.verticalCenter: parent.verticalCenter
                            fontSize: bodyTextSize
                            font.weight: Font.DemiBold
                            color: primaryTextColor
                        }

                        Label {
                            text: i18n.tr("%1 total").arg(albumModel.count)
                            anchors.right: parent.right
                            anchors.rightMargin: spacingMedium + spacingSmall
                            anchors.verticalCenter: parent.verticalCenter
                            fontSize: bodySmallTextSize
                            color: mutedTextColor
                        }
                    }

                    Item {
                        id: albumView
                        width: parent.width
                        height: parent.height - sectionHeaderHeight

                        ListView {
                            id: albumList
                            property int index: -1
                            anchors.fill: parent
                            anchors.leftMargin: layoutGap
                            anchors.rightMargin: layoutGap
                            clip: true
                            spacing: units.gu(0.2)
                            model: albumModel
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: SongListItem {
                                title: name
                                subtitle: artist
                                durationText: Format.durationToString(duration)
                                coverSource: image
                                albumId: album_id
                                leadingText: (index + 1) + "."
                                selected: albumList.index === index
                                rowTextColor: primaryTextColor
                                rowSecondaryTextColor: mutedTextColor
                                selectedColor: albumContainer.selectedColor
                                onMenuClicked: {
                                    if (albumList.index === index) {
                                        context_menu.close()
                                    } else {
                                        albumList.index = index
                                    }
                                    context_menu.caller = caller
                                    context_menu.show()
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
                            fontSize: bodySmallTextSize
                            color: mutedTextColor
                            text: i18n.tr("I'm sorry, list is empty because none of the songs included in this album are of a supported format :(")
                        }
                    }
                }
            }
        }
    }
}
