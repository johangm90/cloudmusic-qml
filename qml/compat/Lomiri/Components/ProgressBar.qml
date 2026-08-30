import QtQuick 2.7
import QtQuick.Controls 2.2 as QQC2

QQC2.ProgressBar {
    id: root
    property real minimumValue: 0
    property real maximumValue: 1
    from: minimumValue
    to: maximumValue
}
