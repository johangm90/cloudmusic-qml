import QtQuick 2.7

QtObject {
    property int contentType: 0
    property int handler: 0
    property int selectionType: 0

    // Real Lomiri.Content has no desktop equivalent (it hands data to another app via the
    // content-hub service). This just returns a plain JS object standing in for a
    // ContentTransfer, immediately "in progress" so callers can proceed.
    function request() {
        return {
            state: 1, // ContentTransfer.InProgress
            items: []
        }
    }
}
