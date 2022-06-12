import QtQuick 2.7
import Ubuntu.Components 1.3
import "../components"

Page {
    id: searchHistoryPage

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
}
