.import QtQuick.LocalStorage 2.0 as Sql

var memory = {}
var ready = false
var writeCount = 0
var MAX_ENTRIES = 1000
var TTL_MS = 30 * 24 * 60 * 60 * 1000
var CLEANUP_EVERY_WRITES = 40

function db() {
    return Sql.LocalStorage.openDatabaseSync("apu", "", "Cloud Music DB", 1000000)
}

function ensure() {
    if (ready) {
        return
    }
    db().transaction(function(tx) {
        tx.executeSql('CREATE TABLE IF NOT EXISTS cover_cache(id INTEGER PRIMARY KEY, album_key TEXT UNIQUE, art TEXT, updated_at INTEGER);')
        cleanup(tx)
    })
    ready = true
}

function cleanup(tx) {
    var now = Date.now()
    var cutoff = now - TTL_MS
    tx.executeSql('DELETE FROM cover_cache WHERE updated_at IS NULL OR updated_at < ?;', [cutoff])

    var rs = tx.executeSql('SELECT COUNT(*) AS total FROM cover_cache;')
    var total = rs.rows.item(0).total
    if (total > MAX_ENTRIES) {
        var extra = total - MAX_ENTRIES
        tx.executeSql(
            'DELETE FROM cover_cache WHERE id IN (SELECT id FROM cover_cache ORDER BY updated_at ASC, id ASC LIMIT ?);',
            [extra]
        )
    }
}

function normalize(url) {
    if (!url || typeof url !== "string") {
        return ""
    }
    if (url.indexOf("../graphics/default.png") !== -1) {
        return url
    }
    if (url.indexOf("file://") === 0 || url.indexOf("http://") === 0 || url.indexOf("https://") === 0 || url.indexOf("qrc:/") === 0) {
        return url
    }
    if (url.charAt(0) === "/") {
        return "file://" + url
    }
    return url
}

function keyFor(albumId, url) {
    if (albumId !== undefined && albumId !== null && albumId !== "" && albumId !== 0) {
        return "album:" + albumId
    }
    if (url && typeof url === "string") {
        return "url:" + url
    }
    return ""
}

function put(albumId, url) {
    ensure()
    var value = normalize(url)
    if (!value || value.indexOf("default.png") !== -1) {
        return
    }
    var key = keyFor(albumId, value)
    if (!key) {
        return
    }
    memory[key] = value
    db().transaction(function(tx) {
        tx.executeSql('INSERT OR REPLACE INTO cover_cache(album_key, art, updated_at) VALUES(?, ?, ?);', [key, value, Date.now()])
        writeCount += 1
        if (writeCount >= CLEANUP_EVERY_WRITES) {
            cleanup(tx)
            writeCount = 0
        }
    })
}

function get(albumId, url) {
    ensure()
    var key = keyFor(albumId, url)
    if (!key) {
        return ""
    }
    if (memory[key]) {
        return memory[key]
    }
    var value = ""
    var now = Date.now()
    var cutoff = now - TTL_MS
    db().transaction(function(tx) {
        var rs = tx.executeSql('SELECT art, updated_at FROM cover_cache WHERE album_key=?;', [key])
        if (rs.rows.length > 0) {
            var row = rs.rows.item(0)
            var updatedAt = row.updated_at || 0
            if (updatedAt >= cutoff) {
                value = row.art
            } else {
                tx.executeSql('DELETE FROM cover_cache WHERE album_key=?;', [key])
            }
        }
    })
    if (value) {
        memory[key] = value
    }
    return value
}

function resolve(albumId, url, fallback) {
    var normalized = normalize(url)
    if (normalized) {
        put(albumId, normalized)
        return normalized
    }
    var cached = get(albumId, url)
    if (cached) {
        return cached
    }
    return fallback || "../graphics/default.png"
}
