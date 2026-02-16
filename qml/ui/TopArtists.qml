import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtGraphicalEffects 1.0
import "../components"
import "../logic/Api.js" as Api

Page {
    id: topArtistsPage
    property var appRoot
    property bool isDarkTheme: appRoot ? appRoot.isDarkTheme : false
    property color primaryTextColor: isDarkTheme ? "#f2f2f2" : "#1f1f1f"
    property color tileColor: isDarkTheme ? "#252525" : "#ffffff"
    property color tileBorderColor: isDarkTheme ? "#3a3a3a" : "#dcdcdc"

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
        cellWidth: (appRoot && appRoot.width > units.gu(25)) ? (parent.width / Math.ceil(parent.width / units.gu(25))) : parent.width
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
                    margins: units.gu(1)
                }

                border.color: tileBorderColor
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
                    spacing: units.gu(1)

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
