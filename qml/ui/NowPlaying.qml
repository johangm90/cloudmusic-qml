import QtQuick 2.4
import Ubuntu.Components 1.3
import QtGraphicalEffects 1.0
import QtMultimedia 5.6
import Ubuntu.DownloadManager 1.2
import Ubuntu.Content 1.1
import Qt.labs.settings 1.0
import Ubuntu.Layouts 1.0
import "../components"
import "../graphics"
import "../themes"
import "../logic/Api.js" as Api
import "../logic/Database.js" as Db

Item {
    id: playingContainer

    property var settings: Settings {
        property bool shuffle: false
        property int repeat: 0
        property bool lyrics: true
        onShuffleChanged: {
            media_player.setSuffleMode(settings.shuffle)
        }
        onRepeatChanged: {
            media_player.setRepeatMode(settings.repeat)
        }
        onLyricsChanged: {
            if(lyrics){
                showLyrics()
            }
        }
    }

    property bool activeState: Qt.application.active

    onActiveStateChanged: {
        /*console.log("Estado: " + activeState)
        console.log("Current index: " + current_index)
        console.log("Playlist index: " + media_player.getIndex())
        console.log("Song id by playlist: " + songs_list[media_player.getIndex()])
        console.log("Song id by porperty: " + current_id)*/
        if(media_player.queue > 1 && (media_player.getIndex() != current_index || songs_list[media_player.getIndex()] != current_id)){
            getSongDetail();
        }
    }

    property int current_index: -1
    property int current_id: -1

    property variant songs_list: []

    function setIndex(index){
        if(index > -1){
            current_index = index
            getSongDetail()
        }
    }

    function getSongDetail(){
        var index = media_player.getIndex()
        console.log("Obteniendo detalle de: " + songs_list[index])
        Api.getSongDetail(songs_list[index]);
    }

    function showLyrics(){
        Api.getLyric(current_id);
    }

    property ListModel model_queue: ListModel {
        id: queue_model
    }

    property ListModel model_lyric: ListModel{
        id: lyric_model
    }

    Layouts {
        id: layouts
        anchors.fill: parent

        layouts: [
            ConditionalLayout {
                name: "column"
                when: layouts.width <= units.gu(50)

                Column {
                    anchors.fill: parent

                    ItemLayout {
                        item: "layout_player"
                        width: parent.width
                        height: parent.height
                    }
                }
            },
            ConditionalLayout {
                name: "small"
                when: layouts.width > units.gu(50) && layouts.width < units.gu(100)

                Column {
                    anchors.fill: parent

                    ItemLayout {
                        item: "layout_player"
                        width: parent.width
                        height: parent.height
                    }
                }
            },
            ConditionalLayout {
                name: "row"
                when: layouts.width >= units.gu(100)

                Row {
                    anchors.fill: parent

                    ItemLayout {
                        item: "layout_player"
                        width: (parent.width/3)*2
                        height: parent.height
                    }

                    /*ItemLayout {
                        item: "layout_queue"
                        width: parent.width/3
                        height: parent.height
                    }*/

                    Rectangle {
                        id: queue_layout
                        color: "transparent"
                        width: parent.width/3
                        height: parent.height

                        Rectangle {
                            id: queue_title
                            color: "#333"
                            width: parent.width
                            height: units.gu(5)
                            Label{
                                anchors.left: parent.left
                                anchors.leftMargin: units.gu(1)
                                anchors.verticalCenter: parent.verticalCenter
                                text: i18n.tr("Queue")
                                fontSize: "large"
                                color: "#fff"
                            }
                        }

                        Rectangle {
                            id: songs_view
                            color: "transparent"
                            anchors.top: queue_title.bottom
                            anchors.bottom: parent.bottom
                            width: parent.width

                            Item {
                                width: parent.width
                                height: parent.height

                                ListView {
                                    id: queue_list
                                    clip: true
                                    model: queue_model
                                    width: parent.width
                                    height: parent.height
                                    boundsBehavior: Flickable.StopAtBounds

                                    delegate: ListItem {
                                        contentItem.anchors {
                                            leftMargin: units.gu(2)
                                            rightMargin: units.gu(2)
                                            topMargin: units.gu(1)
                                            bottomMargin: units.gu(1)
                                        }

                                        color: current_index == index ? "#5d5d5d" : "transparent"

                                        Label {
                                            id: lbl_name
                                            text: name
                                            elide: Label.ElideRight
                                            anchors.left: parent.left
                                            anchors.right: lbl_duration.left
                                        }

                                        Label {
                                            id: lbl_artist
                                            text: artist
                                            fontSize: "small"
                                            color: "#898B8C"
                                            elide: Label.ElideRight
                                            anchors.left: parent.left
                                            anchors.right: lbl_duration.left
                                            anchors.bottom: parent.bottom
                                        }

                                        Label {
                                            id: lbl_duration
                                            text: Api.durationToString(duration)
                                            width: units.gu(5)
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: parent.right
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        onClicked: {
                                            media_player.setIndex(index)
                                        }
                                    }
                                }
                                Scrollbar {
                                    flickableItem: queue_list
                                    align: Qt.AlignTrailing
                                }
                            }
                        }
                    }
                }
            }
        ]

        Rectangle {
            id: player_layout
            Layouts.item: "layout_player"
            width: parent.width
            height: parent.height

            Image {
                id: bg
                source: albumImage.source
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                smooth: true
                z: 1
                onStatusChanged: bg.status == Image.Ready ? overlay.opacity=0.7 : overlay.opacity=1
            }

            FastBlur {
                anchors.fill: bg
                source: bg
                radius: 32
            }

            Rectangle {
                id: overlay
                anchors.fill: parent
                color: "#000"
                opacity: 0.7
                z: 2
            }

            Rectangle {
                id: detalle_wrapper
                anchors.fill: parent
                color: "transparent"
                z: 3

                Rectangle {
                    id: albumArt
                    color: "transparent"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: tags.top

                    Rectangle {
                        id: loader_overlay
                        visible: playing_loader.running
                        width: albumImage.width
                        height: albumImage.height
                        anchors.centerIn: parent
                        color: "#000"
                        opacity: 0.8
                        z: 4
                    }

                    ActivityIndicator {
                        id: playing_loader
                        anchors.centerIn: parent
                        z: 999
                    }

                    Image {
                        id: albumImage
                        property real escalay: parent.height/albumImage.sourceSize.height
                        property real escalax: parent.width/albumImage.sourceSize.width
                        source: "../graphics/default.png"
                        width: albumImage.sourceSize.width*escalax
                        height: albumImage.sourceSize.height*escalay
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                    }

                    /*MouseArea {
                        anchors.fill: parent
                        property real lastX: -1

                        onPressed: lastX = mouse.x

                        onReleased: {
                            var diff = mouse.x - lastX
                            if (Math.abs(diff) < units.gu(4)) {
                                return;
                            } else if (diff < 0) {
                                //playMusic.playSong(1, false)
                                media_player.next()
                            } else if (diff > 0) {
                                //playMusic.playSong(-1, false)
                                media_player.previuos()
                            }
                        }
                    }*/

                    Rectangle {
                        id: lyric_overlay
                        color: "#000"
                        anchors.fill: parent
                        visible: settings.lyrics
                        opacity: 0.4
                        z: 4
                    }

                    Rectangle {
                        id: lyric_view
                        color: "transparent"
                        anchors.fill: parent
                        visible: lyric_overlay.visible
                        z : 5

                        Rectangle {
                            id: lyric_bg
                            color: "#000"
                            width: lbl_lyric.contentWidth + units.gu(4)
                            height: units.gu(4) * lbl_lyric.lineCount
                            opacity: 0.8
                            radius: (lbl_lyric.height + units.gu(4)) / 2;
                            anchors.centerIn: parent
                        }

                        Label {
                            id: lbl_lyric
                            fontSize: "large"
                            color: "#fff"
                            width: parent.width - units.gu(6)
                            anchors {
                                centerIn: parent
                            }
                            wrapMode: Label.WordWrap
                            horizontalAlignment: Label.AlignHCenter
                            verticalAlignment: Label.AlignVCenter
                        }
                        Label {
                            id: lbl_next
                            fontSize: "medium"
                            color: "#fefefe"
                            anchors {
                                top: lbl_lyric.bottom
                                left: parent.left
                                right: parent.right
                                topMargin: units.gu(2)
                                leftMargin: units.gu(2)
                                rightMargin: units.gu(2)
                            }
                            wrapMode: Label.WordWrap
                            horizontalAlignment: Label.AlignHCenter
                            verticalAlignment: Label.AlignVCenter
                        }
                    }
                }

                Rectangle{
                    color: "#000"
                    width: parent.width
                    anchors.bottom: nav_wrapper.top
                    height: units.gu(8)
                    opacity: 0.4
                }

                Rectangle{
                    id: tags
                    color: "transparent"
                    width: parent.width
                    anchors.bottom: nav_wrapper.top
                    height: units.gu(8)
                    //opacity: 0.4

                    Column {
                        anchors {
                            margins: units.gu(1)
                            left: parent.left
                            right: lyric_toggle.left
                        }

                        Label {
                            id: lbl_artistaDetalle
                            width: parent.width
                            fontSize: "x-large"
                            color: "#fff"
                            elide: Text.ElideRight
                        }

                        Label {
                            id: lbl_albumDetalle
                            width: parent.width
                            color: "#fff"
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: lyric_toggle
                        height: width
                        width: units.gu(5)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        opacity: settings.lyrics ? 1 : .4
                        onClicked: settings.lyrics = !settings.lyrics

                        Icon {
                            height: units.gu(3)
                            width: height
                            anchors.centerIn: parent
                            color: "white"
                            name: "note"
                            opacity: settings.lyrics ? 1 : .4
                        }
                    }
                }

                Rectangle{
                    color: "#000"
                    width: parent.width
                    anchors.bottom: control_wrapper.top
                    height: units.gu(3)
                    opacity: 0.6
                }

                Rectangle{
                    id: nav_wrapper
                    color: "transparent"
                    width: parent.width
                    anchors.bottom: control_wrapper.top
                    height: units.gu(3)
                    //opacity: 0.75

                    Label {
                        id: current
                        text: Api.durationToString(seek.value)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        color: "#fff"
                        fontSize: "small"
                    }

                    Slider {
                        id: seek
                        anchors.left: current.right
                        anchors.leftMargin: units.gu(1)
                        anchors.right: total.left
                        anchors.rightMargin: units.gu(1)
                        anchors.verticalCenter: parent.verticalCenter
                        minimumValue: 0.00
                        value: media_player.position
                        live: true
                        style: SliderStyle {}

                        function formatValue(v) {
                            return Api.durationToString(v)
                        }

                        onPressedChanged: {
                            //playMusic.seek(seek.value)
                            media_player.seek(seek.value)
                        }

                        Connections {
                            target: media_player
                            onPlaybackStateChanged: {
                                if(media_player.playbackState === 1){
                                    playpause.name = "media-playback-pause"
                                }else{
                                    playpause.name = "media-playback-start"
                                }
                            }
                            onPositionChanged: {
                                //seek.value = playMusic.position
                                if(settings.lyrics) {
                                    for(var i = 0; i < lyric_model.count; i++){
                                        if(lyric_model.get(i).position <= media_player.position){
                                            //console.log("Model position: " + lyric_model.get(i).position)
                                            //console.log("Player position: " + media_player.position)
                                            //console.log("Wrap mode: " + lbl_lyric.wrapMode)
                                            //console.log("Lyric line: " + lyric_model.get(i).line)
                                            if(lyric_model.get(i).line != ""){
                                                lbl_lyric.text = lyric_model.get(i).line
                                            }else{
                                                lbl_lyric.text = "..."
                                            }
                                            if(i + 1 < lyric_model.count && lyric_model.get(i + 1).line != ""){
                                                lbl_next.text = lyric_model.get(i + 1).line
                                            }else{
                                                lbl_next.text = "..."
                                            }
                                        }
                                    }
                                }
                                seek.value = media_player.position
                            }
                            onStopped: {
                                seek.value=0.00
                                playpause.name = "media-playback-start"
                            }
                        }
                    }

                    Label {
                        id: total
                        text: Api.durationToString(media_player.duration)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        color: "#fff"
                        fontSize: "small"
                    }
                }

                Rectangle {
                    color: "#000"
                    width: parent.width
                    anchors.bottom: parent.bottom
                    height: units.gu(7)
                    opacity: 0.6
                }

                Rectangle {
                    id: control_wrapper
                    color: "transparent"
                    width: parent.width
                    anchors.bottom: parent.bottom
                    height: units.gu(7)
                    //opacity: 0.8

                    Row {
                        spacing: units.gu(4)
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            id: player_repeat
                            height: units.gu(5)
                            width: height
                            opacity: settings.repeat != 0 && media_player.queue > 1 ? 1 : .4
                            onClicked: {
                                if(settings.repeat == 0){
                                    settings.repeat = 1
                                    repeat_icon.name = "media-playlist-repeat"
                                }else if(settings.repeat == 1){
                                    settings.repeat = 2
                                    repeat_icon.name = "media-playlist-repeat-one"
                                }else {
                                    settings.repeat = 0
                                    repeat_icon.name = "media-playlist-repeat"
                                }
                            }

                            Icon {
                                id: repeat_icon
                                height: units.gu(3)
                                width: height
                                anchors.centerIn: parent
                                color: "white"
                                name: "media-playlist-repeat"
                                opacity: settings.repeat != 0 && media_player.queue > 1 ? 1 : .4
                            }
                        }

                        Rectangle {
                            id: player_prev
                            color: "#e53446";
                            width: units.gu(5)
                            height: units.gu(5)
                            radius: units.gu(2.5)
                            anchors.verticalCenter: parent.verticalCenter

                            Icon{
                                id: prev
                                width: units.gu(3)
                                height: units.gu(3)
                                name: "media-skip-backward"
                                color: "#fff"
                                anchors.centerIn: parent
                                opacity: media_player.queue > 1 ? 1 : .4
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    /*if(playMusic.queue>1){
                                        playMusic.playSong(-1, true)
                                    }*/
                                    //media_player.pause();
                                    media_player.previuos();
                                    //console.log("Indice: " + media_player.getIndex());
                                    //getSongDetail(songs_list[media_player.getIndex()]);
                                }
                            }
                        }

                        Rectangle {
                            id: player_control
                            color: "#e53446";
                            width: units.gu(6)
                            height: units.gu(6)
                            radius: units.gu(3)

                            Icon{
                                id: playpause
                                width: units.gu(4)
                                height: units.gu(4)
                                name: "media-playback-start"
                                color: "#fff"
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    /*if(playMusic.playbackState === Audio.PlayingState){
                                        playMusic.pause()
                                    }else{
                                        playMusic.play()
                                    }*/
                                    media_player.togle()
                                }
                            }
                        }

                        Rectangle {
                            id: player_next
                            color: "#e53446";
                            width: units.gu(5)
                            height: units.gu(5)
                            radius: units.gu(2.5)
                            anchors.verticalCenter: parent.verticalCenter

                            Icon{
                                id: next
                                width: units.gu(3)
                                height: units.gu(3)
                                name: "media-skip-forward"
                                color: "#fff"
                                anchors.centerIn: parent
                                opacity: media_player.queue > 1 ? 1 : .4
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    /*if(playMusic.queue>1){
                                        playMusic.playSong(1, true)
                                    }*/
                                    //console.log("Indice: " + media_player.getIndex());
                                    //getSongDetail(songs_list[media_player.getIndex() + 1]);
                                    //media_player.pause();
                                    media_player.next();
                                }
                            }
                        }

                        MouseArea {
                            id: player_shuffle
                            height: units.gu(5)
                            width: height
                            opacity: settings.shuffle && media_player.queue > 1 ? 1 : .4
                            onClicked: settings.shuffle = !settings.shuffle

                            Icon {
                                height: units.gu(3)
                                width: height
                                anchors.centerIn: parent
                                color: "white"
                                name: "media-playlist-shuffle"
                                opacity: settings.shuffle && media_player.queue > 1 ? 1 : .4
                            }
                        }
                    }
                }
            }
        }
    }
}
