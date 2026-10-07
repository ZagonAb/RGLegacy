import QtQuick 2.15
import QtGraphicalEffects 1.12

PathView {
    id: systemView
    width: parent.width
    height: parent.height * metrics.collectionHeight

    anchors {
        horizontalCenter: parent.horizontalCenter
        top: parent.top
        topMargin: parent.height * metrics.collectionTop
    }

    model: api.collections
    pathItemCount: Math.min(metrics.collectionVisibleItems, model.count)
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange
    highlightMoveDuration: 300
    opacity: collectionsVisible ? 1 : 0
    visible: collectionsVisible

    property real step: width * metrics.collectionStep
    property real itemSpacing: pathItemCount > 1 ? step * pathItemCount / (pathItemCount - 1) : step
    property real delegateSize: Math.min(step * metrics.collectionDelegateK, height * 0.9)

    path: Path {
        startX: systemView.width / 2 - ((systemView.pathItemCount - 1) * systemView.itemSpacing) / 2
        startY: systemView.height / 2
        PathLine {
            x: systemView.width / 2 + ((systemView.pathItemCount - 1) * systemView.itemSpacing) / 2
            y: systemView.height / 2
        }
    }

    delegate: Item {
        id: delegateItem

        width: systemView.delegateSize
        height: systemView.delegateSize
        scale: PathView.isCurrentItem ? 1 : metrics.collectionSideScale
        opacity: {
            const distance = Math.abs(PathView.view.currentIndex - index)
            return distance <= 2 ? 1 - (distance * 0.15) : 0.7
        }
        z: PathView.isCurrentItem ? 1 : 0

        readonly property real slotOffset: (x + width / 2 - systemView.width / 2) / systemView.step

        function shiftFor(d) {
            var a = Math.abs(d)
            if (a < 0.0001) return 0
                var near = metrics.collectionShiftNear * systemView.step
                var far = metrics.collectionShiftFar * systemView.step
                var v
                if (a <= 1)
                    v = near * Math.sin(Math.PI / 2 * a)
                    else if (a <= 2)
                        v = near + (far - near) * (1 - Math.cos(Math.PI * (a - 1))) / 2
                        else
                            v = far
                            return d < 0 ? -v : v
        }

        transform: Translate { x: delegateItem.shiftFor(delegateItem.slotOffset) }

        Rectangle {
            id: selectionRect
            anchors {
                fill: parent
                margins: -parent.width * 0.0
                topMargin: -parent.width * 0.02
                bottomMargin: -systemView.height * metrics.collectionCapsuleExtra
            }
            color: delegateItem.PathView.isCurrentItem ? "#33FFFFFF" : "transparent"
            border.color: "white"
            border.width: Math.max(2, parent.width * 0.015)
            radius: parent.width * 0.2
            opacity: delegateItem.PathView.isCurrentItem ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
            Behavior on color {
                ColorAnimation { duration: 300 }
            }

            MouseArea {
                anchors.fill: parent
                property int clickCount: 0

                onClicked: {
                    clickCount++

                    if (clickCount === 1) {
                        systemView.currentIndex = index
                    } else if (clickCount >= 2) {
                        clickCount = 0
                        systemView.currentIndex = index
                        naviSound.play()

                        if (gameImage && gameImage.videoLoader) {
                            gameImage.videoLoader.active = true
                        }

                        collectionsVisible = false
                        collectionsFocused = false
                        gamesVisible = true
                        gamesFocused = true
                        gameListView.forceActiveFocus()
                    }
                }
            }
        }

        Image {
            id: systemIcon
            anchors {
                fill: parent
                margins: parent.width * 0.05
            }

            source: "assets/shortnames/" + model.shortName + ".png"
            fillMode: Image.PreserveAspectFit
            mipmap: true
            asynchronous: true

            onStatusChanged: {
                if (status === Image.Error) {
                    source = "assets/shortnames/default.png"
                }
            }
        }

        Column {
            anchors {
                bottom: selectionRect.bottom
                bottomMargin: selectionRect.height * 0.05
                horizontalCenter: parent.horizontalCenter
            }
            spacing: parent.height * 0.01

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: delegateItem.width * metrics.collectionNameWidthFactor
                horizontalAlignment: Text.AlignHCenter
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 8
                text: modelData.shortName.toUpperCase() || ""
                color: "white"
                font.bold: true
                font.pixelSize: Math.max(metrics.collectionNameMinFont, delegateItem.width * metrics.collectionNameFontFactor)
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "(" + getConsoleYear(modelData.shortName) + ")"
                color: "white"
                font.pixelSize: Math.max(metrics.collectionYearMinFont, delegateItem.width * metrics.collectionYearFontFactor)
                font.bold: true
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }

    focus: collectionsFocused

    Keys.onLeftPressed: decrementCurrentIndex(naviSound.play())
    Keys.onRightPressed: incrementCurrentIndex(naviSound.play())

    Keys.onPressed: {
        if (event.isAutoRepeat) {
            return
        }

        if (api.keys.isAccept(event)) {
            naviSound.play()
            if (gameImage.videoLoader) {
                gameImage.videoLoader.active = true
            }
            event.accepted = true
            collectionsVisible = false
            collectionsFocused = false
            gamesVisible = true
            gamesFocused = true
            gameListView.forceActiveFocus()
        } else if (api.keys.isNextPage(event)) {
            naviSound.play()
            event.accepted = true
            incrementCurrentIndex()
        } else if (api.keys.isPrevPage(event)) {
            naviSound.play()
            event.accepted = true
            decrementCurrentIndex()
        }
    }

    onCurrentIndexChanged: {
        const selectedCollection = api.collections.get(currentIndex)
        proxyModel.sourceModel = selectedCollection.games
        currentCollectionName = model.get(currentIndex).name
        currentShortName = model.get(currentIndex).shortName
        root.backgroundColor = getColorForSystem(currentShortName)

        if (gameImage && gameImage.isVideoType && gameImage.resetMedia) {
            gameImage.resetMedia()
        }
        proxyModel.invalidate()
    }

    Component.onCompleted: {
        currentIndex = 0
        const initialCollection = api.collections.get(currentIndex)
        proxyModel.sourceModel = initialCollection.games
        currentCollectionName = model.get(currentIndex).name
        currentShortName = model.get(currentIndex).shortName
        root.backgroundColor = getColorForSystem(currentShortName)
        game = proxyModel.get(gameListView.currentIndex)
    }
}
