.pragma library

var glyphs = {
    "add": "+",
    "add-to-playlist": "+♪",
    "close": "✕",
    "contact": "☺",
    "contact-group": "☺☺",
    "contextual-menu": "⋮",
    "delete": "✖",
    "edit": "✎",
    "find": "ὐD",
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

function glyphFor(name) {
    if (glyphs.hasOwnProperty(name)) {
        return glyphs[name]
    }
    return "●"
}
