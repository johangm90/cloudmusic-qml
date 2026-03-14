import QtQuick 2.12
import Lomiri.Components 1.3
import QtGraphicalEffects 1.0
import QtMultimedia 5.6
import Lomiri.DownloadManager 1.2
import Lomiri.Content 1.1
import Qt.labs.settings 1.0
import QtQuick.Layouts 1.2
import "../components"
import "../graphics"
import "../logic/Format.js" as Format
import "../logic/RequestBus.js" as RequestBus
import "../logic/Database.js" as Db
import "../logic/CloudBridge.js" as CloudBridge

Item {
    id: playingContainer
    property var appRoot
    property color pageColor: appRoot ? appRoot.pageColor : "#1f1f1f"
    property color cardColor: appRoot ? appRoot.cardColor : "#232323"
    property color borderColor: appRoot ? appRoot.borderColor : "#3a3a3a"
    property color textColor: appRoot ? appRoot.textColor : "#f2f2f2"
    property color secondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#b8b8b8"
    property color inverseTextColor: appRoot ? appRoot.inverseTextColor : "#ffffff"
    property color sectionColor: appRoot ? appRoot.sectionColor : "#333333"
    property color selectedColor: appRoot ? appRoot.selectedColor : "#5d5d5d"
    property color accentColor: appRoot ? appRoot.primaryColor : "#e53446"
    property color overlayColor: appRoot && appRoot.designTokens ? appRoot.designTokens.color.toastBg : "#000"
    property real spacingSmall: appRoot ? appRoot.spacingSmall : units.gu(0.8)
    property real spacingMedium: appRoot ? appRoot.spacingMedium : units.gu(1.2)
    property real radiusSmall: appRoot ? appRoot.radiusSmall : units.gu(0.8)
    property real radiusMedium: appRoot ? appRoot.radiusMedium : units.gu(1.2)
    property string bodyTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.body : "medium"
    property string smallTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.bodySmall : "small"
    property string titleTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.title : "large"
    property real queueBreakpoint: units.gu(100)
    property real queueHeaderHeight: units.gu(6)
    property real queueAccentWidth: units.gu(0.6)
    property real queueAccentHeight: units.gu(3.2)
    property real queueAccentLeft: units.gu(1.6)
    property real queueTitleLeft: units.gu(3)
    property real queueRightInset: units.gu(1.6)
    property real lyricInsets: units.gu(2.5)
    property real lyricBubblePadding: units.gu(4)
    property real lyricTextInset: units.gu(6)
    property real lyricNextTopMargin: units.gu(2)
    property real lyricNextSideMargin: units.gu(2)
    property real coverMinSide: units.gu(18)
    property real coverInset: units.gu(6)
    property real tagsHeight: units.gu(8)
    property real navHeight: units.gu(4.5)
    property real controlsHeight: units.gu(7)
    property real iconButtonSize: units.gu(5)
    property real iconSize: units.gu(3)
    property real primaryButtonSize: units.gu(6)
    property real primaryIconSize: units.gu(4)
    property real controlsRowSpacing: units.gu(4)
    property real sideInset: units.gu(2)
    property real compactSpacing: spacingSmall + units.gu(0.2)
    property string songRequestContext: "now_playing_song_" + String(Date.now())
    property string lyricRequestContext: "now_playing_lyric_" + String(Date.now())

    property
    var settings: Settings {
        property bool shuffle: false
        property int repeat: 0
        property bool lyrics: true
        onShuffleChanged: {
            media_player.setShuffleMode(settings.shuffle)
        }
        onRepeatChanged: {
            media_player.setRepeatMode(settings.repeat)
        }
        onLyricsChanged: {
            if (lyrics) {
                showLyrics()
            }
        }
    }

    property bool activeState: Qt.application.active

    onActiveStateChanged: {
        if (media_player.queue > 1 && (media_player.getIndex() != current_index || songs_list[media_player.getIndex()] != current_id)) {
            getSongDetail();
        }
    }

    property int current_index: -1
    property int current_id: -1

    property variant songs_list: []

    function setIndex(index) {
        if (index > -1) {
            current_index = index
            getSongDetail()
        }
    }

    function getSongDetail() {
        var index = media_player.getIndex()
        if (index < 0 || index >= songs_list.length) {
            return
        }
        requestSongDetail(songs_list[index])
    }

    function showLyrics() {
        if (current_id > 0) {
            requestLyric(current_id)
        }
    }

    function currentSongRecord() {
        var idx = media_player.getIndex()
        var src = "netease"
        if (idx >= 0 && idx < model_queue.count) {
            src = model_queue.get(idx).source ? model_queue.get(idx).source : "netease"
        }
        return {
            id: current_id,
            name: playingPage.title,
            artist: lbl_artistaDetalle.text,
            album: lbl_albumDetalle.text,
            duration: seek.maximumValue,
            image: albumImage.source,
            source: src
        }
    }

    function currentQueueDuration() {
        var idx = media_player.getIndex()
        if (idx >= 0 && idx < model_queue.count) {
            var value = model_queue.get(idx).duration
            if (value && value > 0) {
                return value
            }
        }
        if (seek.maximumValue && seek.maximumValue > 0) {
            return seek.maximumValue
        }
        return 0
    }

    function toggleCurrentSongLike() {
        if (current_id <= 0) {
            return false
        }
        var liked = Db.toggleLikedSong(currentSongRecord())
        return liked
    }

    function isCurrentSongLiked() {
        if (current_id <= 0) {
            return false
        }
        var idx = media_player.getIndex()
        var src = "netease"
        if (idx >= 0 && idx < model_queue.count) {
            src = model_queue.get(idx).source ? model_queue.get(idx).source : "netease"
        }
        return Db.isLikedSong(current_id, src)
    }

    function requestSongDetail(songId) {
        if (!appRoot || !appRoot.cloudApi) {
            return
        }
        RequestBus.cancelContext(songRequestContext)
        playingPage.title = i18n.tr("Now Playing")
        playingPage.header.title = i18n.tr("Now Playing")
        lbl_artistaDetalle.text = ""
        lbl_albumDetalle.text = ""
        albumImage.source = "../graphics/default.png"
        if (settings.lyrics) {
            requestLyric(songId)
        }
        playing_loader.running = true

        // Determine provider from the queue item at the current playback index
        var idx = media_player.getIndex()
        var itemSource = "netease"
        if (idx >= 0 && idx < model_queue.count) {
            itemSource = model_queue.get(idx).source ? model_queue.get(idx).source : "netease"
        }

        if (itemSource === "youtube") {
            // ── YouTube Music path ────────────────────────────────────────────
            CloudBridge.directApiAsync(
                "ytmusic_song",
                { id: String(songId) },
                function(data) {
                    if (data) {
                        var artistName = typeof data.artist === "string" ? data.artist : ""
                        var duration = (data.duration && data.duration > 0) ? data.duration : currentQueueDuration()
                        var cover = data.img || data.image || "../graphics/default.png"
                        var title = data.title || data.name || i18n.tr("Now Playing")
                        playingPage.title = title
                        playingPage.header.title = title
                        albumImage.source = cover
                        lbl_artistaDetalle.text = artistName
                        lbl_albumDetalle.text = data.album || ""
                        if (duration > 0) {
                            seek.maximumValue = duration
                        }
                        player_toolbar.cargar(title, artistName, cover)
                        current_id = data.id ? data.id : songId
                        Db.addRecentlyPlayed({
                            id: current_id,
                            name: title,
                            artist: artistName,
                            album: data.album || "",
                            duration: duration,
                            image: cover,
                            source: "youtube"
                        })
                    }
                    playing_loader.running = false
                },
                function(err) {
                    console.log(err)
                    playing_loader.running = false
                }
            )
        } else {
            // ── NetEase path (unchanged) ──────────────────────────────────────
            var songDetailRequestId = RequestBus.createId("song_detail")
            RequestBus.registerRequest(songDetailRequestId, {
                context: songRequestContext,
                onSuccess: function(data) {
                    var song = data && data.song ? data.song : data
                    if (!song) {
                        return
                    }
                    var artistName = typeof song.artist === "string" ? song.artist : ""
                    var duration = (song.duration && song.duration > 0) ? song.duration : currentQueueDuration()
                    var cover = song.big_image ? song.big_image : (song.image ? song.image : "../graphics/default.png")
                    playingPage.title = song.name || i18n.tr("Now Playing")
                    playingPage.header.title = playingPage.title
                    albumImage.source = cover
                    lbl_artistaDetalle.text = artistName
                    lbl_albumDetalle.text = song.album || ""
                    if (duration > 0) {
                        seek.maximumValue = duration
                    }
                    player_toolbar.cargar(playingPage.title, artistName, cover)
                    current_id = song.id ? song.id : (current_index >= 0 && current_index < songs_list.length ? songs_list[current_index] : current_id)
                    Db.addRecentlyPlayed({
                        id: current_id,
                        name: playingPage.title,
                        artist: artistName,
                        album: song.album || "",
                        duration: duration,
                        image: cover,
                        source: song.source || "netease"
                    })
                },
                onError: function(err) {
                    console.log(err)
                },
                onFinally: function() {
                    playing_loader.running = false
                }
            })
            appRoot.cloudApi.songDetailAsync(String(songId), songDetailRequestId)
        }
    }

    function requestLyric(songId) {
        if (!appRoot || !appRoot.cloudApi || !songId || songId <= 0) {
            return
        }
        RequestBus.cancelContext(lyricRequestContext)
        model_lyric.clear()
        lbl_lyric.text = ""
        lbl_next.text = ""
        var lyricRequestId = RequestBus.createId("lyric")
        RequestBus.registerRequest(lyricRequestId, {
            context: lyricRequestContext,
            onSuccess: function(lyricData) {
                parseLyricText(lyricData && lyricData.lyric ? lyricData.lyric : "")
                if (model_lyric.count === 0) {
                    lbl_lyric.text = i18n.tr("No lyrics available")
                }
            },
            onError: function(err) {
                console.log(err)
                lbl_lyric.text = i18n.tr("I'm sorry but I forgot that lyric :(")
            }
        })
        appRoot.cloudApi.lyricAsync(String(songId), lyricRequestId)
    }

    Component.onDestruction: {
        RequestBus.cancelContext(songRequestContext)
        RequestBus.cancelContext(lyricRequestContext)
    }

    function parseLyricText(lyric) {
        model_lyric.clear()
        if (!lyric || typeof lyric !== "string") {
            lbl_lyric.text = i18n.tr("No lyrics available")
            lbl_next.text = ""
            return
        }
        var lines = lyric.split(/\r\n|\n/)
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].match(/^(\[)(\d*)(:)(.*)(\])(.*)/i)
            if (!line) {
                continue
            }
            var sec = (parseInt(line[2], 10) * 60) + parseInt(line[4], 10)
            model_lyric.append({
                position: sec * 1000,
                line: line[6]
            })
        }
    }

    Connections {
        target: appRoot && appRoot.cloudApi ? appRoot.cloudApi : null
        onRequestFinished: function(requestId, ok, payloadJson, error) {
            RequestBus.dispatch(requestId, ok, payloadJson, error)
        }
    }

    property ListModel model_queue: ListModel {
        id: queue_model
    }

    property ListModel model_lyric: ListModel {
        id: lyric_model
    }

    Rectangle {
        anchors.fill: parent
        color: pageColor
    }

    GridLayout {
        id: layouts
        anchors.fill: parent
        columns: layouts.width < queueBreakpoint ? 1 : 2
        columnSpacing: 1
        rowSpacing: 1

                    Rectangle {
                        id: queue_layout
                        color: cardColor
                        radius: radiusMedium
                        border.color: borderColor
                        border.width: 1
                        clip: true
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.row: layouts.columns == 1 ? 1 : 0
                        Layout.column: layouts.columns == 1 ? 0 : 1
                        Layout.preferredWidth: layouts.columns == 1 ? 0 : parent.width / 3
                        Layout.preferredHeight: layouts.columns == 1 ? 0 : parent.height

                        Rectangle {
                            id: queue_title
                            color: sectionColor
                            width: parent.width
                            height: queueHeaderHeight

                            Rectangle {
                                width: queueAccentWidth
                                height: queueAccentHeight
                                radius: width / 2
                                color: accentColor
                                anchors.left: parent.left
                                anchors.leftMargin: queueAccentLeft
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Label {
                                anchors.left: parent.left
                                anchors.leftMargin: queueTitleLeft
                                anchors.verticalCenter: parent.verticalCenter
                                text: i18n.tr("Queue")
                                fontSize: bodyTextSize
                                font.weight: Font.DemiBold
                                color: textColor
                            }

                            Label {
                                anchors.right: parent.right
                                anchors.rightMargin: queueRightInset
                                anchors.verticalCenter: parent.verticalCenter
                                text: i18n.tr("%1 total").arg(queue_model.count)
                                fontSize: smallTextSize
                                color: secondaryTextColor
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

                                    delegate: SongListItem {
                                        title: name
                                        subtitle: artist
                                        durationText: Format.durationToString(duration)
                                        coverSource: image
                                        albumId: album_id
                                        selected: current_index == index
                                        showMenu: false
                                        rowTextColor: textColor
                                        rowSecondaryTextColor: secondaryTextColor
                                        selectedColor: playingContainer.selectedColor
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

        Rectangle {
            id: player_layout
            color: "transparent"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.row: 0
            Layout.column: 0
            Layout.preferredWidth: layouts.columns == 1 ? parent.width : (parent.width / 3) * 2
            Layout.preferredHeight: layouts.columns == 1 ? parent.height : parent.height

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
                        width: coverFrame.width
                        height: coverFrame.height
                        anchors.centerIn: parent
                        color: overlayColor
                        opacity: 0.8
                        z: 4
                        radius: radiusMedium
                    }

                    ActivityIndicator {
                        id: playing_loader
                        anchors.centerIn: parent
                        z: 999
                    }

                    Rectangle {
                        id: coverFrame
                        property real side: Math.max(coverMinSide, Math.min(parent.width, parent.height) - coverInset)
                        width: side
                        height: side
                        anchors.centerIn: parent
                        radius: radiusMedium
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1
                        color: sectionColor
                        z: 3

                        Image {
                            id: albumImage
                            source: "../graphics/default.png"
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: albumImage
                            cached: true
                            maskSource: Rectangle {
                                width: coverFrame.width
                                height: coverFrame.height
                                radius: coverFrame.radius
                            }
                        }
                    }

                    Rectangle {
                        id: lyric_overlay
                        color: overlayColor
                        anchors.fill: parent
                        visible: settings.lyrics
                        opacity: 0.4
                        z: 4
                    }

                    Rectangle {
                        id: lyric_view
                        color: "transparent"
                        anchors.fill: parent
                        anchors.margins: lyricInsets
                        visible: lyric_overlay.visible
                        z: 5

                        Rectangle {
                            id: lyric_bg
                            color: overlayColor
                            width: lbl_lyric.contentWidth + lyricBubblePadding
                            height: lyricBubblePadding * lbl_lyric.lineCount
                            opacity: 0.8
                            radius: (lbl_lyric.height + lyricBubblePadding) / 2;
                            anchors.centerIn: parent
                        }

                        Label {
                            id: lbl_lyric
                            fontSize: bodyTextSize
                            font.weight: Font.DemiBold
                            color: inverseTextColor
                            width: parent.width - lyricTextInset
                            anchors {
                                centerIn: parent
                            }
                            wrapMode: Label.WordWrap
                            horizontalAlignment: Label.AlignHCenter
                            verticalAlignment: Label.AlignVCenter
                        }
                        Label {
                            id: lbl_next
                            fontSize: smallTextSize
                            color: inverseTextColor
                            anchors {
                                top: lbl_lyric.bottom
                                left: parent.left
                                right: parent.right
                                topMargin: lyricNextTopMargin
                                leftMargin: lyricNextSideMargin
                                rightMargin: lyricNextSideMargin
                            }
                            wrapMode: Label.WordWrap
                            horizontalAlignment: Label.AlignHCenter
                            verticalAlignment: Label.AlignVCenter
                        }
                    }

                    Rectangle {
                        id: bgOverlay
                        anchors.fill: parent
                        color: overlayColor
                        opacity: 0.7
                        z: 2
                    }

                    Image {
                        id: bg
                        source: albumImage.source
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        visible: false
                        z: 1
                        onStatusChanged: bg.status == Image.Ready ? bgOverlay.opacity=0.7 : bgOverlay.opacity=1
                    }

                    GaussianBlur {
                        anchors.fill: bg
                        source: bg
                        radius: 8
                        samples: 16
                    }
                }

                    Rectangle {
                        id: tags
                        color: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.86)
                        border.color: borderColor
                        border.width: 1
                        radius: radiusMedium
                        width: parent.width
                        anchors.bottom: nav_wrapper.top
                        height: tagsHeight

                    Column {
                        anchors {
                            margins: sideInset
                            left: parent.left
                            right: lyric_toggle.left
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: compactSpacing

                        Label {
                            id: lbl_artistaDetalle
                            width: parent.width
                            fontSize: titleTextSize
                            elide: Label.ElideRight
                            color: textColor
                        }

                        Label {
                            id: lbl_albumDetalle
                            width: parent.width
                            elide: Label.ElideRight
                            color: secondaryTextColor
                        }

                        Label {
                            id: lbl_sourceBadge
                            visible: current_id > 0
                            fontSize: "x-small"
                            color: secondaryTextColor
                            text: {
                                var idx = media_player.getIndex()
                                var src = "netease"
                                if (idx >= 0 && idx < model_queue.count) {
                                    src = model_queue.get(idx).source ? model_queue.get(idx).source : "netease"
                                }
                                return src === "youtube" ? "YouTube" : "NetEase"
                            }
                        }
                    }

                    MouseArea {
                        id: lyric_toggle
                        height: width
                        width: iconButtonSize
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        onClicked: settings.lyrics = !settings.lyrics

                        Icon {
                            height: iconSize
                            width: height
                            anchors.centerIn: parent
                            name: "note"
                            color: textColor
                            opacity: settings.lyrics ? 1 : .4
                        }
                    }
                }

                    Rectangle {
                        id: nav_wrapper
                        color: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.9)
                        border.color: borderColor
                        border.width: 1
                        radius: radiusMedium
                        width: parent.width
                        anchors.bottom: control_wrapper.top
                        height: navHeight

                    Label {
                        id: current
                        text: Format.durationToString(seek.value)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: sideInset
                        fontSize: smallTextSize
                        color: textColor
                    }

                    Slider {
                        id: seek
                        anchors.left: current.right
                        anchors.leftMargin: sideInset
                        anchors.right: total.left
                        anchors.rightMargin: sideInset
                        anchors.verticalCenter: parent.verticalCenter
                        minimumValue: 0.00
                        value: media_player.position
                        live: true
                        StyleHints { foregroundColor: accentColor }

                        function formatValue(v) {
                            return Format.durationToString(v)
                        }

                        onPressedChanged: {
                            media_player.seek(seek.value)
                        }

                        Connections {
                            target: media_player
                            onPlaybackStateChanged: {
                                if (media_player.playbackState === 1) {
                                    playpause.name = "media-playback-pause"
                                } else {
                                    playpause.name = "media-playback-start"
                                }
                            }
                            onPositionChanged: {
                                if (settings.lyrics) {
                                    for (var i = 0; i < lyric_model.count; i++) {
                                        if (lyric_model.get(i).position <= media_player.position) {
                                            if (lyric_model.get(i).line != "") {
                                                lbl_lyric.text = lyric_model.get(i).line
                                            } else {
                                                lbl_lyric.text = "..."
                                            }
                                            if (i + 1 < lyric_model.count && lyric_model.get(i + 1).line != "") {
                                                lbl_next.text = lyric_model.get(i + 1).line
                                            } else {
                                                lbl_next.text = "..."
                                            }
                                        }
                                    }
                                }
                                seek.value = media_player.position
                            }
                            onStopped: {
                                seek.value = 0.00
                                playpause.name = "media-playback-start"
                            }
                        }
                    }

                    Label {
                        id: total
                        text: Format.durationToString(media_player.duration)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: sideInset
                        fontSize: smallTextSize
                        color: textColor
                    }
                }

                    Rectangle {
                        id: control_wrapper
                        color: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.92)
                        border.color: borderColor
                        border.width: 1
                        radius: radiusMedium
                        width: parent.width
                        anchors.bottom: parent.bottom
                        anchors.margins: 0
                        height: controlsHeight

                    Row {
                        spacing: controlsRowSpacing
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            id: player_repeat
                            height: iconButtonSize
                            width: height
                            onClicked: {
                                if (settings.repeat == 0) {
                                    settings.repeat = 1
                                    repeat_icon.name = "media-playlist-repeat"
                                } else if (settings.repeat == 1) {
                                    settings.repeat = 2
                                    repeat_icon.name = "media-playlist-repeat-one"
                                } else {
                                    settings.repeat = 0
                                    repeat_icon.name = "media-playlist-repeat"
                                }
                            }

                            Icon {
                                id: repeat_icon
                                height: iconSize
                                width: height
                                anchors.centerIn: parent
                                name: "media-playlist-repeat"
                                color: textColor
                                opacity: settings.repeat != 0 && media_player.queue > 1 ? 1 : .4
                            }
                        }

                        Rectangle {
                            id: player_prev
                            color: "transparent";
                            width: iconButtonSize
                            height: iconButtonSize
                            radius: iconButtonSize / 2
                            anchors.verticalCenter: parent.verticalCenter

                            Icon {
                                id: prev
                                width: iconSize
                                height: iconSize
                                name: "media-skip-backward"
                                color: accentColor
                                anchors.centerIn: parent
                                opacity: media_player.queue > 1 ? 1 : .4
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    media_player.previous();
                                }
                            }
                        }

                        Rectangle {
                            id: player_control
                            color: "transparent";
                            border.color: accentColor
                            border.width: 1
                            width: primaryButtonSize
                            height: primaryButtonSize
                            radius: primaryButtonSize / 2

                            Icon {
                                id: playpause
                                width: primaryIconSize
                                height: primaryIconSize
                                name: "media-playback-start"
                                color: accentColor
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    media_player.toggle()
                                }
                            }
                        }

                        Rectangle {
                            id: player_next
                            color: "transparent";
                            width: iconButtonSize
                            height: iconButtonSize
                            radius: iconButtonSize / 2
                            anchors.verticalCenter: parent.verticalCenter

                            Icon {
                                id: next
                                width: iconSize
                                height: iconSize
                                name: "media-skip-forward"
                                color: accentColor
                                anchors.centerIn: parent
                                opacity: media_player.queue > 1 ? 1 : .4
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    media_player.next();
                                }
                            }
                        }

                        MouseArea {
                            id: player_shuffle
                            height: iconButtonSize
                            width: height
                            onClicked: settings.shuffle = !settings.shuffle

                            Icon {
                                height: iconSize
                                width: height
                                anchors.centerIn: parent
                                name: "media-playlist-shuffle"
                                color: textColor
                                opacity: settings.shuffle && media_player.queue > 1 ? 1 : .4
                            }
                        }
                    }
                }
            }
        }
    }
}
