import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtGraphicalEffects 1.0
import "../components"

Page {
    id: topArtistsPage
    property var appRoot
    property color pageColor: appRoot ? appRoot.pageColor : "#f5f5f5"
    property color primaryTextColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color tileColor: appRoot ? appRoot.tileColor : "#ffffff"
    property color tileBorderColor: appRoot ? appRoot.tileBorderColor : "#dcdcdc"
    property real pagePadding: appRoot ? appRoot.pagePadding : units.gu(1.2)
    property real radiusMedium: appRoot ? appRoot.radiusMedium : units.gu(1.2)
    property real spacingSmall: appRoot ? appRoot.spacingSmall : units.gu(0.8)
    property real gridBreakpoint: units.gu(25)
    property real tileCaptionHeight: units.gu(4)
    property string bodyTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.body : "medium"
    property int requestSeq: 0
    property string activeRequestId: ""
    property bool initialLoadDone: false

    TabsList {
        id: tabsList
    }

    header: PageHeader {
        title: i18n.tr("Top Artists")
        leadingActionBar {
            numberOfSlots: 0
            actions: tabsList.actions
        }
    }

    function getTopArtists(limit) {
        if (!appRoot || !appRoot.cloudApi) {
            top_artists_error.visible = true
            return
        }
        top_artists_error.visible = false
        artistsModel.clear()
        top_artists_loader.running = true
        requestSeq += 1
        activeRequestId = "top_artists_" + requestSeq
        appRoot.cloudApi.getTopArtistsAsync(Number(limit), activeRequestId)
    }

    function ensureInitialLoad() {
        if (initialLoadDone) {
            return
        }
        if (!appRoot || !appRoot.cloudApi) {
            return
        }
        initialLoadDone = true
        getTopArtists(50)
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
            top_artists_loader.running = false
            if (!ok) {
                console.log(error)
                top_artists_error.visible = true
                return
            }
            try {
                var data = JSON.parse(payloadJson)
                if (!data || !data.artists) {
                    top_artists_error.visible = true
                    return
                }
                for (var i = 0; i < data.artists.length; i++) {
                    var artist = data.artists[i]
                    artistsModel.append({
                        id: artist.id,
                        name: artist.name,
                        image: artist.image ? artist.image : "../graphics/default.png",
                        big_image: artist.big_image ? artist.big_image : "../graphics/default.png",
                        source: "netease"
                    })
                }
            } catch (e) {
                console.log(e)
                top_artists_error.visible = true
            }
        }
    }

    ListModel {
        id: artistsModel
    }

    MouseArea {
        id: top_artists_error
        z: 2
        visible: false
        anchors {
            top: topArtistsPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        onClicked: getTopArtists(50)
        Label {
            text: i18n.tr("An error occurred\nTouch to retry")
            horizontalAlignment: Label.AlignHCenter
            anchors.centerIn: parent
        }
    }

    ActivityIndicator {
        id: top_artists_loader
        anchors.centerIn: parent
    }

    Rectangle {
        color: pageColor
        anchors {
            top: topArtistsPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: media_player.playbackState != 0 ? (appRoot && appRoot.layoutPlayerInset ? appRoot.layoutPlayerInset : units.gu(7.25)) : 0
        }

        GridView {
            id: artistsView
            anchors {
                fill: parent
                margins: pagePadding
            }
            clip: true
            z: 1
            width: parent.width
            height: parent.height
            cellWidth: (appRoot && appRoot.width > gridBreakpoint) ? (width / Math.ceil(width / gridBreakpoint)) : width
            cellHeight: cellWidth + tileCaptionHeight
            model: artistsModel
            cacheBuffer: 50

            delegate: MouseArea {
                width: artistsView.cellWidth
                height: artistsView.cellHeight

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
                        spacing: spacingSmall + units.gu(0.2)

                        Image {
                            id: wimage
                            width: parent.width
                            height: parent.height - tileCaptionHeight
                            source: image
                            clip: true
                            cache: true
                            fillMode: Image.PreserveAspectCrop
                        }

                        Label {
                            text: name
                            width: parent.width
                            horizontalAlignment: Label.AlignHCenter
                            verticalAlignment: Label.AlignBottom
                            elide: Text.ElideRight
                            fontSize: bodyTextSize
                            color: primaryTextColor
                        }
                    }
                }

                onClicked: {
                    artist_page.cargar(id);
                    pagestack.push(artistPage);
                }
            }
        }
    }
}
