import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../components"
import "../logic/Database.js" as Db

Page {
    id: libraryPage
    property var appRoot
    property color pageColor: appRoot ? appRoot.pageColor : "#f5f5f5"
    property color cardColor: appRoot ? appRoot.cardColor : "#ffffff"
    property color borderColor: appRoot ? appRoot.borderColor : "#d8d8d8"
    property color textColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color secondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#898B8C"
    property color accentColor: appRoot ? appRoot.primaryColor : "#e53446"
    property real pagePadding: appRoot ? appRoot.pagePadding : units.gu(1.2)
    property real radiusMedium: appRoot ? appRoot.radiusMedium : units.gu(1.2)
    property int favoritesCount: 0
    property int recentCount: 0

    function refreshLibrary() {
        Db.updateRecords(modelo_playlists)
        favoritesCount = Db.getLikedSongs(1000).length
        recentCount = Db.getRecentlyPlayed(1000).length
    }

    onVisibleChanged: {
        if (visible) {
            refreshLibrary()
        }
    }

    Component.onCompleted: {
        refreshLibrary()
    }

    TabsList {
        id: tabsList
    }

    header: PageHeader {
        title: i18n.tr("Library")
        leadingActionBar {
            numberOfSlots: 0
            actions: tabsList.actions
        }
        trailingActionBar.actions: [
            Action{
                id: addPlaylistAction
                text: i18n.tr("Add Playlist")
                iconName: "add"
                onTriggered: PopupUtils.open(newplaylist)
            }
        ]
    }

    ListModel { id: modelo_playlists }

    Component {
        id: newplaylist
        Dialog {
            id: create_playlist
            title: i18n.tr("New playlist")
            TextField {
                id: txt_playlist
                placeholderText: i18n.tr("Enter playlist name")
                inputMethodHints: Qt.ImhNoPredictiveText
                onVisibleChanged: if (visible) forceActiveFocus()
            }
            Button {
                text: i18n.tr("Create")
                color: LomiriColors.green
                onClicked: {
                    Db.insertPlaylist(txt_playlist.text)
                    refreshLibrary()
                    PopupUtils.close(create_playlist)
                }
            }
            Button {
                text: i18n.tr("Cancel")
                color: LomiriColors.darkGrey
                onClicked: PopupUtils.close(create_playlist)
            }
        }
    }

    Component {
        id: editplaylist
        Dialog {
            id: edit_playlist
            title: i18n.tr("Edit playlist")
            TextField {
                id: txt_name
                text: playlist_lista.current
                placeholderText: i18n.tr("Edit playlist name")
                inputMethodHints: Qt.ImhNoPredictiveText
                onVisibleChanged: {
                    if (visible) {
                        forceActiveFocus()
                        selectAll()
                    }
                }
            }
            Button {
                text: i18n.tr("Save")
                color: LomiriColors.green
                onClicked: {
                    Db.updatePlaylist(playlist_lista.currentId, txt_name.text)
                    refreshLibrary()
                    PopupUtils.close(edit_playlist)
                }
            }
            Button {
                text: i18n.tr("Cancel")
                color: LomiriColors.darkGrey
                onClicked: PopupUtils.close(edit_playlist)
            }
        }
    }

    Component {
        id: delplaylist
        Dialog {
            id: delete_playlist
            title: i18n.tr("Delete playlist")
            text: i18n.tr("This cannot be undone")
            Button {
                text: i18n.tr("Delete")
                color: LomiriColors.red
                onClicked: {
                    Db.removePlaylist(playlist_lista.currentId)
                    refreshLibrary()
                    PopupUtils.close(delete_playlist)
                }
            }
            Button {
                text: i18n.tr("Cancel")
                color: LomiriColors.darkGrey
                onClicked: PopupUtils.close(delete_playlist)
            }
        }
    }

    Rectangle {
        color: pageColor
        anchors {
            top: libraryPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: media_player.playbackState != 0 ? units.gu(7.25) : 0
        }

        Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: sections.implicitHeight + pagePadding * 2
            clip: true

            Column {
                id: sections
                width: parent.width - pagePadding * 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: pagePadding
                spacing: units.gu(1.2)

                Rectangle {
                    width: parent.width
                    height: units.gu(10)
                    radius: radiusMedium
                    color: cardColor
                    border.color: borderColor
                    border.width: 1
                    Row {
                        anchors.fill: parent
                        anchors.margins: units.gu(1.6)
                        spacing: units.gu(1.4)
                        Icon {
                            width: units.gu(3.2)
                            height: units.gu(3.2)
                            name: "like"
                            color: accentColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: units.gu(0.2)
                            Label {
                                text: i18n.tr("Favorites")
                                color: textColor
                                font.weight: Font.DemiBold
                            }
                            Label {
                                text: i18n.tr("%1 songs").arg(favoritesCount)
                                color: secondaryTextColor
                                fontSize: "small"
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            favorites_query.text = ""
                            favorites_page.clearQuery()
                            favorites_page.refreshData()
                            pagestack.push(favoritesPage)
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: units.gu(10)
                    radius: radiusMedium
                    color: cardColor
                    border.color: borderColor
                    border.width: 1
                    Row {
                        anchors.fill: parent
                        anchors.margins: units.gu(1.6)
                        spacing: units.gu(1.4)
                        Icon {
                            width: units.gu(3.2)
                            height: units.gu(3.2)
                            name: "history"
                            color: accentColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: units.gu(0.2)
                            Label {
                                text: i18n.tr("Recently Played")
                                color: textColor
                                font.weight: Font.DemiBold
                            }
                            Label {
                                text: i18n.tr("%1 songs").arg(recentCount)
                                color: secondaryTextColor
                                fontSize: "small"
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            recent_query.text = ""
                            recent_page.clearQuery()
                            recent_page.refreshData()
                            pagestack.push(recentPage)
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    radius: radiusMedium
                    color: cardColor
                    border.color: borderColor
                    border.width: 1
                    height: Math.max(units.gu(12), units.gu(6) + modelo_playlists.count * units.gu(7))
                    clip: true
                    Column {
                        anchors.fill: parent
                        Rectangle {
                            width: parent.width
                            height: units.gu(6)
                            color: "transparent"
                            Label {
                                text: i18n.tr("Playlists")
                                anchors.left: parent.left
                                anchors.leftMargin: units.gu(2)
                                anchors.verticalCenter: parent.verticalCenter
                                color: textColor
                                font.weight: Font.DemiBold
                            }
                        }
                        ListView {
                            id: playlist_lista
                            property int currentId: 0
                            property string current: ""
                            width: parent.width
                            height: parent.height - units.gu(6)
                            model: modelo_playlists
                            clip: true
                            delegate: ListItem {
                                contentItem.anchors.leftMargin: units.gu(2)
                                contentItem.anchors.rightMargin: units.gu(2)
                                leadingActions: ListItemActions {
                                    actions: [
                                        Action {
                                            iconName: "delete"
                                            onTriggered: {
                                                playlist_lista.currentId = playlistId
                                                PopupUtils.open(delplaylist)
                                            }
                                        }
                                    ]
                                }
                                trailingActions: ListItemActions {
                                    actions: [
                                        Action {
                                            iconName: "edit"
                                            onTriggered: {
                                                playlist_lista.current = playlistName
                                                playlist_lista.currentId = playlistId
                                                PopupUtils.open(editplaylist)
                                            }
                                        }
                                    ]
                                }
                                Label {
                                    text: playlistName
                                    color: textColor
                                    anchors.left: parent.left
                                    elide: Text.ElideRight
                                }
                                Label {
                                    text: i18n.tr("%1 song", "%1 songs", playlistCount).arg(playlistCount)
                                    color: secondaryTextColor
                                    fontSize: "small"
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                }
                                onClicked: {
                                    playlistDetailPage.title = playlistName
                                    playlistDetailPage.header.title = playlistName
                                    playlist_detail_page.cargar(playlistId)
                                    playlist_detail_page.setStatus(isOffline)
                                    pagestack.push(playlistDetailPage)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
