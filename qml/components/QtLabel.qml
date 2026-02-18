import QtQuick 2.12

Text {
    id: label
    property string fontSize: ""
    property int basePixelSize: 16

    function updateFontSize() {
    var baseSize = basePixelSize
        if (fontSize === "small") {
            font.pixelSize = Math.round(baseSize * 0.85)
        } else if (fontSize === "medium") {
            font.pixelSize = Math.round(baseSize * 1.0)
        } else if (fontSize === "large") {
            font.pixelSize = Math.round(baseSize * 1.2)
        }
    }

    onFontSizeChanged: updateFontSize()
    Component.onCompleted: updateFontSize()
}
