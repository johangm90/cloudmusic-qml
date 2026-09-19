import QtQuick 2.12
import Lomiri.Components 1.3
import "../components"

Page {
    id: searchHistoryPage
    property var appRoot
    property color pageColor: appRoot ? appRoot.pageColor : "#f5f5f5"

    header: PageHeader {
        title: i18n.tr("Search")
        trailingActionBar {
            numberOfSlots: 1
            actions: [
                Action {
                    text: i18n.tr("Search")
                    iconName: "find"
                    onTriggered: pagestack.push(searchPage)
                }
            ]
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: searchHistoryPage.header ? searchHistoryPage.header.height : 0
        color: pageColor
        z: -1

        Column {
            anchors.centerIn: parent
            width: parent.width - units.gu(8)
            spacing: units.gu(1)

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                width: units.gu(6)
                height: width
                name: "find"
                color: appRoot ? appRoot.secondaryTextColor : "#666666"
                opacity: 0.72
            }

            Label {
                width: parent.width
                text: i18n.tr("Find your next favorite")
                horizontalAlignment: Text.AlignHCenter
                color: appRoot ? appRoot.textColor : "#1f1f1f"
                font.weight: Font.DemiBold
            }

            Label {
                width: parent.width
                text: i18n.tr("Search for songs, albums or artists to start listening.")
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: appRoot ? appRoot.secondaryTextColor : "#666666"
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: i18n.tr("Search music")
                color: appRoot ? appRoot.primaryColor : "#e53446"
                onClicked: pagestack.push(searchPage)
            }
        }
    }
}
