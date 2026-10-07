import QtQuick 2.15

QtObject {
    id: metrics

    property real viewportWidth: 1280
    property real viewportHeight: 720

    readonly property real designHeight: 720

    readonly property real aspectRatio: viewportHeight > 0 ? viewportWidth / viewportHeight : 16 / 9

    readonly property string profile: {
        var ar = aspectRatio
        if (ar >= 1.55) return "wide"
            if (ar >= 1.17) return "standard"
                if (ar >= 0.88) return "square"
                    return "portrait"
    }

    readonly property bool isWide: profile === "wide"
    readonly property bool isStandard: profile === "standard"
    readonly property bool isSquare: profile === "square"
    readonly property bool isPortrait: profile === "portrait"

    readonly property bool stacked: isSquare || isPortrait

    readonly property real scale: viewportHeight / designHeight
    readonly property real vw: viewportWidth / 100
    readonly property real vh: viewportHeight / 100
    readonly property real vmin: Math.min(viewportWidth, viewportHeight) / 100

    function px(designPixels) {
        return designPixels * scale
    }

    function pick(wide, standard, square, portrait) {
        if (profile === "wide") return wide
            if (profile === "standard") return standard
                if (profile === "square") return square
                    return portrait === undefined ? square : portrait
    }

    readonly property real gamesGap: pick(px(20), px(18.7), px(17.3), px(17.3))

    readonly property int collectionVisibleItems: pick(5, 5, 3, 3)
    readonly property real collectionStep: pick(0.192, 0.195, 0.335, 0.335)
    readonly property real collectionDelegateK: pick(1.125, 1.28, 1.10, 1.05)
    readonly property real collectionSideScale: pick(0.85, 0.75, 0.85, 0.80)

    readonly property real collectionShiftNear: pick(0.05, 0.12, 0, 0)
    readonly property real collectionShiftFar: pick(0, 0.10, 0, 0)

    readonly property real collectionTop: pick(0.15, 0.15, 0.14, 0.20)
    readonly property real collectionHeight: pick(0.45, 0.48, 0.52, 0.40)

    readonly property real collectionCapsuleExtra: 0.45

    readonly property real collectionNameFontFactor: 0.10
    readonly property real collectionYearFontFactor: 0.12
    readonly property real collectionNameMinFont: 10
    readonly property real collectionYearMinFont: 11
    readonly property real collectionNameWidthFactor: 0.94

    readonly property real dotsMaxSize: vmin * (16 / 9)
    readonly property real dotsSpacingFactor: 0.63
    readonly property real dotsMaxWidthFraction: 0.84
    readonly property real dotsCompactMinSize: 4
    readonly property real dotsBottomMargin: px(64)
    readonly property real dotsClearanceAboveCount: px(1.4)
    readonly property real dotsCounterFontSize: Math.max(10, px(18.7))

    readonly property real gameCountFontSize: Math.max(11, px(25.6))
    readonly property real gameCountBottomMargin: px(25.6)

    readonly property real clockFontSize: pick(vw * 2.5, vw * 2.5, vmin * 3.6, vmin * 3.6)
    readonly property real clockTopMargin: pick(px(20), px(20), gamesGap, gamesGap)
    readonly property real clockLeftMargin: pick(px(20), px(20), gamesGap, gamesGap)

    readonly property real batteryItemHeight: px(40)
    readonly property real batteryTopMargin: pick(vh * 4, vh * 4, vh * 3, vh * 3)
    readonly property real batteryRightMargin: pick(px(10), px(10), gamesGap, gamesGap)
    readonly property real batteryIconWidth: pick(vw * 10, vw * 10, vmin * 10, vmin * 10)
    readonly property real batteryIconHeight: pick(vh * 5, vh * 5, vmin * 4.5, vmin * 4.5)

    readonly property real listWidthFraction: pick(0.40, 0.42, 1.0, 1.0)
    readonly property real listHeightFraction: pick(0.72, 0.72, 0.33, 0.43)
    readonly property real listTopFraction: pick(0, 0, 0.55, 0.47)
    readonly property int listRows: pick(8, 9, 4, 7)
    readonly property real listRowSpacing: px(5)
    readonly property real listTextMargin: Math.max(6, px(10))
    readonly property real listRowRadiusFactor: 0.166
    readonly property real listRowFontFactor: 0.55
    readonly property real listRowFontMaxWidthFactor: 0.065
    readonly property real listRowMinFont: 10
    readonly property real noGamesFontSize: Math.max(11, px(25.6))

    readonly property real listPanelPad: pick(px(28.8), px(28.8), px(4.3), px(4.3))
    readonly property real listPanelRadius: Math.max(6, px(10))

    readonly property bool listScrollBarVisible: pick(true, true, true, true)
    readonly property real listScrollBarWidth: px(6)
    readonly property real listScrollBarGap: px(8)
    readonly property real listScrollBarMargin: px(8)
    readonly property real listScrollBarMinThumb: px(30)
    readonly property real listScrollBarReserve: listScrollBarVisible
    ? listScrollBarWidth + listScrollBarGap + listScrollBarMargin : 0

    readonly property real listMarqueeSpeed: px(45)
    readonly property int listMarqueeDelay: 1200
    readonly property string listMarqueeSeparator: "  •  "

    readonly property real mediaHeightFraction: pick(0.75, 0.70, 0.38, 0.32)
    readonly property real mediaTopFraction: pick(0, 0, 0.12, 0.10)

    readonly property real mediaIndicatorHeightFraction: 0.05
    readonly property real mediaIndicatorBottomFraction: 0.06
    readonly property real mediaIndicatorStackedHeight: px(27)
    readonly property real mediaIndicatorStackedGap: px(3.6)
    readonly property real mediaIndicatorSpacingFactor: 0.3

    readonly property real volumeMinWidth: px(26)
    readonly property real volumeWidthFraction: 0.06
    readonly property real volumeHeightFraction: pick(0.6, 0.6, 0.85, 0.85)
    readonly property real volumeTopMargin: Math.max(4, px(8))
    readonly property real volumeSliderMargin: Math.max(6, px(15))

    readonly property real filterNoticeFontSize: Math.max(11, px(16))
    readonly property real filterNoticeMarginX: px(20)
    readonly property real filterNoticeMarginY: px(10)

    readonly property rect listRect: {
        var g = gamesGap
        var w = viewportWidth * listWidthFraction - (stacked ? 2 * g : 0)
        var h = viewportHeight * listHeightFraction
        var y = stacked ? viewportHeight * listTopFraction : (viewportHeight - h) / 2
        return Qt.rect(g, y, w, h)
    }

    readonly property rect mediaRect: {
        var g = gamesGap
        var h = viewportHeight * mediaHeightFraction
        if (stacked)
            return Qt.rect(g, viewportHeight * mediaTopFraction, viewportWidth - 2 * g, h)
            var x = listRect.x + listRect.width + g
            return Qt.rect(x, (viewportHeight - h) / 2, viewportWidth - x - g, h)
    }

    readonly property rect listViewRect: Qt.rect(listRect.x, listRect.y,
                                                 listRect.width - listScrollBarReserve, listRect.height)
    readonly property rect listScrollBarRect: Qt.rect(listRect.x + listRect.width - listScrollBarMargin - listScrollBarWidth,
                                                      listRect.y, listScrollBarWidth, listRect.height)

    readonly property real headerFontSize: Math.max(9, pick(vw * 2, vw * 2, vmin * 3, vmin * 3))
    readonly property real headerTop: pick(vw * 1, vw * 1, px(18), px(18))

    readonly property real headerTabsX: pick(vw * 7, vw * 7, gamesGap, gamesGap)
    readonly property real headerTabSpacing: pick(vw * 3, vw * 3, vmin * 2.4, vmin * 2.4)

    readonly property bool headerNameRightAligned: pick(false, false, true, true)
    readonly property real headerNameX: vw * 62
    readonly property real headerNameLogoSpacing: pick(vw * 15, vw * 15, vmin * 2, vmin * 2)
    readonly property real headerLogoSize: pick(vw * 14 / 3, vw * 14 / 3, vmin * 7.5, vmin * 7.5)
    readonly property real headerLogoOffsetY: pick(-vw * 0.2, -vw * 0.2, 0, 0)

    readonly property real buttonsBarHeightFraction: 0.08

    readonly property real gamesCountFontSize: pick(vw * 2.2, vw * 2.2, Math.max(11, px(23)), Math.max(11, px(23)))
    readonly property real gamesCountLeftMargin: pick(vw * 17, vw * 17, gamesGap, gamesGap)

    readonly property real buttonIconSize: pick(vw * 3.2, vw * 3.2, vmin * 4.4, vmin * 4.4)
    readonly property real buttonFontSize: pick(vw * 2.1, vw * 2.1, vmin * 2.9, vmin * 2.9)
    readonly property real buttonInnerSpacing: vw * 0.1
    readonly property real buttonsSpacing: pick(vw * 2, vw * 2, vmin * 2, vmin * 2)
    readonly property real buttonsRightMargin: pick(vw * 10, vw * 10, gamesGap, gamesGap)

    readonly property real alphaBoxWidth: vw * 22
    readonly property real alphaBoxHeight: vh * 32
    readonly property real alphaBoxRadius: vw * 2.5
    readonly property real alphaBorderWidth: vw * 0.4
    readonly property real alphaLetterFontSize: vw * 14

    readonly property real volumeFeedbackFontSize: vw * 3
    readonly property real volumeFeedbackPaddingX: vw * 6
    readonly property real volumeFeedbackPaddingY: vh * 2.5

    readonly property bool gameInfoSideBySide: stacked

    readonly property real gameInfoSidePadding: pick(0, 0, px(12), px(12))
    readonly property real gameInfoVerticalPadding: pick(0, 0, px(10), px(10))

    readonly property real gameInfoMetaWidthFraction: pick(1, 1, 0.48, 0.48)
    readonly property real gameInfoPaneGap: px(12)

    readonly property real gameInfoGridWidthFraction: pick(0.9, 0.9, 1.0, 1.0)
    readonly property real gameInfoGridSpacing: px(8)
    readonly property real gameInfoItemMaxHeightFraction: 0.40

    readonly property real gameInfoTitleFontFactor: pick(0.06, 0.06, 0.075, 0.075)
    readonly property int gameInfoTitleMaxLines: pick(2, 2, 1, 1)
    readonly property real gameInfoDescFontFactor: pick(0.05, 0.04, 0.08, 0.06)
    readonly property real gameInfoValueFontMaxWidthFactor: pick(10, 10, 0.12, 0.12)
    readonly property real gameInfoLabelFontMaxWidthFactor: pick(10, 10, 0.075, 0.075)
    readonly property real gameInfoStarMaxWidthFactor: 0.16

    readonly property real gameInfoMarqueeSpeed: px(40)
    readonly property int gameInfoMarqueeDelay: 1500

    readonly property bool gameInfoAlignTopToListPanel: pick(true, true, false, false)
    readonly property real gameInfoExtendTop: gameInfoAlignTopToListPanel
    ? Math.max(0, mediaRect.y - (listRect.y - listPanelPad)) : 0
    readonly property real gameInfoExtendBottom: px(pick(0, 0, 0, 0))
}
