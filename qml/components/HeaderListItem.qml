import QtQuick 2.12
import Lomiri.Components 1.3

ListItem {
    id: headerListItem
    property var appRoot: (typeof cloudMusic !== "undefined" ? cloudMusic : null)
    property real dividerInset: appRoot ? (appRoot.spacingMedium + appRoot.spacingSmall) : units.gu(2)

    property alias title: headerText.title

    height: headerText.height + divider.height
    divider.anchors.leftMargin: dividerInset
    divider.anchors.rightMargin: dividerInset

    ListItemLayout {
        id: headerText
        title.text: " "
        title.font.weight: Font.DemiBold
    }
}
