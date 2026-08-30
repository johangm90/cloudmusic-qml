import QtQuick 2.7
import QtQuick.Controls 2.2 as QQC2

QQC2.Slider {
    property real minimumValue: 0
    property real maximumValue: 1
    from: minimumValue
    to: maximumValue
    property var formatValue: function(v) { return v }
}
