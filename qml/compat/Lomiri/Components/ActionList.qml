import QtQuick 2.7

QtObject {
    id: root
    default property list<QtObject> children
    property alias actions: root.children
}
