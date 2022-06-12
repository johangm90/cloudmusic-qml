import QtQuick 2.7
import Ubuntu.Components 1.3

ActionList {
    id: tabsList

    children: [
        Action {
            iconName: "search"
            text: i18n.tr("Search")
            enabled: pagestack.currentPage !== searchLoader
            onTriggered: {
                pagestack.push(searchLoader)
            }
        },

        Action {
            iconName: "slideshow"
            text: i18n.tr("New Albums")
            enabled: pagestack.currentPage !== albumsLoader
            onTriggered: {
                pagestack.push(albumsLoader)
            }
        },

        Action {
            iconName: "contact-group"
            text: i18n.tr("Top Artists")
            enabled: pagestack.currentPage !== artistsLoader
            onTriggered: {
                pagestack.push(artistsLoader)
            }
        },

        Action {
            iconName: "stock_music"
            text: i18n.tr("Playlists")
            enabled: pagestack.currentPage !== playlistsLoader
            onTriggered: {
                pagestack.push(playlistsLoader)
            }
        },

        Action {
            iconName: "settings"
            text: i18n.tr("Settings")
            enabled: pagestack.currentPage !== settingsLoader
            onTriggered: {
                pagestack.push(settingsLoader)
            }
        },

        Action {
            iconName: "help"
            text: i18n.tr("About")
            enabled: pagestack.currentPage !== aboutLoader
            onTriggered: {
                pagestack.push(aboutLoader)
            }
        }
    ]
}

