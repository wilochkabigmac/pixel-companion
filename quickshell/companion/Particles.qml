// Particles.qml - the little emoji that burst out of her when she feels
// something.
//
// A mood change throws a whole handful of symbols into the air around her.
// They rise, drift sideways, and fade out.
import QtQuick

Item {
    id: root

    // idle | talking | happy | love | sad | surprised | thinking
    property string mood: "idle"

    // The emoji each mood throws.
    property var emojiFor: ({
        "idle": [],
        "talking": ["💬", "💬", "💬"],
        "happy": ["✨", "🎉", "😄", "⭐", "🌟", "🎊", "😃", "💫"],
        "love": ["💖", "💕", "💗", "🥰", "💘", "💝", "💞", "🫶"],
        "sad": ["💧", "😢", "🥺", "💔", "😞", "💦", "🌧️", "☁️"],
        "surprised": ["❗", "😮", "💫", "❓", "❕", "😲"],
        "thinking": ["💭", "🤔", "💡", "🧠", "❔"]
    })

    // Moods you invented yourself (character-angry.png and so on) do not have
    // a list above; these are thrown for them instead. Set to [] for nothing.
    property var fallbackEmoji: ["✨", "💫"]

    property int poolSize: 18
    // How many she throws at once.
    property int burstSize: 9
    // How far apart they start, in milliseconds.
    property int stagger: 65

    Timer {
        id: staggerTimer
        interval: root.stagger
        repeat: true
        running: false
        onTriggered: {
            if (root.spawned >= root.burstSize) {
                root.spawned = 0
                staggerTimer.running = false
                return
            }
            root.spawned++
            root.launchOne()
        }
    }

    property int spawned: 0

    function launchOne() {
        // A mood listed above with an empty list is deliberately quiet; a
        // mood that is not listed at all gets the fallback.
        var list = emojiFor[mood]
        if (list === undefined)
            list = fallbackEmoji
        if (!list || list.length === 0)
            return
        for (var i = 0; i < pool.count; i++) {
            var p = pool.itemAt(i)
            if (p.busy)
                continue
            p.launch(list[Math.floor(Math.random() * list.length)], root.width)
            return
        }
    }

    function burst() {
        if (!emojiFor[mood] || emojiFor[mood].length === 0)
            return
        spawned = 0
        staggerTimer.running = true
    }

    // A new mood throws its emoji.
    onMoodChanged: {
        if (mood !== "idle")
            burst()
    }

    Repeater {
        id: pool
        model: root.poolSize

        delegate: Text {
            id: particle

            property bool busy: false
            property real startX: 0
            property real drift: 0
            property real rise: 60
            property real progress: 0

            visible: busy
            opacity: 0
            font.pixelSize: 17
            text: "✨"

            function launch(emoji, centreX) {
                text = emoji
                // Spread them across her, and a little beyond.
                startX = centreX / 2 - width / 2 + (Math.random() * (centreX + 40) - 20)
                drift = (Math.random() * 56 - 28)
                rise = 52 + Math.random() * 46
                busy = true
                progress = 0
                x = startX
                y = 46

                anim.restart()
            }

            NumberAnimation {
                id: anim
                target: particle
                property: "progress"
                from: 0
                to: 1
                duration: 1400 + Math.random() * 500
                easing.type: Easing.OutCubic

                onStarted: particle.opacity = 1
                onFinished: {
                    particle.busy = false
                    particle.opacity = 0
                }
            }

            onProgressChanged: {
                var p = particle.progress
                x = particle.startX + particle.drift * p
                y = 46 - particle.rise * p
                opacity = p < 0.12 ? p / 0.12 : (1 - (p - 0.12) / 0.88)
                scale = 0.5 + 0.5 * Math.min(1, p * 5)
                rotation: Math.sin(p * 6.0) * 12
            }
        }
    }
}
