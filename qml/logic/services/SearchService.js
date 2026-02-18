.import "../CloudBridge.js" as CloudBridge
function apiSearch(deps, query, type, limit, context) {
    var token = deps.nextSearchToken()
    var ctx = context || {}
    var setVisible = ctx.setVisible || function() {}
    var onStarted = ctx.onStarted || null
    var onFinished = ctx.onFinished || null
    var songsModelRef = ctx.songsModel || null
    var albumsModelRef = ctx.albumsModel || null
    var artistsModelRef = ctx.artistsModel || null
    var songsLoaderRef = ctx.songsLoader || null
    var albumsLoaderRef = ctx.albumsLoader || null
    var artistsLoaderRef = ctx.artistsLoader || null

    if (!songsModelRef || !albumsModelRef || !artistsModelRef || !songsLoaderRef || !albumsLoaderRef || !artistsLoaderRef) {
        return
    }

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

    CloudBridge.directApiAsync(
        "search",
        { query: String(query), type: "1", limit: Number(limit) },
        function(songsData) {
            if (!deps.isTokenActive(token)) {
                songsLoaderRef.running = false
                done()
                return
            }
            if (songsData && songsData.result && songsData.result.songs) {
                for (var i = 0; i < songsData.result.songs.length; i++) {
                    var song = songsData.result.songs[i]
                    songsModelRef.append({
                        id: song.id,
                        name: song.name,
                        album_id: song.album.id,
                        album: song.album.name,
                        artist_id: song.artists[0].id,
                        artist: song.artists[0].name,
                        duration: song.duration,
                        image: deps.resolveSongCover(song),
                        source: "netease"
                    })
                }
            }
            songsLoaderRef.running = false
            done()
        },
        function(err) {
            if (!deps.isTokenActive(token)) {
                songsLoaderRef.running = false
                done()
                return
            }
            console.log(err)
            songsLoaderRef.running = false
            done()
        }
    )

    CloudBridge.directApiAsync(
        "search",
        { query: String(query), type: "10", limit: Number(limit) },
        function(albumsData) {
            if (!deps.isTokenActive(token)) {
                albumsLoaderRef.running = false
                done()
                return
            }
            if (albumsData && albumsData.result && albumsData.result.albums) {
                for (var j = 0; j < albumsData.result.albums.length; j++) {
                    var album = albumsData.result.albums[j]
                    var date = new Date(album.publishTime)
                    var releaseDate = deps.formatDate(date)
                    albumsModelRef.append({
                        id: album.id,
                        name: album.name,
                        artist: album.artist.name,
                        date: releaseDate,
                        size: album.size,
                        image: deps.resolveAlbumCover(album),
                        big_image: deps.resolveAlbumCover(album),
                        source: "netease"
                    })
                }
            }
            albumsLoaderRef.running = false
            done()
        },
        function(err) {
            if (!deps.isTokenActive(token)) {
                albumsLoaderRef.running = false
                done()
                return
            }
            console.log(err)
            albumsLoaderRef.running = false
            done()
        }
    )

    CloudBridge.directApiAsync(
        "search",
        { query: String(query), type: "100", limit: Number(limit) },
        function(artistsData) {
            if (!deps.isTokenActive(token)) {
                artistsLoaderRef.running = false
                done()
                return
            }
            if (artistsData && artistsData.result && artistsData.result.artists) {
                for (var k = 0; k < artistsData.result.artists.length; k++) {
                    var artist = artistsData.result.artists[k]
                    var image = "../graphics/default.png"
                    var bigimage = "../graphics/default.png"
                    if (artist.picUrl != null) {
                        image = artist.picUrl + "?param=200y200"
                        bigimage = artist.picUrl
                    }
                    artistsModelRef.append({
                        id: artist.id,
                        name: artist.name,
                        image: image,
                        big_image: bigimage,
                        source: "netease"
                    })
                }
            }
            artistsLoaderRef.running = false
            done()
        },
        function(err) {
            if (!deps.isTokenActive(token)) {
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

function getNewAlbums(deps, limit, context) {
    var ctx = context || {}
    var errorRef = ctx.errorItem || null
    var albumsModelRef = ctx.model || null
    var loaderRef = ctx.loader || null
    if (!errorRef || !albumsModelRef || !loaderRef) {
        return
    }

    errorRef.visible = false
    albumsModelRef.clear()
    loaderRef.running = true
    CloudBridge.directApiAsync(
        "getNewAlbums",
        { limit: Number(limit) },
        function(data) {
            if (data && data.albums) {
                for (var i = 0; i < data.albums.length; i++) {
                    var album = data.albums[i]
                    var date = new Date(album.publishTime)
                    var releaseDate = deps.formatDate(date)
                    albumsModelRef.append({
                        id: album.id,
                        name: album.name,
                        artist: album.artist.name,
                        date: releaseDate,
                        image: deps.resolveAlbumCover(album),
                        big_image: deps.resolveAlbumCover(album),
                        source: "netease"
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

function getTopArtists(deps, limit, context) {
    var ctx = context || {}
    var errorRef = ctx.errorItem || null
    var artistsModelRef = ctx.model || null
    var loaderRef = ctx.loader || null
    if (!errorRef || !artistsModelRef || !loaderRef) {
        return
    }

    errorRef.visible = false
    artistsModelRef.clear()
    loaderRef.running = true
    CloudBridge.directApiAsync(
        "getTopArtists",
        { limit: Number(limit) },
        function(data) {
            if (data && data.artists) {
                for (var i = 0; i < data.artists.length; i++) {
                    var artist = data.artists[i]
                    artistsModelRef.append({
                        id: artist.id,
                        name: artist.name,
                        image: artist.picUrl + "?param=200y200",
                        big_image: artist.picUrl,
                        source: "netease"
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
