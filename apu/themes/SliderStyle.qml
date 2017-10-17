import QtQuick 2.4
import Ubuntu.Components 1.3

/*
  The default slider style consists of a bar and a thumb shape.

  This style is themed using the following properties:
  - thumbSpacing: spacing between the thumb and the bar
*/
Item {
    id: sliderStyle

    property color foregroundColor: "#e53446" // CUSTOM
    property color backgroundColor: "#333333" // CUSTOM

    property real thumbSpacing: units.gu(0)
    property Item bar: background
    property Item thumb: thumb

    implicitWidth: units.gu(38)
    implicitHeight: units.gu(5)

    UbuntuShape {
        id: background
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            left: parent.left
        }
        height: units.dp(4)

        backgroundColor: "white"
    }

    PartialColorizeUbuntuShape {
        anchors.fill: background
        sourceItem: background
        progress: thumb.x / thumb.barMinusThumbWidth
        leftColor: foregroundColor
        rightColor: backgroundColor
        mirror: Qt.application.layoutDirection == Qt.RightToLeft
    }

    Rectangle {
        id: thumb

        anchors {
            verticalCenter: parent.verticalCenter
            topMargin: thumbSpacing
            bottomMargin: thumbSpacing
        }

        property real barMinusThumbWidth: background.width - (thumb.width + 2.0*thumbSpacing)
        property real position: thumbSpacing + SliderUtils.normalizedValue(styledItem) * barMinusThumbWidth
        property bool pressed: SliderUtils.isPressed(styledItem)
        property bool positionReached: x == position
        x: position

        /* Enable the animation on x when pressing the slider.
           Disable it when x has reached the target position.
        */
        onPressedChanged: if (pressed) xBehavior.enabled = true;
        onPositionReachedChanged: if (positionReached) xBehavior.enabled = false;

        Behavior on x {
            id: xBehavior
            SmoothedAnimation {
                duration: UbuntuAnimation.FastDuration
            }
        }
        width: units.gu(2)
        height: units.gu(2)
        radius: units.gu(1)
        opacity: 0.97
        color: Theme.palette.normal.overlay
    }
}
