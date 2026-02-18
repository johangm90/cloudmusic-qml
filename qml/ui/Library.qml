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
    property real spacingSmall: appRoot ? appRoot.spacingSmall : units.gu(0.8)
    property real spacingMedium: appRoot ? appRoot.spacingMedium : units.gu(1.2)
    property real layoutPlayerInset: appRoot ? appRoot.layoutPlayerInset : units.gu(7.25)
    property real cardHeight: units.gu(10)
    property real iconSize: units.gu(3.2)
    property real compactSpacing: units.gu(0.2)
    property real playlistsHeaderHeight: units.gu(6)
    property real playlistRowHeight: units.gu(7.6)
    property real playlistRowHorizontalPadding: spacingMedium + spacingSmall
    property real playlistRowVerticalPadding: 0
    property real playlistRowTextGap: compactSpacing
    property real playlistChevronSize: units.gu(2.2)
    property string smallTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.bodySmall : "small"
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
            bottomMargin: media_player.playbackState != 0 ? layoutPlayerInset : 0
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
                spacing: spacingMedium

                Rectangle {
                    width: parent.width
                    height: cardHeight
                    radius: radiusMedium
                    color: cardColor
                    border.color: borderColor
                    border.width: 1
                    Row {
                        anchors.fill: parent
                        anchors.margins: spacingMedium + (spacingSmall / 2)
                        spacing: spacingMedium + compactSpacing
                        Icon {
                            width: iconSize
                            height: iconSize
                            name: "like"
                            color: accentColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: compactSpacing
                            Label {
                                text: i18n.tr("Favorites")
                                color: textColor
                                font.weight: Font.DemiBold
                            }
                            Label {
                                text: i18n.tr("%1 songs").arg(favoritesCount)
                                color: secondaryTextColor
                                fontSize: smallTextSize
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
                    height: cardHeight
                    radius: radiusMedium
                    color: cardColor
                    border.color: borderColor
                    border.width: 1
                    Row {
                        anchors.fill: parent
                        anchors.margins: spacingMedium + (spacingSmall / 2)
                        spacing: spacingMedium + compactSpacing
                        Icon {
                            width: iconSize
                            height: iconSize
                            name: "history"
                            color: accentColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: compactSpacing
                            Label {
                                text: i18n.tr("Recently Played")
                                color: textColor
                                font.weight: Font.DemiBold
                            }
                            Label {
                                text: i18n.tr("%1 songs").arg(recentCount)
                                color: secondaryTextColor
                                fontSize: smallTextSize
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
                    height: Math.max(units.gu(12), playlistsHeaderHeight + modelo_playlists.count * playlistRowHeight)
                    clip: true
                    Column {
                        anchors.fill: parent
                        Rectangle {
                            width: parent.width
                            height: playlistsHeaderHeight
                            color: "transparent"
                            Label {
                                text: i18n.tr("Playlists")
                                anchors.left: parent.left
                                anchors.leftMargin: spacingMedium + spacingSmall
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
                            height: parent.height - playlistsHeaderHeight
                            model: modelo_playlists
                            clip: true
                            delegate: ListItem {
                                id: playlistRow
                                contentItem.anchors.leftMargin: playlistRowHorizontalPadding
                                contentItem.anchors.rightMargin: playlistRowHorizontalPadding
                                contentItem.anchors.topMargin: playlistRowVerticalPadding
                                contentItem.anchors.bottomMargin: playlistRowVerticalPadding
                                color: pressed ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.14) : "transparent"
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

                                Icon {
                                    id: playlistChevron
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: playlistChevronSize
                                    height: width
                                    name: "go-next"
                                    color: secondaryTextColor
                                }

                                Column {
                                    anchors.left: parent.left
                                    anchors.right: playlistChevron.left
                                    anchors.rightMargin: spacingSmall
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: playlistRowTextGap

                                    Label {
                                        text: playlistName
                                        color: textColor
                                        elide: Text.ElideRight
                                        width: parent.width
                                        font.weight: Font.DemiBold
                                    }

                                    Label {
                                        text: i18n.tr("%1 song", "%1 songs", playlistCount).arg(playlistCount)
                                        color: secondaryTextColor
                                        fontSize: smallTextSize
                                        width: parent.width
                                        elide: Text.ElideRight
                                    }
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
