pragma ComponentBehavior: Bound

import QtQuick
import WinShun

// Mac-style launcher action dock. Native Launcher remains the only place that
// implements keyboard shortcuts, sorting, delete confirmations, and actions.
Item {
    id: footer
    required property Launcher launcher
    required property WindowFrame frame

    implicitHeight: 58
    readonly property bool atStart: launcher.query.trim().length === 0
                                    && launcher.scope !== Launcher.Content
    readonly property var sortLabels: atStart ? [qsTr("最近打开"), qsTr("最近修改")]
                                               : [qsTr("最匹配"), qsTr("最新"), qsTr("最早")]
    readonly property int currentSort: atStart ? launcher.startList : launcher.sort

    Component.onCompleted: frame.addDragArea(footer)

    Rectangle {
        id: footerSurface
        anchors.fill: parent
        radius: Theme.windowRadius
        color: Qt.rgba(0.035, 0.038, 0.042, 0.48)
    }
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Theme.windowRadius
        color: footerSurface.color
    }
    Rectangle {
        height: 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        color: Qt.rgba(1, 1, 1, 0.09)
    }
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        height: launcher.busy ? 2 : 0
        width: launcher.progress >= 0 ? parent.width * launcher.progress : parent.width
        color: Theme.glassAccent
        opacity: launcher.busy ? 0.7 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    Rectangle {
        id: mark
        width: 32
        height: 32
        radius: 16
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.rgba(1, 1, 1, 0.07)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.13)
        Text {
            anchors.centerIn: parent
            text: "L"
            color: Theme.glassText
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }
    }

    Rectangle {
        id: sortButton
        anchors.left: mark.right
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        height: 30
        width: sortText.implicitWidth + 27
        radius: 15
        color: sortArea.containsMouse ? Qt.rgba(1, 1, 1, 0.13)
                                      : Qt.rgba(1, 1, 1, 0.065)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
        Text {
            id: sortText
            anchors.centerIn: parent
            text: footer.sortLabels[Math.max(0, Math.min(footer.currentSort, footer.sortLabels.length - 1))] + "  ↻"
            color: Theme.glassSecondary
            font.pixelSize: Theme.uiCaption
        }
        MouseArea {
            id: sortArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (footer.atStart)
                    footer.launcher.startList = (footer.launcher.startList + 1) % 2
                else
                    footer.launcher.sort = (footer.launcher.sort + 1) % 3
            }
        }
        Component.onCompleted: footer.frame.addControl(sortButton)
    }

    Text {
        id: status
        anchors.left: sortButton.right
        anchors.leftMargin: 16
        anchors.right: actionDock.left
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: footer.launcher.statusText
        color: Theme.glassMuted
        font.pixelSize: Theme.uiCaption
    }

    // Two-click confirmation is still required to clear recent history.
    RowAction {
        id: clearHistory
        property bool armed: false
        visible: footer.launcher.canClearHistory && hoverFooter.hovered
        glass: true
        anchors.right: actionDock.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        glyph: "\uE74D"
        tip: armed ? "" : qsTr("清除最近使用记录（点两次确认）")
        text: armed ? qsTr("确认清除") : ""
        danger: armed
        onClicked: {
            if (armed) {
                armed = false
                footer.launcher.clearHistory()
            } else {
                armed = true
                disarm.restart()
            }
        }
        onVisibleChanged: if (!visible) armed = false
        Component.onCompleted: footer.frame.addControl(clearHistory)
        Timer {
            id: disarm
            interval: 3000
            onTriggered: clearHistory.armed = false
        }
    }

    Rectangle {
        id: actionDock
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        height: 37
        width: actions.implicitWidth + 32
        radius: 18.5
        color: Qt.rgba(0, 0, 0, 0.20)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.17)

        Row {
            id: actions
            anchors.centerIn: parent
            spacing: 13
            Text {
                text: footer.launcher.keyHints.enter ?? qsTr("打开")
                color: Theme.glassText
                font.pixelSize: Theme.uiCaption
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                width: enterKey.implicitWidth + 14
                height: 23
                radius: 7
                color: Qt.rgba(1, 1, 1, 0.085)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.15)
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: enterKey
                    anchors.centerIn: parent
                    text: "Enter"
                    color: Theme.glassSecondary
                    font.pixelSize: 12
                }
            }
            Rectangle {
                width: 1
                height: 22
                color: Qt.rgba(1, 1, 1, 0.14)
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: qsTr("操作")
                color: Theme.glassSecondary
                font.pixelSize: Theme.uiCaption
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                width: actionKey.implicitWidth + 12
                height: 23
                radius: 7
                color: Qt.rgba(1, 1, 1, 0.07)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.13)
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: actionKey
                    anchors.centerIn: parent
                    text: "Shift+F10"
                    font.pixelSize: 11
                    color: Theme.glassMuted
                }
            }
        }
    }

    ShortcutsButton {
        id: info
        readonly property string modifier: footer.launcher.numberKeys === "alt" ? "Alt" : "Ctrl"
        shortcuts: [
            ["Enter", qsTr("打开所选结果")],
            ["Shift+F10", qsTr("所选结果的全部操作菜单")],
            ["Ctrl+Enter", qsTr("打开文件所在位置")],
            ["↑ ↓", qsTr("上下选择结果")],
            ["Shift+↑ ↓", qsTr("选中多行")],
            ["Ctrl+C", qsTr("复制文件")],
            ["Ctrl+Shift+C", qsTr("复制路径")],
            ["Ctrl+S", qsTr("切换排序方式")],
            ["Tab", qsTr("切换搜索范围")],
            [modifier + "+1…9", qsTr("打开对应位置的结果")],
            ["Esc", qsTr("关闭搜索窗口")]
        ]
        host: footer.launcher
        frame: footer.frame
        anchors.right: actionDock.left
        anchors.rightMargin: 11
        anchors.verticalCenter: parent.verticalCenter
        opacity: hoverFooter.hovered ? 0.85 : 0.42
    }

    HoverHandler { id: hoverFooter }
    HoverTip {
        target: clearHistory.tipWanted ? clearHistory
               : sortArea.containsMouse ? sortButton : null
        text: clearHistory.tipWanted ? clearHistory.tip
            : qsTr("点击切换排序，快捷键 Ctrl+S")
    }
}
