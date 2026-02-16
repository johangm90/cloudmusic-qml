import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Content 1.3
import UserMetrics 0.1
import Lomiri.DownloadManager 1.2
import Qt.labs.settings 1.0
import FileManager 1.0
import "components"
import "graphics"
import "ui"
import "logic/Api.js" as Api
import "logic/Database.js" as Db

ApplicationWindow {
    id: appWindow
    objectName: "appWindow"

    width: units.gu(45)
    height: units.gu(75)
    visible: true

    property string app_version: "1.7.6"

    property string primaryColor: "#e53446"

    function normalizedThemeMode() {
        if (settings.theme === "Ambiance" || settings.theme === "SuruDark" || settings.theme === "System") {
            return settings.theme
        }
        return "System"
    }

    function applyThemeMode() {
        var mode = normalizedThemeMode()
        if (mode === "System") {
            // Keep platform default (system) theme by not forcing Theme.name.
            Theme.name = ""
        } else {
            Theme.name = "Lomiri.Components.Themes." + mode
        }
    }

    property var settings: Settings {
        property string download_quality: "96000"
        property string streaming_quality: "96000"
        property string theme: "System"
        property bool first_run: true
        property string current_version: ""
        onThemeChanged: appWindow.applyThemeMode()
    }

    MainView {
        id: cloudMusic

        // objectName for functional testing purposes (autopilot-qt5)
        objectName: "mainView"

        // Note! applicationName needs to match the "name" field of the click manifest
        applicationName: "cloudmusic.jgm90.com"

        //automaticOrientation: true

        anchors.fill: parent
        property var settings: appWindow.settings
        property color primaryColor: appWindow.primaryColor
        property string app_version: appWindow.app_version

        // TRANSLATORS: %1 refers to the amount of songs played in the day
        Metric {
            id: cloud_music_metric
            name: "Cloud Music"
            format: i18n.tr("%1 songs played today") + " - Cloud Music"
            emptyFormat: i18n.tr("0 songs played today") + " - Cloud Music"
            domain: "cloudmusic.jgm90.com"
        }

        property
        var server: "https://cloudmusicapi.nubit.io/netease/";
        property bool isDarkTheme: {
            var mode = appWindow.normalizedThemeMode()
            if (mode === "SuruDark") {
                return true
            }
            if (mode === "Ambiance") {
                return false
            }
            // System mode: infer from current effective theme name when available.
            var effectiveTheme = Theme.name ? Theme.name : ""
            return effectiveTheme.indexOf("SuruDark") !== -1
        }
        property color pageColor: isDarkTheme ? "#1f1f1f" : "#f5f5f5"
        property color cardColor: isDarkTheme ? "#232323" : "#ffffff"
        property color borderColor: isDarkTheme ? "#3a3a3a" : "#d8d8d8"
        property color sectionColor: isDarkTheme ? "#1a1a1a" : "#ececec"
        property color textColor: isDarkTheme ? "#f2f2f2" : "#1f1f1f"
        property color secondaryTextColor: isDarkTheme ? "#b8b8b8" : "#666666"
        property color inverseTextColor: "#ffffff"
        property color selectedColor: Qt.rgba(0.9, 0.2, 0.28, isDarkTheme ? 0.22 : 0.16)
        property color tileColor: isDarkTheme ? "#252525" : "#ffffff"
        property color tileBorderColor: isDarkTheme ? "#3a3a3a" : "#dcdcdc"

        Component.onCompleted: {
            appWindow.applyThemeMode()
        }

        Component {
            id: searchPage
            Search {
                appRoot: cloudMusic
            }
        }

        Component {
            id: queuePage
            Queue {
                appRoot: cloudMusic
            }
        }

        ChangeLogDialog {
            id: changelog_dialog
        }

        // Main Actions for page header
        actions: [
            Action {
                id: searchAction
                text: i18n.tr("Search")
                iconName: "find"
                onTriggered: {
                    pagestack.push(searchPage)
                }
            },
            Action {
                id: downloadAction
                text: i18n.tr("Download")
                iconName: "save"
                onTriggered: {
                    pagestack.push(searchPage)
                }
            }
        ]

        function setdialogtext(text) {
            dialog_sub_label.text = text
        }

        PageStack {
            id: pagestack

            Component.onCompleted: {
                Db.init()
                if (settings.current_version != app_version) {
                    PopupUtils.open(changelog_dialog)
                }
                push(searchLoader)
            }
        }

        Loader {
            id: searchLoader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            source: (pagestack.currentPage === searchLoader) ? Qt.resolvedUrl("ui/SearchHistory.qml") : ""
            onLoaded: {
                try {
                    item.appRoot = cloudMusic
                } catch (e) {}
            }
            visible: false
        }

        Loader {
            id: albumsLoader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            source: Qt.resolvedUrl("ui/NewAlbums.qml")
            onLoaded: {
                try {
                    item.appRoot = cloudMusic
                } catch (e) {}
            }
            visible: false
        }

        Loader {
            id: artistsLoader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            source: Qt.resolvedUrl("ui/TopArtists.qml")
            onLoaded: {
                try {
                    item.appRoot = cloudMusic
                } catch (e) {}
            }
            visible: false
        }

        Loader {
            id: playlistsLoader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            source: (pagestack.currentPage === playlistsLoader) ? Qt.resolvedUrl("ui/Playlists.qml") : ""
            onLoaded: {
                try {
                    item.appRoot = cloudMusic
                } catch (e) {}
            }
            visible: false
        }

        Loader {
            id: settingsLoader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            source: (pagestack.currentPage === settingsLoader) ? Qt.resolvedUrl("ui/SettingsPage.qml") : ""
            onLoaded: {
                try {
                    item.appRoot = cloudMusic
                } catch (e) {}
            }
            visible: false
        }

        Loader {
            id: aboutLoader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            source: (pagestack.currentPage === aboutLoader) ? Qt.resolvedUrl("ui/About.qml") : ""
            onLoaded: {
                try {
                    item.appRoot = cloudMusic
                } catch (e) {}
            }
            visible: false
        }

        Page {
            id: artistPage
            visible: false

            header: PageHeader {
                title: i18n.tr("Artist")
            }

            Artist {
                id: artist_page
                appRoot: cloudMusic
                anchors {
                    top: artistPage.header.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: media_player.playbackState != 0 ? units.gu(7.25) : 0
                }
            }
        }

        Page {
            id: albumPage
            visible: false
            header: PageHeader {
                title: i18n.tr("Album")
                trailingActionBar {
                    numberOfSlots: 0
                    actions: [
                        Action {
                            id: toqueueAction
                            text: i18n.tr("Add to playlist")
                            iconName: "add-to-playlist"
                            onTriggered: {
                                album_page.add_to_playlist()
                            }
                        }
                    ]
                }
            }

            Album {
                id: album_page
                appRoot: cloudMusic
                anchors {
                    top: albumPage.header.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: media_player.playbackState != 0 ? units.gu(7.25) : 0
                }
            }
        }

        Page {
            id: playlistDetailPage
            visible: false
            header: PageHeader {
                title: i18n.tr("Playlist")
            }

            PlaylistDetail {
                id: playlist_detail_page
                appRoot: cloudMusic
                anchors {
                    top: playlistDetailPage.header.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
            }
        }

        Page {
            id: playingPage
            visible: false
            header: PageHeader {
                title: i18n.tr("Now Playing")
                trailingActionBar.actions: [
                    Action {
                        id: queueAction
                        text: i18n.tr("Queue")
                        iconName: "media-playlist"
                        onTriggered: {
                            pagestack.push(queuePage)
                        }
                        visible: cloudMusic.width < units.gu(100) ? true : false
                    }
                ]
            }

            NowPlaying {
                id: playing_page
                appRoot: cloudMusic
                anchors {
                    top: playingPage.header.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
            }
        }

        Player {
            id: media_player
        }

        PlayerToolbar {
            id: player_toolbar
        }

        Messager {
            id: messager
        }

        Component {
            id: downloadDialog
            DownloadDialog {}
        }

        Component {
            id: transferFileDialog
            TransferFileDialog {}
        }

        //test
        SingleDownload {
            id: downloader
        }

        Component {
            id: ddialog
            Dialog {
                id: dialogue
                title: "Downloading"
                text: "please wait"
                ProgressBar {
                    width: parent.width
                    minimumValue: 0
                    maximumValue: 100
                    value: downloader.progress
                }
                Connections {
                    target: downloader
                    onFinished: {
                        PopupUtils.close(dialogue)
                    }
                }
                Button {
                    text: "Cancel"
                    color: LomiriColors.orange
                    onClicked: {
                        downloader.cancel()
                        PopupUtils.close(dialogue)
                    }
                }
            }
        }

        Component {
            id: downloadComponent
            SingleDownload {
                autoStart: false
                property
                var contentType
                property string name
                property string nameArtist
                property var activeTransfer
                metadata: Metadata {
                    showInIndicator: true
                    title: nameArtist + "-" + name
                }
                onDownloadIdChanged: {
                    activeTransfer = contentPeer.request()
                    activeTransfer.downloadId = downloadId
                    activeTransfer.state = ContentTransfer.Downloading
                }

                onFinished: {
                    var nameComb = nameArtist + "-" + name + ".mp3"
                    var fileDir = Api.splitFileName(path)
                    contentItemTransfer.url = fileDir[0] + fileDir[1]
                    var resultMove = contentItemTransfer.move(fileDir[0], nameComb)
                    contentItemTransfer.url = fileDir[0] + nameComb
                    PopupUtils.open(transferFileDialog, cloudMusic, {
                                        "contentType": ContentType.Music,
                                        "fileUrl": contentItemTransfer.url
                    })
                    destroy()
                }
            }
        }
        ContentPeer {
        id: contentPeer
        contentType: ContentType.Music
        handler: ContentHandler.Source
        selectionType: ContentTransfer.Single
        }
        ContentItem {
        id: contentItemTransfer
        }
    }
}
