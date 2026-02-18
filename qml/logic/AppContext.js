.pragma library

var _values = {}

function set(key, value) {
    _values[key] = value
}

function get(key) {
    if (_values.hasOwnProperty(key)) {
        return _values[key]
    }
    return null
}

function clear() {
    _values = {}
}
