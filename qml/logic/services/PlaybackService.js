.import "../CloudBridge.js" as CloudBridge
function getSongDetail(deps, id, context) {
    var ctx = context || {}
    var setPageTitle = ctx.setPageTitle || function() {}
    var setArtistText = ctx.setArtistText || function() {}
    var setAlbumText = ctx.setAlbumText || function() {}
    var setAlbumImage = ctx.setAlbumImage || function() {}
    var setSeekMaximum = ctx.setSeekMaximum || function() {}
    var fallbackDuration = ctx.fallbackDuration || 0
    var setCurrentId = ctx.setCurrentId || function() {}
    var updateToolbar = ctx.updateToolbar || function() {}
    var onSongResolved = ctx.onSongResolved || null
    var lyricsEnabled = ctx.lyricsEnabled
    if (lyricsEnabled === undefined && deps.defaultLyricsEnabled) {
        lyricsEnabled = deps.defaultLyricsEnabled()
    }
    var lyricContext = ctx.lyricContext || null
    var playingLoaderRef = ctx.loader || null

    setPageTitle(i18n.tr("Now Playing"))
    setArtistText("")
    setAlbumText("")
    setAlbumImage("../graphics/default.png")
    if (lyricsEnabled) {
        getLyric(deps, id, lyricContext)
    }
    if (playingLoaderRef) {
        playingLoaderRef.running = true
    }

    CloudBridge.directApiAsync(
        "songDetail",
        { id: String(id) },
        function(data) {
            if (data) {
                var song = data
                if (data && data.length && data.length > 0) {
                    song = data[0]
                }
                var artistName = ""
                if (song.artist && song.artist.length && song.artist.length > 0) {
                    artistName = song.artist.join(", ")
                } else if (typeof song.artist === "string") {
                    artistName = song.artist
                }

                var resolvedDuration = 0
                if (song.duration && song.duration > 0) {
                    resolvedDuration = song.duration
                } else if (fallbackDuration && fallbackDuration > 0) {
                    resolvedDuration = fallbackDuration
                }

                var picId = song.pic_id ? song.pic_id : ""
                var cover = (picId !== "" && picId !== "0") ? (deps.apiBase + "pic/" + picId + "?size=300") : "../graphics/default.png"
                setPageTitle(song.name || i18n.tr("Now Playing"))
                setAlbumImage(cover)
                setArtistText(artistName)
                setAlbumText(song.album || "")
                if (resolvedDuration > 0) {
                    setSeekMaximum(resolvedDuration)
                }
                updateToolbar(song.name || i18n.tr("Now Playing"), artistName, cover)
                setCurrentId(song.id ? song.id : id)
                if (onSongResolved) {
                    onSongResolved({
                        id: song.id ? song.id : id,
                        name: song.name || "",
                        artist: artistName,
                        album: song.album || "",
                        duration: resolvedDuration,
                        image: cover,
                        source: song.source || "netease"
                    })
                }
            }
            if (playingLoaderRef) {
                playingLoaderRef.running = false
            }
        },
        function(e) {
            console.log(e)
            if (playingLoaderRef) {
                playingLoaderRef.running = false
            }
        }
    )
}

function getLyric(deps, id, context) {
    var ctx = context || {}
    var lyricModelRef = ctx.lyricModel || null
    var setCurrentLyric = ctx.setCurrentLyric || function() {}
    var setNextLyric = ctx.setNextLyric || function() {}
    if (!lyricModelRef) {
        return
    }

    lyricModelRef.clear()
    setCurrentLyric("")
    setNextLyric("")
    CloudBridge.directApiAsync(
        "lyric",
        { id: String(id) },
        function(data) {
            if (data) {
                parseLyric(lyricModelRef, data.lyric, setCurrentLyric, setNextLyric)
            } else {
                setCurrentLyric(i18n.tr("I'm sorry but I forgot that lyric :("))
            }
        },
        function(e) {
            console.log(e)
            setCurrentLyric(i18n.tr("I'm sorry but I forgot that lyric :("))
        }
    )
}

function parseLyric(lyricModelRef, lyric, setCurrentLyric, setNextLyric) {
    if (!lyric || typeof lyric !== "string") {
        lyricModelRef.clear()
        setCurrentLyric(i18n.tr("No lyrics available"))
        setNextLyric("")
        return
    }
    var lines = lyric.split(/\r\n|\n/)
    appendLyricLines(lyricModelRef, lines)
}

function appendLyricLines(lyricModelRef, lines) {
    var line = " "
    for (var i = 0; i < lines.length; i++) {
        if (lines[i].search(/^(\[)(\d*)(:)(.*)(\])(.*)/i) >= 0) {
            line = lines[i].match(/^(\[)(\d*)(:)(.*)(\])(.*)/i)
            var sec = (parseInt(line[2], 10) * 60) + parseInt(line[4], 10)
            lyricModelRef.append({
                position: sec * 1000,
                line: line[6]
            })
        }
    }
}

function durationToString(duration) {
    var value = Number(duration)
    if (!isFinite(value) || value < 0) {
        value = 0
    }
    var totalSeconds = Math.floor(value / 1000)
    var minutes = Math.floor(totalSeconds / 60)
    var seconds = totalSeconds % 60
    return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds)
}
