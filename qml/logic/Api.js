var server = "http://127.0.0.1:39876/";
var api2 = "http://127.0.0.1:39876/";
var _activeSearchToken = 0;
var _asyncSeq = 0;
var _asyncConnected = false;
var _asyncCallbacks = {};

function directApi(action, params) {
    try {
        if (!cloudMusic || !cloudMusic.cloudApi) {
            return null
        }
        var raw = cloudMusic.cloudApi.call(action, JSON.stringify(params || {}))
        if (!raw || raw === "") {
            return null
        }
        return JSON.parse(raw)
    } catch (e) {
        console.log(e)
        return null
    }
}

function ensureAsyncBridgeConnected() {
    if (_asyncConnected) {
        return true
    }
    if (!cloudMusic || !cloudMusic.cloudApi || !cloudMusic.cloudApi.requestFinished) {
        return false
    }
    cloudMusic.cloudApi.requestFinished.connect(function(requestId, ok, payloadJson, error) {
        var id = String(requestId)
        var cb = _asyncCallbacks[id]
        if (!cb) {
            return
        }
        delete _asyncCallbacks[id]
        if (!ok) {
            if (cb.onError) {
                cb.onError(error ? String(error) : "request failed")
            }
            return
        }
        try {
            var payload = JSON.parse(payloadJson)
            if (payload && payload.error) {
                if (cb.onError) {
                    cb.onError(payload.error)
                }
                return
            }
            if (cb.onSuccess) {
                cb.onSuccess(payload)
            }
        } catch (e) {
            if (cb.onError) {
                cb.onError(e)
            }
        }
    })
    _asyncConnected = true
    return true
}

function directApiAsync(action, params, onSuccess, onError) {
    if (!ensureAsyncBridgeConnected()) {
        if (onError) {
            onError("cloud api bridge unavailable")
        }
        return
    }
    _asyncSeq += 1
    var reqId = "req_" + String(_asyncSeq)
    _asyncCallbacks[reqId] = {
        onSuccess: onSuccess,
        onError: onError
    }
    cloudMusic.cloudApi.callAsync(action, JSON.stringify(params || {}), reqId)
}

function requestJson(url, onSuccess, onError) {
    var cn = new XMLHttpRequest()
    cn.open("GET", url, true)
    cn.onreadystatechange = function() {
        if (cn.readyState !== XMLHttpRequest.DONE) {
            return
        }
        if (cn.status === 200) {
            try {
                var data = JSON.parse(cn.responseText)
                onSuccess(data)
            } catch (e) {
                if (onError) onError(e)
            }
        } else {
            if (onError) onError(cn.status)
        }
    }
    cn.send()
}

function resolveSongCover(song) {
    if (!song || !song.album) {
        return "../graphics/default.png"
    }
    var picId = song.album.picId || song.album.pic_id || song.album.pic || 0
    if (song.album.picUrl) {
        var match = /\/(\d+)\./.exec(song.album.picUrl)
        if (match && match.length > 1) {
            picId = match[1]
        }
    }
    if (picId && picId !== 0) {
        return api2 + "pic/" + picId + "?size=120"
    }
    return "../graphics/default.png"
}

function resolveAlbumCover(album) {
    if (!album) {
        return "../graphics/default.png"
    }
    var picId = album.picId || album.pic_id || album.pic || 0
    if (album.picUrl) {
        var match = /\/(\d+)\./.exec(album.picUrl)
        if (match && match.length > 1) {
            picId = match[1]
        }
    }
    if (picId && picId !== 0) {
        return api2 + "pic/" + picId + "?size=200"
    }
    return "../graphics/default.png"
}

function apiSearch(query, type, limit, context) {
    var token = ++_activeSearchToken
    var ctx = context || {}
    var setVisible = ctx.setVisible || is_visible
    var onStarted = ctx.onStarted || null
    var onFinished = ctx.onFinished || null
    var songsModelRef = ctx.songsModel || searchSongsModel
    var albumsModelRef = ctx.albumsModel || searchAlbumsModel
    var artistsModelRef = ctx.artistsModel || searchArtistsModel
    var songsLoaderRef = ctx.songsLoader || search_songs_loader
    var albumsLoaderRef = ctx.albumsLoader || search_albums_loader
    var artistsLoaderRef = ctx.artistsLoader || search_artists_loader

    setVisible(false)
    songsModelRef.clear()
    albumsModelRef.clear()
    artistsModelRef.clear()
    songsLoaderRef.running = true
    albumsLoaderRef.running = true
    artistsLoaderRef.running = true
    if (onStarted) {
        onStarted()
    }
    var pending = 3
    function done() {
        pending -= 1
        if (pending <= 0) {
            setVisible(true)
            if (onFinished) {
                onFinished()
            }
        }
    }

    directApiAsync(
        "search",
        { query: String(query), type: "1", limit: Number(limit) },
        function(songsData) {
            if (token !== _activeSearchToken) {
                songsLoaderRef.running = false
                done()
                return
            }
            if (songsData && songsData.result && songsData.result.songs) {
                for (var i = 0; i < songsData.result.songs.length; i++) {
                    var song = songsData.result.songs[i];
                    songsModelRef.append({
                        'id': song.id,
                        'name': song.name,
                        'album_id': song.album.id,
                        'album': song.album.name,
                        'artist_id': song.artists[0].id,
                        'artist': song.artists[0].name,
                        'duration': song.duration,
                        'image': resolveSongCover(song),
                        'source': "netease"
                    });
                }
            }
            songsLoaderRef.running = false
            done()
        },
        function(err) {
            if (token !== _activeSearchToken) {
                songsLoaderRef.running = false
                done()
                return
            }
            console.log(err)
            songsLoaderRef.running = false
            done()
        }
    )

    directApiAsync(
        "search",
        { query: String(query), type: "10", limit: Number(limit) },
        function(albumsData) {
            if (token !== _activeSearchToken) {
                albumsLoaderRef.running = false
                done()
                return
            }
            if (albumsData && albumsData.result && albumsData.result.albums) {
                for (var j = 0; j < albumsData.result.albums.length; j++) {
                    var album = albumsData.result.albums[j];
                    var date = new Date(album.publishTime);
                    var release_date = formatDate(date);
                    albumsModelRef.append({
                        'id': album.id,
                        'name': album.name,
                        'artist': album.artist.name,
                        'date': release_date,
                        'size': album.size,
                        'image': resolveAlbumCover(album),
                        'big_image': resolveAlbumCover(album),
                        'source': "netease"
                    });
                }
            }
            albumsLoaderRef.running = false
            done()
        },
        function(err) {
            if (token !== _activeSearchToken) {
                albumsLoaderRef.running = false
                done()
                return
            }
            console.log(err)
            albumsLoaderRef.running = false
            done()
        }
    )

    directApiAsync(
        "search",
        { query: String(query), type: "100", limit: Number(limit) },
        function(artistsData) {
            if (token !== _activeSearchToken) {
                artistsLoaderRef.running = false
                done()
                return
            }
            if (artistsData && artistsData.result && artistsData.result.artists) {
                for (var k = 0; k < artistsData.result.artists.length; k++) {
                    var artist = artistsData.result.artists[k];
                    var image = "../graphics/default.png";
                    var bigimage = "../graphics/default.png";
                    if (artist.picUrl != null) {
                        image = artist.picUrl + "?param=200y200";
                        bigimage = artist.picUrl;
                    }
                    artistsModelRef.append({
                        'id': artist.id,
                        'name': artist.name,
                        'image': image,
                        'big_image': bigimage,
                        'source': "netease"
                    });
                }
            }
            artistsLoaderRef.running = false
            done()
        },
        function(err) {
            if (token !== _activeSearchToken) {
                artistsLoaderRef.running = false
                done()
                return
            }
            console.log(err)
            artistsLoaderRef.running = false
            done()
        }
    )
}

function getNewAlbums(limit, context) {
    var ctx = context || {}
    var errorRef = ctx.errorItem || new_albums_error
    var albumsModelRef = ctx.model || newAlbumsModel
    var loaderRef = ctx.loader || new_albums_loader

    errorRef.visible = false;
    albumsModelRef.clear();
    loaderRef.running = true;
    directApiAsync(
        "getNewAlbums",
        { limit: Number(limit) },
        function(data) {
        if (data && data.albums) {
            for (var i = 0; i < data.albums.length; i++) {
                var album = data.albums[i];
                var date = new Date(album.publishTime);
                var release_date = formatDate(date);
                albumsModelRef.append({
                    'id': album.id,
                    'name': album.name,
                    'artist': album.artist.name,
                    'date': release_date,
                    'image': resolveAlbumCover(album),
                    'big_image': resolveAlbumCover(album),
                    'source': "netease"
                });
            }
        } else {
            errorRef.visible = true
        }
        loaderRef.running = false
    },
    function(e) {
        console.log(e)
        errorRef.visible = true
        loaderRef.running = false
    }
    )
}

function getTopArtists(limit, context) {
    var ctx = context || {}
    var errorRef = ctx.errorItem || top_artists_error
    var artistsModelRef = ctx.model || artistsModel
    var loaderRef = ctx.loader || top_artists_loader

    errorRef.visible = false;
    artistsModelRef.clear();
    loaderRef.running = true;
    directApiAsync(
        "getTopArtists",
        { limit: Number(limit) },
        function(data) {
        if (data && data.artists) {
            for (var i = 0; i < data.artists.length; i++) {
                var artist = data.artists[i];
                artistsModelRef.append({
                    'id': artist.id,
                    'name': artist.name,
                    'image': artist.picUrl + '?param=200y200',
                    'big_image': artist.picUrl,
                    'source': "netease"
                })
            }
        } else {
            errorRef.visible = true
        }
        loaderRef.running = false
    },
    function(e) {
        console.log(e)
        errorRef.visible = true
        loaderRef.running = false
    }
    )
}

function getArtistTopSongs(id, context) {
    var ctx = context || {}
    var setPageTitle = ctx.setPageTitle || function(title) {
        artistPage.title = title
        artistPage.header.title = title
    }
    var setPhoto = ctx.setPhoto || function(source) {
        photo.source = source
    }
    var setVisible = ctx.setVisible || is_visible
    var songsModelRef = ctx.songsModel || songsModel
    var songsLoaderRef = ctx.songsLoader || artist_songs_loader

    setPageTitle(i18n.tr("Artist"))
    setPhoto("../graphics/default.png")
    setVisible(false)
    songsModelRef.clear()
    songsLoaderRef.running = true
    directApiAsync(
        "getArtistTopSongs",
        { id: String(id) },
        function(data) {
        if (data && data.hotSongs) {
            for (var i = 0; i < data.hotSongs.length; i++) {
                var song = data.hotSongs[i];
                songsModelRef.append({
                    'id': song.id,
                    'name': song.name,
                    'album_id': song.album.id,
                    'album': song.album.name,
                    'artist_id': song.artists[0].id,
                    'artist': song.artists[0].name,
                    'duration': song.duration,
                    'image': resolveSongCover(song),
                    'source': "netease"
                })
            }
        }
        songsLoaderRef.running = false
    },
    function(e) {
        console.log(e)
        songsLoaderRef.running = false
    }
    )
}

function getArtistAlbums(id, context) {
    var ctx = context || {}
    var albumsModelRef = ctx.albumsModel || albumsModel
    var albumsLoaderRef = ctx.albumsLoader || artist_albums_loader
    var setPhoto = ctx.setPhoto || function(source) {
        photo.source = source
    }
    var setPageTitle = ctx.setPageTitle || function(title) {
        artistPage.title = title
        artistPage.header.title = title
    }
    var setVisible = ctx.setVisible || is_visible

    albumsModelRef.clear()
    albumsLoaderRef.running = true
    directApiAsync(
        "getArtistAlbums",
        { id: String(id) },
        function(data) {
        if (data) {
            setPhoto(data.artist ? data.artist.picUrl : "../graphics/default.png")
            setPageTitle(data.artist ? data.artist.name : i18n.tr("Artist"))
            if (data.hotAlbums) {
                for (var i = 0; i < data.hotAlbums.length; i++) {
                    var album = data.hotAlbums[i];
                    var date = new Date(album.publishTime);
                    var release_date = formatDate(date);
                    albumsModelRef.append({
                        'id': album.id,
                        'name': album.name,
                        'artist': data.artist ? data.artist.name : "",
                        'date': release_date,
                        'size': album.size,
                        'image': resolveAlbumCover(album),
                        'big_image': resolveAlbumCover(album),
                        'source': "netease"
                    })
                }
            }
        }
        albumsLoaderRef.running = false
        setVisible(true)
    },
    function(e) {
        console.log(e)
        albumsLoaderRef.running = false
        setVisible(true)
    }
    )
}

function getAlbumDetail(id, context) {
    var ctx = context || {}
    var setPhoto = ctx.setPhoto || function(source) {
        photo.source = source
    }
    var setAlbumTitle = ctx.setAlbumTitle || function(title) {
        lbl_album_title.text = title
    }
    var setAlbumDate = ctx.setAlbumDate || function(dateText) {
        lbl_album_date.text = dateText
    }
    var setVisible = ctx.setVisible || is_visible
    var albumModelRef = ctx.albumModel || albumModel
    var albumLoaderRef = ctx.loader || album_loader

    setPhoto("../graphics/default.png")
    setAlbumTitle("")
    setVisible(false)
    albumModelRef.clear()
    albumLoaderRef.running = true
    directApiAsync(
        "getAlbumDetail",
        { id: String(id) },
        function(data) {
        if (data && data.album) {
            setPhoto(data.album.picUrl)
            setAlbumTitle(data.album.name)
            var date = new Date(data.album.publishTime);
            var release_date = formatDate(date);
            setAlbumDate(i18n.tr('Release Date:') + ' ' + release_date)
            for (var i = 0; i < data.album.songs.length; i++) {
                var song = data.album.songs[i];
                albumModelRef.append({
                    'id': song.id,
                    'name': song.name,
                    'album_id': song.album.id,
                    'album': song.album.name,
                    'artist_id': song.artists[0].id,
                    'artist': song.artists[0].name,
                    'duration': song.duration,
                    'image': resolveSongCover(song),
                    'source': "netease"
                })
            }
        }
        albumLoaderRef.running = false
        setVisible(true)
    },
    function(e) {
        console.log(e)
        albumLoaderRef.running = false
        setVisible(true)
    }
    )
}

function getSongDetail(id, context) {
    var ctx = context || {}
    var setPageTitle = ctx.setPageTitle || function(title) {
        playingPage.title = title
        playingPage.header.title = title
    }
    var setArtistText = ctx.setArtistText || function(text) {
        lbl_artistaDetalle.text = text
    }
    var setAlbumText = ctx.setAlbumText || function(text) {
        lbl_albumDetalle.text = text
    }
    var setAlbumImage = ctx.setAlbumImage || function(source) {
        albumImage.source = source
    }
    var setSeekMaximum = ctx.setSeekMaximum || function(value) {
        seek.maximumValue = value
    }
    var fallbackDuration = ctx.fallbackDuration || 0
    var setCurrentId = ctx.setCurrentId || function(value) {
        current_id = value
    }
    var updateToolbar = ctx.updateToolbar || function(name, artist, image) {
        player_toolbar.cargar(name, artist, image)
    }
    var onSongResolved = ctx.onSongResolved || null
    var lyricsEnabled = ctx.lyricsEnabled
    if (lyricsEnabled === undefined) {
        lyricsEnabled = playing_page.settings.lyrics
    }
    var lyricContext = ctx.lyricContext || null
    var playingLoaderRef = ctx.loader || playing_loader

    setPageTitle(i18n.tr("Now Playing"))
    setArtistText("")
    setAlbumText("")
    setAlbumImage("../graphics/default.png")
    if (lyricsEnabled) {
        getLyric(id, lyricContext)
    }
    playingLoaderRef.running = true
    directApiAsync(
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
            var cover = (picId !== "" && picId !== "0") ? (api2 + "pic/" + picId + "?size=300") : "../graphics/default.png"
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
        playingLoaderRef.running = false
    },
    function(e) {
        console.log(e)
        playingLoaderRef.running = false
    }
    )
}

function stream(id) {
    var cn = new XMLHttpRequest();
    cn.open('GET', server + '?stream=' + id + '&quality=' + (cloudMusic && cloudMusic.settings ? cloudMusic.settings.streaming_quality : "96"));
    cn.onreadystatechange = function () {
        if (cn.readyState == XMLHttpRequest.DONE && cn.status == 200) {
            var data = cn.responseText;
            data = JSON.parse(data);
            media_player.source = data.mp3;
            media_player.play();
        }
    };
    cn.send();
}

function download(id, name, nameArt) {
    var cn = new XMLHttpRequest();
    cn.open('GET', api2 + 'url/' + id + '/' + cloudMusic.settings.download_quality);
    cn.onreadystatechange = function () {
        if (cn.readyState == XMLHttpRequest.DONE) {
            if (cn.status == 200) {
                var data = cn.responseText;
                console.log("Download API response: " + data)
                try {
                    data = JSON.parse(data);
                    if (!data.url) {
                        console.error("Download error: API response has no URL field")
                        return
                    }
                    console.log("Starting download from URL: " + data.url)
                    var singleDownload = downloadComponent.createObject(cloudMusic, {
                        "name": name,
                        "nameArtist": nameArt.replace(" ", "_")
                    });
                    if (!singleDownload) {
                        console.error("Download error: failed to create SingleDownload component")
                        return
                    }
                    console.log("Calling download with: " + data.url)
                    singleDownload.download(data.url);
                } catch (e) {
                    console.error("Download error: " + e)
                }
            } else {
                console.error("Download API error: status " + cn.status)
            }
        }
    };
    cn.send();
}

//Downloads
function adddownloads() {
    var counter = 0;
    var helper = 0;
    var xhr = [];
    for (var i = 0; i < modelo_playlist.count; i++) {
        (function (i) {
            if (!modelo_playlist.get(i).local) {
                helper = helper + 1;
                var id = modelo_playlist.get(i).songId;
                var quality = settings.download_quality;
                var title = modelo_playlist.get(i).songName;
                xhr[i] = new XMLHttpRequest();
                var url = server + '?offline=' + id + '&quality=' + quality;
                xhr[i].open("GET", url, true);
                xhr[i].onreadystatechange = function () {
                    if (xhr[i].readyState == 4 && xhr[i].status == 200) {
                        counter = counter + 1;
                        var data = xhr[i].responseText;
                        data = JSON.parse(data);
                        downloadqueue.append({
                            songId: id,
                            songName: title,
                            url: data.mp3,
                            img: data.img
                        });
                        if (counter == helper) {
                            downloadSong(0);
                            downloadImage(0);
                        }
                    }
                };
                xhr[i].send();
            }
        })(i);
    }
}

function downloadImage(index) {
    imageDownloader.songId = downloadqueue.get(index).songId;
    imageDownloader.download(downloadqueue.get(index).img);
}

function downloadSong(index) {
    //progreso.visible=true;
    musicDownloader.songId = downloadqueue.get(index).songId;
    musicDownloader.songName = downloadqueue.get(index).songName;
    musicDownloader.download(downloadqueue.get(index).url);
}

//Lyrics
function getLyric(id, context) {
    var ctx = context || {}
    var lyricModelRef = ctx.lyricModel || playing_page.model_lyric
    var setCurrentLyric = ctx.setCurrentLyric || function(text) {
        lbl_lyric.text = text
    }
    var setNextLyric = ctx.setNextLyric || function(text) {
        lbl_next.text = text
    }

    lyricModelRef.clear()
    setCurrentLyric("")
    setNextLyric("")
    directApiAsync(
        "lyric",
        { id: String(id) },
        function(data) {
        if (data) {
            parseLyric(data.lyric, {
                lyricModel: lyricModelRef,
                setCurrentLyric: setCurrentLyric,
                setNextLyric: setNextLyric
            })
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

function parseLyric(lyric, context) {
    var ctx = context || {}
    var lyricModelRef = ctx.lyricModel || playing_page.model_lyric
    var setCurrentLyric = ctx.setCurrentLyric || function(text) {
        lbl_lyric.text = text
    }
    var setNextLyric = ctx.setNextLyric || function(text) {
        lbl_next.text = text
    }

    if (!lyric || typeof lyric !== "string") {
        lyricModelRef.clear()
        setCurrentLyric(i18n.tr("No lyrics available"))
        setNextLyric("")
        return
    }
    var lines = lyric.split(/\r\n|\n/);
    next(lines, {
        lyricModel: lyricModelRef
    })
}

function next(lines, context) {
    var ctx = context || {}
    var lyricModelRef = ctx.lyricModel || playing_page.model_lyric
    var lyrics = [];
    var tim = [];
    var line = " ";
    for (var i = 0; i < lines.length; i++) {
        if (lines[i].search(/^(\[)(\d*)(:)(.*)(\])(.*)/i) >= 0) {
            line = lines[i].match(/^(\[)(\d*)(:)(.*)(\])(.*)/i);
            tim[i] = (parseInt(line[2]) * 60) + parseInt(line[4]); // will give seconds
            lyrics[i] = line[6]; //will give lyrics
            lyricModelRef.append({
                'position': tim[i] * 1000,
                'line': lyrics[i]
            });
        }
    }
}

// Converts an duration in ms to a formated string ("minutes:seconds")
function durationToString(duration) {
    var value = Number(duration)
    if (!isFinite(value) || value < 0) {
        value = 0
    }
    var totalSeconds = Math.floor(value / 1000)
    var minutes = Math.floor(totalSeconds / 60)
    var seconds = totalSeconds % 60
    return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds);
}

function formatDate(date) {
    var y = date.getFullYear();
    var m = date.getMonth() + 1;
    var d = date.getDate();
    return y + '-' + (m < 10 ? ('0' + m) : m) + '-' + (d < 10 ? ('0' + d) : d);
}

function splitFileName(urlFile) {
    if (!urlFile || typeof urlFile !== "string") {
        return ["", "download.mp3"]
    }
    var list = urlFile.split("/")
    var nameFile = list[list.length - 1]
    var localDirectory = urlFile.split(nameFile)
    var listFin = []
    listFin[0] = localDirectory[0]
    listFin[1] = nameFile.replace(/%/g, "%25")
    return listFin
}
