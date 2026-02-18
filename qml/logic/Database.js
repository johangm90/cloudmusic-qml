.import QtQuick.LocalStorage 2.0 as Sql

function db() {
    return Sql.LocalStorage.openDatabaseSync("apu", "", "Cloud Music DB", 1000000);
}

function init() {
    try {
        db().transaction(function(tx) {
            create_tables(tx);
            migrate_schema(tx);
            console.log("Database version: " + db().version);
        })
    } catch (e) {
        console.log(e);
    }
}

function create_tables(tx) {
    tx.executeSql('CREATE TABLE IF NOT EXISTS playlists(id INTEGER PRIMARY KEY, name TEXT UNIQUE, offline NUMERIC);');
    tx.executeSql('CREATE TABLE IF NOT EXISTS songs(id INTEGER PRIMARY KEY, sid INTEGER, name TEXT, artist_id INTEGER, artist TEXT, album_id INTEGER, album TEXT, duration TEXT, playlist INTEGER, song_order INTEGER, local TEXT, local_art TEXT, lyric TEXT);');
    tx.executeSql('CREATE TABLE IF NOT EXISTS search_history(id INTEGER PRIMARY KEY, search TEXT UNIQUE, created_at INTEGER);');
    tx.executeSql('CREATE TABLE IF NOT EXISTS liked_songs(id INTEGER PRIMARY KEY, sid INTEGER UNIQUE, name TEXT, artist_id INTEGER, artist TEXT, album_id INTEGER, album TEXT, duration INTEGER, art TEXT, added_at INTEGER);');
    tx.executeSql('CREATE TABLE IF NOT EXISTS recently_played(id INTEGER PRIMARY KEY, sid INTEGER UNIQUE, name TEXT, artist_id INTEGER, artist TEXT, album_id INTEGER, album TEXT, duration INTEGER, art TEXT, played_at INTEGER);');
}

function migrate_schema(tx) {
    ensure_search_history_created_at(tx)
    ensure_liked_songs_schema(tx)
    ensure_recently_played_schema(tx)
}

function ensure_search_history_created_at(tx) {
    var hasCreatedAt = false
    var info = tx.executeSql('PRAGMA table_info(search_history);')
    for (var i = 0; i < info.rows.length; i++) {
        if (info.rows.item(i).name === "created_at") {
            hasCreatedAt = true
            break
        }
    }

    if (!hasCreatedAt) {
        tx.executeSql('ALTER TABLE search_history ADD COLUMN created_at INTEGER;')
        tx.executeSql('UPDATE search_history SET created_at=? WHERE created_at IS NULL;', [Date.now()])
    }
}

function ensure_column_exists(tx, tableName, columnName, definition) {
    var hasColumn = false
    var info = tx.executeSql('PRAGMA table_info(' + tableName + ');')
    for (var i = 0; i < info.rows.length; i++) {
        if (info.rows.item(i).name === columnName) {
            hasColumn = true
            break
        }
    }
    if (!hasColumn) {
        tx.executeSql('ALTER TABLE ' + tableName + ' ADD COLUMN ' + columnName + ' ' + definition + ';')
    }
}

function ensure_liked_songs_schema(tx) {
    ensure_column_exists(tx, "liked_songs", "art", "TEXT")
    ensure_column_exists(tx, "liked_songs", "added_at", "INTEGER")
    tx.executeSql('UPDATE liked_songs SET added_at=? WHERE added_at IS NULL;', [Date.now()])
}

function ensure_recently_played_schema(tx) {
    ensure_column_exists(tx, "recently_played", "art", "TEXT")
    ensure_column_exists(tx, "recently_played", "played_at", "INTEGER")
    tx.executeSql('UPDATE recently_played SET played_at=? WHERE played_at IS NULL;', [Date.now()])
}

function delete_tables(tx) {
    tx.executeSql('DROP TABLE IF EXISTS songs');
    tx.executeSql('DROP TABLE IF EXISTS playlists');
    tx.executeSql('DROP TABLE IF EXISTS search_history');
    tx.executeSql('DROP TABLE IF EXISTS liked_songs');
    tx.executeSql('DROP TABLE IF EXISTS recently_played');
}

function updateRecords(targetModel) {
    var model = targetModel || (typeof modelo_playlists !== "undefined" ? modelo_playlists : null)
    if (!model) {
        return
    }
    model.clear();

    var records = getPlaylists();

    for (var i = 0; i < records.length; i++) {
        model.append({
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
        tx.executeSql('UPDATE playlists SET name=? WHERE id=?', [name, id]);
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
        tx.executeSql('UPDATE songs SET song_order=? WHERE id=?', [order, id]);
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
                'image': rs.rows.item(i).local_art ? rs.rows.item(i).local_art : "",
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
        tx.executeSql('UPDATE playlists SET offline=? WHERE id=?', [value, id]);
    })
}

function getSearchHistory(limit) {
    var records = []
    var max = (typeof limit === "number" && limit > 0) ? limit : 20

    db().transaction(function(tx) {
        var rs = tx.executeSql(
            'SELECT search FROM search_history ORDER BY created_at DESC, id DESC LIMIT ?;',
            [max]
        )
        for (var i = 0; i < rs.rows.length; i++) {
            records.push(rs.rows.item(i).search)
        }
    })

    return records
}

function insertSearchHistory(search, max) {
    var value = (search || "").trim()
    if (!value) {
        return
    }

    var maxRows = (typeof max === "number" && max > 0) ? max : 20
    db().transaction(function(tx) {
        tx.executeSql('DELETE FROM search_history WHERE search=?;', [value])
        tx.executeSql(
            'INSERT INTO search_history(search, created_at) VALUES(?, ?);',
            [value, Date.now()]
        )

        var countRs = tx.executeSql('SELECT COUNT(*) as total FROM search_history;')
        var total = countRs.rows.item(0).total
        if (total > maxRows) {
            tx.executeSql(
                'DELETE FROM search_history WHERE id IN (SELECT id FROM search_history ORDER BY created_at ASC, id ASC LIMIT ?);',
                [total - maxRows]
            )
        }
    })
}

function deleteSearchHistory(search) {
    var value = (search || "").trim()
    if (!value) {
        return
    }

    db().transaction(function(tx) {
        tx.executeSql('DELETE FROM search_history WHERE search=?;', [value])
    })
}

function normalizeSongRecord(song) {
    if (!song) {
        return null
    }
    var sid = song.id || song.song_id || song.sid
    if (!sid) {
        return null
    }
    return {
        sid: sid,
        name: song.name || "",
        artist_id: song.artist_id || 0,
        artist: song.artist || "",
        album_id: song.album_id || 0,
        album: song.album || "",
        duration: song.duration || 0,
        art: song.image || song.art || ""
    }
}

function isLikedSong(songId) {
    var sid = parseInt(songId, 10)
    if (!sid) {
        return false
    }
    var liked = false
    db().transaction(function(tx) {
        var rs = tx.executeSql('SELECT COUNT(*) as total FROM liked_songs WHERE sid=?;', [sid])
        liked = rs.rows.item(0).total > 0
    })
    return liked
}

function insertLikedSong(song) {
    var record = normalizeSongRecord(song)
    if (!record) {
        return false
    }
    db().transaction(function(tx) {
        tx.executeSql(
            'INSERT OR REPLACE INTO liked_songs(sid, name, artist_id, artist, album_id, album, duration, art, added_at) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?);',
            [record.sid, record.name, record.artist_id, record.artist, record.album_id, record.album, record.duration, record.art, Date.now()]
        )
    })
    return true
}

function removeLikedSong(songId) {
    var sid = parseInt(songId, 10)
    if (!sid) {
        return false
    }
    db().transaction(function(tx) {
        tx.executeSql('DELETE FROM liked_songs WHERE sid=?;', [sid])
    })
    return true
}

function toggleLikedSong(song) {
    var record = normalizeSongRecord(song)
    if (!record) {
        return false
    }
    if (isLikedSong(record.sid)) {
        removeLikedSong(record.sid)
        return false
    }
    insertLikedSong(record)
    return true
}

function getLikedSongs(limit) {
    var records = []
    var max = (typeof limit === "number" && limit > 0) ? limit : 200
    db().transaction(function(tx) {
        var rs = tx.executeSql(
            'SELECT sid, name, artist_id, artist, album_id, album, duration, art, added_at FROM liked_songs ORDER BY added_at DESC LIMIT ?;',
            [max]
        )
        for (var i = 0; i < rs.rows.length; i++) {
            records.push({
                song_id: rs.rows.item(i).sid,
                name: rs.rows.item(i).name,
                artist_id: rs.rows.item(i).artist_id,
                artist: rs.rows.item(i).artist,
                album_id: rs.rows.item(i).album_id,
                album: rs.rows.item(i).album,
                duration: rs.rows.item(i).duration,
                image: rs.rows.item(i).art,
                timestamp: rs.rows.item(i).added_at
            })
        }
    })
    return records
}

function addRecentlyPlayed(song) {
    var record = normalizeSongRecord(song)
    if (!record) {
        return false
    }
    db().transaction(function(tx) {
        tx.executeSql(
            'INSERT OR REPLACE INTO recently_played(sid, name, artist_id, artist, album_id, album, duration, art, played_at) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?);',
            [record.sid, record.name, record.artist_id, record.artist, record.album_id, record.album, record.duration, record.art, Date.now()]
        )
    })
    return true
}

function getRecentlyPlayed(limit) {
    var records = []
    var max = (typeof limit === "number" && limit > 0) ? limit : 50
    db().transaction(function(tx) {
        var rs = tx.executeSql(
            'SELECT sid, name, artist_id, artist, album_id, album, duration, art, played_at FROM recently_played ORDER BY played_at DESC LIMIT ?;',
            [max]
        )
        for (var i = 0; i < rs.rows.length; i++) {
            records.push({
                song_id: rs.rows.item(i).sid,
                name: rs.rows.item(i).name,
                artist_id: rs.rows.item(i).artist_id,
                artist: rs.rows.item(i).artist,
                album_id: rs.rows.item(i).album_id,
                album: rs.rows.item(i).album,
                duration: rs.rows.item(i).duration,
                image: rs.rows.item(i).art,
                timestamp: rs.rows.item(i).played_at
            })
        }
    })
    return records
}
