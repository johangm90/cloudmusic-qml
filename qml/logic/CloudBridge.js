.import "AppContext.js" as AppCtx

var _asyncSeq = 0
var _asyncConnected = false
var _asyncCallbacks = {}
var _asyncTimeoutMs = 30000

function _appRoot() {
    var root = AppCtx.get("appRoot")
    if (root) {
        return root
    }
    if (typeof cloudMusic !== "undefined" && cloudMusic) {
        return cloudMusic
    }
    return null
}

function _cloudApiBridge() {
    var root = _appRoot()
    if (root && root.cloudApi) {
        return root.cloudApi
    }
    return AppCtx.get("cloudApi")
}

function directApi(action, params) {
    try {
        var bridge = _cloudApiBridge()
        if (!bridge) {
            return null
        }
        var raw = bridge.call(action, JSON.stringify(params || {}))
        if (!raw || raw === "") {
            return null
        }
        return JSON.parse(raw)
    } catch (e) {
        console.log(e)
        return null
    }
}

function ensureAsyncBridgeConnected() {
    if (_asyncConnected) {
        return true
    }
    var bridge = _cloudApiBridge()
    if (!bridge || !bridge.requestFinished) {
        return false
    }
    bridge.requestFinished.connect(function(requestId, ok, payloadJson, error) {
        var id = String(requestId)
        var cb = _asyncCallbacks[id]
        if (!cb) {
            return
        }
        delete _asyncCallbacks[id]
        if (!ok) {
            if (cb.onError) {
                cb.onError(error ? String(error) : "request failed")
            }
            return
        }
        try {
            var payload = JSON.parse(payloadJson)
            if (payload && payload.error) {
                if (cb.onError) {
                    cb.onError(payload.error)
                }
                return
            }
            if (cb.onSuccess) {
                cb.onSuccess(payload)
            }
        } catch (e) {
            if (cb.onError) {
                cb.onError(e)
            }
        }
    })
    _asyncConnected = true
    return true
}

function directApiAsync(action, params, onSuccess, onError) {
    pruneAsyncCallbacks()
    if (!ensureAsyncBridgeConnected()) {
        if (onError) {
            onError("cloud api bridge unavailable")
        }
        return
    }
    var bridge = _cloudApiBridge()
    if (!bridge) {
        if (onError) {
            onError("cloud api bridge unavailable")
        }
        return
    }
    _asyncSeq += 1
    var reqId = "req_" + String(_asyncSeq)
    _asyncCallbacks[reqId] = {
        onSuccess: onSuccess,
        onError: onError,
        createdAt: Date.now()
    }
    bridge.callAsync(action, JSON.stringify(params || {}), reqId)
}

function pruneAsyncCallbacks() {
    var now = Date.now()
    var keys = Object.keys(_asyncCallbacks)
    for (var i = 0; i < keys.length; i++) {
        var id = keys[i]
        var cb = _asyncCallbacks[id]
        if (!cb || !cb.createdAt) {
            continue
        }
        if ((now - cb.createdAt) > _asyncTimeoutMs) {
            delete _asyncCallbacks[id]
            if (cb.onError) {
                cb.onError("request timeout")
            }
        }
    }
}

