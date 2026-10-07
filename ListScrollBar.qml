import QtQuick 2.15

Item {
    id: bar

    property Item view: null
    property color trackColor: "#26FFFFFF"
    property color thumbColor: "#D9FFFFFF"
    property real minThumbHeight: 24

    readonly property real ratio: (view && view.visibleArea) ? view.visibleArea.heightRatio : 1
    readonly property real pos: (view && view.visibleArea) ? view.visibleArea.yPosition : 0

    visible: ratio < 0.999

    Rectangle {
        id: track
        anchors.fill: parent
        radius: width / 2
        color: bar.trackColor
    }

    Rectangle {
        id: thumb
        width: parent.width
        radius: width / 2
        color: bar.thumbColor
        height: Math.min(parent.height, Math.max(bar.minThumbHeight, parent.height * bar.ratio))
        y: (bar.ratio < 0.999)
           ? Math.max(0, Math.min(1, bar.pos / (1 - bar.ratio))) * (parent.height - height)
           : 0
    }
}
