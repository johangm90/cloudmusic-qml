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
    property real spacingSmall: appRoot ? appRoot.spacingSmall : units.gu(0.8)
    property real spacingMedium: appRoot ? appRoot.spacingMedium : units.gu(1.2)
    property real spacingLarge: appRoot ? appRoot.spacingLarge : units.gu(1.8)
    property real compactSpacing: spacingSmall + units.gu(0.2)
    property real contentBottomInset: units.gu(10)
    property real headerOffset: spacingLarge + units.gu(3.2)
    property real sectionSpacing: spacingLarge + spacingMedium
    property real tabsHeight: units.gu(6)
    property real tabsBottomGap: units.gu(1)
    property string headingTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.heading : "x-large"
    property string smallTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.bodySmall : "small"
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
                contentHeight: dataColumn.height + contentBottomInset + dataColumn.anchors.topMargin

                Column {
                    id: dataColumn
                    spacing: sectionSpacing
                    anchors {
                        top: parent.top; left: parent.left; right: parent.right; topMargin: headerOffset
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
                            fontSize: headingTextSize
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
                            margins: spacingMedium + spacingSmall
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            text: "(C) 2015 - " + date.getFullYear() + " Johan Guerreros"
                            color: secondaryTextColor
                        }
                        Label {
                            fontSize: smallTextSize
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            text: i18n.tr("Released under the terms of the GNU GPL v3")
                            color: secondaryTextColor
                        }
                    }

                    Button {
                        x: (parent.width - width) / 2
                        color: accentColor
                        text: i18n.tr("Donate")
                        onClicked: Qt.openUrlExternally("https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4CRZUPJYLN8G2")
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        fontSize: smallTextSize
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
        spacing: compactSpacing

        Rectangle {
            id: aboutTabs
            width: parent.width
            height: tabsHeight
            color: "transparent"

            SegmentedTabs {
                anchors.fill: parent
                labels: [i18n.tr("About"), i18n.tr("Credits")]
                currentIndex: aboutPage.currentTab
                activeColor: aboutPage.accentColor
                textColor: aboutPage.textColor
                activeTextColor: aboutPage.inverseTextColor
                borderColor: aboutPage.borderColor
                backgroundColor: aboutPage.cardColor
                onSelected: function(index) { aboutPage.currentTab = index }
            }
        }

        Item {
            width: parent.width
            height: parent.height - aboutTabs.height - tabsBottomGap

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
