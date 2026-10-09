import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12
import SortFilterProxyModel 0.2
import QtMultimedia 5.8
import QtQuick.Window 2.15

FocusScope {
    id: root
    focus: true
    property string currentShortName: ""
    property string currentCollectionName: ""
    property string backgroundColor: "#000000"
    property bool collectionsVisible: true
    property bool collectionsFocused: true
    property bool gamesVisible: false
    property bool gamesFocused: false
    property var game: null
    property int filterState: 0
    property bool restoringState: false
    property alias consoleYears: consoleYearsObj.data
    property alias consoleColors: consoleColorsObj.data
    property bool debugLayout: false

    LayoutMetrics {
        id: metrics
        viewportWidth: root.width
        viewportHeight: root.height
    }

    ConsoleYears {
        id: consoleYearsObj
    }

    ConsoleColors {
        id: consoleColorsObj
    }

    function getConsoleYear(shortName) {
        return consoleYears[shortName.toLowerCase()] || "none"
    }

    function getColorForSystem(shortName) {
        return consoleColors[shortName.toLowerCase()] || "#000000"
    }

    SortFilterProxyModel {
        id: proxyModel
        sourceModel: systemView.currentIndex >= 0 ? api.collections.get(systemView.currentIndex).games : []

        filters: AllOf {
            ExpressionFilter {
                expression: {
                    if (root.filterState === 1) {
                        return model.favorite === true
                    }
                    if (root.filterState === 2) {
                        var currentDate = new Date()
                        var sevenDaysAgo = new Date(currentDate.getTime() - 7 * 24 * 60 * 60 * 1000)
                        var lastPlayedDate = new Date(model.lastPlayed)
                        return lastPlayedDate >= sevenDaysAgo && (model.playTime / 60) > 1
                    }
                    return true
                }
            }
        }

        sorters: RoleSorter {
            id: gameSorter
            roleName: root.filterState === 2 ? "lastPlayed" : "title"
            sortOrder: root.filterState === 2 ? Qt.DescendingOrder : Qt.AscendingOrder
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: root.backgroundColor
        Behavior on color {
            ColorAnimation { duration: 500 }
        }
    }

    SoundEffect {
        id: naviSound
        source: "assets/sound/mov.wav"
        volume: 0.2
    }

    SoundEffect {
        id: faviSound
        source: "assets/sound/fav.wav"
        volume: 0.5
    }

    TopBar {
        id: topBar
    }

    CollectionView {
        id: systemView
    }

    GameCount {
        id: gamesCount
    }

    DotsView {
        id: dotsRow
    }

    Item {
        id: gamesPanel
        width: parent.width
        height: parent.height
        visible: gamesVisible

        layer.enabled: gameListView.alphaScrollActive
        layer.effect: FastBlur {
            radius: gameListView.alphaScrollActive ? 48 : 0
            Behavior on radius {
                NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
            }
        }

        Item {
            id: animatableItem
            width: parent.width
            height: parent.height

            y: !gamesVisible ? -height : 0

            SequentialAnimation on y {
                NumberAnimation {
                    from: -height
                    to: 0
                    duration: 300
                    easing.type: Easing.OutCubic
                }
                running: gamesVisible
            }

            SequentialAnimation on y {
                NumberAnimation {
                    from: 0
                    to: -height
                    duration: 300
                    easing.type: Easing.InCubic
                }
                running: !gamesVisible
            }

            Row {
                id: headerTabs
                x: metrics.headerTabsX
                y: metrics.headerTop
                spacing: metrics.headerTabSpacing

                Text {
                    id: favoritesText
                    color: "white"
                    opacity: root.filterState === 1 ? 1.0 : 0.2
                    font.pixelSize: metrics.headerFontSize
                    font.bold: true
                    text: "Favorites"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            naviSound.play()
                            root.filterState = 1
                            gameListView.currentIndex = 0
                            gameListView.updateGameImage()
                        }
                    }
                }

                Text {
                    id: allText
                    color: "white"
                    opacity: root.filterState === 0 ? 1.0 : 0.2
                    font.pixelSize: metrics.headerFontSize
                    font.bold: true
                    text: "All"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            naviSound.play()
                            root.filterState = 0
                            gameListView.currentIndex = 0
                            gameListView.updateGameImage()
                        }
                    }
                }

                Text {
                    id: recentText
                    color: "white"
                    opacity: root.filterState === 2 ? 1.0 : 0.2
                    font.pixelSize: metrics.headerFontSize
                    font.bold: true
                    text: "Recently Played"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            naviSound.play()
                            root.filterState = 2
                            gameListView.currentIndex = 0
                            gameListView.updateGameImage()
                        }
                    }
                }
            }

            Row {
                id: headerCollection
                x: metrics.headerNameRightAligned ? parent.width - metrics.gamesGap - width
                : metrics.headerNameX
                y: metrics.headerTop
                spacing: metrics.headerNameLogoSpacing

                Text {
                    color: "white"
                    font.pixelSize: metrics.headerFontSize
                    font.bold: true
                    text: currentShortName
                }

                Item {
                    width: metrics.headerLogoSize
                    height: metrics.headerLogoSize

                    Image {
                        id: collectionImage
                        source: currentShortName ? "assets/shortnames/" + currentShortName + ".png" : ""
                        y: metrics.headerLogoOffsetY
                        width: parent.width
                        height: parent.height
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        asynchronous: true
                        visible: status !== Image.Error
                    }

                    Image {
                        id: defaultImage
                        source: "assets/shortnames/default.png"
                        y: metrics.headerLogoOffsetY
                        width: parent.width
                        height: parent.height
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        visible: collectionImage.status === Image.Error
                    }
                }
            }
        }

        Rectangle {
            id: gameRectangle
            x: metrics.listRect.x
            y: metrics.listRect.y - metrics.listPanelPad
            width: metrics.listRect.width
            height: metrics.listRect.height + 2 * metrics.listPanelPad
            color: "black"
            opacity: 0.2
            radius: metrics.listPanelRadius
            border.color: "transparent"
        }

        GameListView {
            id: gameListView
            opacity: gamesVisible ? 1 : 0
            visible: gamesVisible
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }

        ListScrollBar {
            id: gameListScrollBar
            view: gameListView
            minThumbHeight: metrics.listScrollBarMinThumb
            x: metrics.listScrollBarRect.x
            y: metrics.listScrollBarRect.y
            width: metrics.listScrollBarRect.width
            height: metrics.listScrollBarRect.height
            opacity: gamesVisible && metrics.listScrollBarVisible ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }

        GameMedia {
            id: gameImage
            visible: gamesVisible
        }

        Item {
            id: buttons
            width: parent.width
            height: parent.height * metrics.buttonsBarHeightFraction
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            Text {
                id: gamesCountText
                text: {
                    if (gameListView.model.count === 0) {
                        return "Game 0/0"
                    }
                    return "Game " + (gameListView.currentIndex + 1) + "/" + gameListView.model.count
                }
                font.pixelSize: metrics.gamesCountFontSize
                color: "white"
                font.bold: true
                y: gamesVisible ? parent.height - height : parent.height
                anchors {
                    left: parent.left
                    leftMargin: metrics.gamesCountLeftMargin
                }

                SequentialAnimation on y {
                    NumberAnimation {
                        to: parent.height - height
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                    running: gamesVisible
                }

                SequentialAnimation on y {
                    NumberAnimation {
                        to: parent.height
                        duration: 300
                        easing.type: Easing.InCubic
                    }
                    running: !gamesVisible
                }
            }

            Row {
                id: mainRow
                spacing: metrics.buttonsSpacing

                anchors {
                    right: parent.right
                    rightMargin: metrics.buttonsRightMargin
                }

                y: buttons.height

                SequentialAnimation on y {
                    NumberAnimation {
                        from: buttons.height
                        to: (buttons.height - mainRow.height) / 2
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                    running: gamesVisible
                }

                SequentialAnimation on y {
                    NumberAnimation {
                        from: (buttons.height - mainRow.height) / 2
                        to: buttons.height
                        duration: 300
                        easing.type: Easing.InCubic
                    }
                    running: !gamesVisible
                }

                Item {
                    width: row1.width
                    height: row1.height
                    scale: btnArea1.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                    Row {
                        id: row1
                        spacing: metrics.buttonInnerSpacing
                        Image {
                            id: row1Icon
                            source: "assets/icons/x.png"
                            width: metrics.buttonIconSize
                            height: metrics.buttonIconSize
                            mipmap: true
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                        Text {
                            text: "Favorite"
                            color: "white"
                            font.pixelSize: metrics.buttonFontSize
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                    }
                    MouseArea {
                        id: btnArea1
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            faviSound.play()
                            gameListView.toggleFavorite()
                        }
                    }
                }

                Item {
                    width: row2.width
                    height: row2.height
                    scale: btnArea2.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                    Row {
                        id: row2
                        spacing: metrics.buttonInnerSpacing
                        Image {
                            source: "assets/icons/a.png"
                            width: metrics.buttonIconSize
                            height: metrics.buttonIconSize
                            mipmap: true
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                        Text {
                            text: "OK"
                            color: "white"
                            font.pixelSize: metrics.buttonFontSize
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                    }
                    MouseArea {
                        id: btnArea2
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            naviSound.play()
                            gameListView.handleGameLaunch()
                        }
                    }
                }

                Item {
                    width: row3.width
                    height: row3.height
                    scale: btnArea3.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                    Row {
                        id: row3
                        spacing: metrics.buttonInnerSpacing
                        Image {
                            source: "assets/icons/y.png"
                            width: metrics.buttonIconSize
                            height: metrics.buttonIconSize
                            mipmap: true
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                        Text {
                            text: "Filter"
                            color: "white"
                            font.pixelSize: metrics.buttonFontSize
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                    }
                    MouseArea {
                        id: btnArea3
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (gameImage && gameImage.isVideoPlaying) {
                                if (gameImage.filterBlockedNotification) {
                                    gameImage.filterBlockedNotification.show()
                                }
                                return
                            }
                            naviSound.play()
                            root.filterState = (root.filterState + 1) % 3
                            gameListView.currentIndex = 0
                            gameListView.updateGameImage()
                        }
                    }
                }

                Item {
                    width: row4.width
                    height: row4.height
                    scale: btnArea4.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                    Row {
                        id: row4
                        spacing: metrics.buttonInnerSpacing
                        Image {
                            source: "assets/icons/b.png"
                            width: metrics.buttonIconSize
                            height: metrics.buttonIconSize
                            mipmap: true
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                        Text {
                            text: "Back"
                            color: "white"
                            font.pixelSize: metrics.buttonFontSize
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 2
                                verticalOffset: 2
                                radius: 6
                                samples: 13
                                color: "#CC000000"
                            }
                        }
                    }
                    MouseArea {
                        id: btnArea4
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            naviSound.play()
                            if (gameImage && gameImage.isVideoType) {
                                gameImage.resetMedia()
                            }
                            collectionsVisible = true
                            collectionsFocused = true
                            gamesVisible = false
                            gamesFocused = false
                            systemView.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }

    Item {
        id: alphaOverlay
        anchors.centerIn: parent
        width: letterBg.width
        height: letterBg.height
        z: 9999
        visible: gamesVisible && gameListView.alphaScrollEnabled
        opacity: gameListView.alphaScrollActive ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
        }

        Rectangle {
            id: letterBg
            width: metrics.alphaBoxWidth
            height: metrics.alphaBoxHeight
            radius: metrics.alphaBoxRadius
            color: "#CC000000"
        }

        Rectangle {
            anchors.fill: letterBg
            radius: letterBg.radius
            color: "transparent"
            border.color: getColorForSystem(currentShortName)
            border.width: metrics.alphaBorderWidth
            opacity: 0.85
        }

        Text {
            anchors.centerIn: parent
            text: gameListView.alphaScrollLetter
            color: "white"
            font.pixelSize: metrics.alphaLetterFontSize
            font.bold: true
            style: Text.Outline
            styleColor: "#80000000"
        }
    }

    Keys.onPressed: {
        if (event.isAutoRepeat) {
            return
        }

        if (gamesVisible && gameImage.visible && gameImage.isVideoPlaying) {
            if (api.keys.isNextPage(event)) {
                event.accepted = true
                var newVolumeUp = Math.min(1.0, gameImage.savedVolume + 0.05)
                gameImage.setVideoVolume(newVolumeUp)
                showVolumeFeedback(true)
            } else if (api.keys.isPrevPage(event)) {
                event.accepted = true
                var newVolumeDown = Math.max(0.01, gameImage.savedVolume - 0.05)
                gameImage.setVideoVolume(newVolumeDown)
                showVolumeFeedback(false)
            }
        }
    }

    function showVolumeFeedback(isUp) {
        if (!gameImage.isVideoPlaying) {
            return
        }
        volumeFeedback.text = Math.round(gameImage.savedVolume * 100) + "%"
        volumeFeedback.opacity = 1
        volumeFeedbackTimer.restart()
    }

    Item {
        id: volumeFeedbackContainer
        x: metrics.volumeBarRect.x + (metrics.volumeBarRect.width - width) / 2
        y: metrics.volumeBarRect.y + metrics.volumeBarRect.height + metrics.volumeFeedbackGap
        width: volumeFeedback.width + metrics.volumeFeedbackPaddingX
        height: volumeFeedback.height + metrics.volumeFeedbackPaddingY
        z: 10000
        opacity: volumeFeedback.opacity

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        Rectangle {
            anchors.fill: parent
            radius: metrics.volumeFeedbackRadius
            color: root.backgroundColor
            opacity: 0.9

            layer.enabled: true
            layer.effect: FastBlur {
                radius: 48
                transparentBorder: true
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: metrics.volumeFeedbackRadius
            color: "transparent"
            border.color: getColorForSystem(currentShortName)
            border.width: 0
            opacity: 0.9
        }

        Text {
            id: volumeFeedback
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: metrics.volumeFeedbackFontSize
            font.bold: true
            opacity: 0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }
    }

    Timer {
        id: volumeFeedbackTimer
        interval: 1000
        onTriggered: volumeFeedback.opacity = 0
    }

    Connections {
        target: gameImage
        function onVideoPlayingChanged(isPlaying) {
            if (!isPlaying) {
                volumeFeedbackTimer.stop()
                volumeFeedback.opacity = 0
            }
        }
    }

    Connections {
        target: proxyModel
        function onCountChanged() {
            gameListView.updateGameImage()
        }
    }

    Connections {
        target: systemView
        function onCurrentIndexChanged() {
            if (systemView.currentIndex >= 0) {
                const selectedCollection = api.collections.get(systemView.currentIndex)
                proxyModel.sourceModel = selectedCollection.games
                if (!root.restoringState) {
                    gameListView.currentIndex = 0
                    gameListView.updateGameImage()
                }
            }
        }
    }

    Timer {
        id: restoreTimer
        interval: 150
        repeat: false
        onTriggered: {
            const savedCollectionIndex = api.memory.get('lastCollectionIndex')
            const savedGameTitle = api.memory.get('lastGameTitle')

            if (savedCollectionIndex === undefined || savedGameTitle === undefined) return

                api.memory.unset('lastCollectionIndex')
                api.memory.unset('lastGameTitle')

                const collIdx = parseInt(savedCollectionIndex)

                if (collIdx < 0 || collIdx >= api.collections.count) return

                    root.restoringState = true

                    systemView.currentIndex = collIdx

                    Qt.callLater(function() {
                        let targetIdx = 0
                        for (let i = 0; i < proxyModel.count; i++) {
                            const g = proxyModel.get(i)
                            if (g && g.title === savedGameTitle) {
                                targetIdx = i
                                break
                            }
                        }

                        gameListView.currentIndex = targetIdx
                        gameListView.positionViewAtIndex(targetIdx, ListView.Center)
                        gameListView.updateGameImage()

                        collectionsVisible = false
                        collectionsFocused = false
                        gamesVisible = true
                        gamesFocused = true
                        gameListView.forceActiveFocus()

                        root.restoringState = false
                    })
        }
    }

    DebugOverlay {
        id: debugOverlay
        visible: root.debugLayout
        sceneWidth: root.width
        sceneHeight: root.height
        layoutMode: metrics.profile
        vh: metrics.vh
    }

    Component.onCompleted: {
        restoreTimer.start()
    }
}
