import QtQuick 2.12
import QtMultimedia 5.0
import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.0 as UListItem
import QtGraphicalEffects 1.0
import "../ui"

Rectangle {
    id: playerToolbar
    property color accentColor: cloudMusic.primaryColor
    property color textColor: cloudMusic.textColor
    property color secondaryTextColor: cloudMusic.secondaryTextColor
    visible: media_player.queue > 0 && !playingPage.visible && !aboutLoader.visible && !settingsLoader.visible ? true : false
    anchors {
        bottom: parent.bottom
        left: parent.left
        right: parent.right
    }
    color: "transparent"
    height: units.gu(7.25)

    function cargar(name, artist, image){
        coverArt.source = image
        lbl_toolbar_name.text = name
        lbl_toolbar_artist.text = artist
    }

    Image {
        id: coverArt
        anchors.left: parent.left
        height: parent.height
        fillMode: Image.PreserveAspectFit
    }

    Column {
        anchors {
            margins: units.gu(2)
            left: coverArt.right
            right: playerControl.left
            verticalCenter: parent.verticalCenter
        }

        Label {
            id: lbl_toolbar_name
            width: parent.width
            elide: Text.ElideRight
            font.weight: Font.DemiBold
            color: textColor
        }

        Label {
            id: lbl_toolbar_artist
            width: parent.width
            elide: Text.ElideRight
            fontSize: "small"
            color: secondaryTextColor
            opacity: 0.9
        }
    }

    Rectangle {
        id: playerControl
        z: 2
        anchors.right: parent.right
        anchors.rightMargin: units.gu(1)
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        border.color: accentColor
        border.width: 1
        width: units.gu(5)
        height: units.gu(5)
        radius: units.gu(2.5)

        Icon {
            width: units.gu(3)
            height: units.gu(3)
            name: media_player.playbackState === 1 ? "media-playback-pause" : "media-playback-start"
            color: accentColor
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            onClicked: media_player.togle()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            playingPage.title = lbl_toolbar_name.text
            pagestack.push(playingPage);
        }
    }
    /* Object which provides the progress bar when toolbar is minimized */
    Column {
        anchors {
            bottom: parent.top
            left: parent.left
            right: parent.right
        }
        height: units.gu(0.1)

        UListItem.ThinDivider {
            id: divider
        }

        Rectangle {
           id: progreso
           width: parent.width
           height: parent.height
           color: "transparent"

           Rectangle {
               id: progresoHint
               color: accentColor
               height: parent.height
               width: media_player.duration > 0 ? (media_player.position / media_player.duration) * progreso.width : 0

               Connections {
                   target: media_player
                   onPositionChanged: {
                       progresoHint.width = (media_player.position / media_player.duration) * progreso.width
                   }
                   onStopped: {
                       progresoHint.width = 0;
                   }
               }
           }
        }

        /*DropShadow {
            width: parent.width
            height: parent.height
            horizontalOffset: 0
            verticalOffset: -1
            radius: 4
            samples: 17
            source: divider
        }*/
    }
}
