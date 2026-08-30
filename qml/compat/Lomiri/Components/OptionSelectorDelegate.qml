import QtQuick 2.7

QtObject {
    property string text: ""
    // Every real usage of this type in the app binds `text` and/or `onClicked` to bare
    // `name`/`key` (a ListModel row's roles), assuming per-delegate context injection like
    // a real ListView/Repeater would give a Component-based delegate. Since instances here
    // are created manually (see OptionSelector.qml / ListItems/ItemSelector.qml) rather
    // than through an actual ListView, `name`/`key` are declared as real properties so
    // `createObject(parent, {name: ..., key: ...})` actually sets them.
    property string name: ""
    property string key: ""
    property string playlistName: ""
    signal clicked()
}
