import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtGraphicalEffects 1.0
import "../components"
import "../logic/Api.js" as Api
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
        Api.getNewAlbums(limit, {
            model: newAlbumsModel,
            loader: new_albums_loader,
            errorItem: new_albums_error
        })
    }

    ListModel {
        id: newAlbumsModel
        Component.onCompleted: {
            getNewAlbums(50)
        }
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
            bottomMargin: media_player.playbackState != 0 ? units.gu(7.25) : 0
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
            cellWidth: (appRoot && appRoot.width > units.gu(25)) ? (width / Math.ceil(width / units.gu(25))) : width
            cellHeight: cellWidth + units.gu(8)
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
                            height: parent.height - units.gu(8)
                            source: CoverCache.resolve(id, image, "../graphics/default.png")
                            clip: true
                            cache: true
                            fillMode: Image.PreserveAspectCrop
                        }

                        Label {
                            text: name
                            width: parent.width
                            height: units.gu(4)
                            horizontalAlignment: Label.AlignHCenter
                            verticalAlignment: Label.AlignBottom
                            elide: Label.ElideRight
                            fontSize: "medium"
                            color: primaryTextColor
                        }


                        Label {
                            text: artist
                            width: parent.width
                            height: units.gu(4)
                            horizontalAlignment: Label.AlignHCenter
                            verticalAlignment: Label.AlignTop
                            elide: Label.ElideRight
                            fontSize: "small"
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
