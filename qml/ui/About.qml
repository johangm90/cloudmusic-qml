import QtQuick 2.4
import Ubuntu.Components 1.3
import "../components"

Page {
    id: aboutPage
    property var date: new Date()

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

        extension: Sections {
            id: aboutPageHeaderSections

            anchors {
                left: parent.left
                bottom: parent.bottom
            }
            // TRANSTORS: Credits as in the code and design contributors to the app
            model: [i18n.tr("About"), i18n.tr("Credits")]
        }
    }


    VisualItemModel {
        id: sections

        Item {
            width: tabView.width
            height: tabView.height

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

                    UbuntuShape {
                        width: Math.min(parent.width/2, parent.height/2)
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: "medium"
                        image: Image{
                            source: "../../assets/logo.svg"
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
                        }
                        Label {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            // TRANSLATORS: App version number e.g Version 1.0.0
                            text: i18n.tr("Version %1").arg(cloudMusic.app_version)
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
                        }
                        Label {
                            fontSize: "small"
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            text: i18n.tr("Released under the terms of the GNU GPL v3")
                        }
                    }

                    Button {
                        x: (parent.width - width) / 2
                        color: "#e53446"
                        text: i18n.tr("Donate")
                        onClicked: Qt.openUrlExternally("https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4CRZUPJYLN8G2")
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        fontSize: "small"
                        horizontalAlignment: Text.AlignHCenter
                        linkColor: UbuntuColors.blue
                        text: i18n.tr("Report bugs on %1").arg("<a href=\"https://gitlab.com/johangm90/cloudmusic-qml/issues\">gitlab.com</a>")
                        onLinkActivated: Qt.openUrlExternally(link)
                    }
                }
            }
        }

        Credits {
            width: tabView.width
            height: tabView.height
        }
    }

    ListView {
        id: tabView
        model: sections
        interactive: false

        anchors {
            top: aboutPageHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        currentIndex: aboutPageHeaderSections.selectedIndex
        highlightMoveDuration: UbuntuAnimation.SlowDuration
    }
}
