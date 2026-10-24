// Bubble.qml - the speech bubble next to the character.
//
// Shows whatever the assistant last said, typed out character by character,
// and doubles as the permission prompt when the agent wants to do something.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root

    // Full text of the reply.
    property string fullText: ""
    // How much of fullText is currently revealed.
    property int shownChars: 0
    // When set, the bubble asks for a permission decision instead.
    property var permission: null
    property string copyHint: ""
    // Where the character is, so the tail can point at her.
    property real tailCenter: 165
    // How many lines fit before we start eliding.
    property int maxLines: 12

    signal permissionReply(string requestId, string decision)
    signal copyRequested()

    // The bubble reports its natural height separately: the panel's surface
    // must not take its size from the text, or it resizes as she talks.
    readonly property real naturalHeight: content.implicitHeight + 26
    implicitWidth: 0
    implicitHeight: 0

    property color bgColor: "#f6f1f3"
    property color fgColor: "#2b2226"
    property color mutedColor: "#6d5f64"
    property color accentColor: "#f38d70"

    readonly property color bg: root.bgColor
    readonly property color fg: root.fgColor
    readonly property color dim: root.mutedColor

    // tail: the lower half of a rotated square peeking out from under the
    // bubble body (PathSvg in a Shape strokes instead of filling, so a
    // rotated square is the reliable way to get a solid triangle).
    Item {
        width: 18
        height: 14
        x: Math.max(0, Math.min(root.width - 18, root.tailCenter - 9))
        y: parent.height - 13

        Rectangle {
            width: 11
            height: 11
            rotation: 45
            x: 3
            y: -4
            color: root.bg
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.bottomMargin: 12
        radius: 16
        color: root.bg
        border.width: 1
        border.color: root.accentColor
        opacity: 0.97
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        anchors.bottomMargin: 22
        spacing: 8

        // ---- permission prompt -------------------------------------------
        ColumnLayout {
            id: permBlock
            visible: root.permission !== null
            spacing: 6
            Layout.fillWidth: true

            Text {
                text: "The assistant wants to run:"
                color: root.dim
                font.pixelSize: 11
                font.bold: true
            }

            Text {
                text: root.permission ? (root.permission.action || "an action") : ""
                color: root.fg
                font.pixelSize: 12
                font.family: "monospace"
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 4
                Layout.fillWidth: true
            }

            Text {
                visible: root.permission && root.permission.resources && root.permission.resources.length > 0
                text: root.permission && root.permission.resources
                      ? root.permission.resources.slice(0, 3).join("\n")
                      : ""
                color: root.dim
                font.pixelSize: 10
                font.family: "monospace"
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 3
                Layout.fillWidth: true
            }
            RowLayout {
                spacing: 6
                Layout.fillWidth: true

                Button {
                    text: "Allow"
                    font.pixelSize: 11
                    flat: true
                    onClicked: root.permissionReply(root.permission.id, "once")
                }
                Button {
                    text: "Always"
                    font.pixelSize: 11
                    flat: true
                    onClicked: root.permissionReply(root.permission.id, "always")
                }
                Button {
                    text: "Deny"
                    font.pixelSize: 11
                    flat: true
                    onClicked: root.permissionReply(root.permission.id, "reject")
                }
            }
        }

        // ---- normal reply -------------------------------------------------
        Text {
            id: body
            visible: root.permission === null
            text: root.shownChars > 0 ? root.fullText.substring(0, root.shownChars) : ""
            color: root.fg
            font.pixelSize: 12
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            textFormat: Text.PlainText
            maximumLineCount: root.maxLines
            elide: Text.ElideRight
            onLinkActivated: Qt.openUrlExternally(link)
        }

        // ---- waiting indicator -------------------------------------------
        RowLayout {
            visible: root.permission === null && root.fullText === "" && root.shownChars === 0
            spacing: 4
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    width: 6; height: 6; radius: 3
                    color: root.dim
                    SequentialAnimation on opacity {
                        running: true
                        loops: Animation.Infinite
                        PauseAnimation { duration: 140 * index }
                        NumberAnimation { to: 0.25; duration: 140 }
                        NumberAnimation { to: 1; duration: 140 }
                    }
                }
            }
            Text {
                text: "thinking..."
                color: root.dim
                font.pixelSize: 11
                font.italic: true
            }
        }

        // ---- footer -------------------------------------------------------
        RowLayout {
            visible: root.permission === null && root.fullText !== ""
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.copyHint
                color: root.dim
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Button {
                text: "copy"
                flat: true
                font.pixelSize: 10
                onClicked: root.copyRequested()
            }
        }
    }
}
