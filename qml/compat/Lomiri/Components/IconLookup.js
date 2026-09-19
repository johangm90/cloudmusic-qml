.pragma library

var glyphs = {
    "add": "+",
    "add-to-playlist": "+♪",
    "audio-volume-high": "🔊",
    "audio-volume-mute": "🔇",
    "back": "←",
    "close": "✕",
    "contact": "☺",
    "contact-group": "☺☺",
    "contextual-menu": "⋮",
    "delete": "✖",
    "edit": "✎",
    "find": "🔍",
    "go-next": "›",
    "help": "?",
    "history": "↺",
    "like": "♥",
    "unlike": "♡",
    "media-playback-pause": "❚❚",
    "media-playback-start": "▶",
    "media-playlist": "≡",
    "media-playlist-repeat": "↻",
    "media-playlist-repeat-one": "↻1",
    "media-playlist-shuffle": "⥁",
    "media-skip-backward": "⏮",
    "media-skip-forward": "⏭",
    "navigation-menu": "☰",
    "note": "♪",
    "save": "⤓",
    "settings": "⚙",
    "slideshow": "▣",
    "stock_music": "♫"
}

var assets = {
    "add": "plus",
    "add-to-playlist": "list-plus",
    "audio-volume-high": "volume-2",
    "audio-volume-mute": "volume-x",
    "back": "arrow-left",
    "close": "x",
    "contact": "user",
    "contact-group": "users",
    "contextual-menu": "more-horizontal",
    "delete": "trash-2",
    "edit": "pencil",
    "find": "search",
    "go-next": "chevron-right",
    "help": "circle-help",
    "history": "history",
    "like": "heart",
    "unlike": "heart",
    "media-playback-pause": "pause",
    "media-playback-start": "play",
    "media-playlist": "list-music",
    "media-playlist-repeat": "repeat",
    "media-playlist-repeat-one": "repeat-1",
    "media-playlist-shuffle": "shuffle",
    "media-skip-backward": "skip-back",
    "media-skip-forward": "skip-forward",
    "navigation-menu": "menu",
    "note": "music-2",
    "save": "download",
    "settings": "settings",
    "slideshow": "library",
    "stock_music": "list-music"
}

function assetFor(name) {
    return assets.hasOwnProperty(name) ? assets[name] : ""
}

function glyphFor(name) {
    if (glyphs.hasOwnProperty(name)) {
        return glyphs[name]
    }
    return "●"
}
