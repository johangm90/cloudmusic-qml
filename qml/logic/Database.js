.import QtQuick.LocalStorage 2.0 as Sql

function db() {
    return Sql.LocalStorage.openDatabaseSync("apu", "", "Cloud Music DB", 1000000);
}

function init() {
    try {
        db().transaction(function(tx) {
            create_tables(tx);
            console.log("Database version: " + db().version);
        })
    } catch (e) {
        console.log(e);
    }
}

function create_tables(tx) {
    tx.executeSql('CREATE TABLE IF NOT EXISTS playlists(id INTEGER PRIMARY KEY, name TEXT UNIQUE, offline NUMERIC);');
    tx.executeSql('CREATE TABLE IF NOT EXISTS songs(id INTEGER PRIMARY KEY, sid INTEGER, name TEXT, artist_id INTEGER, artist TEXT, album_id INTEGER, album TEXT, duration TEXT, playlist INTEGER, song_order INTEGER, local TEXT, local_art TEXT, lyric TEXT);');
    tx.executeSql('CREATE TABLE IF NOT EXISTS search_history(id INTEGER PRIMARY KEY, search TEXT);');
}

function delete_tables(tx) {
    tx.executeSql('DROP TABLE IF EXISTS songs');
    tx.executeSql('DROP TABLE IF EXISTS playlists');
    tx.executeSql('DROP TABLE IF EXISTS search_history');
}

function updateRecords() {
    modelo_playlists.clear();

    var records = getPlaylists();

    for (var i = 0; i < records.length; i++) {
        modelo_playlists.append({
            'playlistId': records[i].id,
            'playlistName': records[i].name,
            'playlistCount': records[i].count,
            'isOffline': records[i].offline
        })
    }
}

function getPlaylists() {
    var records = [];

    db().transaction(function(tx) {
        var rs = tx.executeSql('SELECT p.id, p.name, count(s.id) as count, offline FROM playlists p LEFT JOIN songs s ON s.playlist = p.id GROUP BY p.id;');
        var offline;
        for (var i = 0; i < rs.rows.length; i++) {
            if (rs.rows.item(i).offline === null) {
                offline = 0;
            } else {
                offline = rs.rows.item(i).offline;
            }
            var record = {
                id: rs.rows.item(i).id,
                name: rs.rows.item(i).name,
                count: rs.rows.item(i).count,
                offline: offline
            }
            records.push(record);
        }
    })
    return records;
}

function getLastPlaylist() {
    db().transaction(function(tx) {
        var rs = tx.executeSql('SELECT MAX(id) AS id FROM playlists;');
        song_dialog.add_song(rs.rows.item(0).id);
    })
}

function insertPlaylist(content) {
    db().transaction(function(tx) {
        try {
            tx.executeSql('INSERT INTO playlists VALUES(NULL, ?, 0);', [content]);
        } catch (e) {
            console.log(e);
            messager.show_message(e.message, 3);
        }
    })
}

function updatePlaylist(id, name) {
    db().transaction(function(tx) {
        tx.executeSql('UPDATE playlists SET name="' + name + '" WHERE id=' + id);
    })
}

function removePlaylist(id) {
    db().transaction(function(tx) {
        tx.executeSql('DELETE FROM playlists WHERE id=?;', [id]);
        tx.executeSql('DELETE FROM songs WHERE playlist=?;', [id]);
    })
}

//song table
function insertSong(content) {
    console.log("Attemp to insert: " + content[0]);
    db().transaction(function(tx) {
        try {
            tx.executeSql('INSERT INTO songs VALUES(NULL, ?, ?, ?, ?, ?, ?, ?, ?, NULL, NULL, NULL, NULL);', content);
        } catch (e) {
            console.log(e);
            messager.show_message(e.message, 3);
        }
    })
}

function updateSong(order, id) {
    db().transaction(function(tx) {
        tx.executeSql('UPDATE songs SET song_order=' + order + ' WHERE id=' + id);
    })
}

function setlocal(ruta, id) {
    db().transaction(function(tx) {
        tx.executeSql('UPDATE songs SET local=? WHERE sid=?', [ruta, id]);
    })
}

function setlocalArt(ruta, id) {
    db().transaction(function(tx) {
        tx.executeSql('UPDATE songs SET local_art=? WHERE sid=?', [ruta, id]);
    })
}

function setLyric(lyric, id) {
    db().transaction(function(tx) {
        tx.executeSql('UPDATE songs SET lyric=? WHERE sid=?', [lyric, id]);
    })
}

function removeSong(id) {
    db().transaction(function(tx) {
        tx.executeSql('DELETE FROM songs WHERE id=?;', [id]);
    })
}

//playlist

function getPlaylist(id) {
    songsModel.clear()
    db().transaction(function(tx) {
        var rs = tx.executeSql('SELECT * FROM songs WHERE playlist=? ORDER BY song_order;', [id]);
        for (var i = 0; i < rs.rows.length; i++) {
            songsModel.append({
                'id': rs.rows.item(i).id,
                'song_id': rs.rows.item(i).sid,
                'name': rs.rows.item(i).name,
                'artist_id': rs.rows.item(i).artist_id,
                'artist': rs.rows.item(i).artist,
                'album_id': rs.rows.item(i).album_id,
                'album': rs.rows.item(i).album,
                'duration': rs.rows.item(i).duration,
                'local': rs.rows.item(i).local,
                'playlist_id': rs.rows.item(i).playlist
            })
        }
    })
}

function getOffline(id) {
    db().transaction(function(tx) {
        var rs = tx.executeSql('SELECT offline FROM playlists WHERE id=?;', [id]);
        for (var i = 0; i < rs.rows.length; i++) {
            if (rs.rows.item(i).offline) {
                swdownload.isOffline = rs.rows.item(i).offline;
            } else {
                swdownload.isOffline = 0;
            }
        }
    })
}

function setOffline(id, value) {
    db().transaction(function(tx) {
        tx.executeSql('UPDATE playlists SET offline=' + value + ' WHERE id=' + id);
    })
}
