import QtQuick 2.12
import "../RequestBus.js" as RequestBus

Item {
    id: viewModel

    visible: false
    width: 0
    height: 0

    property var appRoot: null
    property bool loading: false
    property bool loadingSongs: false
    property bool loadingAlbums: false
    property bool loadingArtists: false
    property bool resultsReady: false
    property string error: ""
    property int pendingRequests: 0
    property string requestContext: "search_vm_" + String(Date.now())

    property alias songsModel: songs
    property alias albumsModel: albums
    property alias artistsModel: artists

    signal searchFinished()

    ListModel { id: songs }
    ListModel { id: albums }
    ListModel { id: artists }

    Connections {
        target: viewModel.appRoot && viewModel.appRoot.cloudApi ? viewModel.appRoot.cloudApi : null
        onRequestFinished: function(requestId, ok, payloadJson, error) {
            RequestBus.dispatch(requestId, ok, payloadJson, error)
        }
    }

    function formatDate(date) {
        var y = date.getFullYear()
        var m = date.getMonth() + 1
        var d = date.getDate()
        return y + "-" + (m < 10 ? ("0" + m) : m) + "-" + (d < 10 ? ("0" + d) : d)
    }

    function clearResults() {
        songs.clear()
        albums.clear()
        artists.clear()
    }

    function finishRequest(kind) {
        if (kind === "songs") {
            loadingSongs = false
        } else if (kind === "albums") {
            loadingAlbums = false
        } else if (kind === "artists") {
            loadingArtists = false
        }

        pendingRequests -= 1
        if (pendingRequests <= 0) {
            pendingRequests = 0
            loading = false
            resultsReady = true
            searchFinished()
        }
    }

    function search(query, limit) {
        if (!appRoot || !appRoot.cloudApi) {
            error = "cloud api bridge unavailable"
            loading = false
            return false
        }

        RequestBus.cancelContext(requestContext)
        clearResults()
        error = ""
        resultsReady = false
        loading = true
        loadingSongs = true
        loadingAlbums = true
        loadingArtists = true
        pendingRequests = 3

        var songsRequestId = RequestBus.createId("search_songs")
        var albumsRequestId = RequestBus.createId("search_albums")
        var artistsRequestId = RequestBus.createId("search_artists")

        RequestBus.registerRequest(songsRequestId, {
            context: requestContext,
            onSuccess: function(data) {
                if (data && data.songs) {
                    for (var i = 0; i < data.songs.length; i++) {
                        songs.append(data.songs[i])
                    }
                }
            },
            onError: function(err) {
                error = String(err)
                console.log(err)
            },
            onFinally: function() {
                finishRequest("songs")
            }
        })

        RequestBus.registerRequest(albumsRequestId, {
            context: requestContext,
            onSuccess: function(data) {
                if (data && data.albums) {
                    for (var j = 0; j < data.albums.length; j++) {
                        var album = data.albums[j]
                        var publishTime = album.publish_time ? album.publish_time : 0
                        albums.append({
                            id: album.id,
                            name: album.name,
                            artist: album.artist,
                            date: formatDate(new Date(publishTime)),
                            size: album.size,
                            image: album.image ? album.image : "../graphics/default.png",
                            big_image: album.big_image ? album.big_image : "../graphics/default.png",
                            source: "netease"
                        })
                    }
                }
            },
            onError: function(err) {
                error = String(err)
                console.log(err)
            },
            onFinally: function() {
                finishRequest("albums")
            }
        })

        RequestBus.registerRequest(artistsRequestId, {
            context: requestContext,
            onSuccess: function(data) {
                if (data && data.artists) {
                    for (var k = 0; k < data.artists.length; k++) {
                        artists.append(data.artists[k])
                    }
                }
            },
            onError: function(err) {
                error = String(err)
                console.log(err)
            },
            onFinally: function() {
                finishRequest("artists")
            }
        })

        appRoot.cloudApi.searchAsync(String(query), "1", Number(limit), songsRequestId)
        appRoot.cloudApi.searchAsync(String(query), "10", Number(limit), albumsRequestId)
        appRoot.cloudApi.searchAsync(String(query), "100", Number(limit), artistsRequestId)
        return true
    }

    Component.onDestruction: RequestBus.cancelContext(requestContext)
}
