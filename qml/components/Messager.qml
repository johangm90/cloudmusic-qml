import QtQuick 2.12
import Lomiri.Components 1.3

Item {
    anchors.fill: parent
    property var appRoot: (typeof cloudMusic !== "undefined" ? cloudMusic : null)
    property real spacingSmall: appRoot ? appRoot.spacingSmall : units.gu(0.8)
    property real spacingMedium: appRoot ? appRoot.spacingMedium : units.gu(1.2)
    property real layoutPlayerInset: appRoot ? appRoot.layoutPlayerInset : units.gu(7.25)
    property real bubblePadding: units.gu(4)
    property real messageSideInset: units.gu(6)

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
        anchors.bottomMargin: layoutPlayerInset - units.gu(2.25)
        z : 999

        Rectangle {
            id: message_bg
            color: cloudMusic && cloudMusic.designTokens ? cloudMusic.designTokens.color.toastBg : "#000"
            width: lbl_message.contentWidth + bubblePadding
            height: bubblePadding * lbl_message.lineCount
            opacity: 0.8
            radius: (lbl_message.height + bubblePadding) / 2;
            anchors.centerIn: parent
        }

        Label {
            id: lbl_message
            color: cloudMusic && cloudMusic.designTokens ? cloudMusic.designTokens.color.toastText : "#fff"
            width: parent.width - messageSideInset
            anchors {
                centerIn: parent
            }
            wrapMode: Label.WordWrap
            horizontalAlignment: Label.AlignHCenter
            verticalAlignment: Label.AlignVCenter
        }
    }

}
