import QtQuick 2.7

QtObject {
    property string text: ""
    property string iconName: ""
    property string name: ""
    property bool enabled: true
    property bool visible: true
    signal triggered(var value)
    function trigger(value) { triggered(value) }
}
