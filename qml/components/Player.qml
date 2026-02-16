import QtQuick 2.12
import Lomiri.Components 1.3
import QtMultimedia 5.6
import "../logic/Api.js" as Api

MediaPlayer {
    id: playMusic
    property int queue: 0
    property bool autoplayPending: false
    property int autoplayAttempts: 0
    property int autoplayTargetIndex: -1
    property int autoplayLastPosition: 0
    property int autoplayProgressTicks: 0
    property bool autoplayPauseIssued: false

    function stopAutoplayRetry(success, silent) {
        autoplayPending = false
        autoplayTargetIndex = -1
        autoplayProgressTicks = 0
        autoplayPauseIssued = false
        autoplayRetry.stop()
        if (!silent) {
            if (success) {
                console.log("Autoplay ready.")
            } else {
                console.log("Autoplay failed after retries.")
            }
        }
    }

    property var autoplayRetry: Timer {
        interval: 300
        repeat: true
        onTriggered: {
            if (!playMusic.autoplayPending) {
                stop()
                return
            }

            // Success only after sustained progress across multiple ticks.
            if (playMusic.position > playMusic.autoplayLastPosition + 80) {
                playMusic.autoplayProgressTicks += 1
            } else {
                playMusic.autoplayProgressTicks = 0
            }
            playMusic.autoplayLastPosition = playMusic.position
            if (playMusic.autoplayProgressTicks >= 3 && playMusic.position > 1000) {
                playMusic.stopAutoplayRetry(true, false)
                return
            }

            if (playMusic.autoplayAttempts >= 30) {
                playMusic.stopAutoplayRetry(false, false)
                return
            }

            playMusic.autoplayAttempts += 1

            // AAL backend may require a forced pause->play cycle with delay.
            if (playMusic.autoplayPauseIssued) {
                playMusic.autoplayPauseIssued = false
                try {
                    playMusic.play()
                } catch (eAfterPause) {
                    console.log(eAfterPause)
                }
                return
            }

            if (playMusic.autoplayAttempts % 5 === 0) {
                try {
                    playMusic.pause()
                    playMusic.autoplayPauseIssued = true
                } catch (ePause) {
                    console.log(ePause)
                }
                return
            }

            try {
                playMusic.play()
            } catch (e) {
                console.log(e)
            }
        }
    }

    function requestAutoplay(targetIndex) {
        autoplayPending = true
        autoplayAttempts = 0
        autoplayTargetIndex = typeof targetIndex === "number" ? targetIndex : autoplayTargetIndex
        autoplayLastPosition = position
        autoplayProgressTicks = 0
        autoplayPauseIssued = false
        autoplayRetry.start()
    }

    playlist: Playlist {
        id: playlist
        onCurrentItemSourceChanged: {
            playing_page.setIndex(currentIndex)
            console.log(playlist.currentItemSource);
            cloud_music_metric.increment(1)
            if (playMusic.autoplayPending &&
                (playMusic.autoplayTargetIndex < 0 || currentIndex === playMusic.autoplayTargetIndex) &&
                playMusic.playbackState !== MediaPlayer.PlayingState) {
                try {
                    playMusic.play()
                } catch (e) {
                    console.log(e)
                }
            }
        }
    }

    onStatusChanged: {
        console.log("[Status] " + status)
        if (autoplayPending && playbackState !== MediaPlayer.PlayingState && (status === MediaPlayer.LoadedMedia || status === MediaPlayer.BufferedMedia)) {
            try {
                playMusic.play()
            } catch (e) {
                console.log(e)
            }
        }
        if (status == 2){
            console.log("[Status] changed to: " + status)
            //cloud_music_metric.increment(1)
        }
    }

    onPlaybackStateChanged: {
        if (autoplayPending && playbackState !== MediaPlayer.PlayingState) {
            try {
                playMusic.play()
            } catch (e) {
                console.log(e)
            }
        }
    }

    onPositionChanged: {
        if (autoplayPending) {
            if (position > autoplayLastPosition + 80) {
                autoplayProgressTicks += 1
            } else {
                autoplayProgressTicks = 0
            }
            autoplayLastPosition = position
            if (autoplayProgressTicks >= 3 && position > 1000) {
                stopAutoplayRetry(true, false)
            }
        }
    }

    function setPlaylist(sources, index){
        stopAutoplayRetry(false, true)
        media_player.stop()
        queue = sources.length
        playlist.clear()
        if(playlist.addItems(sources)){
            setIndex(index)
            requestAutoplay(index)
        }
    }

    function additem(source) {
        queue += 1

        try {
            playlist.addItem(source)
        }catch(e) {
            console.log(e)
        }
    }

    function setSuffleMode(value){
        if(value){
            playlist.playbackMode = Playlist.Random
        }
    }

    function setRepeatMode(mode){
        if(mode == 1){
            playlist.playbackMode = Playlist.Loop
        }else if(mode == 2){
            playlist.playbackMode = Playlist.CurrentItemInLoop
        }else {
            playlist.playbackMode = Playlist.Sequential
        }
    }

    function togle(){
        console.log('[Playing] ' + MediaPlayer.PlayingState)
        if(playMusic.playbackState === MediaPlayer.PlayingState){
            try {
                playMusic.pause()
            } catch(e) {
                console.log(e)
            }
        }else{
            try {
                playMusic.play()
            } catch(e) {
                console.log(e)
            }
        }
    }

    function previuos(){
        try {
            playlist.previous()
        } catch(e) {
           console.log(e)
        }
    }

    function next(){
        try {
            playlist.next()
        } catch(e) {
            console.log(e)
        }
    }

    function getIndex(){
        return playlist.currentIndex
    }

    function setIndex(index){
        playlist.currentIndex = index
        console.log('[Playing] ' + MediaPlayer.PlayingState)
        if(playMusic.playbackState != MediaPlayer.PlayingState){
            try{
                playMusic.play()
            }catch(e){
                console.log(e)
            }
            requestAutoplay(index)
        }
    }
}
