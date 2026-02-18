import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.3 as UListItem
import "../components"

Page {
    id: settingsPage
    property var appRoot
    property color pageColor: appRoot ? appRoot.pageColor : "#f5f5f5"
    property real spacingMedium: appRoot ? appRoot.spacingMedium : units.gu(1.2)

    TabsList {
        id: tabsList
    }

    header: PageHeader {
        title: i18n.tr("Settings")
        leadingActionBar {
            numberOfSlots: 0
            actions: tabsList.actions
        }
    }

    Rectangle {
        color: pageColor
        anchors {
            top: settingsPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        Column {
            anchors.fill: parent
            anchors.margins: spacingMedium
            spacing: spacingMedium

            UListItem.ItemSelector {
                id: qselector
                text: i18n.tr("Download quality")
                model: customModel
                delegate: selectorDelegate
            }
            UListItem.ItemSelector {
                id: qselector2
                text: i18n.tr("Streaming quality")
                model: customModel2
                delegate: selectorDelegate2
            }
            Component {
                id: selectorDelegate
                OptionSelectorDelegate {
                    text: name
                    onClicked: {
                        if (appRoot && appRoot.settings) {
                            appRoot.settings.download_quality = customModel.get(qselector.selectedIndex).key
                            console.log("Download Quality: " + appRoot.settings.download_quality)
                        }
                    }
                }
            }
            ListModel {
                id: customModel
                Component.onCompleted: {
                    var qualitys = [i18n.tr("Normal"), i18n.tr("High"), i18n.tr("Extreme")]
                    var keys = ["96", "160", "320"]
                    for (var i = 0; i < qualitys.length; i++){
                        customModel.append({'name':qualitys[i], 'key':keys[i]})
                    }
                    var selected = 0
                    if (appRoot && appRoot.settings && (appRoot.settings.download_quality == '96' || appRoot.settings.download_quality == '96000')) {
                        selected = 0
                    } else if (appRoot && appRoot.settings && (appRoot.settings.download_quality == '160' || appRoot.settings.download_quality == '160000')) {
                        selected = 1
                    } else {
                        selected = 2
                    }
                    qselector.selectedIndex = selected
                }
            }

            Component {
                id: selectorDelegate2
                OptionSelectorDelegate {
                    text: name
                    onClicked: {
                        if (appRoot && appRoot.settings) {
                            appRoot.settings.streaming_quality = customModel2.get(qselector2.selectedIndex).key
                            console.log("Streaming Quality: " + appRoot.settings.streaming_quality)
                        }
                    }
                }
            }
            ListModel {
                id: customModel2
                Component.onCompleted: {
                    var qualitys = [i18n.tr("Normal"), i18n.tr("High"), i18n.tr("Extreme")]
                    var keys = ["96", "160", "320"]
                    for (var i = 0; i < qualitys.length; i++){
                        customModel2.append({'name':qualitys[i], 'key':keys[i]})
                    }
                    var selected = 0
                    if (appRoot && appRoot.settings && (appRoot.settings.streaming_quality == '96' || appRoot.settings.streaming_quality == '96000')) {
                        selected = 0
                    } else if (appRoot && appRoot.settings && (appRoot.settings.streaming_quality == '160' || appRoot.settings.streaming_quality == '160000')) {
                        selected = 1
                    } else {
                        selected = 2
                    }
                    qselector2.selectedIndex = selected
                }
            }

            //Theme cloudMusic.settings
            UListItem.ItemSelector {
                id: themeSelector
                text: i18n.tr("Theme")
                model: themeModel
                delegate: themeSelectorDelegate
                Component.onCompleted: {
                    if (appRoot && appRoot.settings && appRoot.settings.theme == 'System') {
                        selectedIndex = 0
                    } else if (appRoot && appRoot.settings && appRoot.settings.theme == 'Ambiance') {
                        selectedIndex = 1
                    } else {
                        selectedIndex = 2
                    }
                }
            }
            ListModel {
                id: themeModel
                ListElement { name: "System" }
                ListElement { name: "Ambiance" }
                ListElement { name: "SuruDark" }
            }
            Component {
                id: themeSelectorDelegate
                OptionSelectorDelegate {
                    text: name
                    onClicked: {
                        if (appRoot && appRoot.settings) {
                            appRoot.settings.theme = name
                            console.log("Theme: " + appRoot.settings.theme)
                        }
                    }
                }
            }
        }
    }
}
