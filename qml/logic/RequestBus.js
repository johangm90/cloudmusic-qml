var _seq = 0
var _pending = {}
var _defaultTimeoutMs = 30000

function createId(prefix) {
    _seq += 1
    var base = prefix ? String(prefix) : "req"
    return base + "_" + String(_seq)
}

function registerRequest(requestId, options) {
    if (!requestId) {
        return false
    }
    var opts = options || {}
    _pending[String(requestId)] = {
        context: opts.context ? String(opts.context) : "",
        onSuccess: opts.onSuccess || null,
        onError: opts.onError || null,
        onFinally: opts.onFinally || null,
        createdAt: Date.now(),
        timeoutMs: opts.timeoutMs && opts.timeoutMs > 0 ? Number(opts.timeoutMs) : _defaultTimeoutMs
    }
    return true
}

function dispatch(requestId, ok, payloadJson, error) {
    var id = String(requestId)
    var entry = _pending[id]
    if (!entry) {
        return false
    }
    delete _pending[id]
    if (!ok) {
        if (entry.onError) {
            entry.onError(error ? String(error) : "request failed")
        }
        if (entry.onFinally) {
            entry.onFinally()
        }
        return true
    }
    try {
        var payload = JSON.parse(payloadJson)
        if (payload && payload.error) {
            if (entry.onError) {
                entry.onError(payload.error)
            }
        } else if (entry.onSuccess) {
            entry.onSuccess(payload)
        }
    } catch (e) {
        if (entry.onError) {
            entry.onError(String(e))
        }
    }
    if (entry.onFinally) {
        entry.onFinally()
    }
    return true
}

function cancelContext(context) {
    var ctx = String(context || "")
    if (ctx === "") {
        return
    }
    var keys = Object.keys(_pending)
    for (var i = 0; i < keys.length; i++) {
        var key = keys[i]
        var entry = _pending[key]
        if (entry && entry.context === ctx) {
            delete _pending[key]
        }
    }
}

function prune() {
    var now = Date.now()
    var keys = Object.keys(_pending)
    for (var i = 0; i < keys.length; i++) {
        var key = keys[i]
        var entry = _pending[key]
        if (!entry || !entry.createdAt) {
            continue
        }
        if ((now - entry.createdAt) > entry.timeoutMs) {
            delete _pending[key]
            if (entry.onError) {
                entry.onError("request timeout")
            }
            if (entry.onFinally) {
                entry.onFinally()
            }
        }
    }
}

