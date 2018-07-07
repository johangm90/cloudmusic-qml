import QtQuick 2.4
import Ubuntu.Components 1.3
import "../components"

Item {
    id: creditsPage

    ListModel {
        id: creditsModel
        Component.onCompleted: initialize()
        function initialize() {
            creditsModel.append({ name: "Johan Guerreros", title: i18n.tr("Developers"), url: "https://launchpad.net/~johangm90" })
            creditsModel.append({ name: "Sam Hewitt", title: i18n.tr("Icon"), url: "https://plus.google.com/+SamHewitt" })
            creditsModel.append({ name: "Ubuntu Translators Community", title: i18n.tr("Translators"), url: "http://community.ubuntu.com/contribute/translations" })
        }
    }

    UbuntuListView {
        id: credits

        currentIndex: -1
        model: creditsModel
        anchors.fill: parent

        section.property: "title"
        section.labelPositioning: ViewSection.InlineLabels
        section.delegate: HeaderListItem {
            title.text: section
        }

        // Required to accomodate the now playing bar being shown in landscape mode which
        // can hide a setting if not for this footer.
        footer: Item {
            width: parent.width
            height: units.gu(8)
        }

        delegate: ListItem {
            ListItemLayout {
                title.text: model.name
                ProgressionSlot {}
            }
            divider.visible: false
            onClicked: Qt.openUrlExternally(model.url)
        }
    }
}
