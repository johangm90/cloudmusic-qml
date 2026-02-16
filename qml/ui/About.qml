import QtQuick 2.12
import QtQuick.Controls 2.12
import Lomiri.Components 1.3
import "../components"

Page {
    id: aboutPage
    property var appRoot
    property int currentTab: 0
    property int tabAnimDuration: LomiriAnimation.FastDuration
    property var date: new Date()
    property color pageColor: appRoot ? appRoot.pageColor : "#f5f5f5"
    property color cardColor: appRoot ? appRoot.cardColor : "#ffffff"
    property color borderColor: appRoot ? appRoot.borderColor : "#d8d8d8"
    property color textColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color inverseTextColor: appRoot ? appRoot.inverseTextColor : "#ffffff"
    property color accentColor: appRoot ? appRoot.primaryColor : "#e53446"
    property color primaryTextColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color secondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#666666"
    property string versionText: appRoot && appRoot.app_version ? appRoot.app_version : Qt.application.version

    TabsList {
        id: tabsList
    }

    header: PageHeader {
        id: aboutPageHeader

        title: i18n.tr("About")

        leadingActionBar {
            numberOfSlots: 0
            actions: tabsList.actions
        }
    }


    Component {
        id: aboutSectionComponent

        Item {
            Flickable {
                id: flickable
                anchors.fill: parent
                contentHeight: dataColumn.height + units.gu(10) + dataColumn.anchors.topMargin

                Column {
                    id: dataColumn
                    spacing: units.gu(3)
                    anchors {
                        top: parent.top; left: parent.left; right: parent.right; topMargin: units.gu(5)
                    }

                    LomiriShape {
                        width: Math.min(parent.width/2, parent.height/2)
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: "medium"
                        image: Image{
                            source: "qrc:/assets/logo.svg"
                        }
                    }

                    Column {
                        width: parent.width
                        Label {
                            width: parent.width
                            fontSize: "x-large"
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            text: "Cloud Music"
                            color: primaryTextColor
                        }
                        Label {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            // TRANSLATORS: App version number e.g Version 1.0.0
                            text: i18n.tr("Version %1").arg(versionText)
                            color: secondaryTextColor
                        }
                    }

                    Column {
                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: units.gu(2)
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            text: "(C) 2015 - " + date.getFullYear() + " Johan Guerreros"
                            color: secondaryTextColor
                        }
                        Label {
                            fontSize: "small"
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            text: i18n.tr("Released under the terms of the GNU GPL v3")
                            color: secondaryTextColor
                        }
                    }

                    Button {
                        x: (parent.width - width) / 2
                        color: appRoot ? appRoot.primaryColor : "#e53446"
                        text: i18n.tr("Donate")
                        onClicked: Qt.openUrlExternally("https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4CRZUPJYLN8G2")
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        fontSize: "small"
                        horizontalAlignment: Text.AlignHCenter
                        linkColor: LomiriColors.blue
                        text: i18n.tr("Report bugs on %1").arg("<a href=\"https://github.com/johangm90/cloudmusic-qml/issues\">github.com</a>")
                        color: secondaryTextColor
                        onLinkActivated: Qt.openUrlExternally(link)
                    }
                }
            }
        }
    }

    Component {
        id: creditsSectionComponent
        Credits {
            appRoot: aboutPage.appRoot
        }
    }

    Rectangle {
        anchors {
            top: aboutPageHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        color: pageColor

        Column {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 0
        }
        spacing: units.gu(1)

        Rectangle {
            id: aboutTabs
            width: parent.width
            height: units.gu(6)
            color: cardColor
            border.color: borderColor
            border.width: 1
            radius: units.gu(1)
            clip: true

            Row {
                anchors.fill: parent
                anchors.margins: units.gu(0.6)
                spacing: units.gu(0.6)

                Rectangle {
                    width: (parent.width - units.gu(0.6)) / 2
                    height: parent.height
                    radius: units.gu(0.8)
                    color: currentTab === 0 ? accentColor : "transparent"
                    border.color: currentTab === 0 ? accentColor : borderColor
                    border.width: 1

                    Label {
                        anchors.centerIn: parent
                        text: i18n.tr("About")
                        fontSize: "small"
                        font.weight: Font.DemiBold
                        color: currentTab === 0 ? inverseTextColor : textColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: currentTab = 0
                    }
                }

                Rectangle {
                    width: (parent.width - units.gu(0.6)) / 2
                    height: parent.height
                    radius: units.gu(0.8)
                    color: currentTab === 1 ? accentColor : "transparent"
                    border.color: currentTab === 1 ? accentColor : borderColor
                    border.width: 1

                    Label {
                        anchors.centerIn: parent
                        text: i18n.tr("Credits")
                        fontSize: "small"
                        font.weight: Font.DemiBold
                        color: currentTab === 1 ? inverseTextColor : textColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: currentTab = 1
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: parent.height - aboutTabs.height - units.gu(1)

            Loader {
                id: aboutLoader
                anchors.fill: parent
                sourceComponent: aboutSectionComponent
                visible: opacity > 0
                opacity: currentTab === 0 ? 1 : 0
                Behavior on opacity {
                    LomiriNumberAnimation { duration: tabAnimDuration }
                }
            }

            Loader {
                id: creditsLoader
                anchors.fill: parent
                sourceComponent: creditsSectionComponent
                visible: opacity > 0
                opacity: currentTab === 1 ? 1 : 0
                Behavior on opacity {
                    LomiriNumberAnimation { duration: tabAnimDuration }
                }
            }
        }
    }
    }
}
