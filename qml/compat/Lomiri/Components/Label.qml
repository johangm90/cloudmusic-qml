import QtQuick 2.7

Text {
    id: label
    property string fontSize: "medium"
    property color linkColor: "#19b6ee"
    color: "#303030"
    font.pixelSize: {
        switch (fontSize) {
            case "x-small": return 11
            case "small": return 13
            case "medium": return 15
            case "large": return 20
            case "x-large": return 26
            default: return 15
        }
    }
}
