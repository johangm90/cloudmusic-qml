import QtQuick 2.12
import QtMultimedia 5.0
import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.0 as UListItem
import QtGraphicalEffects 1.0
import "../logic/Format.js" as Format
import "../ui"

Rectangle {
    id: playerToolbar
    property color accentColor: cloudMusic.primaryColor
    property color textColor: cloudMusic.textColor
    property color secondaryTextColor: cloudMusic.secondaryTextColor
    property color borderColor: cloudMusic ? cloudMusic.borderColor : "#d8d8d8"
    property real spacingMedium: cloudMusic ? cloudMusic.spacingMedium : units.gu(1.2)
    property real spacingSmall: cloudMusic ? cloudMusic.spacingSmall : units.gu(0.8)
    property real sideInset: spacingSmall + units.gu(0.2)
    property real controlSize: units.gu(5)
    property real controlIconSize: units.gu(3)
    property real controlRadius: controlSize / 2
    property real progressHeight: units.gu(0.1)
    property string bodySmallTextSize: cloudMusic && cloudMusic.designTokens ? cloudMusic.designTokens.typography.bodySmall : "small"
    // Expanded windows get a real persistent player bar (metadata, transport,
    // seek, volume) instead of the compact tap-to-expand strip -- there's
    // finally enough width to fit playback controls without covering browsing.
    property bool expandedMode: cloudMusic ? cloudMusic.isExpanded : false
    visible: media_player.queue > 0 && !playingPage.visible && !aboutLoader.visible && !settingsLoader.visible ? true : false
    anchors {
        bottom: cloudMusic && cloudMusic.showBottomNav ? bottomNav.top : parent.bottom
        left: parent.left
        right: parent.right
        leftMargin: cloudMusic ? cloudMusic.navInset : 0
    }
    color: "transparent"
    height: cloudMusic && cloudMusic.layoutPlayerInset ? cloudMusic.layoutPlayerInset : units.gu(7.25)

    function cargar(name, artist, image){
        coverArt.source = image
        lbl_toolbar_name.text = name
        lbl_toolbar_artist.text = artist
        expandedCover.source = image
        expandedTitle.text = name
        expandedArtist.text = artist
    }

    /* Compact strip (phone / tablet): whole bar is a tap target that opens Now Playing */
    Item {
        id: compactRow
        anchors.fill: parent
        visible: !expandedMode

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
    }

    /* Hairline progress indicator above the compact strip only -- the expanded
       bar has its own inline seek control instead. */
    Column {
        anchors {
            bottom: parent.top
            left: parent.left
            right: parent.right
        }
        height: progressHeight
        visible: !expandedMode

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
    }

    /* Persistent desktop bar: metadata | transport + seek | volume. Browsing
       stays visible behind/around it -- this never takes over the window. */
    Item {
        id: expandedRow
        anchors.fill: parent
        anchors.margins: sideInset
        visible: expandedMode

        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            anchors.topMargin: -sideInset
            height: 1
            color: playerToolbar.borderColor
        }

        Item {
            id: metaBlock
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: units.gu(24)
            height: parent.height

            Image {
                id: expandedCover
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.height
                height: width
                fillMode: Image.PreserveAspectCrop
            }

            Column {
                anchors.left: expandedCover.right
                anchors.leftMargin: spacingSmall
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: units.gu(0.1)

                Label {
                    id: expandedTitle
                    width: parent.width
                    elide: Text.ElideRight
                    font.weight: Font.DemiBold
                    color: textColor
                }

                Label {
                    id: expandedArtist
                    width: parent.width
                    elide: Text.ElideRight
                    fontSize: bodySmallTextSize
                    color: secondaryTextColor
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    playingPage.title = expandedTitle.text
                    pagestack.push(playingPage)
                }
            }
        }

        Column {
            id: transportBlock
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: units.gu(0.4)
            width: Math.min(units.gu(50), parent.width - metaBlock.width - volumeBlock.width - spacingMedium * 2)

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                height: units.gu(4)
                spacing: units.gu(3)

                Item {
                    width: units.gu(2.4)
                    height: parent.height

                    Icon {
                        anchors.centerIn: parent
                        width: units.gu(2.4)
                        height: width
                        name: "media-skip-backward"
                        color: accentColor
                        opacity: media_player.queue > 1 ? 1 : 0.4
                    }

                    MouseArea { anchors.fill: parent; onClicked: media_player.previous() }
                }

                Rectangle {
                    width: units.gu(4)
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.color: accentColor
                    border.width: 1

                    Icon {
                        anchors.centerIn: parent
                        width: units.gu(2.2)
                        height: width
                        name: media_player.playbackState === 1 ? "media-playback-pause" : "media-playback-start"
                        color: accentColor
                    }

                    MouseArea { anchors.fill: parent; onClicked: media_player.toggle() }
                }

                Item {
                    width: units.gu(2.4)
                    height: parent.height

                    Icon {
                        anchors.centerIn: parent
                        width: units.gu(2.4)
                        height: width
                        name: "media-skip-forward"
                        color: accentColor
                        opacity: media_player.queue > 1 ? 1 : 0.4
                    }

                    MouseArea { anchors.fill: parent; onClicked: media_player.next() }
                }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: units.gu(3)

                Label {
                    id: elapsedLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Format.durationToString(media_player.position)
                    fontSize: playerToolbar.bodySmallTextSize
                    color: secondaryTextColor
                }

                Label {
                    id: totalLabel
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Format.durationToString(media_player.duration)
                    fontSize: playerToolbar.bodySmallTextSize
                    color: secondaryTextColor
                }

                Slider {
                    id: expandedSeek
                    anchors.left: elapsedLabel.right
                    anchors.leftMargin: units.gu(1)
                    anchors.right: totalLabel.left
                    anchors.rightMargin: units.gu(1)
                    anchors.verticalCenter: parent.verticalCenter
                    minimumValue: 0
                    maximumValue: media_player.duration > 0 ? media_player.duration : 1
                    value: media_player.position
                    live: true
                    StyleHints { foregroundColor: accentColor }
                    onPressedChanged: media_player.seek(expandedSeek.value)
                }
            }
        }

        Item {
            id: volumeBlock
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: units.gu(10)
            height: units.gu(3)

            Icon {
                id: volumeIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: units.gu(2.2)
                height: width
                name: media_player.volume <= 0 ? "audio-volume-mute" : "audio-volume-high"
                color: secondaryTextColor
            }

            Slider {
                anchors.left: volumeIcon.right
                anchors.leftMargin: spacingSmall
                anchors.verticalCenter: parent.verticalCenter
                width: units.gu(7)
                minimumValue: 0
                maximumValue: 1
                value: media_player.volume
                live: true
                StyleHints { foregroundColor: accentColor }
                onValueChanged: media_player.volume = value
            }
        }
    }
}
