import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
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
            getNewAlbums(100)
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
        cellWidth: cloudMusic.width > units.gu(25) ? (parent.width/Math.ceil(parent.width/units.gu(25))) : (parent.width)
        cellHeight: cellWidth + units.gu(8)
        model: newAlbumsModel
        cacheBuffer: 50

        delegate: MouseArea {
            width: newAlbumsView.cellWidth
            height: newAlbumsView.cellHeight
            Column {
                id: delegateitem
                anchors.fill: parent
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
                Rectangle{
                    color: "#333"
                    width: newAlbumsView.cellWidth
                    height: units.gu(4)
                    Label {
                        text: name
                        width: newAlbumsView.cellWidth
                        height: units.gu(4)
                        horizontalAlignment: Label.AlignHCenter
                        verticalAlignment: Label.AlignBottom
                        elide: Label.ElideRight
                        fontSize: "medium"
                        color: "#fff"
                    }
                }
                Rectangle{
                    color: "#333"
                    width: newAlbumsView.cellWidth
                    height: units.gu(4)
                    Label {
                        text: artist
                        width: newAlbumsView.cellWidth
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
