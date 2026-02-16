import QtQuick 2.12
import Lomiri.Components 1.3
import "../components"

Item {
    id: creditsPage
    property var appRoot
    property color pageColor: appRoot ? appRoot.pageColor : "#f5f5f5"
    property color cardColor: appRoot ? appRoot.cardColor : "#ffffff"
    property color borderColor: appRoot ? appRoot.borderColor : "#d8d8d8"
    property color sectionColor: appRoot ? appRoot.sectionColor : "#ececec"
    property color textColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color secondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#666666"

    ListModel {
        id: creditsModel
        Component.onCompleted: initialize()
        function initialize() {
            creditsModel.append({ name: "Johan Guerreros", title: i18n.tr("Developers"), url: "https://gitlab.com/johangm90" })
            creditsModel.append({ name: "Matteo", title: i18n.tr("Developers"), url: "https://gitlab.com/mattbel10" })
            creditsModel.append({ name: "Sam Hewitt", title: i18n.tr("Icon"), url: "https://plus.google.com/+SamHewitt" })
            creditsModel.append({ name: "Ubuntu Translators Community", title: i18n.tr("Translators"), url: "http://community.ubuntu.com/contribute/translations" })
        }
    }

    Rectangle {
        anchors.fill: parent
        color: pageColor
    }

    ListView {
        id: credits

        currentIndex: -1
        model: creditsModel
        anchors.fill: parent

        section.property: "title"
        section.labelPositioning: ViewSection.InlineLabels
        section.delegate: Rectangle {
            width: credits.width
            height: units.gu(4.5)
            color: sectionColor
            border.color: borderColor
            border.width: 1

            Label {
                anchors.fill: parent
                anchors.leftMargin: units.gu(1.5)
                verticalAlignment: Text.AlignVCenter
                fontSize: "small"
                font.weight: Font.DemiBold
                text: section
                color: textColor
            }
        }

        // Required to accomodate the now playing bar being shown in landscape mode which
        // can hide a setting if not for this footer.
        footer: Item {
            width: parent.width
            height: units.gu(8)
        }

        delegate: Rectangle {
            width: credits.width
            height: units.gu(6)
            color: cardColor
            border.color: borderColor
            border.width: 1

            Label {
                anchors.left: parent.left
                anchors.right: chevron.left
                anchors.leftMargin: units.gu(1.5)
                anchors.rightMargin: units.gu(1)
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: model.name
                color: textColor
            }

            Icon {
                id: chevron
                anchors.right: parent.right
                anchors.rightMargin: units.gu(1.2)
                anchors.verticalCenter: parent.verticalCenter
                width: units.gu(2.4)
                height: width
                name: "go-next"
                color: secondaryTextColor
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Qt.openUrlExternally(model.url)
            }
        }
    }
}
