import QtQuick 2.15
import QtQuick.Window 2.15

Rectangle {
    id: dbg

    property real sceneWidth: 0
    property real sceneHeight: 0
    property string layoutMode: ""
    property real vh: 0

    readonly property real ratio: sceneHeight > 0 ? sceneWidth / sceneHeight : 0

    readonly property var refs: [
        { name: "21:9", r: 21 / 9 },
        { name: "16:9", r: 16 / 9 },
        { name: "3:2",  r: 3 / 2  },
        { name: "4:3",  r: 4 / 3  },
        { name: "1:1",  r: 1      },
        { name: "3:4",  r: 3 / 4  },
        { name: "9:16", r: 9 / 16 }
    ]

    readonly property var nearest: {
        var best = refs[0]
        for (var i = 1; i < refs.length; i++) {
            if (Math.abs(ratio - refs[i].r) < Math.abs(ratio - best.r))
                best = refs[i]
        }
        return best
    }

    readonly property real deviation: Math.abs(ratio - nearest.r) / nearest.r * 100

    anchors {
        left: parent.left
        bottom: parent.bottom
        margins: 6
    }
    z: 99999
    color: "#CC000000"
    radius: 4
    border.color: "#66FFFFFF"
    border.width: 1
    width: info.implicitWidth + 16
    height: info.implicitHeight + 10

    Text {
        id: info
        anchors.centerIn: parent
        color: dbg.deviation < 2 ? "#00FF88" : "#FFD54F"
        font.family: "monospace"
        font.pixelSize: 12
        text: Math.round(dbg.sceneWidth) + " x " + Math.round(dbg.sceneHeight) + " px\n"
        + "ratio " + dbg.ratio.toFixed(3) + "  ~ " + dbg.nearest.name
        + " (" + dbg.deviation.toFixed(1) + "%)\n"
        + "DPR " + Screen.devicePixelRatio.toFixed(2)
        + (dbg.layoutMode !== "" ? "\nmode " + dbg.layoutMode : "")
        + (dbg.vh > 0 ? "  vh " + dbg.vh.toFixed(2) + "px" : "")
    }

    Shortcut {
        sequence: "F9"
        onActivated: dbg.visible = !dbg.visible
    }
}
