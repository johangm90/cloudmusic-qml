import QtQuick 2.12
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as UListItem
import "../components"

Page {
    id: settingsPage

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

    Column {
        anchors {
            top: settingsPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

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
                    cloudMusic.settings.download_quality = customModel.get(qselector.selectedIndex).key
                    console.log("Download Quality: " + cloudMusic.settings.download_quality)
                }
            }
        }
        ListModel {
            id: customModel
            Component.onCompleted: {
                var qualitys = [i18n.tr("Normal"), i18n.tr("High"), i18n.tr("Extreme")]
                var keys = ["96000", "160000", "320000"]
                for (var i = 0; i < qualitys.length; i++){
                    customModel.append({'name':qualitys[i], 'key':keys[i]})
                }
                var selected = 0
                if(cloudMusic.settings.download_quality=='96000'){
                    selected = 0
                }else if(cloudMusic.settings.download_quality=='160000'){
                    selected = 1
                }else{
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
                    cloudMusic.settings.streaming_quality = customModel2.get(qselector2.selectedIndex).key
                    console.log("Streaming Quality: "+cloudMusic.settings.streaming_quality)
                }
            }
        }
        ListModel {
            id: customModel2
            Component.onCompleted: {
                var qualitys = [i18n.tr("Normal"), i18n.tr("High"), i18n.tr("Extreme")]
                var keys = ["96000", "160000", "320000"]
                for (var i = 0; i < qualitys.length; i++){
                    customModel2.append({'name':qualitys[i], 'key':keys[i]})
                }
                var selected = 0
                if(cloudMusic.settings.streaming_quality=='96000'){
                    selected = 0
                }else if(cloudMusic.settings.streaming_quality=='160000'){
                    selected = 1
                }else{
                    selected = 2
                }
                qselector2.selectedIndex = selected
            }
        }
        //Theme cloudMusic.settings
        UListItem.ItemSelector {
            property variant themeModel: [i18n.tr("Ambiance"), i18n.tr("SuruDark")]
            id: themeSelector
            text: i18n.tr("Theme")
            model: themeModel
            delegate: themeSelectorDelegate
            Component.onCompleted: {
                if(cloudMusic.settings.theme == 'Ambiance'){
                    selectedIndex = 0
                }else{
                    selectedIndex = 1
                }
            }
        }
        ListModel {
            id: themeModel
            ListElement { name: "Ambiance" }
            ListElement { name: "SuruDark" }
        }
        Component {
            id: themeSelectorDelegate
            OptionSelectorDelegate {
                text: name
                onClicked: {
                    cloudMusic.settings.theme = themeModel.get(themeSelector.selectedIndex).name
                    console.log("Theme: "+ cloudMusic.settings.theme)
                }
            }
        }
    }
}
