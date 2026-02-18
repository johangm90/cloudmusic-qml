import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtGraphicalEffects 1.0
import "../components"
import "../logic/Api.js" as Api

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
        Api.getTopArtists(limit, {
            model: artistsModel,
            loader: top_artists_loader,
            errorItem: top_artists_error
        })
    }

    ListModel {
        id: artistsModel
        Component.onCompleted: {
            getTopArtists(50)
        }
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
            bottomMargin: media_player.playbackState != 0 ? units.gu(7.25) : 0
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
            cellWidth: (appRoot && appRoot.width > units.gu(25)) ? (width / Math.ceil(width / units.gu(25))) : width
            cellHeight: cellWidth + units.gu(4)
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
                        spacing: units.gu(1)

                        Image {
                            id: wimage
                            width: parent.width
                            height: parent.height - units.gu(4)
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
                            fontSize: "medium"
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
