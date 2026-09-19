import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.3 as UListItem
import "../components"

Page {
    id: settingsPage
    property var appRoot
    property color pageColor: appRoot ? appRoot.pageColor : "#f5f5f5"
    property color textColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color secondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#666666"
    property color surfaceColor: appRoot ? appRoot.surfaceElevatedColor : "#ffffff"
    property real radiusMedium: appRoot ? appRoot.radiusMedium : units.gu(1.2)
    property real spacingMedium: appRoot ? appRoot.spacingMedium : units.gu(1.2)

    header: PageHeader {
        title: i18n.tr("Settings")
    }

    Rectangle {
        color: pageColor
        anchors {
            top: settingsPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: settingsContent.implicitHeight + spacingMedium * 2
            clip: true

            Column {
                id: settingsContent
                x: spacingMedium
                y: spacingMedium
                width: parent.width - spacingMedium * 2
                spacing: spacingMedium

                Label {
                    text: i18n.tr("Make CloudMusic yours")
                    color: textColor
                    fontSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.heading : "x-large"
                    font.weight: Font.DemiBold
                }

                Label {
                    width: parent.width
                    text: i18n.tr("Tune playback quality and appearance without leaving your music.")
                    color: secondaryTextColor
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: i18n.tr("Playback")
                    color: textColor
                    fontSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.title : "large"
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    width: parent.width
                    height: qselector.implicitHeight + units.gu(2)
                    radius: radiusMedium
                    color: surfaceColor

                    UListItem.ItemSelector {
                        id: qselector
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
                        text: i18n.tr("Download quality")
                        model: customModel
                        delegate: selectorDelegate
                    }
                }

                Rectangle {
                    width: parent.width
                    height: qselector2.implicitHeight + units.gu(2)
                    radius: radiusMedium
                    color: surfaceColor

                    UListItem.ItemSelector {
                        id: qselector2
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
                        text: i18n.tr("Streaming quality")
                        model: customModel2
                        delegate: selectorDelegate2
                    }
                }

                Label {
                    text: i18n.tr("Appearance")
                    color: textColor
                    fontSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.title : "large"
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    width: parent.width
                    height: themeSelector.implicitHeight + units.gu(2)
                    radius: radiusMedium
                    color: surfaceColor

                    UListItem.ItemSelector {
                        id: themeSelector
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
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
}
