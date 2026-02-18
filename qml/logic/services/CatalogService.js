.import "../CloudBridge.js" as CloudBridge
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
