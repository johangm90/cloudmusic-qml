import QtQuick 2.12
import Lomiri.Components 1.3

ActionList {
    id: tabsList

    function isCurrentPage(loader) {
        return pagestack.currentPage === loader || pagestack.currentPage === loader.item
    }

    function navigateTo(loader) {
        if (!loader || isCurrentPage(loader)) {
            return
        }
        pagestack.push(loader)
    }

    children: [
        Action {
            iconName: "find"
            text: i18n.tr("Search")
            enabled: !tabsList.isCurrentPage(searchLoader)
            onTriggered: {
                tabsList.navigateTo(searchLoader)
            }
        },

        Action {
            iconName: "slideshow"
            text: i18n.tr("New Albums")
            enabled: !tabsList.isCurrentPage(albumsLoader)
            onTriggered: {
                tabsList.navigateTo(albumsLoader)
            }
        },

        Action {
            iconName: "contact-group"
            text: i18n.tr("Top Artists")
            enabled: !tabsList.isCurrentPage(artistsLoader)
            onTriggered: {
                tabsList.navigateTo(artistsLoader)
            }
        },

        Action {
            iconName: "stock_music"
            text: i18n.tr("Playlists")
            enabled: !tabsList.isCurrentPage(playlistsLoader)
            onTriggered: {
                tabsList.navigateTo(playlistsLoader)
            }
        },

        Action {
            iconName: "settings"
            text: i18n.tr("Settings")
            enabled: !tabsList.isCurrentPage(settingsLoader)
            onTriggered: {
                tabsList.navigateTo(settingsLoader)
            }
        },

        Action {
            iconName: "help"
            text: i18n.tr("About")
            enabled: !tabsList.isCurrentPage(aboutLoader)
            onTriggered: {
                tabsList.navigateTo(aboutLoader)
            }
        }
    ]
}
