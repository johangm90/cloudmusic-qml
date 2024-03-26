import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtGraphicalEffects 1.0
import "../components"
import "../logic/Api.js" as Api

Page {
    id: newAlbumsPage

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
        Api.getNewAlbums(limit)
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

    GridView {
        id: newAlbumsView
        anchors {
            margins: 0
            top: newAlbumsPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: media_player.playbackState != 0 ? units.gu(7.25) : 0
        }
        clip: true
        z: 1
        width: parent.width
        height: parent.height
        cellWidth: cloudMusic.width > units.gu(25) ? (parent.width / Math.ceil(parent.width / units.gu(25))) : (parent.width)
        cellHeight: cellWidth + units.gu(8)
        model: newAlbumsModel
        cacheBuffer: 50

        delegate: MouseArea {
            width: newAlbumsView.cellWidth
            height: newAlbumsView.cellHeight

            Rectangle {
                id: item
                color: "transparent"

                anchors {
                    fill: parent
                    margins: units.gu(1)
                }

                border.color: cloudMusic.settings.theme == "Ambiance" ? Qt.rgba(0,0,0,0.2) : Qt.rgba(250,250,250,0.2)
                border.width: 1
                radius: units.gu(1.5)

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
                        source: image
                        clip: true
                        cache: true
                        fillMode: Image.PreserveAspectCrop
                        //smooth: true
                    }

                    Label {
                        text: name
                        width: parent.width
                        height: units.gu(4)
                        horizontalAlignment: Label.AlignHCenter
                        verticalAlignment: Label.AlignBottom
                        elide: Label.ElideRight
                        fontSize: "medium"
                    }


                    Label {
                        text: artist
                        width: parent.width
                        height: units.gu(4)
                        horizontalAlignment: Label.AlignHCenter
                        verticalAlignment: Label.AlignTop
                        elide: Label.ElideRight
                        fontSize: "small"
                        color: "#898B8C"
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
