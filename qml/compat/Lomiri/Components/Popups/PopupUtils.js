.pragma library

function open(component, caller, properties) {
    var parentItem = caller || null
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
    popup.destroy()
}
