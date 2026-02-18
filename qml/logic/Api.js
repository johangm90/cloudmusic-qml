var server = "https://vulgry.innves.com/rapsody/api.php";
var api2 = "https://cloudmusicapi.nubit.io/netease/";

function apiSearch(query, type, limit, context) {
    var ctx = context || {}
    var setVisible = ctx.setVisible || is_visible
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
    var song_type = '1';
    var album_type = '10';
    var artist_type = '100';
    var cn1 = new XMLHttpRequest();
    var searchSongsUrl = server + '?action=search&query=' + query + '&type=' + song_type + '&limit=' + limit;
    cn1.open("GET", searchSongsUrl);
    cn1.onreadystatechange = function () {
        if (cn1.readyState == XMLHttpRequest.DONE && cn1.status == 200) {
            var data = cn1.responseText;
            data = JSON.parse(data);
            for (var i = 0; i < data.result.songs.length; i++) {
                var song = data.result.songs[i];
                songsModelRef.append({
                    'id': song.id,
                    'name': song.name,
                    'album_id': song.album.id,
                    'album': song.album.name,
                    'artist_id': song.artists[0].id,
                    'artist': song.artists[0].name,
                    'duration': song.duration
                });
            }
            songsLoaderRef.running = false;
        } else {
            songsLoaderRef.running = false;
        }
    };
    cn1.send();
    albumsLoaderRef.running = true;
    var cn2 = new XMLHttpRequest();
    var searchAlbumsUrl = server + '?action=search&query=' + query + '&type=' + album_type + '&limit=' + limit;
    cn2.open("GET", searchAlbumsUrl);
    cn2.onreadystatechange = function () {
        if (cn2.readyState == XMLHttpRequest.DONE && cn2.status == 200) {
            var data = cn2.responseText;
            data = JSON.parse(data);
            for (var i = 0; i < data.result.albums.length; i++) {
                var album = data.result.albums[i];
                var date = new Date(album.publishTime);
                var release_date = formatDate(date);
                albumsModelRef.append({
                    'id': album.id,
                    'name': album.name,
                    'artist': album.artist.name,
                    'date': release_date,
                    'size': album.size,
                    'image': album.picUrl + '?param=200y200',
                    'big_image': album.picUrl
                });
            }
            albumsLoaderRef.running = false;
        } else {
            albumsLoaderRef.running = false;
        }
    };
    cn2.send();
    artistsLoaderRef.running = true;
    var cn3 = new XMLHttpRequest();
    var searchArtistsUrl = server + '?action=search&query=' + query + '&type=' + artist_type + '&limit=' + limit;
    cn3.open("GET", searchArtistsUrl);
    cn3.onreadystatechange = function () {
        if (cn3.readyState == XMLHttpRequest.DONE && cn3.status == 200) {
            var data = cn3.responseText;
            data = JSON.parse(data);
            try {
                for (var i = 0; i < data.result.artists.length; i++) {
                    var artist = data.result.artists[i];
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
                        'big_image': bigimage
                    });
                }
                artistsLoaderRef.running = false;
            } catch (e) {
                console.log(e);
            }
            setVisible(true)
        } else {
            artistsLoaderRef.running = false;
        }
    };
    cn3.send();
}

function getNewAlbums(limit, context) {
    var ctx = context || {}
    var errorRef = ctx.errorItem || new_albums_error
    var albumsModelRef = ctx.model || newAlbumsModel
    var loaderRef = ctx.loader || new_albums_loader

    errorRef.visible = false;
    albumsModelRef.clear();
    loaderRef.running = true;
    var cn = new XMLHttpRequest();
    cn.open("GET", server + '?action=getNewAlbums&limit=' + limit);
    cn.onreadystatechange = function () {
        if (cn.readyState == XMLHttpRequest.DONE && cn.status == 200) {
            var data = cn.responseText;
            data = JSON.parse(data);
            try {
                for (var i = 0; i < data.albums.length; i++) {
                    var album = data.albums[i];
                    var date = new Date(album.publishTime);
                    var release_date = formatDate(date);
                    albumsModelRef.append({
                        'id': album.id,
                        'name': album.name,
                        'artist': album.artist.name,
                        'date': release_date,
                        'image': album.picUrl + '?param=200y200',
                        'big_image': album.picUrl
                    });
                }
                loaderRef.running = false;
            } catch (e) {
                console.log(e);
                errorRef.visible = true;
                loaderRef.running = false;
            }
        } else if (cn.readyState == XMLHttpRequest.DONE && cn.status != 200) {
            errorRef.visible = true;
            loaderRef.running = false;
        }
    };
    cn.send();
}

function getTopArtists(limit, context) {
    var ctx = context || {}
    var errorRef = ctx.errorItem || top_artists_error
    var artistsModelRef = ctx.model || artistsModel
    var loaderRef = ctx.loader || top_artists_loader

    errorRef.visible = false;
    artistsModelRef.clear();
    loaderRef.running = true;
    var cn = new XMLHttpRequest();
    var url = server + '?action=getTopArtists&limit=' + limit;
    cn.open("GET", url);
    cn.onreadystatechange = function () {
        if (cn.readyState == XMLHttpRequest.DONE && cn.status == 200) {
            var data = cn.responseText;
            data = JSON.parse(data);
            try {
                for (var i = 0; i < data.artists.length; i++) {
                    var artist = data.artists[i];
                    artistsModelRef.append({
                        'id': artist.id,
                        'name': artist.name,
                        'image': artist.picUrl + '?param=200y200',
                        'big_image': artist.picUrl
                    })
                }
                loaderRef.running = false;
            } catch (e) {
                console.log(e);
                errorRef.visible = true;
                loaderRef.running = false;
            }
        } else if (cn.readyState == XMLHttpRequest.DONE && cn.status != 200) {
            errorRef.visible = true;
            loaderRef.running = false;
        }
    };
    cn.send();
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
    var cn = new XMLHttpRequest();
    var url = server + '?action=getArtistTopSongs&id=' + id;
    cn.open("GET", url);
    cn.onreadystatechange = function () {
        if (cn.readyState == XMLHttpRequest.DONE && cn.status == 200) {
            var data = cn.responseText;
            data = JSON.parse(data);
            try {
                for (var i = 0; i < data.hotSongs.length; i++) {
                    var song = data.hotSongs[i];
                    songsModelRef.append({
                        'id': song.id,
                        'name': song.name,
                        'album_id': song.album.id,
                        'album': song.album.name,
                        'artist_id': song.artists[0].id,
                        'artist': song.artists[0].name,
                        'duration': song.duration
                    })
                }
            } catch (e) {
                console.log(e);
            }
            songsLoaderRef.running = false
        } else {
            songsLoaderRef.running = false
        }
    };
    cn.send();
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
    var cn = new XMLHttpRequest();
    var url = server + '?action=getArtistAlbums&id=' + id;
    cn.open("GET", url);
    cn.onreadystatechange = function () {
        if (cn.readyState == XMLHttpRequest.DONE && cn.status == 200) {
            var data = cn.responseText;
            data = JSON.parse(data);
            try {
                setPhoto(data.artist.picUrl)
                setPageTitle(data.artist.name)
                for (var i = 0; i < data.hotAlbums.length; i++) {
                    var album = data.hotAlbums[i];
                    var date = new Date(album.publishTime);
                    var release_date = formatDate(date);
                    albumsModelRef.append({
                        'id': album.id,
                        'name': album.name,
                        'date': release_date,
                        'size': album.size,
                        'image': album.picUrl + '?param=200y200',
                        'big_image': album.picUrl
                    })
                }
            } catch (e) {
                console.log(e);
            }
            albumsLoaderRef.running = false
            setVisible(true)
        } else {
            albumsLoaderRef.running = false
        }
    }
    cn.send();
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
    var cn = new XMLHttpRequest();
    cn.open("GET", server + '?action=getAlbumDetail&id=' + id);
    cn.onreadystatechange = function () {
        if (cn.readyState == XMLHttpRequest.DONE && cn.status == 200) {
            var data = cn.responseText;
            data = JSON.parse(data);
            try {
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
                        'duration': song.duration
                    })
                }
                albumLoaderRef.running = false
            } catch (e) {
                console.log(e);
            }
            setVisible(true)
        } else {
            albumLoaderRef.running = false
            setVisible(true)
        }
    };
    cn.send();
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
    var setCurrentId = ctx.setCurrentId || function(value) {
        current_id = value
    }
    var updateToolbar = ctx.updateToolbar || function(name, artist, image) {
        player_toolbar.cargar(name, artist, image)
    }
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
    var cn = new XMLHttpRequest();
    var url = server + '?action=getSongDetail&id=' + id;
    cn.open('GET', url);
    cn.onreadystatechange = function () {
        if (cn.readyState == XMLHttpRequest.DONE && cn.status == 200) {
            var data = cn.responseText;
            data = JSON.parse(data);
            try {
                var cover = data.picUrl ? data.picUrl : "../graphics/default.png"
                setPageTitle(data.name)
                setAlbumImage(cover)
                setArtistText(data.artist)
                setAlbumText(data.album)
                setSeekMaximum(data.duration)
                updateToolbar(data.name, data.artist, cover)
                setCurrentId(id)
            } catch (e) {
                console.log(e);
            }
            playingLoaderRef.running = false
        } else {
            playingLoaderRef.running = false
        }
    };
    cn.send();
}

function stream(id) {
    var cn = new XMLHttpRequest();
    cn.open('GET', server + '?stream=' + id + '&quality=lMusic');
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
    var cn = new XMLHttpRequest();
    cn.open('GET', server + '?lyric=' + id);
    cn.onreadystatechange = function () {
        if (cn.readyState == XMLHttpRequest.DONE && cn.status == 200) {
            var data = cn.responseText;
            data = JSON.parse(data);
            try {
                parseLyric(data.lyric, {
                    lyricModel: lyricModelRef,
                    setCurrentLyric: setCurrentLyric,
                    setNextLyric: setNextLyric
                })
            } catch (e) {
                console.log(e);
                setCurrentLyric(i18n.tr("I'm sorry but I forgot that lyric :("))
            }
        } else if (cn.readyState == XMLHttpRequest.DONE && cn.status != 200) {
            console.log("Error loading lyric")
        }
    };
    cn.send();
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
    var minutes = Math.floor((duration / 1000) / 60);
    var seconds = Math.floor((duration / 1000)) % 60;
    // Make sure that we never see "NaN:NaN"
    if (minutes.toString() == 'NaN')
        minutes = 0;
    if (seconds.toString() == 'NaN')
        seconds = 0;
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
