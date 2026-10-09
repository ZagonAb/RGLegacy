import QtQuick 2.15
import SortFilterProxyModel 0.2
import "utils.js" as Utils

ListView {
    id: gameListView
    x: metrics.listViewRect.x
    y: metrics.listViewRect.y
    width: metrics.listViewRect.width
    height: metrics.listViewRect.height
    clip: true
    spacing: metrics.listRowSpacing

    readonly property real rowHeight: (height - (metrics.listRows - 1) * spacing) / metrics.listRows
    readonly property real textMargin: metrics.listTextMargin
    opacity: gamesVisible ? 1 : 0
    visible: gamesVisible
    model: proxyModel

    property var game: null
    property string currentGameImageSource: ""
    property int currentMediaType: 0
    property var availableMedia: []

    property bool alphaScrollEnabled: proxyModel.count > 100
    property bool alphaScrollActive: false
    property string alphaScrollLetter: "A"
    property int alphaScrollDirection: 1
    property bool upHeld: false
    property bool downHeld: false

    signal updateImageSource(string source)
    signal updateMediaType(int mediaType)
    signal updateAvailableMedia(var media)

    delegate: Item {
        width: gameListView.width
        height: gameListView.rowHeight
        property var game: null

        Rectangle {
            id: highlightRect
            anchors.fill: parent
            color: gameListView.currentIndex === index ? "yellow" : "transparent"
            radius: gameListView.rowHeight * metrics.listRowRadiusFactor
        }

        Item {
            id: titleBox
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: gameListView.textMargin
            width: parent.width - 2 * gameListView.textMargin
            height: Math.max(prefixText.implicitHeight, titleText.implicitHeight)

            readonly property bool isSelected: gameListView.currentIndex === index
            readonly property color textColor: isSelected ? "black" : "white"
            readonly property real fontSize: Math.max(metrics.listRowMinFont,
                                                      Math.min(gameListView.rowHeight * metrics.listRowFontFactor,
                                                               metrics.listRect.width * metrics.listRowFontMaxWidthFactor))

            Text {
                id: prefixText
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    let number = (index + 1).toString().padStart(3, "0");
                    let starColor = titleBox.isSelected ? "#FF0000" : "#FFD700";
                    let star = model.favorite ? ` <font color="${starColor}">★</font>` : "";
                    return number + " -" + star;
                }
                color: titleBox.textColor
                font.bold: true
                font.pixelSize: titleBox.fontSize
            }

            TextMetrics {
                id: spaceMetrics
                font: prefixText.font
                text: " "
            }

            Item {
                id: marqueeArea
                x: prefixText.implicitWidth + spaceMetrics.advanceWidth
                width: Math.max(0, titleBox.width - x)
                height: parent.height
                clip: true

                readonly property bool needsScroll: titleBox.isSelected && titleText.implicitWidth > width
                readonly property real cycleWidth: titleText.implicitWidth + marqueeSep.implicitWidth
                property real scrollOffset: 0

                onNeedsScrollChanged: if (!needsScroll) scrollOffset = 0

                Text {
                    id: titleText
                    anchors.verticalCenter: parent.verticalCenter
                    text: Utils.cleanGameTitle(model.title)
                    textFormat: Text.PlainText
                    color: titleBox.textColor
                    font.bold: true
                    font.pixelSize: titleBox.fontSize
                    elide: marqueeArea.needsScroll ? Text.ElideNone : Text.ElideRight
                    width: marqueeArea.needsScroll ? implicitWidth : marqueeArea.width
                    x: -marqueeArea.scrollOffset
                }

                Text {
                    id: marqueeSep
                    anchors.verticalCenter: parent.verticalCenter
                    text: metrics.listMarqueeSeparator
                    textFormat: Text.PlainText
                    color: titleBox.textColor
                    font.bold: true
                    font.pixelSize: titleBox.fontSize
                    x: titleText.implicitWidth - marqueeArea.scrollOffset
                    visible: marqueeArea.needsScroll
                }

                Text {
                    id: titleCopy
                    anchors.verticalCenter: parent.verticalCenter
                    text: titleText.text
                    textFormat: Text.PlainText
                    color: titleBox.textColor
                    font.bold: true
                    font.pixelSize: titleBox.fontSize
                    x: marqueeArea.cycleWidth - marqueeArea.scrollOffset
                    visible: marqueeArea.needsScroll
                }

                SequentialAnimation {
                    loops: Animation.Infinite
                    running: marqueeArea.needsScroll

                    PauseAnimation { duration: metrics.listMarqueeDelay }
                    NumberAnimation {
                        target: marqueeArea
                        property: "scrollOffset"
                        from: 0
                        to: marqueeArea.cycleWidth
                        duration: marqueeArea.cycleWidth / metrics.listMarqueeSpeed * 1000
                        easing.type: Easing.Linear
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                gameListView.currentIndex = index;
                gameListView.updateGameImage();
            }
            onDoubleClicked: {
                gameListView.currentIndex = index;
                naviSound.play();
                gameListView.handleGameLaunch();
            }
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }

    Text {
        id: noGamesText
        text: "No games found"
        anchors.centerIn: parent
        visible: proxyModel.count === 0
        font.pixelSize: metrics.noGamesFontSize
        color: "#FFFFFF"
    }

    focus: gamesFocused

    highlightFollowsCurrentItem: true
    highlightMoveDuration: 0

    Timer {
        id: holdTimer
        interval: 1200
        repeat: false
        onTriggered: {
            if (!gameListView.alphaScrollEnabled) return
            if (gameListView.upHeld || gameListView.downHeld) {
                gameListView.alphaScrollActive = true
                var g = proxyModel.get(gameListView.currentIndex)
                if (g && g.title.length > 0) {
                    var ch = g.title[0].toUpperCase()
                    gameListView.alphaScrollLetter = (ch >= "A" && ch <= "Z") ? ch : "A"
                } else {
                    gameListView.alphaScrollLetter = "A"
                }
                alphaStepTimer.start()
            }
        }
    }

    Timer {
        id: alphaStepTimer
        interval: 400
        repeat: true
        onTriggered: {
            if (!gameListView.alphaScrollActive) { stop(); return }
            if (!gameListView.upHeld && !gameListView.downHeld) {
                gameListView.deactivateAlphaScroll()
                stop()
                return
            }
            gameListView.advanceLetter()
            gameListView.jumpToLetter(gameListView.alphaScrollLetter)
            naviSound.play()
        }
    }

    Timer {
        id: alphaReleaseTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (gameListView.alphaScrollActive) {
                gameListView.deactivateAlphaScroll()
            }
        }
    }

    function advanceLetter() {
        var letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ#"
        var idx = letters.indexOf(alphaScrollLetter)
        if (idx === -1) idx = 0
        idx = (idx + alphaScrollDirection + letters.length) % letters.length
        alphaScrollLetter = letters[idx]
    }

    function jumpToLetter(letter) {
        for (var i = 0; i < proxyModel.count; i++) {
            var g = proxyModel.get(i)
            if (!g) continue
            var ch = g.title[0].toUpperCase()
            if (letter === "#") {
                if (ch < "A" || ch > "Z") { currentIndex = i; positionViewAtIndex(i, ListView.Center); return }
            } else {
                if (ch === letter) { currentIndex = i; positionViewAtIndex(i, ListView.Center); return }
            }
        }
    }

    function deactivateAlphaScroll() {
        alphaScrollActive = false
        upHeld = false
        downHeld = false
        holdTimer.stop()
        alphaStepTimer.stop()
        alphaReleaseTimer.stop()
    }

    Keys.onUpPressed: {
        if (alphaScrollActive) {
            alphaScrollDirection = -1
            alphaReleaseTimer.restart()
            event.accepted = true
            return
        }
        downHeld = false
        upHeld = true
        alphaScrollDirection = -1
        if (alphaScrollEnabled && !holdTimer.running) holdTimer.restart()
        alphaReleaseTimer.restart()

        naviSound.play();
        if (currentIndex <= 0) {
            positionViewAtIndex(count - 1, ListView.Contain);
            currentIndex = count - 1;
        } else {
            currentIndex--;
        }
    }

    Keys.onDownPressed: {
        if (alphaScrollActive) {
            alphaScrollDirection = 1
            alphaReleaseTimer.restart()
            event.accepted = true
            return
        }
        upHeld = false
        downHeld = true
        alphaScrollDirection = 1
        if (alphaScrollEnabled && !holdTimer.running) holdTimer.restart()
        alphaReleaseTimer.restart()

        naviSound.play();
        if (currentIndex >= count - 1) {
            positionViewAtIndex(0, ListView.Contain);
            currentIndex = 0;
        } else {
            currentIndex++;
        }
    }

    Keys.onPressed: function(event) {
        if (event.isAutoRepeat) return;

        switch(true) {
            case api.keys.isFilters(event):
                if (gameImage && gameImage.isVideoPlaying) {
                    if (gameImage.filterBlockedNotification) {
                        gameImage.filterBlockedNotification.show();
                    } else {
                        console.log("Filter blocked - video is playing");
                    }
                    event.accepted = true;
                    return;
                }
                naviSound.play();
                root.filterState = (root.filterState + 1) % 3;
                currentIndex = 0;
                updateGameImage();
                event.accepted = true;
                break;

            case api.keys.isCancel(event):
                naviSound.play();
                if (gameImage && gameImage.isVideoType) {
                    gameImage.resetMedia();
                }
                event.accepted = true;
                collectionsVisible = true;
                collectionsFocused = true;
                gamesVisible = false;
                gamesFocused = false;
                systemView.forceActiveFocus();
                break;

            case api.keys.isAccept(event):
                naviSound.play();
                event.accepted = true;
                handleGameLaunch();
                break;

            case api.keys.isDetails(event):
                faviSound.play();
                toggleFavorite();
                event.accepted = true;
                break;

            case (event.key === Qt.Key_Left):
                naviSound.play();
                if (availableMedia.length > 0) {
                    if (gameImage && gameImage.isVideoType) {
                        gameImage.resetMedia();
                    }
                    currentMediaType = (currentMediaType - 1 + availableMedia.length) % availableMedia.length;
                    currentGameImageSource = "";
                    updateGameImage();
                }
                event.accepted = true;
                break;

            case (event.key === Qt.Key_Right):
                naviSound.play();
                if (availableMedia.length > 0) {
                    currentMediaType = (currentMediaType + 1) % availableMedia.length;
                    currentGameImageSource = "";
                    Qt.callLater(function() { updateGameImage(); });
                }
                event.accepted = true;
                break;
        }
    }

    Keys.onReleased: function(event) {
        if (event.isAutoRepeat) return
        var wasUp = (event.key === Qt.Key_Up)
        var wasDown = (event.key === Qt.Key_Down)

        if (wasUp || wasDown) {
            if (alphaScrollActive) {
                deactivateAlphaScroll()
            } else {
                upHeld = false
                downHeld = false
                holdTimer.stop()
                alphaReleaseTimer.stop()
            }
        }
    }

    function getFirstAvailableMedia() {
        for (let i = 0; i < availableMedia.length; i++) {
            const item = availableMedia[i];
            if (item.type !== "info" && item.source !== "") return item.source;
        }
        return "assets/gamepad/default.png";
    }

    function getFirstAvailableNonVideoMedia() {
        for (let i = 0; i < availableMedia.length; i++) {
            const item = availableMedia[i];
            if (!item.isVideo && item.type !== "info" && item.source !== "") return item.source;
        }
        return "assets/gamepad/default.png";
    }

    function getCurrentMediaSource() {
        if (!availableMedia.length) return "assets/gamepad/default.png";
        const item = availableMedia[currentMediaType];
        if (item && item.source !== "") return item.source;
        return getFirstAvailableMedia();
    }

    function getAvailableMedia() {
        if (!game || !game.assets) return [];

        var assets = game.assets;
        var allItems = [];

        function tryAddList(listProp, type, label, priority, isVid) {
            var list = assets[listProp];
            if (list && list.length > 0) {
                for (var i = 0; i < list.length; i++) {
                    var src = list[i];
                    if (src && src.toString() !== "") {
                        allItems.push({
                            source: src.toString(),
                            type: type,
                            label: label + (list.length > 1 ? " " + (i + 1) : ""),
                            isVideo: isVid,
                            orderPriority: priority
                        });
                    }
                }
                return true;
            }
            return false;
        }

        function tryAdd(prop, type, label, priority, isVid) {
            var src = assets[prop];
            if (src && src.toString() !== "") {
                allItems.push({
                    source: src.toString(),
                    type: type,
                    label: label,
                    isVideo: isVid,
                    orderPriority: priority
                });
            }
        }

        if (!tryAddList("screenshotList", "screenshot", "Screenshot", 1, false))
            tryAdd("screenshot", "screenshot", "Screenshot", 1, false);

        if (!tryAddList("titlescreenList", "titlescreen", "Title Screen", 2, false))
            tryAdd("titlescreen", "titlescreen", "Title Screen", 2, false);

        var others = [
            { prop: "logo",         label: "Logo",       priority: 3  },
            { prop: "boxFront",     label: "Box Front",  priority: 4  },
            { prop: "boxFull",      label: "Box Full",   priority: 5  },
            { prop: "boxBack",      label: "Box Back",   priority: 6  },
            { prop: "boxSpine",     label: "Box Spine",  priority: 7  },
            { prop: "background",   label: "Background", priority: 8  },
            { prop: "banner",       label: "Banner",     priority: 9  },
            { prop: "poster",       label: "Poster",     priority: 10 },
            { prop: "tile",         label: "Tile",       priority: 11 },
            { prop: "steam",        label: "Steam Grid", priority: 12 },
            { prop: "marquee",      label: "Marquee",    priority: 13 },
            { prop: "bezel",        label: "Bezel",      priority: 14 },
            { prop: "panel",        label: "Panel",      priority: 15 },
            { prop: "cabinetLeft",  label: "Cabinet L",  priority: 16 },
            { prop: "cabinetRight", label: "Cabinet R",  priority: 17 },
            { prop: "cartridge",    label: "Cartridge",  priority: 18 }
        ];

        for (var k = 0; k < others.length; k++) {
            var a = others[k];
            if (!tryAddList(a.prop + "List", a.prop, a.label, a.priority, false))
                tryAdd(a.prop, a.prop, a.label, a.priority, false);
        }

        if (!tryAddList("videoList", "video", "Video", 99, true))
            tryAdd("video", "video", "Video", 99, true);

        allItems.sort(function(a, b) { return a.orderPriority - b.orderPriority; });

        var result = [];
        for (var n = 0; n < allItems.length; n++) {
            var it = allItems[n];
            result.push({ source: it.source, type: it.type, label: it.label, isVideo: it.isVideo });
        }

        result.push({ source: "", type: "info", label: qsTr("Game Info"), isVideo: false });

        return result;
    }

    function updateGameImage() {
        if (gameImage && gameImage.videoLoader && gameImage.videoLoader.item &&
            gameImage.videoLoader.item.mediaPlayer) {
            gameImage.videoLoader.item.mediaPlayer.stop();
        }

        if (proxyModel.count === 0) {
            currentGameImageSource = "assets/gamepad/default.png";
            game = null;
            availableMedia = [];
            if (gameImage && gameImage.videoLoader) gameImage.videoLoader.active = false;
            if (gameImage && gameImage.infoLoader) gameImage.infoLoader.active = false;
        } else {
            game = proxyModel.get(currentIndex);
            availableMedia = getAvailableMedia();

            if (availableMedia.length === 0 ||
                (availableMedia.length === 1 && availableMedia[0].type === "info")) {
                currentGameImageSource = "";
                currentMediaType = availableMedia.length > 0 ? 0 : 0;
                updateImageSource(currentGameImageSource);
                updateMediaType(currentMediaType);
                updateAvailableMedia(availableMedia);
                return;
            }

            if (currentMediaType >= availableMedia.length) {
                currentMediaType = 0;
            }

            var item = availableMedia[currentMediaType];

            if (item.type === "info") {
                currentGameImageSource = "";
            } else if (item.source !== "") {
                currentGameImageSource = item.source;
            } else {
                var found = false;
                for (var i = 0; i < availableMedia.length; i++) {
                    var fb = availableMedia[i];
                    if (fb.type !== "info" && fb.source !== "") {
                        currentGameImageSource = fb.source;
                        currentMediaType = i;
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    var infoIdx = availableMedia.length - 1;
                    currentGameImageSource = "";
                    currentMediaType = infoIdx;
                }
            }
        }

        updateImageSource(currentGameImageSource);
        updateMediaType(currentMediaType);
        updateAvailableMedia(availableMedia);
    }

    function handleGameLaunch() {
        const currentCollection = api.collections.get(systemView.currentIndex);
        if (currentCollection && currentCollection.games) {
            const filteredGame = proxyModel.get(currentIndex);
            if (filteredGame) {
                let originalGameIndex = -1;
                for (let i = 0; i < currentCollection.games.count; i++) {
                    const g = currentCollection.games.get(i);
                    if (g.title === filteredGame.title) { originalGameIndex = i; break; }
                }
                if (originalGameIndex !== -1) {
                    api.memory.set('lastCollectionIndex', systemView.currentIndex);
                    api.memory.set('lastGameTitle', filteredGame.title);
                    currentCollection.games.get(originalGameIndex).launch();
                }
            }
        }
    }

    function toggleFavorite() {
        const currentCollection = api.collections.get(systemView.currentIndex);
        if (currentCollection && currentCollection.games) {
            const filteredGame = proxyModel.get(currentIndex);
            if (filteredGame) {
                let originalGameIndex = -1;
                for (let i = 0; i < currentCollection.games.count; i++) {
                    const g = currentCollection.games.get(i);
                    if (g.title === filteredGame.title) { originalGameIndex = i; break; }
                }
                if (originalGameIndex !== -1) {
                    const gameToToggle = currentCollection.games.get(originalGameIndex);
                    gameToToggle.favorite = !gameToToggle.favorite;
                    proxyModel.invalidate();
                }
            }
        }
    }

    onCurrentIndexChanged: {
        currentMediaType = 0;
        updateGameImage();
    }
}
