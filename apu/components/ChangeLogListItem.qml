import QtQuick 2.4
import Ubuntu.Components 1.3


Item {
    height: mainColumn.height
    width: parent.width

    property alias app_version: appVersion.text
    property alias changesModel: changesRepeater.model

    Column {
        id: mainColumn
        width: parent.width
        Label {
            id: appVersion
            anchors.margins: units.gu(2)
            fontSize: "large"
            font.bold: true
        }

        Repeater {
            id: changesRepeater

            delegate: Label {
                id: text2
                width: parent.width
                anchors {
                    left: parent.left
                    leftMargin: units.gu(1)
                    right: parent.right
                    rightMargin: units.gu(1)
                }

                wrapMode: Text.Wrap
                text: "<b>✔</b> "+modelData
            }

        }
    }

}
