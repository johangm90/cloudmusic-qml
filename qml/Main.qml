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
import CloudMusic 1.0
import "components"
import "graphics"
import "ui"
import "logic/AppContext.js" as AppContext
import "logic/DesignTokens.js" as DesignTokens
import "logic/RequestBus.js" as RequestBus
import "logic/Database.js" as Db

ApplicationWindow {
    id: appWindow
    objectName: "appWindow"

    width: units.gu(45)
    height: units.gu(75)
    visible: true

    property string app_version: "1.8.0"

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
        property string download_quality: "96"
        property string streaming_quality: "96"
        property string theme: "System"
        property bool first_run: true
        property string current_version: ""
        onThemeChanged: appWindow.applyThemeMode()
    }

    function normalizeQuality(value) {
        var v = parseInt(value, 10)
        if (!v || v <= 0) {
            return "96"
        }
        if (v >= 1000) {
            v = Math.floor(v / 1000)
        }
        if (v >= 320) {
            return "320"
        }
        if (v >= 160) {
            return "160"
        }
        return "96"
    }

    MainView {
        id: cloudMusic

        // objectName for functional testing purposes (autopilot-qt5)
        objectName: "mainView"

        // Note! applicationName needs to match the "name" field of the click manifest
        applicationName: "apu.johangm90"

        //automaticOrientation: true

        anchors.fill: parent
        property var settings: appWindow.settings
        property color primaryColor: appWindow.primaryColor
        property string app_version: appWindow.app_version

        FileManager {
            id: fileMgr
        }

        CloudMusic {
            id: cloudApiBridge
        }

        Timer {
            id: cloudApiPumpTimer
            interval: 30
            running: true
            repeat: true
            onTriggered: {
                cloudApiBridge.pumpResponses()
                RequestBus.prune()
            }
        }
        
        property var fileManager: fileMgr
        property var cloudApi: cloudApiBridge

        // TRANSLATORS: %1 refers to the amount of songs played in the day
        Metric {
            id: cloud_music_metric
            name: "Cloud Music"
            format: i18n.tr("%1 songs played today") + " - Cloud Music"
            emptyFormat: i18n.tr("0 songs played today") + " - Cloud Music"
            domain: "apu.johangm90"
        }

        property
        var server: "http://127.0.0.1:39876/";
        property var designTokens: DesignTokens.build(isDarkTheme, appWindow.primaryColor)
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
        property color pageColor: designTokens.color.page
        property color cardColor: designTokens.color.card
        property color borderColor: designTokens.color.border
        property color sectionColor: designTokens.color.section
        property color textColor: designTokens.color.text
        property color secondaryTextColor: designTokens.color.textMuted
        property color inverseTextColor: designTokens.color.textInverse
        property color selectedColor: designTokens.color.selected
        property color tileColor: designTokens.color.tile
        property color tileBorderColor: designTokens.color.tileBorder
        property real radiusSmall: units.gu(designTokens.radius.sm)
        property real radiusMedium: units.gu(designTokens.radius.md)
        property real spacingSmall: units.gu(designTokens.spacing.sm)
        property real spacingMedium: units.gu(designTokens.spacing.md)
        property real spacingLarge: units.gu(designTokens.spacing.lg)
        property real pagePadding: units.gu(designTokens.spacing.page)
        property real layoutPlayerInset: units.gu(designTokens.layout.playerToolbarHeight)

        Component.onCompleted: {
            appWindow.applyThemeMode()
            appWindow.settings.download_quality = appWindow.normalizeQuality(appWindow.settings.download_quality)
            appWindow.settings.streaming_quality = appWindow.normalizeQuality(appWindow.settings.streaming_quality)
            AppContext.set("appRoot", cloudMusic)
            AppContext.set("settings", appWindow.settings)
            AppContext.set("cloudApi", cloudApiBridge)
            AppContext.set("designTokens", cloudMusic.designTokens)
            AppContext.set("messager", messager)
            AppContext.set("downloadComponent", downloadComponent)
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

        property string downloadRequestContext: "main_download"

        function requestSongDownload(songId, songName, artistName) {
            if (!songId) {
                messager.show_message(i18n.tr("Download failed: missing song id"), 3)
                return
            }
            var requestId = RequestBus.createId("download_url")
            var pending = {
                id: String(songId),
                name: songName ? String(songName) : "",
                artist: artistName ? String(artistName) : i18n.tr("Unknown")
            }
            var q = (appWindow.settings && appWindow.settings.download_quality) ? appWindow.settings.download_quality : "96"
            RequestBus.registerRequest(requestId, {
                context: downloadRequestContext,
                onSuccess: function(payload) {
                    if (!payload || payload.error || !payload.url) {
                        console.error("Download URL payload invalid")
                        messager.show_message(i18n.tr("Download failed"), 3)
                        return
                    }
                    var singleDownload = downloadComponent.createObject(cloudMusic, {
                        "name": pending.name,
                        "nameArtist": pending.artist.replace(/\s+/g, "_")
                    })
                    if (!singleDownload) {
                        console.error("Download component creation failed")
                        messager.show_message(i18n.tr("Download failed"), 3)
                        return
                    }
                    singleDownload.download(payload.url)
                },
                onError: function(err) {
                    console.error("Download URL request failed: " + err)
                    messager.show_message(i18n.tr("Download failed"), 3)
                }
            })
            cloudApiBridge.downloadUrlAsync(String(songId), String(q), requestId)
        }

        Connections {
            target: cloudApiBridge
            onRequestFinished: function(requestId, ok, payloadJson, error) {
                RequestBus.dispatch(requestId, ok, payloadJson, error)
            }
        }

        PageStack {
            id: pagestack

            Component.onCompleted: {
                Db.init()
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
            id: libraryLoader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            source: (pagestack.currentPage === libraryLoader) ? Qt.resolvedUrl("ui/Library.qml") : ""
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
                    bottomMargin: media_player.playbackState != 0 ? cloudMusic.layoutPlayerInset : 0
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
                    bottomMargin: media_player.playbackState != 0 ? cloudMusic.layoutPlayerInset : 0
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
            id: favoritesPage
            visible: false
            header: PageHeader {
                title: i18n.tr("Favorites")
                contents: TextField {
                    id: favorites_query
                    inputMethodHints: Qt.ImhNoPredictiveText
                    placeholderText: i18n.tr("Search in Favorites")
                    anchors.fill: parent
                    anchors.rightMargin: units.gu(2)
                    anchors.topMargin: units.gu(1)
                    anchors.bottomMargin: units.gu(1)
                    onVisibleChanged: {
                        if (visible) {
                            forceActiveFocus()
                        }
                    }
                    onTextChanged: {
                        favorites_page.setQuery(text)
                    }
                }
            }

            LibrarySongs {
                id: favorites_page
                appRoot: cloudMusic
                mode: "favorites"
                anchors {
                    top: favoritesPage.header.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: media_player.playbackState != 0 ? cloudMusic.layoutPlayerInset : 0
                }
            }
        }

        Page {
            id: recentPage
            visible: false
            header: PageHeader {
                title: i18n.tr("Recently Played")
                contents: TextField {
                    id: recent_query
                    inputMethodHints: Qt.ImhNoPredictiveText
                    placeholderText: i18n.tr("Search in Recently Played")
                    anchors.fill: parent
                    anchors.rightMargin: units.gu(2)
                    anchors.topMargin: units.gu(1)
                    anchors.bottomMargin: units.gu(1)
                    onVisibleChanged: {
                        if (visible) {
                            forceActiveFocus()
                        }
                    }
                    onTextChanged: {
                        recent_page.setQuery(text)
                    }
                }
            }

            LibrarySongs {
                id: recent_page
                appRoot: cloudMusic
                mode: "recent"
                anchors {
                    top: recentPage.header.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: media_player.playbackState != 0 ? cloudMusic.layoutPlayerInset : 0
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
                    },
                    Action {
                        id: likeAction
                        text: playing_page.isCurrentSongLiked() ? i18n.tr("Remove from Favorites") : i18n.tr("Add to Favorites")
                        iconName: playing_page.isCurrentSongLiked() ? "like" : "unlike"
                        onTriggered: {
                            var liked = playing_page.toggleCurrentSongLike()
                            messager.show_message(liked ? i18n.tr("Added to Favorites") : i18n.tr("Removed from Favorites"), 3)
                        }
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
                autoStart: true
                property var contentType
                property string name
                property string nameArtist
                property var activeTransfer
                metadata: Metadata {
                    showInIndicator: true
                    title: nameArtist + "-" + name
                }

                onFinished: {
                    console.log("Download finished. Path: " + path)
                    
                    // Validate that path is not empty
                    if (!path || path === "") {
                        console.error("Download error: file path is empty")
                        messager.show_message(i18n.tr("Download failed: invalid file path"), 3)
                        destroy()
                        return
                    }
                    
                    // Generate nice filename from artist and song name
                    var niceName = nameArtist + "-" + name + ".mp3"
                    console.log("Nice filename: " + niceName)
                    
                    // Try to rename the file using fileManager
                    var finalPath = path
                    try {
                        if (fileMgr && typeof fileMgr.moveFile === 'function') {
                            console.log("Attempting to rename file: " + niceName)
                            var moveResult = fileMgr.moveFile(path, niceName)
                            if (moveResult) {
                                // Extract directory and build new path
                                var lastSlash = path.lastIndexOf("/")
                                var directory = path.substring(0, lastSlash + 1)
                                finalPath = directory + niceName
                                console.log("File renamed successfully to: " + finalPath)
                            } else {
                                console.warn("FileManager moveFile failed, using original path")
                            }
                        } else {
                            console.warn("FileManager moveFile not available, using original path")
                        }
                    } catch (e) {
                        console.warn("Error renaming file: " + e)
                    }
                    
                    // Convert to file:// URL if needed
                    var fileUrl = finalPath
                    if (!fileUrl.startsWith("file://")) {
                        fileUrl = "file://" + fileUrl
                    }
                    
                    console.log("Using downloaded file: " + fileUrl)
                    
                    // Set up content item with the saved file
                    contentItemTransfer.url = fileUrl
                    
                    // Open transfer dialog to let user choose destination
                    PopupUtils.open(transferFileDialog, cloudMusic, {
                                        "contentType": ContentType.Music,
                                        "fileUrl": contentItemTransfer.url
                    })
                    destroy()
                }
                
                Component.onCompleted: {
                    console.log("SingleDownload component created")
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
