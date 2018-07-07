import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import "../components"

Component {
    id: warningDialog

    Dialog {
        id: dialogue
        title: "<b>" + i18n.tr("What's new?")


        Flickable {
            width: parent.width
            height: cloudMusic.height/4
            contentHeight: flickableColumn.height
            clip: true
            Column {
                id: flickableColumn
                width: parent.width
                spacing: units.gu(0.5)

                ChangeLogListItem {
                    app_version: cloudMusic.app_version
                    changesModel: [
                        "[FIX] Small bugs fixs",
                        "[NOTE] Enjoy it."
                    ]
                }
            }
        }

        Button {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#043288"
            text: i18n.tr("Donate")
            onClicked: Qt.openUrlExternally("https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4CRZUPJYLN8G2")
        }

        Button {
            id: button2
            width: parent.width - units.gu(3)
            text: i18n.tr("Close")
            color: UbuntuColors.red
            onClicked: {
                PopupUtils.close(dialogue)
                cloudMusic.settings.current_version = cloudMusic.app_version
            }
        }

    }

}
