import QtQuick 2.12
import Lomiri.Components 1.3
import "../components"

Page {
    id: searchHistoryPage
    property var appRoot
    property color pageColor: appRoot ? appRoot.pageColor : "#f5f5f5"

    TabsList {
        id: tabsList
    }

    header: PageHeader {
        title: i18n.tr("Search")
        leadingActionBar {
            numberOfSlots: 0
            actions: tabsList.actions
        }
        trailingActionBar.actions: [searchAction]
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: searchHistoryPage.header ? searchHistoryPage.header.height : 0
        color: pageColor
        z: -1
    }
}
