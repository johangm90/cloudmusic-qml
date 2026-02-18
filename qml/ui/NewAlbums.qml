import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtGraphicalEffects 1.0
import "../components"
import "../logic/CoverCache.js" as CoverCache

Page {
    id: newAlbumsPage
    property var appRoot
    property color pageColor: appRoot ? appRoot.pageColor : "#f5f5f5"
    property color primaryTextColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color secondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#6a6a6a"
    property color tileColor: appRoot ? appRoot.tileColor : "#ffffff"
    property color tileBorderColor: appRoot ? appRoot.tileBorderColor : "#dcdcdc"
    property real pagePadding: appRoot ? appRoot.pagePadding : units.gu(1.2)
    property real radiusMedium: appRoot ? appRoot.radiusMedium : units.gu(1.2)
    property real spacingSmall: appRoot ? appRoot.spacingSmall : units.gu(0.8)
    property real gridBreakpoint: units.gu(25)
    property real albumMetaHeight: units.gu(8)
    property real albumTitleHeight: units.gu(4)
    property string bodyTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.body : "medium"
    property string bodySmallTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.bodySmall : "small"
    property int requestSeq: 0
    property string activeRequestId: ""
    property bool initialLoadDone: false

    TabsList {
        id: tabsList
    }

    header: PageHeader {
        title: i18n.tr("New Albums")
        leadingActionBar {
            numberOfSlots: 0
            actions: tabsList.actions
        }
    }

    function getNewAlbums(limit) {
        if (!appRoot || !appRoot.cloudApi) {
            new_albums_error.visible = true
            return
        }
        new_albums_error.visible = false
        newAlbumsModel.clear()
        new_albums_loader.running = true
        requestSeq += 1
        activeRequestId = "new_albums_" + requestSeq
        appRoot.cloudApi.getNewAlbumsAsync(Number(limit), activeRequestId)
    }

    function ensureInitialLoad() {
        if (initialLoadDone) {
            return
        }
        if (!appRoot || !appRoot.cloudApi) {
            return
        }
        initialLoadDone = true
        getNewAlbums(50)
    }

    onAppRootChanged: ensureInitialLoad()

    Component.onCompleted: {
        Qt.callLater(ensureInitialLoad)
    }

    Connections {
        target: appRoot && appRoot.cloudApi ? appRoot.cloudApi : null
        onRequestFinished: function(requestId, ok, payloadJson, error) {
            if (String(requestId) !== activeRequestId) {
                return
            }
            new_albums_loader.running = false
            if (!ok) {
                console.log(error)
                new_albums_error.visible = true
                return
            }
            try {
                var data = JSON.parse(payloadJson)
                if (!data || !data.albums) {
                    new_albums_error.visible = true
                    return
                }
                for (var i = 0; i < data.albums.length; i++) {
                    var album = data.albums[i]
                    var date = new Date(album.publish_time ? album.publish_time : 0)
                    var releaseDate = date.getFullYear() + "-" + ((date.getMonth() + 1 < 10) ? ("0" + (date.getMonth() + 1)) : (date.getMonth() + 1)) + "-" + ((date.getDate() < 10) ? ("0" + date.getDate()) : date.getDate())
                    newAlbumsModel.append({
                        id: album.id,
                        name: album.name,
                        artist: album.artist,
                        date: releaseDate,
                        image: album.image ? album.image : "../graphics/default.png",
                        big_image: album.big_image ? album.big_image : "../graphics/default.png",
                        source: "netease"
                    })
                }
            } catch (e) {
                console.log(e)
                new_albums_error.visible = true
            }
        }
    }

    ListModel {
        id: newAlbumsModel
    }

    MouseArea {
        id: new_albums_error
        z: 2
        visible: false
        anchors {
            top: newAlbumsPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        onClicked: getNewAlbums(50)
        Label {
            text: i18n.tr("An error occurred\nTouch to retry")
            horizontalAlignment: Label.AlignHCenter
            anchors.centerIn: parent
        }
    }

    ActivityIndicator {
        id: new_albums_loader
        anchors.centerIn: parent
    }

    Rectangle {
        color: pageColor
        anchors {
            top: newAlbumsPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: media_player.playbackState != 0 ? (appRoot && appRoot.layoutPlayerInset ? appRoot.layoutPlayerInset : units.gu(7.25)) : 0
        }

        GridView {
            id: newAlbumsView
            anchors {
                fill: parent
                margins: pagePadding
            }
            clip: true
            z: 1
            width: parent.width
            height: parent.height
            cellWidth: (appRoot && appRoot.width > gridBreakpoint) ? (width / Math.ceil(width / gridBreakpoint)) : width
            cellHeight: cellWidth + albumMetaHeight
            model: newAlbumsModel
            cacheBuffer: 50
            interactive: true

            delegate: MouseArea {
                width: newAlbumsView.cellWidth
                height: newAlbumsView.cellHeight

                Rectangle {
                    id: item
                    color: tileColor

                    anchors {
                        fill: parent
                        margins: spacingSmall / 2
                    }

                    border.color: tileBorderColor
                    border.width: 1
                    radius: radiusMedium

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            x: item.x; y: item.y
                            width: item.width
                            height: item.height
                            radius: item.radius
                        }
                    }

                    Column {
                        anchors {
                            fill: parent
                            margins: 1
                        }

                        Image {
                            id: wimage
                            width: parent.width
                            height: parent.height - albumMetaHeight
                            source: CoverCache.resolve(id, image, "../graphics/default.png")
                            clip: true
                            cache: true
                            fillMode: Image.PreserveAspectCrop
                        }

                        Label {
                            text: name
                            width: parent.width
                            height: albumTitleHeight
                            horizontalAlignment: Label.AlignHCenter
                            verticalAlignment: Label.AlignBottom
                            elide: Label.ElideRight
                            fontSize: bodyTextSize
                            color: primaryTextColor
                        }


                        Label {
                            text: artist
                            width: parent.width
                            height: albumTitleHeight
                            horizontalAlignment: Label.AlignHCenter
                            verticalAlignment: Label.AlignTop
                            elide: Label.ElideRight
                            fontSize: bodySmallTextSize
                            color: secondaryTextColor
                        }
                    }
                }

                onClicked: {
                    album_page.cargar(id);
                    pagestack.push(albumPage);
                }
            }
        }
    }
}
