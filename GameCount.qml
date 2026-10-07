import QtQuick 2.15

Text {
    id: gamesCount
    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
        bottomMargin: metrics.gameCountBottomMargin
    }
    text: api.collections.get(systemView.currentIndex).games.count + " games"
    color: "white"
    font.pixelSize: metrics.gameCountFontSize
    font.bold: true
    visible: collectionsVisible
}
