import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import "../components"
import "../logic/Api.js" as Api

Page {
    id: topArtistsPage

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
        Api.getTopArtists(limit)
    }

    ListModel {
        id: artistsModel
        Component.onCompleted: {
            getTopArtists(100)
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

    GridView {
        id: artistsView
        anchors {
            margins: 0
            top: topArtistsPage.header.bottom
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
        cellHeight: cellWidth + units.gu(4)
        model: artistsModel
        cacheBuffer: 10

        delegate: MouseArea {
            width: artistsView.cellWidth
            height: artistsView.cellHeight
            Column {
                id: delegateitem
                anchors.fill: parent
                Image {
                    id: wimage
                    width: parent.width
                    height: parent.height - units.gu(4)
                    source: image
                    clip: true
                    cache: true
                    fillMode: Image.PreserveAspectCrop
                    //smooth: true
                }
                Rectangle{
                    color: "#333"
                    width: artistsView.cellWidth
                    height: units.gu(4)
                    Label {
                        text: name
                        width: artistsView.cellWidth
                        anchors.margins: units.gu(2)
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        fontSize: "medium"
                        color: "#fff"
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
