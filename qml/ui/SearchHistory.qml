import QtQuick 2.12
import Lomiri.Components 1.3
import "../components"
import "../logic/Database.js" as Db

Page {
    id: searchHistoryPage
    property var appRoot
    property color pageColor: appRoot ? appRoot.pageColor : "#f5f5f5"
    property ListModel recentModel: ListModel {}
    property ListModel playlistModel: ListModel {}

    function refreshHome() {
        recentModel.clear()
        playlistModel.clear()

        var recent = Db.getRecentlyPlayed(4)
        for (var i = 0; i < recent.length; i++) {
            recentModel.append(recent[i])
        }

        var playlists = Db.getPlaylists()
        for (var j = 0; j < Math.min(4, playlists.length); j++) {
            playlistModel.append(playlists[j])
        }
    }

    function openLibrary() {
        pagestack.push(libraryLoader)
    }

    function playSong(record) {
        if (!record || !record.song_id) {
            return
        }
        var source = appRoot ? appRoot.server + "play/" + record.song_id + "/" + appRoot.settings.streaming_quality : ""
        playing_page.model_queue.clear()
        playing_page.model_queue.append(record)
        playing_page.songs_list = [record.song_id]
        pagestack.push(playingPage)
        media_player.setPlaylist([source], 0)
    }

    Component.onCompleted: refreshHome()
    onVisibleChanged: if (visible) refreshHome()

    header: PageHeader {
        title: i18n.tr("Search")
        trailingActionBar {
            numberOfSlots: 1
            actions: [
                Action {
                    text: i18n.tr("Search")
                    iconName: "find"
                    onTriggered: pagestack.push(searchPage)
                }
            ]
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: searchHistoryPage.header ? searchHistoryPage.header.height : 0
        color: pageColor
        z: -1

        Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: homeContent.implicitHeight + units.gu(4)
            clip: true

        Column {
            id: homeContent
            width: parent.width
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: appRoot ? appRoot.pagePadding : units.gu(2)
            }
            spacing: units.gu(2.5)

            Item { width: 1; height: units.gu(1) }

            Label {
                text: i18n.tr("Find something worth replaying")
                color: appRoot ? appRoot.textColor : "#1f1f1f"
                fontSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.display : "x-large"
                font.weight: Font.DemiBold
            }

            Label {
                width: parent.width * 0.72
                text: i18n.tr("Search millions of songs, albums and artists. Your next favorite is probably one search away.")
                wrapMode: Text.WordWrap
                color: appRoot ? appRoot.secondaryTextColor : "#666666"
                fontSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.body : "medium"
            }

            Flow {
                width: parent.width
                spacing: units.gu(1)

                Button {
                    text: i18n.tr("Search music")
                    color: appRoot ? appRoot.primaryColor : "#e53446"
                    onClicked: pagestack.push(searchPage)
                }

                Button {
                    text: i18n.tr("Browse new albums")
                    color: appRoot ? appRoot.surfaceElevatedColor : "#ffffff"
                    onClicked: pagestack.push(albumsLoader)
                }
            }

            Label {
                text: i18n.tr("Your library")
                color: appRoot ? appRoot.textColor : "#1f1f1f"
                fontSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.title : "large"
                font.weight: Font.DemiBold
            }

            Flow {
                width: parent.width
                spacing: units.gu(1)

                Repeater {
                    model: [
                        { title: i18n.tr("Favorites"), value: Db.getLikedSongs(1000).length, icon: "like" },
                        { title: i18n.tr("Recently played"), value: Db.getRecentlyPlayed(1000).length, icon: "history" },
                        { title: i18n.tr("Playlists"), value: Db.getPlaylists().length, icon: "stock_music" }
                    ]

                    delegate: Rectangle {
                        width: homeContent.width < units.gu(45) ? (homeContent.width - units.gu(1)) / 2 : Math.max(units.gu(12), Math.min(units.gu(22), (homeContent.width - units.gu(2)) / 3))
                        height: units.gu(9)
                        radius: appRoot ? appRoot.radiusMedium : units.gu(1)
                        color: appRoot ? appRoot.surfaceElevatedColor : "#ffffff"

                        VectorIcon {
                            anchors { right: parent.right; top: parent.top; margins: units.gu(1.2) }
                            width: units.gu(2.5)
                            height: width
                            iconName: modelData.icon === "like" ? "heart" : (modelData.icon === "history" ? "history" : "list-music")
                            color: appRoot ? appRoot.textColor : "#1f1f1f"
                        }

                        Column {
                            anchors { left: parent.left; bottom: parent.bottom; margins: units.gu(1.2) }
                            spacing: units.gu(0.2)

                            Label {
                                text: modelData.value
                                color: appRoot ? appRoot.textColor : "#1f1f1f"
                                fontSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.heading : "x-large"
                                font.weight: Font.DemiBold
                            }

                            Label {
                                text: modelData.title
                                color: appRoot ? appRoot.secondaryTextColor : "#666666"
                                fontSize: "small"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: openLibrary()
                        }
                    }
                }
            }

            Label {
                visible: recentModel.count > 0
                text: i18n.tr("Continue listening")
                color: appRoot ? appRoot.textColor : "#1f1f1f"
                fontSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.title : "large"
                font.weight: Font.DemiBold
            }

            ListView {
                visible: recentModel.count > 0
                model: recentModel
                width: parent.width
                height: contentHeight
                contentHeight: count * units.gu(6.2)
                interactive: false
                delegate: Rectangle {
                    width: parent.width
                    height: units.gu(6.2)
                    color: "transparent"

                    Rectangle {
                        width: units.gu(4.8)
                        height: width
                        radius: appRoot ? appRoot.radiusSmall : units.gu(0.6)
                        color: appRoot ? appRoot.sectionColor : "#ececec"

                        Image {
                            anchors.fill: parent
                            source: image
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    Column {
                        anchors { left: parent.left; leftMargin: units.gu(6); verticalCenter: parent.verticalCenter }
                        spacing: units.gu(0.2)

                        Label {
                            text: name
                            color: appRoot ? appRoot.textColor : "#1f1f1f"
                            elide: Text.ElideRight
                            width: parent.parent.width - units.gu(7)
                            font.weight: Font.DemiBold
                        }

                        Label {
                            text: artist
                            color: appRoot ? appRoot.secondaryTextColor : "#666666"
                            fontSize: "small"
                            elide: Text.ElideRight
                            width: parent.parent.width - units.gu(7)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: playSong(model)
                    }
                }
            }

            Label {
                visible: playlistModel.count > 0
                text: i18n.tr("Your playlists")
                color: appRoot ? appRoot.textColor : "#1f1f1f"
                fontSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.title : "large"
                font.weight: Font.DemiBold
            }

            Flow {
                visible: playlistModel.count > 0
                width: parent.width
                spacing: units.gu(1)

                Repeater {
                    model: playlistModel
                    delegate: Rectangle {
                        width: units.gu(18)
                        height: units.gu(6)
                        radius: appRoot ? appRoot.radiusMedium : units.gu(1)
                        color: appRoot ? appRoot.surfaceElevatedColor : "#ffffff"

                        VectorIcon {
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: units.gu(1) }
                            width: units.gu(2.2)
                            height: width
                            iconName: "list-music"
                            color: appRoot ? appRoot.secondaryTextColor : "#666666"
                        }

                        Column {
                            anchors { left: parent.left; leftMargin: units.gu(4); verticalCenter: parent.verticalCenter }
                            spacing: units.gu(0.1)
                            Label { text: name; color: appRoot ? appRoot.textColor : "#1f1f1f"; elide: Text.ElideRight; width: units.gu(13); font.weight: Font.DemiBold }
                            Label { text: i18n.tr("%1 songs").arg(count); color: appRoot ? appRoot.secondaryTextColor : "#666666"; fontSize: "small" }
                        }

                        MouseArea { anchors.fill: parent; onClicked: openLibrary() }
                    }
                }
            }

            Item { width: 1; height: units.gu(1) }
        }
        }
    }
}
