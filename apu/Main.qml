import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.1
import UserMetrics 0.1
import Ubuntu.DownloadManager 1.2
import Qt.labs.settings 1.0
import Apu 1.0
import "components"
import "graphics"
import "themes"
import "ui"
import "logic/Api.js" as Api
import "logic/Database.js" as Db

MainView {
    id: cloudMusic

    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "apu.johangm90"

    //automaticOrientation: true

    width: units.gu(50)
    height: units.gu(75)

    property string app_version: "1.5.9"

    property var settings: Settings {
        property string download_quality: "96000"
        property string streaming_quality: "96000"
        property string theme: "Ambiance"
        property bool first_run: true
        property string current_version: ""
        onThemeChanged: Theme.name = "Ubuntu.Components.Themes." + settings.theme
    }

    // TRANSLATORS: %1 refers to the amount of songs played in the day
    Metric {
        id: cloud_music_metric
        name: "Cloud Music"
        format: i18n.tr("%1 songs played today") + " - Cloud Music"
        emptyFormat: i18n.tr("0 songs played today") + " - Cloud Music"
        domain: "apu.johangm90"
    }

    property var server: "http://app.jgm90.com/cmapi/netease/";

    Component {
        id: searchPage
        Search {}
    }

    Component {
        id: queuePage
        Queue {}
    }

    ChangeLogDialog {
        id: changelog_dialog
    }

    // Main Actions for page header
    actions: [
        Action {
            id: searchAction
            text: i18n.tr("Search")
            iconName: "search"
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

    ListModel {
        id: migrationModel
    }

    Rectangle {
         id: dialog
         visible: false
         color: "#333"
         z: 9
         anchors.fill: parent

         Label {
             id: dialog_label
             anchors.top: parent.top
             anchors.horizontalCenter: parent.horizontalCenter
             anchors.topMargin: units.gu(15)
             color: "#fff"
             fontSize: "large"
             text: i18n.tr("Migration required")
         }

         Label {
             id: dialog_sub_label
             anchors.top: dialog_label.bottom
             anchors.left: parent.left
             anchors.right: parent.right
             anchors.margins: units.gu(2)
             color: "#fff"
             fontSize: "medium"
             wrapMode: Label.WordWrap
             horizontalAlignment: Label.AlignHCenter
             verticalAlignment: Label.AlignVCenter
             text: i18n.tr("This migration is to ensure your previous database works properly. If you haven't run CloudMusic before, click the button anyway and you'll have a fresh database")
         }

         ActivityIndicator {
             id: dialog_loader
             anchors.centerIn: parent
             z: 99
         }

         Button {
             id: dialog_button
             text: i18n.tr("Migrate")
             color: UbuntuColors.green
             anchors.horizontalCenter: parent.horizontalCenter
             anchors.bottom: parent.bottom
             anchors.bottomMargin: units.gu(15)
             onClicked: {
                 Db.migrate()
                 dialog_loader.running = true
                 dialog_button.visible = false
                 Api.migration()
             }
         }
    }

    function migrate(data){
        Db.upgradesong(data)
    }

    function migrated(){
        dialog.visible = false
        settings.first_run = false
        pagestack.push(searchLoader)
    }

    function setdialogtext(text){
        dialog_sub_label.text = text
    }

    PageStack {
        id: pagestack

        Component.onCompleted: {
            Db.init()
            if(settings.current_version != app_version){
                PopupUtils.open(changelog_dialog)
            }
            if(settings.first_run){
                dialog.visible = true
            }else{
                push(searchLoader)
            }
        }
    }

    Loader {
        id: searchLoader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        source: (pagestack.currentPage === searchLoader) ? Qt.resolvedUrl("ui/SearchHistory.qml") : ""
        visible: false
    }

    Loader {
        id: albumsLoader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        source: Qt.resolvedUrl("ui/NewAlbums.qml")
        visible: false
    }

    Loader {
        id: artistsLoader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        source: Qt.resolvedUrl("ui/TopArtists.qml")
        visible: false
    }

    Loader {
        id: playlistsLoader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        source: (pagestack.currentPage === playlistsLoader) ? Qt.resolvedUrl("ui/Playlists.qml") : ""
        visible: false
    }

    Loader {
        id: settingsLoader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        source: (pagestack.currentPage === settingsLoader) ? Qt.resolvedUrl("ui/SettingsPage.qml") : ""
        visible: false
    }

    Loader {
        id: aboutLoader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        source: (pagestack.currentPage === aboutLoader) ? Qt.resolvedUrl("ui/About.qml") : ""
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
        DownloadDialog { }
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
                 color: UbuntuColors.orange
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
            property var contentType
            property string name
            metadata: Metadata {
                showInIndicator: true
                title: name
            }
            onDownloadIdChanged: {
                PopupUtils.open(downloadDialog, cloudMusic, {"contentType" : ContentType.Music, "downloadId" : downloadId})
            }

            onFinished: {
                destroy()
            }
        }
    }
}

