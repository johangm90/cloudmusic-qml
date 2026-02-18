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
    property real spacingMedium: cloudMusic ? cloudMusic.spacingMedium : units.gu(1.2)
    property real spacingSmall: cloudMusic ? cloudMusic.spacingSmall : units.gu(0.8)
    property real sideInset: spacingSmall + units.gu(0.2)
    property real controlSize: units.gu(5)
    property real controlIconSize: units.gu(3)
    property real controlRadius: controlSize / 2
    property real progressHeight: units.gu(0.1)
    property string bodySmallTextSize: cloudMusic && cloudMusic.designTokens ? cloudMusic.designTokens.typography.bodySmall : "small"
    visible: media_player.queue > 0 && !playingPage.visible && !aboutLoader.visible && !settingsLoader.visible ? true : false
    anchors {
        bottom: parent.bottom
        left: parent.left
        right: parent.right
    }
    color: "transparent"
    height: cloudMusic && cloudMusic.layoutPlayerInset ? cloudMusic.layoutPlayerInset : units.gu(7.25)

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
            margins: spacingMedium + spacingSmall
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
            fontSize: bodySmallTextSize
            color: secondaryTextColor
            opacity: 0.9
        }
    }

    Rectangle {
        id: playerControl
        z: 2
        anchors.right: parent.right
        anchors.rightMargin: sideInset
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        border.color: accentColor
        border.width: 1
        width: controlSize
        height: controlSize
        radius: controlRadius

        Icon {
            width: controlIconSize
            height: controlIconSize
            name: media_player.playbackState === 1 ? "media-playback-pause" : "media-playback-start"
            color: accentColor
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            onClicked: media_player.toggle()
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
        height: progressHeight

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
