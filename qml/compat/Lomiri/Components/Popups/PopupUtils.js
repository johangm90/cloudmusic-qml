.pragma library

function open(component, caller, properties) {
    // A popup without an Item/window parent cannot resolve its QQuickWindow on
    // desktop, so QQC2 silently closes it with "cannot find any window".  Most
    // call sites omit caller; use the active application window as the fallback.
    var parentItem = caller || (Qt.application ? Qt.application.activeWindow : null) || null
    var obj = component.createObject(parentItem, properties || {})
    if (!obj) {
        console.error("PopupUtils.open: failed to create popup from component")
        return null
    }
    if (typeof obj.open === "function") {
        obj.open()
    } else if (typeof obj.show === "function") {
        obj.show()
    } else {
        obj.visible = true
    }
    return obj
}

function close(popup) {
    if (!popup) {
        return
    }
    if (typeof popup.close === "function") {
        popup.close()
    } else if (typeof popup.hide === "function") {
        popup.hide()
    } else {
        popup.visible = false
    }
    // PopupBase instances can be created by a Component with an indestructible
    // QML root. Hiding is sufficient for those objects; don't let cleanup turn
    // a successful action into a runtime error.
    try {
        popup.destroy()
    } catch (e) {
        popup.visible = false
    }
}
