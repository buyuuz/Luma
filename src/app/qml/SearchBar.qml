import QtQuick
import WinShun

// Search icon, the input field and the scope switcher. The rest of it drags
// the window (see WindowFrame).
Item {
    id: bar

    required property Launcher launcher
    required property Placement placement
    required property WindowFrame frame
    property alias text: input.text
    readonly property bool hasSelection: input.selectedText.length > 0
    readonly property string composition: input.preeditText // an input method's, not typed yet
    readonly property Item field: input // what the clipboard pastes into
    // Opened over Luma's box on the taskbar: the field is drawn there (its
    // state reported, see Launcher.inTaskbarBox), here only the tabs show.
    // The field stays, out of sight, with the keyboard.
    readonly property bool inBox: launcher.inTaskbarBox
    // The pointer over the header: Windows takes its drag area as a title bar,
    // so QML hears of the pointer there only from the frame.
    readonly property bool hovered: hover.hovered || contains(mapFromItem(null, frame.pointer))

    signal keyPressed(var event)
    signal keyReleased(var event)

    // On whole device pixels, as the rows' text (ResultRow.qml): centred, at
    // 150 % the field's text sits on a half pixel, and while the window slides
    // in (Placement.contentShift) its glyphs come out a pixel taller on some
    // frames than when it rests.
    function onPixel(y) { return Math.round(y * Screen.devicePixelRatio) / Screen.devicePixelRatio }

    function focusAndSelect() {
        input.forceActiveFocus()
        input.selectAll()
    }

    function reportField() {
        if (inBox)
            launcher.reportField(input.text, input.cursorPosition, input.selectionStart, input.selectionEnd,
                                 input.preeditText)
    }
    onInBoxChanged: reportField()

    Connections {
        target: bar.launcher
        function onCaretRequested(position, word) {
            input.cursorPosition = position
            if (word)
                input.selectWord()
        }
        function onSelectionRequested(anchor, position) { input.select(anchor, position) }
    }

    implicitHeight: bar.inBox ? Theme.headerHeight : Theme.headerHeight - 4 // 60px default launcher header; taskbar unaffected

    // Spotlight/Raycast: open header without a nested Windows-style outline.
    // The input floats directly on the glass panel; no nested Windows pill.
    Rectangle {
        anchors.fill: parent
        visible: !bar.inBox
        radius: Theme.launcherRadius
        color: Qt.rgba(1, 1, 1, 0.016)
    }

    Component.onCompleted: {
        frame.addDragArea(bar)
        frame.addControl(input)
        frame.addControl(tabs)
    }

    HoverHandler { id: hover } // over the field and the tabs

    states: State {
        when: bar.inBox
        AnchorChanges {
            target: input
            anchors.right: undefined
        }
        PropertyChanges {
            input.width: 1 // still takes the keys; too thin to be clicked
            input.opacity: 0
        }
        AnchorChanges {
            target: tabs
            anchors.right: undefined
            anchors.left: bar.left
        }
    }

    // Grip: shows that the header moves the window. Faint while the pointer is
    // over the header; pointed at, it grows and brightens; while the window
    // moves, it takes the accent colour.
    Item {
        id: grip

        readonly property bool pointed: contains(mapFromItem(null, bar.frame.pointer))
        readonly property bool held: bar.placement.moving

        visible: false // Mac-style search panel needs no Windows drag handle.
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 72 // easier to find than the pill itself
        height: 14

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 6 // even: on whole device pixels at 150 %
            width: grip.held || grip.pointed ? 48 : 36
            height: 4
            radius: 2
            color: grip.held ? Theme.accent : grip.pointed ? Theme.subtext : Theme.faint
            opacity: grip.held || grip.pointed ? 1 : bar.hovered ? 0.7 : 0
            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    Glyph {
        id: icon
        visible: !bar.inBox
        anchors.left: parent.left
        anchors.leftMargin: 35
        y: bar.onPixel((bar.height - height) / 2)
        glyph: bar.launcher.scope === Launcher.Content ? "" // Document
             : "" // Search
        size: Math.max(18, Theme.searchIconSize - 2) // 20px at default UI scale
        color: Theme.glassSecondary
    }

    TextInput {
        id: input
        objectName: "searchField" // App answers the input method for it while it is in the box
        anchors.left: icon.right
        anchors.leftMargin: 20
        anchors.right: tabs.left
        anchors.rightMargin: 20
        y: bar.onPixel((bar.height - height) / 2)
        focus: true
        clip: true
        color: Theme.glassText
        font.pixelSize: bar.inBox ? Theme.uiSearch : Theme.uiSearch - 2 // 22px default launcher input
        selectByMouse: true
        selectionColor: Theme.textSelection
        selectedTextColor: Theme.text
        // Still shown while the clipboard under it has the keyboard: what a
        // paste there goes over.
        persistentSelection: true
        onTextChanged: {
            bar.launcher.query = text
            bar.reportField()
        }
        onPreeditTextChanged: bar.reportField()
        onCursorPositionChanged: bar.reportField()
        onSelectionStartChanged: bar.reportField()
        onSelectionEndChanged: bar.reportField()
        Keys.onPressed: (event) => bar.keyPressed(event)
        Keys.onReleased: (event) => bar.keyReleased(event)

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: bar.launcher.placeholder
            color: Theme.glassMuted
            font: input.font
            elide: Text.ElideRight
            visible: input.text.length === 0 && input.preeditText.length === 0
        }

        Text { // a plugin command's hint, after its keyword, until the words are typed ("kill |进程名或 PID")
            id: keywordHint

            // Where the typed text ends: asked again whenever it changes
            // (positionToRectangle is a call, not a property, so a binding
            // would not follow the text). On displayTextChanged, not
            // textChanged: TextInput emits textChanged before it lays the
            // new text out, and asked then for a text that grew, the old
            // layout has no such position and answers x = 0 (the hint came
            // out over the keyword; pitfalls "TextInput 的 textChanged 早于排版").
            property real textEnd: 0
            function place() { textEnd = input.positionToRectangle(input.length).x }

            // Placed by x, so not anchored on the right (an anchor there would
            // set x itself, see pitfalls "只锚了右边又写了 x"): the width to the edge instead.
            x: textEnd + 2
            width: Math.max(0, parent.width - x)
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            verticalAlignment: Text.AlignVCenter
            text: bar.launcher.pluginHint
            color: Theme.glassMuted
            font: input.font
            elide: Text.ElideRight
            visible: text.length > 0 && input.preeditText.length === 0 && !bar.inBox

            Connections {
                target: input
                function onDisplayTextChanged() { keywordHint.place() }
                function onFontChanged() { keywordHint.place() }
            }
        }
    }

    ScopeTabs {
        id: tabs
        scaled: true
        anchors.right: parent.right
        anchors.rightMargin: 32
        anchors.leftMargin: 16
        y: bar.onPixel((bar.height - height) / 2)
        // 文件夹 is a chip of the strip under the box (TypeStrip): 文件 stays current.
        current: bar.launcher.scope === Launcher.Folders ? Launcher.Files : bar.launcher.scope
        contentTab: bar.launcher.contentEnabled
        // 全部 › [icon] 结束进程 while a plugin's keyword has the list; the
        // chip (or 全部 itself) empties the box, which leaves the mode.
        pluginLabel: bar.launcher.pluginLabel
        pluginIcon: bar.launcher.pluginIcon
        onActivated: (scope) => {
            if (scope === Launcher.All && bar.launcher.scope === Launcher.All && bar.launcher.pluginKeyword.length > 0)
                bar.launcher.leaveKeyword()
            else if (scope !== Launcher.Files || bar.launcher.scope !== Launcher.Folders) // 文件 in 文件夹: stays
                bar.launcher.scope = scope
        }
        onPluginClicked: bar.launcher.leaveKeyword()
    }
}
