import QtQuick 2.12
import Ubuntu.Components 1.3

Item {
    anchors.fill: parent

    function show_message(text, duration) {
        lbl_message.text = text
        timer.duration = duration
        message_view.visible = true
        timer.start()
    }

    Timer {
        id: timer
        property int duration: 0
        interval: 1000
        running: false
        repeat: true
        onTriggered: {
            if(timer.duration > 1) {
                timer.duration -= 1;
            }else {
                timer.stop()
                message_view.visible = false
            }
        }
    }

    Rectangle {
        id: message_view
        visible: false
        color: "transparent"
        width: parent.width
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(5)
        z : 999

        Rectangle {
            id: message_bg
            color: "#000"
            width: lbl_message.contentWidth + units.gu(4)
            height: units.gu(4) * lbl_message.lineCount
            opacity: 0.8
            radius: (lbl_message.height + units.gu(4)) / 2;
            anchors.centerIn: parent
        }

        Label {
            id: lbl_message
            color: "#fff"
            width: parent.width - units.gu(6)
            anchors {
                centerIn: parent
            }
            wrapMode: Label.WordWrap
            horizontalAlignment: Label.AlignHCenter
            verticalAlignment: Label.AlignVCenter
        }
    }

}

