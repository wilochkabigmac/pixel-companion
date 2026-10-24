// Character.qml - the companion herself.
//
// A chibi drawn from QML primitives, so her colours follow the Omarchy theme
// and she can be redrawn into any mood without an asset to load.
//
//   mood: idle | talking | happy | love | sad | surprised | thinking
//
// The face is built from paths that swap with the mood, and moods that come
// with a feeling (love, sad) throw off emoji that drift up and fade.
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    implicitWidth: 132
    implicitHeight: 168

    // True while the agent is answering.
    property bool talking: false
    // True while she is waiting for the agent.
    property bool waiting: false
    // idle | talking | happy | love | sad | surprised | thinking
    property string mood: "idle"

    property color skinColor: "#f3d9c9"
    property color hairColor: "#4a3b52"
    property color hairShade: "#3a2e40"
    property color accentColor: "#f38d70"
    property color accentShade: "#c96f57"
    property color eyeColor: "#2b2230"
    property color outlineColor: "#00000030"
    property color blushColor: "#ff9aa2"
    property color mouthColor: "#7a3b48"

    // ---- animation state -------------------------------------------------
    property real bob: 0
    property real blink: 1
    property real mouth: 3.5
    // The hop and the squash are driven from outside, so artwork and the
    // drawn chibi can bounce together.
    property real hop: 0
    property real squash: 1

    readonly property bool eyesHappy: mood === "happy"
    readonly property bool eyesLove: mood === "love"
    readonly property bool eyesWide: mood === "surprised"
    readonly property bool eyesLidded: mood === "sad" || mood === "thinking"
    readonly property bool eyesShut: blink < 0.2

    SequentialAnimation {
        running: true
        loops: Animation.Infinite
        NumberAnimation {
            target: root; property: "bob"
            from: 0; to: -3.5; duration: 1500
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root; property: "bob"
            from: -3.5; to: 0; duration: 1500
            easing.type: Easing.InOutSine
        }
    }

    // Blink, a little less often when she is happy.
    Timer {
        interval: root.mood === "happy" ? 3600 : 2400
        running: true
        repeat: true
        onTriggered: blinkTimer.restart()
    }
    Timer {
        id: blinkTimer
        interval: 110
        onTriggered: root.blink = 1
    }
    SequentialAnimation {
        NumberAnimation { target: root; property: "blink"; to: 0.08; duration: 70 }
        NumberAnimation { target: root; property: "blink"; to: 1; duration: 90 }
    }

    // Talking mouth.
    SequentialAnimation {
        running: root.talking && root.mood !== "happy" && root.mood !== "love"
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "mouth"; to: 10; duration: 120; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "mouth"; to: 3.5; duration: 120; easing.type: Easing.InQuad }
    }

    // ---- the face --------------------------------------------------------
    function eyePath() {
        if (root.eyesHappy)
            return "M 0 13 Q 8 1 16 13"
        if (root.eyesLove)
            return "M 8 17 C 0 11 0 3 4 3 C 6 3 8 5 8 6 C 8 5 10 3 12 3 C 16 3 16 11 8 17 Z"
        if (root.eyesWide)
            return "M 0 10 C 0 2 4 0 8 0 C 12 0 16 2 16 10 C 16 18 12 20 8 20 C 4 20 0 18 0 10 Z"
        return "M 0 9 C 0 3 4 0 8 0 C 12 0 16 3 16 9 C 16 15 12 18 8 18 C 4 18 0 15 0 9 Z"
    }

    function mouthPath() {
        if (root.mood === "happy")
            return "M 0 0 Q 10 15 20 0 Q 10 5 0 0 Z"
        if (root.mood === "love")
            return "M 0 1 Q 10 9 20 1"
        if (root.mood === "sad")
            return "M 0 9 Q 10 -1 20 9"
        if (root.mood === "surprised")
            return "M 3 1 C 7 0 13 0 17 1 C 18 6 16 11 10 11 C 4 11 2 6 3 1 Z"
        if (root.mood === "thinking")
            return "M 2 4 L 18 4"
        return "M 4 3 Q 10 5 16 3"
    }

    readonly property bool mouthIsShape: mood === "happy" || mood === "love"
        || mood === "sad" || mood === "surprised" || mood === "thinking"

    // ---- shadow ----------------------------------------------------------
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: 84
        height: 12
        radius: 6
        color: "#00000033"
        opacity: 0.5
        scale: 1 - root.bob * 0.02
    }

    // ---- body ------------------------------------------------------------
    Item {
        id: body
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        width: 132
        height: 168

        transform: Translate { y: root.bob + root.hop }
        scale: root.squash


        // arms
        Rectangle {
            id: armLeft
            x: 12; y: 96
            width: 18; height: 42
            radius: 9
            color: root.accentShade
            rotation: 14
            transformOrigin: Item.Top
        }
        Rectangle {
            id: armRight
            x: 102; y: 96
            width: 18; height: 42
            radius: 9
            color: root.accentShade
            rotation: -14
            transformOrigin: Item.Top
        }

        // hoodie
        Rectangle {
            id: hoodie
            anchors.horizontalCenter: parent.horizontalCenter
            y: 94
            width: 78
            height: 60
            radius: 24
            color: root.accentColor

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: -12
                width: 52
                height: 26
                radius: 13
                color: root.accentShade
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 26
                width: 44
                height: 20
                radius: 9
                color: root.accentShade
                opacity: 0.75
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 8
                width: 20
                height: 12
                radius: 3
                color: root.outlineColor
                opacity: 0.5
            }
        }

        // feet
        Rectangle {
            x: 44; y: 150
            width: 20; height: 10
            radius: 5
            color: root.accentShade
        }
        Rectangle {
            x: 70; y: 150
            width: 20; height: 10
            radius: 5
            color: root.accentShade
        }

        // ---- head --------------------------------------------------------
        Item {
            id: head
            anchors.horizontalCenter: parent.horizontalCenter
            y: 6
            width: 132
            height: 104

            // hair behind
            Shape {
                anchors.fill: parent
                ShapePath {
                    fillColor: root.hairShade
                    PathSvg {
                        path: "M 22 74 C 16 30 40 0 66 0 C 92 0 116 30 110 74 C 114 92 108 102 100 108 L 32 108 C 24 102 18 92 22 74 Z"
                    }
                }
            }

            // face
            Rectangle {
                id: face
                anchors.horizontalCenter: parent.horizontalCenter
                y: 8
                width: 86
                height: 88
                radius: 40
                color: root.skinColor
            }

            // fringe
            Shape {
                anchors.fill: parent
                z: 2
                ShapePath {
                    fillColor: root.hairColor
                    PathSvg {
                        path: "M 23 54 C 23 24 41 8 66 8 C 91 8 109 24 109 54 C 101 41 93 35 85 37 C 77 39 73 30 65 32 C 55 34 47 26 41 34 C 33 40 29 47 23 54 Z"
                    }
                }
            }

            // side locks
            Shape {
                anchors.fill: parent
                z: 2
                ShapePath {
                    fillColor: root.hairColor
                    PathSvg {
                        path: "M 25 46 C 20 70 20 92 26 110 L 38 108 C 33 90 33 66 36 50 Z"
                    }
                }
                ShapePath {
                    fillColor: root.hairColor
                    PathSvg {
                        path: "M 107 46 C 112 70 112 92 106 110 L 94 108 C 99 90 99 66 96 50 Z"
                    }
                }
            }

            // ---- eyes --------------------------------------------------
            component Eye: Item {
                id: eye
                width: 16
                height: 18

                // A sad or thinking look is half-lidded.
                readonly property real lidScale: root.eyesLidded ? 0.62 : 1.0
                readonly property real lidShift: root.eyesLidded ? 3 : 0

                Shape {
                    anchors.fill: parent
                    visible: !root.eyesShut
                    transformOrigin: Item.Bottom
                    scale: eye.lidScale
                    y: eye.lidShift
                    ShapePath {
                        fillColor: root.eyeColor
                        PathSvg { path: root.eyePath() }
                    }
                }

                // the pupil, only for the open-eyed moods
                Rectangle {
                    visible: !root.eyesHappy && !root.eyesLove && !root.eyesShut
                    x: 3; y: root.mood === "thinking" ? -1 : 3
                    width: 5; height: 5
                    radius: 2.5
                    color: "#ffffff"
                    scale: eye.lidScale
                }
            }

            Eye {
                x: 40; y: 52
            }
            Eye {
                x: 78; y: 52
            }

            // a tear, when she is sad
            Shape {
                visible: root.mood === "sad"
                x: 48; y: 66
                width: 8; height: 12
                ShapePath {
                    fillColor: "#7fc4e8"
                    PathSvg { path: "M 4 0 C 8 5 7 11 4 11 C 1 11 0 5 4 0 Z" }
                }
                SequentialAnimation on opacity {
                    running: root.mood === "sad"
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.0; to: 1.0; duration: 900 }
                    NumberAnimation { from: 1.0; to: 0.0; duration: 900 }
                }
            }

            // blush
            Rectangle {
                x: 28; y: 70
                width: 15; height: 8
                radius: 4
                color: root.blushColor
                opacity: root.mood === "love" ? 0.8 : 0.45
            }
            Rectangle {
                x: 89; y: 70
                width: 15; height: 8
                radius: 4
                color: root.blushColor
                opacity: root.mood === "love" ? 0.8 : 0.45
            }

            // ---- mouth -------------------------------------------------
            Shape {
                visible: root.mouthIsShape
                x: 56; y: 74
                width: 20; height: 12
                ShapePath {
                    fillColor: root.mouthColor
                    PathSvg { path: root.mouthPath() }
                }
            }

            // the talking mouth is an opening oval
            Rectangle {
                visible: !root.mouthIsShape && root.mood !== "idle"
                anchors.horizontalCenter: parent.horizontalCenter
                y: 78
                width: 12
                height: root.mouth
                radius: root.mouth / 2
                color: root.mouthColor
                Behavior on height { NumberAnimation { duration: 90 } }
                Behavior on radius { NumberAnimation { duration: 90 } }
            }

            // a small neutral mouth when there is nothing to say
            Rectangle {
                visible: !root.mouthIsShape && root.mood === "idle"
                anchors.horizontalCenter: parent.horizontalCenter
                y: 80
                width: 8
                height: 3
                radius: 1.5
                color: root.mouthColor
            }

            // raised brows for surprise
            Shape {
                visible: root.mood === "surprised"
                anchors.fill: parent
                z: 3
                ShapePath {
                    fillColor: root.hairColor
                    PathSvg { path: "M 38 44 L 52 40 L 52 44 L 38 48 Z" }
                }
                ShapePath {
                    fillColor: root.hairColor
                    PathSvg { path: "M 94 44 L 80 40 L 80 44 L 94 48 Z" }
                }
            }
        }

        // ---- mood particles ------------------------------------------
        Particles {
            id: particles
            anchors.fill: parent
            mood: root.mood
        }
    }
}
