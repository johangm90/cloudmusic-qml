.import QtQuick.LocalStorage 2.0 as Sql

var memory = {}
var ready = false

function db() {
    return Sql.LocalStorage.openDatabaseSync("apu", "", "Cloud Music DB", 1000000)
}

function ensure() {
    if (ready) {
        return
    }
    db().transaction(function(tx) {
        tx.executeSql('CREATE TABLE IF NOT EXISTS cover_cache(id INTEGER PRIMARY KEY, album_key TEXT UNIQUE, art TEXT, updated_at INTEGER);')
    })
    ready = true
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
    db().transaction(function(tx) {
        var rs = tx.executeSql('SELECT art FROM cover_cache WHERE album_key=?;', [key])
        if (rs.rows.length > 0) {
            value = rs.rows.item(0).art
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
