import QtQuick 2.15

Item {
    id: marquee

    property string text: ""
    property color color: "white"
    property alias font: label.font
    property bool scrollingEnabled: true
    property int horizontalAlignment: Text.AlignHCenter
    property real speed: 45
    property int delay: 1200
    property string separator: "  •  "

    clip: true
    implicitHeight: label.implicitHeight

    readonly property bool needsScroll: scrollingEnabled && label.implicitWidth > width
    readonly property real cycleWidth: label.implicitWidth + sep.implicitWidth
    property real scrollOffset: 0

    onNeedsScrollChanged: if (!needsScroll) scrollOffset = 0

    onCycleWidthChanged: {
        scrollOffset = 0;
        if (needsScroll) anim.restart();
    }

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: marquee.text
        textFormat: Text.PlainText
        color: marquee.color
        width: marquee.needsScroll ? implicitWidth : marquee.width
        horizontalAlignment: marquee.needsScroll ? Text.AlignLeft : marquee.horizontalAlignment
        x: -marquee.scrollOffset
    }

    Text {
        id: sep
        anchors.verticalCenter: parent.verticalCenter
        text: marquee.separator
        textFormat: Text.PlainText
        color: marquee.color
        font: label.font
        x: label.implicitWidth - marquee.scrollOffset
        visible: marquee.needsScroll
    }

    Text {
        id: copy
        anchors.verticalCenter: parent.verticalCenter
        text: marquee.text
        textFormat: Text.PlainText
        color: marquee.color
        font: label.font
        x: marquee.cycleWidth - marquee.scrollOffset
        visible: marquee.needsScroll
    }

    SequentialAnimation {
        id: anim
        loops: Animation.Infinite
        running: marquee.needsScroll

        PauseAnimation { duration: marquee.delay }
        NumberAnimation {
            target: marquee
            property: "scrollOffset"
            from: 0
            to: marquee.cycleWidth
            duration: marquee.cycleWidth / marquee.speed * 1000
            easing.type: Easing.Linear
        }
    }
}
