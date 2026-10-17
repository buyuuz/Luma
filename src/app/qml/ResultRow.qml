pragma ComponentBehavior: Bound

import QtQuick
import WinShun

// One result: icon, highlighted name, folder (or the matching line for
// content search) and a small trailing label. The current and the hovered row
// show buttons instead of the label: reveal, copy, copy path, delete (click
// twice). An installed app shows where it comes from instead of a folder, an
// "应用" tag, and its own buttons: run as administrator, reveal, copy (its
// program file, if it has one), copy path. A place in Windows (a page of
// Settings, a Control Panel task, a system tool) is tagged "系统", says where
// in Windows it is, and has only the copy button, which copies its command.
// A web shortcut's site or search is tagged "网页" and copies its address.
// A file or folder says when it was last written, at the end of its name's
// line (also on the current row, where the buttons take the right end).
// A file or folder on a network share that cannot be reached now is dimmed
// and tagged "离线".
// A plugin's row (an app in the list's terms) is tagged with the plugin's
// name, shows what the plugin said under its title, and has one button,
// which copies its text (its actions are the plugin's: Enter, Ctrl+Enter,
// Shift+Enter, and the menu).
// The rows shown carry their shortcut on the icon (Ctrl+1 opens the first one
// shown); one another program holds is struck through, its tip says why.
// A file's or folder's row can be dragged out with the mouse, into a chat or
// a folder (with the selection, when it is in it).
Item {
    id: row

    required property int index
    required property string name
    required property string nameHtml
    required property var nameMatches // where the terms are in the name: start, length, ...
    required property string folder
    required property var folderMatches // where in it the terms the name lacks are: start, length, ...
    required property string path
    required property bool isDir
    required property string icon
    required property string snippetHtml
    required property int line
    required property string location // of a content match: "第 3 行", "第 2 页"
    required property bool recent
    required property bool isApp // or a place, or a plugin's row
    required property bool place // or a web page
    required property bool web
    required property bool packagedApp
    required property bool elevatable
    required property bool revealable
    required property bool copyable
    required property bool selected // one of several picked with Ctrl / Shift
    required property string modified // "昨天 14:32"; empty for an app, or not known
    required property string modifiedFull
    required property bool offline // on a network share that cannot be reached now: dimmed, tagged
    required property bool plugin // a plugin's row
    required property string source // ... the plugin's name
    required property bool favorite // one of its user's favorites: tagged 收藏 (with its keyword)
    required property string favoriteKeyword
    required property bool missing // a favorite no longer there: dimmed, tagged
    property bool showModified: true
    property int hint: 0 // its number for the number keys (Ctrl+1…), on its icon; 0 for none
    property string hintModifier: "Ctrl" // ... with this held
    property bool hintTaken: false // another program holds that chord as a global hotkey: shown struck through

    readonly property bool contentMode: line > 0 // a content match (also mixed into 全部)
    readonly property bool current: ListView.isCurrentItem
    // With rows selected, the background marks them; the current row keeps only its accent pill.
    readonly property int selectedCount: ListView.view ? ListView.view.model.selectedCount : 0
    readonly property var results: ListView.view ? ListView.view.model : null // the ResultModel
    readonly property bool showActions: area.containsMouse
    // Room kept on the right for the buttons, the badge or the label.
    readonly property real trailingSpace: (showActions ? actions.width + actions.anchors.rightMargin
                                           : isApp ? badge.width + badge.anchors.rightMargin
                                           : trailing.width + trailing.anchors.rightMargin) + 10
    property bool deleteArmed: false // first click on delete; the second one deletes

    signal clicked(int index, int modifiers)
    signal menuRequested(int index, point globalPos)
    signal actionRequested(int index, int action)
    signal dragRequested(int index) // its file or folder dragged out of the window

    // Text on whole device pixels. Qt rounds each corner of a glyph's quad to
    // the pixel grid on the GPU, in single precision: on a half pixel (where
    // centring often puts it at 150 %) the rounding goes either way from one
    // scroll position to the next, and the text jumps or stretches by a pixel.
    function onPixel(y) { return Math.round(y * Screen.devicePixelRatio) / Screen.devicePixelRatio }
    function upToPixel(y) { return Math.ceil(y * Screen.devicePixelRatio - 1e-6) / Screen.devicePixelRatio }

    onShowActionsChanged: if (!showActions) deleteArmed = false
    onPathChanged: deleteArmed = false // delegate reused for another result

    Timer {
        id: disarmTimer
        interval: 3000
        onTriggered: row.deleteArmed = false
    }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 3
        anchors.bottomMargin: 3
        radius: 15
        color: row.selected || (row.current && row.selectedCount === 0) ? Theme.glassSelection
               : area.containsMouse ? Theme.glassHover : "transparent"
        border.width: row.current && row.selectedCount === 0 ? 1 : 0
        border.color: row.current ? Qt.rgba(1, 1, 1, 0.11) : "transparent"
        Behavior on color { ColorAnimation { duration: 90 } }
    }

    Rectangle { // accent pill on the current row, as in Windows 11 lists
        visible: false // The rounded selection surface replaces the WinUI accent rail.
        x: 7
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 18
        radius: 1.5
        color: Theme.accent
    }

    Item {
        id: iconSlot
        opacity: row.offline || row.missing ? 0.6 : 1
        x: 24
        anchors.verticalCenter: parent.verticalCenter
        width: 32 // 48 device pixels at 150 %, 64 at 200 %: sizes icons are drawn for
        height: 32

        Image {
            id: iconImage

            readonly property real dpr: Screen.devicePixelRatio
            readonly property int pixels: Math.round(iconSlot.width * dpr)

            // Exactly as many device pixels as the icon has, sampled
            // unsmoothed: smoothly it would blur wherever it sits on a half
            // pixel (at 150 % most rows do). Nudged off the exact half pixel,
            // where the nearest sample is a tie that can take one column twice.
            // sourceSize is in logical pixels: Image asks the provider for it
            // times the device pixel ratio.
            x: 1 / 64
            y: 1 / 64
            width: pixels / dpr
            height: pixels / dpr
            source: row.icon
            sourceSize.width: pixels / dpr
            sourceSize.height: pixels / dpr
            smooth: false
            asynchronous: true
            fillMode: Image.PreserveAspectFit
        }
    }

    // Mac launcher row: icon, title and location share a baseline.
    // Long paths elide in their own flexible region rather than squeezing
    // the filename into a column and wasting vertical space.
    Item {
        opacity: row.offline || row.missing ? 0.6 : 1
        anchors.left: iconSlot.right
        anchors.leftMargin: 20
        anchors.right: parent.right
        anchors.rightMargin: row.trailingSpace + (date.visible ? date.width + 20 : 0)
        anchors.verticalCenter: parent.verticalCenter
        height: row.height - 12

        Text {
            id: title
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.width * 0.50, Math.max(160, Math.min(300, implicitWidth + 24)))
            text: row.results && row.nameMatches.length > 0
                  ? row.results.elidedHtml(row.name, row.nameMatches, width, font, row.results.highlightColor)
                  : row.nameHtml
            textFormat: Text.StyledText
            elide: Text.ElideRight
            color: Theme.glassText
            font.pixelSize: Theme.uiTitle + 2
            font.weight: row.current ? Font.DemiBold : Font.Medium
        }

        Text {
            anchors.left: title.right
            anchors.leftMargin: 18
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: row.contentMode ? row.snippetHtml
                  : row.folderMatches.length > 0 && row.results !== null
                      ? row.results.elidedHtml(row.folder, row.folderMatches, width, font, row.results.highlightColor)
                      : row.folder
            textFormat: row.contentMode || row.folderMatches.length > 0 ? Text.StyledText : Text.PlainText
            elide: Text.ElideMiddle
            maximumLineCount: 1
            color: Theme.glassSecondary
            font.pixelSize: Theme.uiCaption + 1
        }
    }

    // When it was last written: centred on the row, and both lines on the left
    // stop short of it, so the path below the name never runs under it.
    Text {
        id: date
        visible: row.showModified && row.modified.length > 0
        anchors.right: parent.right
        anchors.rightMargin: row.trailingSpace
        y: row.onPixel((row.height - height) / 2)
        width: Math.ceil(implicitWidth)
        text: row.modified
        textFormat: Text.PlainText
        color: Theme.glassMuted
        font.pixelSize: Theme.uiCaption
    }

    Text {
        id: trailing
        visible: !row.showActions && !row.isApp
        anchors.right: parent.right
        anchors.rightMargin: 18
        y: row.onPixel((row.height - height) / 2)
        width: Math.min(implicitWidth, 200)
        elide: Text.ElideMiddle
        text: row.contentMode ? row.location
            : row.offline ? qsTr("离线")
            : row.missing ? qsTr("已不存在")
            : row.favorite ? (row.favoriteKeyword.length > 0 ? qsTr("收藏 · %1").arg(row.favoriteKeyword) : qsTr("收藏"))
            : row.recent ? qsTr("最近") : ""
        color: Theme.glassMuted
        font.pixelSize: Theme.uiCaption
    }

    Rectangle {
        id: badge
        visible: row.isApp && !row.showActions
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: badgeText.implicitWidth + 16
        height: Theme.badgeHeight
        radius: height / 2
        color: Theme.badge

        Text {
            id: badgeText
            anchors.horizontalCenter: parent.horizontalCenter
            y: row.onPixel((badge.height - height) / 2)
            text: row.plugin ? row.source : row.missing ? qsTr("已不存在")
                : row.favorite ? (row.favoriteKeyword.length > 0 ? qsTr("收藏 · %1").arg(row.favoriteKeyword) : qsTr("收藏"))
                : row.recent ? qsTr("最近") : row.web ? qsTr("网页") : row.place ? qsTr("系统") : qsTr("应用")
            color: Theme.accent
            font.pixelSize: Theme.uiCaption + 1
        }
    }

    IconNumber { // Shortcut remains enabled in Launcher; no badge over file icon.
        id: iconNumber
        visible: false
        keys: row.hint > 0 ? row.hintModifier + "+" + row.hint : ""
        taken: row.hintTaken
        // From the icon's top left corner rightwards, clear of the title.
        x: row.onPixel(iconSlot.x - 5)
        y: row.onPixel(iconSlot.y - 4)
    }

    MouseArea {
        id: area

        // A file's or folder's row, held with the mouse and moved past the
        // system's drag distance, drags it out (into a chat, a folder). The
        // list then does not take the drag for scrolling (the wheel, the
        // scroll bar and touch still scroll it); the other rows scroll as before.
        property point pressedAt: Qt.point(0, 0)
        property bool draggedOut: false

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (mouse) => {
            draggedOut = false
            pressedAt = Qt.point(mouse.x, mouse.y)
            preventStealing = mouse.button === Qt.LeftButton && !row.isApp && !row.offline && !row.missing
                              && mouse.source === Qt.MouseEventNotSynthesized
        }
        onPositionChanged: (mouse) => {
            if (!pressed || !preventStealing || draggedOut || !(mouse.buttons & Qt.LeftButton))
                return
            if (Math.hypot(mouse.x - pressedAt.x, mouse.y - pressedAt.y) < Application.styleHints.startDragDistance)
                return
            draggedOut = true
            row.dragRequested(row.index) // returns once it was let go
        }
        onClicked: (mouse) => {
            if (draggedOut) // the release that ended a drag out
                return
            if (mouse.button === Qt.RightButton)
                row.menuRequested(row.index, area.mapToGlobal(mouse.x, mouse.y))
            else
                row.clicked(row.index, mouse.modifiers)
        }

        // Context actions remain available via right-click, Shift+F10, or
        // the single unobtrusive overflow button on hover. All actions
        // themselves are still implemented by the existing context menu.
        Row {
            id: actions
            visible: row.showActions
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter

            RowAction {
                id: moreAction
                glass: true
                glyph: "\uE10C" // horizontal ellipsis, Segoe MDL2
                tip: qsTr("操作")
                tipShortcut: "Shift+F10"
                onClicked: row.menuRequested(row.index,
                    row.mapToGlobal(Qt.point(row.width - 32, row.height - 10)))
            }
        }
    }

    HoverTip {
        // Keep full timestamps accessible; selected row no longer sprouts
        // five grey icons over its filename and folder path.
        readonly property bool onDate: date.visible && area.containsMouse
            && date.contains(date.mapFromItem(area, area.mouseX, area.mouseY))
        target: moreAction.tipWanted ? moreAction : onDate ? date : null
        text: moreAction.tipWanted ? moreAction.tip : onDate ? row.modifiedFull : ""
        shortcut: moreAction.tipWanted ? moreAction.tipShortcut : ""
    }
}
