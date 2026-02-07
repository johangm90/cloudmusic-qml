var server = "https://vulgry.innves.com/rapsody/api.php";
var api2 = "https://cloudmusicapi.nubit.io/netease/";

function apiSearch(query, type, limit) {
    is_visible(false);
    searchSongsModel.clear();
    searchAlbumsModel.clear();
    searchArtistsModel.clear();
    search_songs_loader.running = true;
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
                if (song.fee != 1) {
                    searchSongsModel.append({
                        'id': song.id,
                        'name': song.name,
                        'album_id': song.album.id,
                        'album': song.album.name,
                        'artist_id': song.artists[0].id,
                        'artist': song.artists[0].name,
                        'duration': song.duration
                    });
                }
            }
            search_songs_loader.running = false;
        } else {
            search_songs_loader.running = false;
        }
    };
    cn1.send();
    search_albums_loader.running = true;
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
                searchAlbumsModel.append({
                    'id': album.id,
                    'name': album.name,
                    'artist': album.artist.name,
                    'date': release_date,
                    'size': album.size,
                    'image': album.picUrl + '?param=200y200',
                    'big_image': album.picUrl
                });
            }
            search_albums_loader.running = false;
        } else {
            search_albums_loader.running = false;
        }
    };
    cn2.send();
    search_artists_loader.running = true;
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
                    searchArtistsModel.append({
                        'id': artist.id,
                        'name': artist.name,
                        'image': image,
                        'big_image': bigimage
                    });
                }
                search_artists_loader.running = false;
            } catch (e) {
                console.log(e);
            }
            is_visible(true);
        } else {
            search_artists_loader.running = false;
        }
    };
    cn3.send();
}

function getNewAlbums(limit) {
    new_albums_error.visible = false;
    newAlbumsModel.clear();
    new_albums_loader.running = true;
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
                    newAlbumsModel.append({
                        'id': album.id,
                        'name': album.name,
                        'artist': album.artist.name,
                        'date': release_date,
                        'image': album.picUrl + '?param=200y200',
                        'big_image': album.picUrl
                    });
                }
                new_albums_loader.running = false;
            } catch (e) {
                console.log(e);
                new_albums_error.visible = true;
                new_albums_loader.running = false;
            }
        } else if (cn.readyState == XMLHttpRequest.DONE && cn.status != 200) {
            new_albums_error.visible = true;
            new_albums_loader.running = false;
        }
    };
    cn.send();
}

function getTopArtists(limit) {
    top_artists_error.visible = false;
    artistsModel.clear();
    top_artists_loader.running = true;
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
                    artistsModel.append({
                        'id': artist.id,
                        'name': artist.name,
                        'image': artist.picUrl + '?param=200y200',
                        'big_image': artist.picUrl
                    })
                }
                top_artists_loader.running = false;
            } catch (e) {
                console.log(e);
                top_artists_error.visible = true;
                top_artists_loader.running = false;
            }
        } else if (cn.readyState == XMLHttpRequest.DONE && cn.status != 200) {
            top_artists_error.visible = true;
            top_artists_loader.running = false;
        }
    };
    cn.send();
}

function getArtistTopSongs(id) {
    artistPage.title = i18n.tr("Artist");
    artistPage.header.title = i18n.tr("Artist");
    photo.source = "../graphics/default.png";
    is_visible(false);
    songsModel.clear();
    artist_songs_loader.running = true;
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
                    if (song.fee != 1) {
                        songsModel.append({
                            'id': song.id,
                            'name': song.name,
                            'album_id': song.album.id,
                            'album': song.album.name,
                            'artist_id': song.artists[0].id,
                            'artist': song.artists[0].name,
                            'duration': song.duration
                        })
                    }
                }
            } catch (e) {
                console.log(e);
            }
            artist_songs_loader.running = false;
        } else {
            artist_songs_loader.running = false;
        }
    };
    cn.send();
}

function getArtistAlbums(id) {
    albumsModel.clear();
    artist_albums_loader.running = true;
    var cn = new XMLHttpRequest();
    var url = server + '?action=getArtistAlbums&id=' + id;
    cn.open("GET", url);
    cn.onreadystatechange = function () {
        if (cn.readyState == XMLHttpRequest.DONE && cn.status == 200) {
            var data = cn.responseText;
            data = JSON.parse(data);
            try {
                photo.source = data.artist.picUrl;
                artistPage.title = data.artist.name;
                artistPage.header.title = data.artist.name;
                for (var i = 0; i < data.hotAlbums.length; i++) {
                    var album = data.hotAlbums[i];
                    var date = new Date(album.publishTime);
                    var release_date = formatDate(date);
                    albumsModel.append({
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
            artist_albums_loader.running = false;
            is_visible(true);
        } else {
            artist_albums_loader.running = false;
        }
    }
    cn.send();
}

function getAlbumDetail(id) {
    photo.source = "../graphics/default.png";
    lbl_album_title.text = "";
    is_visible(false);
    albumModel.clear();
    album_loader.running = true;
    var cn = new XMLHttpRequest();
    cn.open("GET", server + '?action=getAlbumDetail&id=' + id);
    cn.onreadystatechange = function () {
        if (cn.readyState == XMLHttpRequest.DONE && cn.status == 200) {
            var data = cn.responseText;
            data = JSON.parse(data);
            try {
                photo.source = data.album.picUrl;
                lbl_album_title.text = data.album.name;
                var date = new Date(data.album.publishTime);
                var release_date = formatDate(date);
                lbl_album_date.text = i18n.tr('Release Date:') + ' ' + release_date;
                for (var i = 0; i < data.album.songs.length; i++) {
                    var song = data.album.songs[i];
                    if (song.fee != 1) {
                        albumModel.append({
                            'id': song.id,
                            'name': song.name,
                            'album_id': song.album.id,
                            'album': song.album.name,
                            'artist_id': song.artists[0].id,
                            'artist': song.artists[0].name,
                            'duration': song.duration
                        })
                    }
                }
                album_loader.running = false;
            } catch (e) {
                console.log(e);
            }
            is_visible(true);
        } else {
            album_loader.running = false;
            is_visible(true);
        }
    };
    cn.send();
}

function getSongDetail(id) {
    playingPage.title = i18n.tr("Now Playing");
    playingPage.header.title = i18n.tr("Now Playing");
    lbl_artistaDetalle.text = "";
    lbl_albumDetalle.text = "";
    albumImage.source = "../graphics/default.png";
    if (playing_page.settings.lyrics) {
        getLyric(id);
    }
    playing_loader.running = true;
    var cn = new XMLHttpRequest();
    var url = server + '?action=getSongDetail&id=' + id;
    cn.open('GET', url);
    cn.onreadystatechange = function () {
        if (cn.readyState == XMLHttpRequest.DONE && cn.status == 200) {
            var data = cn.responseText;
            data = JSON.parse(data);
            try {
                playingPage.title = data.name;
                playingPage.header.title = data.name;
                albumImage.source = data.picUrl;
                lbl_artistaDetalle.text = data.artist;
                lbl_albumDetalle.text = data.album;
                seek.maximumValue = data.duration;
                player_toolbar.cargar(data.name, data.artist, data.picUrl);
                current_id = id;
            } catch (e) {
                console.log(e);
            }
            playing_loader.running = false;
        } else {
            playing_loader.running = false;
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
            var data = cn.responseText;
            data = JSON.parse(data);
            var singleDownload = downloadComponent.createObject(cloudMusic);
            singleDownload.name = name;
            var nameArtMod = nameArt.replace(" ", "_")
            singleDownload.nameArtist = nameArtMod;
            singleDownload.download(data.url);
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
function getLyric(id) {
    playing_page.model_lyric.clear();
    lbl_lyric.text = "";
    lbl_next.text = "";
    var cn = new XMLHttpRequest();
    cn.open('GET', server + '?lyric=' + id);
    cn.onreadystatechange = function () {
        if (cn.readyState == XMLHttpRequest.DONE && cn.status == 200) {
            var data = cn.responseText;
            data = JSON.parse(data);
            try {
                parseLyric(data.lyric);
            } catch (e) {
                console.log(e);
                lbl_lyric.text = i18n.tr("I'm sorry but I forgot that lyric :(")
            }
        } else if (cn.readyState == XMLHttpRequest.DONE && cn.status != 200) {
            console.log("Error loading lyric")
        }
    };
    cn.send();
}

function parseLyric(lyric) {
    var lines = " ";
    lines = lyric.split(/\r\n|\n/);
    next(lines);
}

function next(lines) {
    var lyrics = [];
    var tim = [];
    var line = " ";
    for (var i = 0; i < lines.length; i++) {
        if (lines[i].search(/^(\[)(\d*)(:)(.*)(\])(.*)/i) >= 0) {
            line = lines[i].match(/^(\[)(\d*)(:)(.*)(\])(.*)/i);
            tim[i] = (parseInt(line[2]) * 60) + parseInt(line[4]); // will give seconds
            lyrics[i] = line[6]; //will give lyrics
            playing_page.model_lyric.append({
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
    var list = urlFile.split("/")
    var nameFile = list[list.length - 1]
    var localDirectory = urlFile.split(nameFile)
    var listFin = []
    listFin[0] = localDirectory[0]
    listFin[1] = nameFile.replace(/%/g, "%25")
    return listFin
}
