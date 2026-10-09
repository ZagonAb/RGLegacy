import QtQuick 2.15

// Barra superior de la pantalla de colecciones:
// reloj a la izquierda; porcentaje + icono de batería a la derecha.
// Tamaños y márgenes: LayoutMetrics.qml (clock*, battery*, topBarHeight).
Item {
    id: topBar

    width: parent.width
    height: metrics.topBarHeight
    anchors.top: parent.top
    visible: collectionsVisible

    // ------------------------------------------------------------------ RELOJ
    Text {
        id: clock
        anchors.left: parent.left
        anchors.leftMargin: metrics.clockLeftMargin
        anchors.verticalCenter: parent.verticalCenter
        color: "white"
        font.pixelSize: metrics.clockFontSize
        font.bold: true
        horizontalAlignment: Text.AlignLeft

        function formatTime() {
            let date = new Date()
            let hours = date.getHours()
            let minutes = date.getMinutes()
            let ampm = hours >= 12 ? "PM" : "AM"
            hours = hours % 12
            hours = hours ? hours : 12
            let minutesStr = minutes < 10 ? "0" + minutes : minutes
            return hours + ":" + minutesStr + " " + ampm
        }

        text: formatTime()

        Timer {
            running: topBar.visible
            interval: 1000
            repeat: true
            triggeredOnStart: true
            onTriggered: clock.text = clock.formatTime()
        }
    }

    // ---------------------------------------------------------------- BATERÍA
    Item {
        id: batteryStatus
        anchors.right: parent.right
        anchors.rightMargin: metrics.batteryRightMargin
        anchors.verticalCenter: parent.verticalCenter
        width: statusRow.width
        height: Math.max(batteryIcon.height, batteryPercentText.implicitHeight)

        QtObject {
            id: batteryPoller
            property int cachedPercent: 0
            property bool cachedCharging: false
            property bool hasBattery: false

            function poll() {
                const pct = api.device.batteryPercent
                if (!isNaN(pct)) {
                    hasBattery = true
                    cachedPercent = Math.round(pct * 100)
                    cachedCharging = api.device.batteryCharging
                } else {
                    hasBattery = false
                }
            }
        }

        Timer {
            id: batteryTimer
            interval: 500
            repeat: true
            running: topBar.visible
            triggeredOnStart: true
            onTriggered: batteryPoller.poll()
        }

        Connections {
            target: api.device
            function onBatteryChargingChanged() { batteryPoller.poll() }
            function onBatteryPercentChanged() { batteryPoller.poll() }
        }

        Row {
            id: statusRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: metrics.batteryGap

            Text {
                id: batteryPercentText
                anchors.verticalCenter: parent.verticalCenter
                visible: metrics.batteryShowPercent && batteryPoller.hasBattery
                text: batteryPoller.cachedPercent + "%"
                color: "white"
                font.pixelSize: metrics.batteryPercentFontSize
                font.bold: true
            }

            Image {
                id: batteryIcon
                anchors.verticalCenter: parent.verticalCenter
                width: metrics.batteryIconSize
                height: width
                mipmap: true
                smooth: true
                fillMode: Image.PreserveAspectFit
                sourceSize { width: 128; height: 128 }

                readonly property int iconIndex: {
                    if (batteryPoller.cachedCharging)
                        return Math.min(10, Math.round(batteryPoller.cachedPercent / 10))
                    else
                        return Math.min(9, Math.floor(batteryPoller.cachedPercent / 10))
                }

                source: {
                    if (!batteryPoller.hasBattery)
                        return "assets/icons/no_battery.svg"
                    if (batteryPoller.cachedCharging)
                        return "assets/icons/charging/fluent--battery-charge-" + iconIndex + "-20-regular.svg"
                    return "assets/icons/not-charging/fluent--battery-" + iconIndex + "-20-regular.svg"
                }

                onStatusChanged: {
                    if (status === Image.Error)
                        source = "assets/icons/no_battery.svg"
                }
            }
        }
    }
}
