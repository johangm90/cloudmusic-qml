import QtQuick 2.7
import Ubuntu.Components 1.3
import QtMultimedia 5.6
import "../logic/Api.js" as Api

MediaPlayer {
    id: playMusic
    property int queue: 0

    playlist: Playlist {
        id: playlist
        onCurrentItemSourceChanged: {
            playing_page.setIndex(currentIndex)
            console.log(playlist.currentItemSource);
            cloud_music_metric.increment(1)
        }
    }

    onStatusChanged: {
        console.log("[Status] " + status)
        if (status == 2){
            console.log("[Status] changed to: " + status)
            //cloud_music_metric.increment(1)
        }
    }

    function setPlaylist(sources, index){
        media_player.stop()
        queue = sources.length
        playlist.clear()
        if(playlist.addItems(sources)){
            setIndex(index)
            try{
                media_player.play()
            }catch(e){
                console.log(e)
            }
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
        }
    }
}

