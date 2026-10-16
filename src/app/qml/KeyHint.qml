import QtQuick
import WinShun

// "[Ctrl ↵] 打开位置" in the footer.
Row {
    id: hint

    property string keys
    property string label
    property bool glass: false
    // Its width when shown, also while hidden (a hidden Row lays out nothing).
    readonly property real fullWidth: label.length > 0 ? keyText.implicitWidth + 10 + spacing + labelText.implicitWidth : 0

    spacing: 5

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: keyText.implicitWidth + 10
        height: Theme.keycapHeight
        radius: hint.glass ? 6 : 4
        color: hint.glass ? Theme.glassKeycap : Theme.keycap
        border.width: 1
        border.color: hint.glass ? Theme.glassOutline : Theme.keycapBorder

        Text {
            id: keyText
            anchors.centerIn: parent
            text: hint.keys
            color: hint.glass ? Theme.glassText : Theme.subtext
            font.pixelSize: Theme.uiCaption
        }
    }

    Text {
        id: labelText
        anchors.verticalCenter: parent.verticalCenter
        text: hint.label
        color: hint.glass ? Theme.glassSecondary : Theme.faint
        font.pixelSize: Theme.uiBody
    }
}
