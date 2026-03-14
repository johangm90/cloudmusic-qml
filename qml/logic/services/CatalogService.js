.import "../CloudBridge.js" as CloudBridge
.import "../Database.js" as Db

// ── Provider helper ───────────────────────────────────────────────────────────

/**
 * Returns the currently active provider ("netease" or "youtube").
 * Falls back to "netease" when no setting has been stored yet.
 */
function getActiveProvider() {
    var v = Db.getSetting("active_provider")
    return (v === "youtube") ? "youtube" : "netease"
}

// ── YouTube Music normalization ───────────────────────────────────────────────

/**
 * Normalises a raw YouTube Music song object returned by the
 * ytmusic_search / ytmusic_song actions into the same shape used
 * everywhere else in the QML layer:
 *   { id, name, artist_id, artist, album_id, album, duration, image, big_image, source }
 */
function normalizeYoutubeSong(raw) {
    if (!raw) {
        return null
    }
    var id     = raw.id     || ""
    var name   = raw.title  || raw.name  || ""
    var artist = raw.artist || ""
    var album  = raw.album  || ""
    var image  = raw.img    || raw.image || "../graphics/default.png"
    var duration = raw.duration || 0
    if (!id) {
        return null
    }
    return {
        id:        id,
        name:      name,
        artist_id: 0,
        artist:    artist,
        album_id:  0,
        album:     album,
        duration:  duration,
        image:     image,
        big_image: image,
        source:    "youtube"
    }
}

// ── Search ────────────────────────────────────────────────────────────────────

/**
 * Searches the active provider for songs matching `query`.
 *
 * For YouTube Music the action "ytmusic_search" is used; the backend
 * returns a bare JSON array of song objects.
 *
 * For NetEase the existing "search" CloudBridge action is used unchanged.
 *
 * @param {string}   query          Search string
 * @param {number}   limit          Maximum number of results
 * @param {object}   context        Caller-supplied context object:
 *   - songsModel     {ListModel}   Model to append results to
 *   - songsLoader    {object}      ActivityIndicator (.running)
 *   - onFinished     {function?}   Called after success or error
 * @param {string}   [provider]     Override active provider (optional)
 */
function search(query, limit, context, provider) {
    var ctx           = context || {}
    var songsModelRef = ctx.songsModel  || null
    var songsLoaderRef= ctx.songsLoader || null
    var onFinished    = ctx.onFinished  || null

    if (!songsModelRef || !songsLoaderRef) {
        return
    }

    var activeProvider = provider || getActiveProvider()

    songsModelRef.clear()
    songsLoaderRef.running = true

    if (activeProvider === "youtube") {
        // ── YouTube Music path ────────────────────────────────────────────────
        CloudBridge.directApiAsync(
            "ytmusic_search",
            { q: String(query), limit: Number(limit) || 20 },
            function(data) {
                // data is a bare JSON array from innertube_search
                if (data && Array.isArray(data)) {
                    for (var i = 0; i < data.length; i++) {
                        var song = normalizeYoutubeSong(data[i])
                        if (song) {
                            songsModelRef.append(song)
                        }
                    }
                }
                songsLoaderRef.running = false
                if (onFinished) {
                    onFinished()
                }
            },
            function(err) {
                console.log("CatalogService.search(youtube) error: " + err)
                songsLoaderRef.running = false
                if (onFinished) {
                    onFinished()
                }
            }
        )
    } else {
        // ── NetEase path (unchanged) ──────────────────────────────────────────
        CloudBridge.directApiAsync(
            "search",
            { query: String(query), type: "1", limit: Number(limit) },
            function(songsData) {
                if (songsData && songsData.songs) {
                    for (var j = 0; j < songsData.songs.length; j++) {
                        songsModelRef.append(songsData.songs[j])
                    }
                }
                songsLoaderRef.running = false
                if (onFinished) {
                    onFinished()
                }
            },
            function(err) {
                console.log("CatalogService.search(netease) error: " + err)
                songsLoaderRef.running = false
                if (onFinished) {
                    onFinished()
                }
            }
        )
    }
}

/**
 * Fetches details for a single song, routing to the correct provider based
 * on the `source` field of the song object (or the active provider when
 * source is not present).
 *
 * @param {string|object} songOrId    Song ID (string/number) or a song object
 *                                    that carries a `source` field.
 * @param {function}      onSuccess   Called with a normalised song object.
 * @param {function}      [onError]   Called with an error string.
 */
function getSong(songOrId, onSuccess, onError) {
    var id, source
    if (songOrId && typeof songOrId === "object") {
        id     = songOrId.id || songOrId.song_id || songOrId.sid || ""
        source = songOrId.source || "netease"
    } else {
        id     = String(songOrId || "")
        source = "netease"
    }

    if (!id) {
        if (onError) {
            onError("getSong: missing id")
        }
        return
    }

    if (source === "youtube") {
        // ── YouTube Music path ────────────────────────────────────────────────
        CloudBridge.directApiAsync(
            "ytmusic_song",
            { id: String(id) },
            function(data) {
                var song = normalizeYoutubeSong(data)
                if (!song) {
                    if (onError) {
                        onError("getSong(youtube): invalid response")
                    }
                    return
                }
                if (onSuccess) {
                    onSuccess(song)
                }
            },
            function(err) {
                console.log("CatalogService.getSong(youtube) error: " + err)
                if (onError) {
                    onError(err)
                }
            }
        )
    } else {
        // ── NetEase path (unchanged) ──────────────────────────────────────────
        CloudBridge.directApiAsync(
            "songDetail",
            { id: String(id) },
            function(data) {
                var song = data && data.song ? data.song : data
                if (onSuccess) {
                    onSuccess(song)
                }
            },
            function(err) {
                console.log("CatalogService.getSong(netease) error: " + err)
                if (onError) {
                    onError(err)
                }
            }
        )
    }
}

// ── Unchanged NetEase catalog functions ───────────────────────────────────────

function getArtistTopSongs(deps, id, context) {
    var ctx = context || {}
    var setPageTitle = ctx.setPageTitle || function() {}
    var setPhoto = ctx.setPhoto || function() {}
    var setVisible = ctx.setVisible || function() {}
    var songsModelRef = ctx.songsModel || null
    var songsLoaderRef = ctx.songsLoader || null
    if (!songsModelRef || !songsLoaderRef) {
        return
    }

    setPageTitle(i18n.tr("Artist"))
    setPhoto("../graphics/default.png")
    setVisible(false)
    songsModelRef.clear()
    songsLoaderRef.running = true
    CloudBridge.directApiAsync(
        "getArtistTopSongs",
        { id: String(id) },
        function(data) {
            if (data && data.hotSongs) {
                for (var i = 0; i < data.hotSongs.length; i++) {
                    var song = data.hotSongs[i]
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
        },
        function(e) {
            console.log(e)
            songsLoaderRef.running = false
        }
    )
}

function getArtistAlbums(deps, id, context) {
    var ctx = context || {}
    var albumsModelRef = ctx.albumsModel || null
    var albumsLoaderRef = ctx.albumsLoader || null
    var setPhoto = ctx.setPhoto || function() {}
    var setPageTitle = ctx.setPageTitle || function() {}
    var setVisible = ctx.setVisible || function() {}
    if (!albumsModelRef || !albumsLoaderRef) {
        return
    }

    albumsModelRef.clear()
    albumsLoaderRef.running = true
    CloudBridge.directApiAsync(
        "getArtistAlbums",
        { id: String(id) },
        function(data) {
            if (data) {
                setPhoto(data.artist ? data.artist.picUrl : "../graphics/default.png")
                setPageTitle(data.artist ? data.artist.name : i18n.tr("Artist"))
                if (data.hotAlbums) {
                    for (var i = 0; i < data.hotAlbums.length; i++) {
                        var album = data.hotAlbums[i]
                        var date = new Date(album.publishTime)
                        var releaseDate = deps.formatDate(date)
                        albumsModelRef.append({
                            id: album.id,
                            name: album.name,
                            artist: data.artist ? data.artist.name : "",
                            date: releaseDate,
                            size: album.size,
                            image: deps.resolveAlbumCover(album),
                            big_image: deps.resolveAlbumCover(album),
                            source: "netease"
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

function getAlbumDetail(deps, id, context) {
    var ctx = context || {}
    var setPhoto = ctx.setPhoto || function() {}
    var setAlbumTitle = ctx.setAlbumTitle || function() {}
    var setAlbumDate = ctx.setAlbumDate || function() {}
    var setVisible = ctx.setVisible || function() {}
    var albumModelRef = ctx.albumModel || null
    var albumLoaderRef = ctx.loader || null
    if (!albumModelRef || !albumLoaderRef) {
        return
    }

    setPhoto("../graphics/default.png")
    setAlbumTitle("")
    setVisible(false)
    albumModelRef.clear()
    albumLoaderRef.running = true
    CloudBridge.directApiAsync(
        "getAlbumDetail",
        { id: String(id) },
        function(data) {
            if (data && data.album) {
                setPhoto(data.album.picUrl)
                setAlbumTitle(data.album.name)
                var date = new Date(data.album.publishTime)
                var releaseDate = deps.formatDate(date)
                setAlbumDate(i18n.tr("Release Date:") + " " + releaseDate)
                for (var i = 0; i < data.album.songs.length; i++) {
                    var song = data.album.songs[i]
                    albumModelRef.append({
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
