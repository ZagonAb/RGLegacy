import QtQuick 2.15

Item {
    id: dotsRoot

    readonly property int total: api.collections.count
    readonly property real maxDot: metrics.dotsMaxSize
    readonly property real fitDot: total > 0 ? (root.width * metrics.dotsMaxWidthFraction) / (total * (1 + metrics.dotsSpacingFactor)) : maxDot
    readonly property real dotSize: Math.min(maxDot, fitDot)
    readonly property bool compact: fitDot < metrics.dotsCompactMinSize

    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
        bottomMargin: Math.max(metrics.dotsBottomMargin,
                               gamesCount.height + gamesCount.anchors.bottomMargin + metrics.dotsClearanceAboveCount)
    }

    width: compact ? counter.implicitWidth : dotsRow.width
    height: compact ? counter.implicitHeight : dotsRow.height
    visible: collectionsVisible

    Row {
        id: dotsRow
        visible: !dotsRoot.compact
        spacing: dotsRoot.dotSize * metrics.dotsSpacingFactor

        Repeater {
            model: api.collections.count

            Rectangle {
                width: dotsRoot.dotSize
                height: dotsRoot.dotSize
                radius: width / 2
                color: "white"
                border {
                    width: 1
                    color: "white"
                }

                opacity: systemView.currentIndex === index ? 1 : 0.5

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }
        }
    }

    Text {
        id: counter
        visible: dotsRoot.compact
        text: (systemView.currentIndex + 1) + " / " + dotsRoot.total
        color: "white"
        opacity: 0.8
        font.bold: true
        font.pixelSize: metrics.dotsCounterFontSize
    }
}
