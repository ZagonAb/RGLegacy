import QtQuick 2.15
import QtGraphicalEffects 1.12
import QtQuick.Layouts 1.15
import "utils.js" as Utils
import "qrc:/qmlutils" as PegasusUtils

Item {
    id: gameInfoRoot
    width: parent.width
    height: parent.height

    property var game: null
    property color textColor: "white"
    property color secondaryColor: "#AAAAAA"
    property color backgroundColor: "#40000000"
    property color shadowColor: "#80000000"
    property color highlightColor: "#4CAF50"
    property real cornerRadius: 10
    property real contentMargin: 0.05

    readonly property bool sideBySide: metrics.gameInfoSideBySide

    readonly property int metaVisibleCount: 4 + ((game && game.playCount > 0) ? 1 : 0)
    + ((game && game.playTime > 0) ? 1 : 0)
    readonly property int metaRows: Math.ceil(metaVisibleCount / 2)

    readonly property real metaItemHeight: sideBySide
    ? Math.min(contentBounds.height * metrics.gameInfoItemMaxHeightFraction,
               Math.max(0, (bodyArea.height - (metaRows - 1) * metrics.gameInfoGridSpacing) / metaRows))
    : contentBounds.height * 0.14

    Rectangle {
        id: contentBounds
        anchors {
            fill: parent
        }
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: backgroundColor
            radius: cornerRadius
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: contentBounds.width
                    height: contentBounds.height
                    radius: cornerRadius
                }
            }
        }

        Column {
            width: parent.width - 2 * metrics.gameInfoSidePadding
            anchors.centerIn: parent
            spacing: contentBounds.height * 0.005

            Text {
                id: titleText
                width: parent.width
                text: game ? Utils.cleanGameTitle(game.title) : ""
                color: textColor
                font {
                    pixelSize: contentBounds.height * metrics.gameInfoTitleFontFactor
                    bold: true
                    family: global.fonts.condensed
                    capitalization: Font.AllUppercase
                }
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: metrics.gameInfoTitleMaxLines
                wrapMode: Text.Wrap

                layer.enabled: true
                layer.effect: DropShadow {
                    color: shadowColor
                    radius: 8
                    samples: 16
                }
            }

            Item {
                id: bodyArea
                width: parent.width
                readonly property real gap: contentBounds.height * 0.005
                height: gameInfoRoot.sideBySide
                ? Math.max(0, contentBounds.height - 2 * metrics.gameInfoVerticalPadding - titleText.height - gap)
                : contentBounds.height * 0.55 + gap + contentBounds.height * 0.30

                Item {
                    id: metaArea
                    width: gameInfoRoot.sideBySide ? bodyArea.width * metrics.gameInfoMetaWidthFraction : bodyArea.width
                    height: gameInfoRoot.sideBySide ? bodyArea.height : contentBounds.height * 0.55

                    Grid {
                        id: metadataGrid
                        anchors.centerIn: parent
                        width: parent.width * metrics.gameInfoGridWidthFraction
                        columns: 2
                        columnSpacing: gameInfoRoot.sideBySide ? metrics.gameInfoGridSpacing : contentBounds.width * 0.03
                        rowSpacing: gameInfoRoot.sideBySide ? metrics.gameInfoGridSpacing : contentBounds.height * 0.02

                        component MetadataContainer: Rectangle {
                            property alias labelText: metaLabel.text
                            property alias valueText: metaValue.text
                            property alias valueColor: metaValue.color
                            property alias valueVisible: metaValue.visible
                            property alias customContent: customContentLoader.sourceComponent
                            property bool marquee: false

                            width: (metadataGrid.width - metadataGrid.columnSpacing) / 2
                            height: gameInfoRoot.metaItemHeight
                            color: "#20FFFFFF"
                            border.color: "#50FFFFFF"
                            border.width: 1
                            radius: 8

                            Column {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 0
                                clip: true

                                Text {
                                    id: metaLabel
                                    width: parent.width
                                    height: parent.height * 0.35
                                    font {
                                        pixelSize: Math.max(8, Math.min(parent.height * 0.25, parent.width * metrics.gameInfoLabelFontMaxWidthFactor))
                                        bold: true
                                        family: global.fonts.sans
                                        letterSpacing: 1.5
                                    }
                                    color: secondaryColor
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    width: parent.width * 0.4
                                    height: 1
                                    color: "#40FFFFFF"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    id: metaValue
                                    width: parent.width
                                    height: parent.height * 0.65 - 1
                                    fontSizeMode: gameInfoRoot.sideBySide ? Text.HorizontalFit : Text.FixedSize
                                    minimumPixelSize: 9
                                    font {
                                        pixelSize: Math.max(10, Math.min(parent.height * 0.5, parent.width * metrics.gameInfoValueFontMaxWidthFactor))
                                        bold: true
                                        family: global.fonts.sans
                                    }
                                    color: textColor
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                    visible: text !== "" && !marquee

                                    layer.enabled: true
                                    layer.effect: DropShadow {
                                        color: shadowColor
                                        radius: 4
                                        samples: 9
                                    }
                                }

                                MarqueeText {
                                    id: metaMarquee
                                    width: parent.width
                                    height: parent.height * 0.65 - 1
                                    visible: marquee && metaValue.text !== ""
                                    text: metaValue.text
                                    color: metaValue.color
                                    font: metaValue.font
                                    speed: metrics.gameInfoMarqueeSpeed
                                    delay: metrics.gameInfoMarqueeDelay
                                    separator: metrics.listMarqueeSeparator

                                    layer.enabled: true
                                    layer.effect: DropShadow {
                                        color: shadowColor
                                        radius: 4
                                        samples: 9
                                    }
                                }

                                Loader {
                                    id: customContentLoader
                                    width: parent.width
                                    height: parent.height * 0.65 - 1
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        MetadataContainer {
                            labelText: "DEVELOPER"
                            marquee: true
                            valueText: game && game.developer ? game.developer : "Unknown"
                        }

                        MetadataContainer {
                            labelText: "RELEASE YEAR"
                            valueText: {
                                if (!game) return "-"
                                    if (game.releaseYear) return game.releaseYear
                                        if (game.release && !isNaN(game.release.getTime()))
                                            return game.release.getFullYear()
                                            return "Unknown"
                            }
                        }

                        MetadataContainer {
                            labelText: "RATING"
                            valueText: ""
                            customContent: Component {
                                Item {
                                    readonly property real starSize: gameInfoRoot.sideBySide
                                    ? Math.min(parent.height * 0.75, parent.width * metrics.gameInfoStarMaxWidthFactor)
                                    : contentBounds.height * 0.05
                                    height: starSize
                                    width: parent.width

                                    readonly property real ratingValue: gameInfoRoot.game
                                    ? gameInfoRoot.game.rating * 5
                                    : 0.0

                                    Row {
                                        spacing: contentBounds.width * 0.01
                                        anchors.centerIn: parent

                                        Text {
                                            id: ratingFallbackText
                                            text: gameInfoRoot.game
                                            ? Math.round(gameInfoRoot.game.rating * 100) + "%"
                                            : "0%"
                                            color: textColor
                                            font {
                                                pixelSize: contentBounds.height * 0.03
                                                bold: true
                                            }
                                            visible: false
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Repeater {
                                            id: starsRepeater
                                            model: 5
                                            Image {
                                                required property int index
                                                width: starSize
                                                height: width
                                                fillMode: Image.PreserveAspectFit
                                                mipmap: true
                                                anchors.verticalCenter: parent.verticalCenter

                                                source: {
                                                    var starIndex = index + 1
                                                    if (ratingValue >= starIndex)
                                                        return "assets/icons/star1.png"
                                                        else if (ratingValue >= starIndex - 0.5)
                                                            return "assets/icons/star2.png"
                                                            else
                                                                return "assets/icons/star0.png"
                                                }

                                                onStatusChanged: {
                                                    if (status === Image.Error) {
                                                        starsRepeater.model = 0
                                                        ratingFallbackText.visible = true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        MetadataContainer {
                            labelText: "LAST PLAYED"
                            valueText: {
                                if (!game || !game.lastPlayed || isNaN(game.lastPlayed.getTime()))
                                    return "Never played"

                                    let now = new Date()
                                    let diff = Math.floor((now - game.lastPlayed) / (1000 * 60 * 60 * 24))

                                    if (diff === 0) return "Today"
                                        if (diff === 1) return "Yesterday"
                                            if (diff < 7) return diff + " days ago"
                                                if (diff < 30) return Math.floor(diff / 7) + " weeks ago"
                                                    return game.lastPlayed.toLocaleDateString(Qt.locale(), "MMM d, yyyy")
                            }
                        }

                        MetadataContainer {
                            labelText: "PLAY COUNT"
                            valueText: game ? game.playCount : "0"
                            visible: game && game.playCount > 0
                        }

                        MetadataContainer {
                            labelText: "PLAY TIME"
                            valueText: {
                                if (!game || game.playTime <= 0) return "-"
                                    const hours = Math.floor(game.playTime / 3600)
                                    const minutes = Math.floor((game.playTime % 3600) / 60)
                                    return (hours > 0 ? hours + "h " : "") + minutes + "m"
                            }
                            visible: game && game.playTime > 0
                        }
                    }
                }

                Rectangle {
                    id: descriptionContainer
                    x: gameInfoRoot.sideBySide ? metaArea.width + metrics.gameInfoPaneGap : 0
                    y: gameInfoRoot.sideBySide ? 0 : metaArea.height + bodyArea.gap
                    width: gameInfoRoot.sideBySide ? bodyArea.width - x : bodyArea.width
                    height: gameInfoRoot.sideBySide ? bodyArea.height : contentBounds.height * 0.30
                    color: "transparent"
                    clip: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Item {
                            width: descriptionContainer.width
                            height: descriptionContainer.height
                            Rectangle {
                                anchors.top: parent.top
                                width: parent.width
                                height: parent.height * 0.15
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#00FFFFFF" }
                                    GradientStop { position: 1.0; color: "#FFFFFFFF" }
                                }
                            }
                            Rectangle {
                                y: parent.height * 0.15
                                width: parent.width
                                height: parent.height * 0.7
                                color: "#FFFFFFFF"
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: parent.height * 0.15
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#FFFFFFFF" }
                                    GradientStop { position: 1.0; color: "#00FFFFFF" }
                                }
                            }
                        }
                    }

                    PegasusUtils.AutoScroll {
                        id: autoscroll
                        anchors.fill: parent
                        pixelsPerSecond: 10
                        scrollWaitDuration: 5000

                        Text {
                            width: parent.width * 0.94
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: game && game.description ? game.description : "No description available..."
                            color: textColor
                            font {
                                pixelSize: contentBounds.height * metrics.gameInfoDescFontFactor
                                family: global.fonts.sans
                                letterSpacing: 1.5
                            }
                            wrapMode: Text.WordWrap
                            lineHeight: 1.2
                            textFormat: Text.RichText
                            onLinkActivated: Qt.openUrlExternally(link)
                            topPadding: contentBounds.height * 0.02

                            layer.enabled: true
                            layer.effect: DropShadow {
                                color: shadowColor
                                radius: 2
                                samples: 5
                            }
                        }
                    }
                }
            }
        }
    }
}
