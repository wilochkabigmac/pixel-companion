//@ pragma UseQApplication
// shell.qml - the desktop companion.
//
// A little character who lives on your screen and talks to the same opencode
// server your terminal and web UI use.
//
//   click the character  -> open the input
//   drag the character  -> move her anywhere on the screen
//   right click         -> menu (new chat, copy, hide, quit)
//
// The panel is a layer-shell surface, so it floats above windows without
// taking up a workspace slot and never steals focus unless you are typing.
//
// The surface is a fixed size and only the contents move inside it: a
// layer-shell surface that resizes after it is mapped tends not to come back,
// and a fixed surface can be masked so only the character and the bubble
// take clicks.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    id: root

    readonly property string home: Quickshell.env("HOME")

    // ---- theme colours (read from the active Omarchy theme) ---------------
    property string accent: "#f38d70"
    property string bgColor: "#2c2525"
    property string fgColor: "#e6d9db"
    property string mutedColor: "#72696a"
    property string selectionColor: "#403e41"

    // ---- state -----------------------------------------------------------
    property bool inputOpen: false
    property bool busy: false
    property string replyText: ""
    property int shownChars: 0
    property var permission: null
    property string pendingPrompt: ""
    property int consumed: 0
    property string lastError: ""
    property bool pendingReveal: false
    property bool voiceEnabled: true
    property real charInterval: 65   // ms per character while the voice is on
    property real voiceRate: 15      // syllables per second
    property real voicePitch: 1.0     // a multiplier on the pitch
    property string voiceBase: "bright"
    // Which sound effect plays when she is tapped (~/.config/oc-companion/sfx/).
    property string clickSound: "click"
    // How she is feeling: idle | talking | happy | love | sad | surprised | thinking
    property string mood: "idle"
    property string pendingAnswer: ""
    property bool sfxEnabled: true
    // A picture waiting to be sent with the next message.
    property string pendingImage: ""
    // The bubble fades out on its own, and comes back when you tap her.
    property bool bubbleVisible: true
    property int bubbleIdle: 25000  // ms of quiet before the bubble fades
    // The hop, shared by the drawn chibi and any artwork.
    property real hop: 0
    property real squash: 1

    // ---- geometry --------------------------------------------------------
    // The panel is one bubble wide and a fixed height. The character sits at
    // either end of it and slides between the ends, so the bubble always has
    // somewhere to go.
    readonly property int panelWidth: 330
    readonly property int charWidth: 132
    readonly property int charHeight: 168
    readonly property int charGap: 8
    readonly property int inputHeight: 42
    readonly property int bubbleArea: 190   // the room the bubble may use

    readonly property int inputTop: bubbleArea + charGap
    readonly property int charTop: inputTop + inputHeight + charGap
    readonly property int panelHeight: charTop + charHeight

    // 0 = character on the left (bubble opens to the right)
    // 1 = character on the right (bubble opens to the left)
    // Animated, so crossing the middle is a slide and not a jump.
    property real flip: 1
    property real flipTarget: 1

    readonly property real charOffset: flip * (panelWidth - charWidth)

    // Position of the character on screen, in pixels from the left edge.
    property real charX: 1628
    // The y of the character's lower edge, measured from the top of the screen.
    property real charBottom: 1056

    property bool shown: true
    // The panel is only built once we know which monitor she belongs on:
    // a surface that is rebuilt for another output does not come back.
    property bool positionLoaded: false
    readonly property var panelItem: panelLoader.item
    property bool dragging: false
    property bool pressArmed: false
    // Where on her the pointer went down, in her own coordinates.
    property real grabLocalX: 0
    property real grabLocalY: 0
    property real pressLocalX: 0
    property real pressLocalY: 0
    property real lastCursorX: 0
    property real lastCursorY: 0
    property string cursorBuf: ""
    property string monitorName: ""

    readonly property bool hasBubble: replyText !== "" || permission !== null || busy

    // The output she lives on. Sticky: she does not chase your focus between
    // monitors unless you drag her there.
    // The screen list goes empty for a moment now and then, and a window with
    // no output does not map, so the last known screen is kept.
    property var cachedScreen: null

    function resolveScreen() {
        var list = Quickshell.screens
        if (list.length === 0)
            return cachedScreen

        var found = null
        if (monitorName !== "") {
            for (var i = 0; i < list.length; i++) {
                if (list[i].name === monitorName) {
                    found = list[i]
                    break
                }
            }
        }
        if (!found) {
            var monitor = Hyprland.focusedMonitor
            if (monitor) {
                for (var j = 0; j < list.length; j++) {
                    if (list[j].name === monitor.name) {
                        found = list[j]
                        break
                    }
                }
            }
        }
        if (!found)
            found = list[0]
        if (found)
            cachedScreen = found
        return found
    }

    readonly property var targetScreen: resolveScreen()

    readonly property real screenW: targetScreen ? targetScreen.width : 1920
    readonly property real screenH: targetScreen ? targetScreen.height : 1080
    readonly property real monitorX: targetScreen ? targetScreen.x : 0
    readonly property real monitorY: targetScreen ? targetScreen.y : 0

    // Optional custom artwork. Drop character.png (or .gif) next to this
    // file and it replaces the drawn chibi. Add character-happy.png,
    // character-love.png and so on to give the art its own expressions.
    property string customCharacter: ""
    property var customMoods: ({})

    // ---- processes -------------------------------------------------------
    property Process askProc: Process {
        id: askProc
        running: false
        command: ["oc-ask", "--jsonl", root.pendingPrompt]
        stdout: StdioCollector {
            waitForEnd: false
            onTextChanged: root.consume(text)
        }
        onExited: {
            root.busy = false
            if (root.pendingPrompt !== "" && root.replyText === "" && root.lastError === "")
                root.showError("the assistant did not answer")
        }
    }

    property Process permProc: Process {
        running: false
        command: ["oc-ask", "--reply", "pending", "once"]
    }

    // A long lived voice process: the typewriter feeds it characters as they
    // are revealed, so the blips follow the text instead of racing it.
    property Process voiceProc: Process {
        id: voiceProc
        running: false
        stdinEnabled: true
        command: ["oc-voice", "--stream",
                  "--rate", String(root.voiceRate),
                  "--pitch", String(root.voicePitch),
                  "--base", root.voiceBase]
    }

    property Process attachProc: Process {
        running: false
        command: ["oc-attach"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var path = String(text || "").trim()
                if (path !== "")
                    root.pendingImage = path
            }
        }
    }

    property Process sfxProc: Process {
        running: false
        command: ["oc-voice", "--sfx", "click"]
    }

    property Process voiceCfgProc: Process {
        running: false
        command: ["oc-companion", "voice", "toggle"]
    }

    // Her own voice comes out of the speakers, and the microphone is right
    // there. Closing it while she talks stops her from hearing herself.
    property Process micProc: Process {
        running: false
        command: ["agentvoice", "lock"]
    }

    property Process resetProc: Process {
        running: false
        command: ["oc-ask", "--reset"]
        onExited: root.say("New conversation started.")
    }

    property Process themeProc: Process {
        running: false
        command: ["sh", "-c", "cat \"$HOME/.local/state/omarchy/current/theme/colors.toml\" 2>/dev/null"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.applyTheme(text)
        }
    }

    property Process charProc: Process {
        running: false
        command: ["sh", "-c", "ls -1 \"$HOME/.config/quickshell/companion\"/character* 2>/dev/null"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.applyArtwork(String(text || ""))
        }
    }

    property Process configProc: Process {
        running: false
        command: ["sh", "-c", "cat \"$HOME/.config/oc-companion/config.json\" 2>/dev/null"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.applyConfig(text)
        }
    }

    property Process posProc: Process {
        running: false
        command: ["oc-companion", "position", "0", "0", "right", ""]
    }

    // The position is read synchronously: it names the monitor she lives on,
    // and changing the monitor after the panel is up makes the surface
    // remap badly.
    FileView {
        id: positionFile
        path: root.home + "/.local/state/oc-companion/position.json"
        blockLoading: true
        printErrors: false
        onLoaded: {
            root.applyPosition(__text)
            root.positionLoaded = true
        }
        onFileChanged: root.applyPosition(__text)
    }

    // While dragging we need the absolute cursor position: a layer-shell
    // surface carries the pointer with it, so the position inside the surface
    // tells us nothing about where the cursor is on the screen.
    property Process cursorProc: Process {
        id: cursorProc
        running: false
        command: ["sh", "-c", "while true; do hyprctl cursorpos 2>/dev/null; sleep 0.006; done"]
        stdout: StdioCollector {
            waitForEnd: false
            onTextChanged: root.onCursor(text)
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.themeProc.running = true
    }

    // ---- the typewriter ---------------------------------------------------
    Timer {
        id: typer
        interval: root.charInterval
        repeat: true
        running: false
        onTriggered: root.revealNext()
    }

    // The bubble drifts away after a while of nothing happening, and comes
    // back when you tap her.
    Timer {
        id: bubbleIdleTimer
        interval: root.bubbleIdle
        repeat: true
        onTriggered: {
            if (!root.inputOpen && !root.busy)
                root.bubbleVisible = false
        }
    }

    // agentvoice's lock only holds for ten seconds, so refresh it while she
    // is still talking.
    Timer {
        id: micLockTimer
        interval: 4000
        repeat: true
        running: false
        onTriggered: {
            root.micProc.command = ["agentvoice", "lock"]
            root.micProc.running = true
        }
    }

    // ---- ipc (so a keybind or the tray icon can drive the companion) -----
    IpcHandler {
        target: "companion"
        function toggle(): void {
            root.shown = !root.shown
        }
        function summon(): void {
            root.shown = true
            root.bubbleVisible = true
            bubbleIdleTimer.restart()
            root.inputOpen = true
            Qt.callLater(function () { root.panelItem.inputField.forceActiveFocus() })
        }
        function attach(): void {
            root.attachProc.running = true
        }
        function poke(): void {
            // A tap on her: a little hop and a sound.
            root.shown = true
            root.hopNow()
            root.playSound(root.clickSound)
        }
        function mood(name: string): void {
            // Preview an expression, e.g. from a script:
            // quickshell ipc -c companion call companion mood angry
            root.shown = true
            root.setMood(name, 6000)
        }
        function dismiss(): void {
            root.shown = false
            root.inputOpen = false
            root.stopVoice()
        }
        function ask(text: string): void {
            root.sendText(text)
        }
        function copy(): void {
            root.copyReply()
        }
        function result(text: string): void {
            root.shown = true
            root.say(text)
        }
        function exchange(question: string, answer: string): void {
            // A spoken exchange: the question appears at once (you already
            // said it), then the answer types itself out and she says it.
            root.shown = true
            typer.stop()
            root.replyText = question
            root.shownChars = question.length
            root.pendingAnswer = answer
            answerTimer.restart()
        }
        function menu(): void {
            root.panelItem.menuPopup.popup()
        }
        function place(x: string, y: string, side: string): void {
            root.charX = parseFloat(x)
            root.charBottom = root.screenH - parseFloat(y)
            root.flipTarget = side === "left" ? 0 : 1
            root.flip = root.flipTarget
            root.savePosition()
        }
        function reload(): void {
            root.configProc.running = true
            root.charProc.running = true
        }
    }

    // ---- the panel -------------------------------------------------------
    Loader {
        id: panelLoader
        active: root.positionLoaded
        asynchronous: false

        sourceComponent: Component {
    PanelWindow {
        id: panel

        // The root needs to reach these.
        property alias inputField: input
        property alias menuPopup: menu
        property alias theCharacter: character

        anchors {
            top: false
            bottom: true
            left: true
            right: false
        }

        margins {
            left: Math.round(root.charX - root.charOffset)
            bottom: Math.round(root.screenH - root.charBottom)
        }

        WlrLayershell.namespace: "oc-companion"
        WlrLayershell.layer: WlrLayer.Top

        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        screen: root.resolveScreen()
        focusable: true
        visible: root.shown

        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight

        // Only the character and the bubble take clicks; the rest of the
        // surface is see-through and lets clicks through to whatever is under.
        // Only the character and the bubble take clicks; the rest of the
        // surface is see-through and lets clicks through to whatever is
        // underneath.
        mask: Region {
            Region {
                item: character
            }
            Region {
                item: bubble
            }
            Region {
                item: inputBox
            }
        }

        onVisibleChanged: {
            if (visible && root.pendingReveal) {
                root.pendingReveal = false
                root.say(root.replyText)
            }
        }

        // Clicking anywhere empty in the panel should not eat clicks meant
        // for the windows underneath.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
        }

        // The contents live in a fixed-size item: the surface takes its size
        // from here, and a surface that resizes after it is mapped tends not
        // to come back.
        Item {
            id: content
            width: root.panelWidth
            height: root.panelHeight

        Bubble {
            id: bubble
            x: 0
            y: (root.inputOpen ? root.inputTop : root.charTop) - root.charGap - height
            width: root.panelWidth
            height: Math.min(naturalHeight, root.bubbleArea)
            visible: root.hasBubble && root.shown && root.bubbleVisible
            opacity: root.bubbleVisible ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
            }

            fullText: root.replyText
            shownChars: root.shownChars
            permission: root.permission
            copyHint: root.replyText.length > 260 ? "copy for the full answer" : ""
            tailCenter: root.charOffset + root.charWidth / 2
            maxLines: Math.max(2, Math.floor((root.bubbleArea - 34) / 16))

            bgColor: root.bgColor
            fgColor: root.fgColor
            mutedColor: root.mutedColor

            onPermissionReply: (requestId, decision) => {
                root.permProc.command = ["oc-ask", "--reply", requestId, decision]
                root.permProc.running = true
                root.permission = null
                root.say("")
            }
            onCopyRequested: root.copyReply()
        }

        // ---- input ------------------------------------------------------
        Rectangle {
            id: inputBox
            x: 0
            y: root.inputTop
            width: root.panelWidth
            height: root.inputHeight
            visible: root.inputOpen
            radius: 12
            color: root.bgColor
            border.width: 1
            border.color: root.accent
            opacity: 0.96

            // The picture waiting to go with the next message. Click it to
            // take it back off.
            Image {
                id: attachmentPreview
                visible: root.pendingImage !== ""
                x: 6
                y: 3
                width: 36
                height: 36
                source: root.pendingImage
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: true
                clip: true

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "transparent"
                    border.width: 1
                    border.color: root.accent
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pendingImage = ""
                }
            }

            TextField {
                id: input
                anchors.fill: parent
                anchors.leftMargin: root.pendingImage !== "" ? 50 : 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                placeholderText: root.pendingImage !== ""
                    ? "say something about the picture..."
                    : "ask anything..."
                color: root.fgColor
                placeholderTextColor: root.mutedColor
                font.pixelSize: 13
                selectByMouse: true
                background: null
                onAccepted: root.sendText(input.text)
                Keys.onEscapePressed: {
                    root.inputOpen = false
                    input.text = ""
                }
            }
        }

        // ---- the character ----------------------------------------------
        AnimatedImage {
            id: customArt
            visible: root.currentArt !== ""
            x: root.charOffset
            y: root.charTop
            width: root.charWidth
            height: root.charHeight
            source: root.currentArt
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: true
            clip: true

            CompanionDrag {
                id: customDrag
            }
        }

        Character {
            id: character
            visible: root.currentArt === ""
            x: root.charOffset
            y: root.charTop
            width: root.charWidth
            height: root.charHeight

            accentColor: root.accent
            mood: root.mood
            hop: root.hop
            squash: root.squash
            talking: root.busy || typer.running
            waiting: root.busy

            CompanionDrag {
                id: charDrag
            }
        }

        Menu {
            id: menu

            MenuItem {
                text: "Ask something..."
                onTriggered: {
                    root.shown = true
                    root.inputOpen = true
                    Qt.callLater(function () { root.panelItem.inputField.forceActiveFocus() })
                }
            }
            MenuItem {
                text: "New conversation"
                onTriggered: root.resetProc.running = true
            }
            MenuItem {
                text: "Copy last reply"
                onTriggered: root.copyReply()
            }
            MenuItem {
                text: root.voiceEnabled ? "Mute voice" : "Unmute voice"
                onTriggered: root.toggleVoice()
            }
            MenuItem {
                text: "Settings"
                onTriggered: root.openSettings()
            }
            MenuItem {
                text: "Hide companion"
                onTriggered: root.shown = false
            }
            MenuItem {
                text: "Quit"
                onTriggered: Qt.quit()
            }
        }
        }
        }
    }
    }

    // A drag handler shared by the drawn character and custom artwork.
    component CompanionDrag: MouseArea {
        id: dragArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        preventStealing: true
        hoverEnabled: true

        property bool moved: false

        // Keep the cursor position fresh so a press knows exactly where it
        // grabbed her.
        onEntered: {
            if (!root.dragging)
                cursorProc.running = true
        }
        onExited: {
            if (!root.dragging && !root.pressArmed)
                cursorProc.running = false
        }

        onPressed: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                root.panelItem.menuPopup.popup()
                mouse.accepted = true
                return
            }
            moved = false
            root.pressArmed = true
            // Where on her the pointer went down, in her own coordinates.
            // The polled cursor position can be a frame stale, and using it
            // made her jump to some other point under the pointer.
            root.grabLocalX = mouse.x
            root.grabLocalY = mouse.y
            root.pressLocalX = mouse.x
            root.pressLocalY = mouse.y
            cursorProc.running = true
        }

        onReleased: function (mouse) {
            if (root.pressArmed && !root.dragging) {
                // A click, not a drag: open the input, with a little bounce.
                root.pressArmed = false
                cursorProc.running = false
                root.hopNow()
                root.playSound(root.clickSound)
                root.bubbleVisible = true
                bubbleIdleTimer.restart()
                if (root.inputOpen) {
                    root.inputOpen = false
                    root.panelItem.inputField.text = ""
                } else {
                    root.inputOpen = true
                    Qt.callLater(function () { root.panelItem.inputField.forceActiveFocus() })
                }
                return
            }
            if (root.dragging)
                root.endDrag()
        }

        onPositionChanged: function (mouse) {
            if (!root.pressArmed || root.dragging || moved)
                return
            var dx = mouse.x - root.pressLocalX
            var dy = mouse.y - root.pressLocalY
            if (dx * dx + dy * dy > 9) {
                // The pointer has really travelled, so this is a drag.
                moved = true
                root.beginDrag()
            }
        }
    }

    // ---- the hop ---------------------------------------------------------
    SequentialAnimation {
        id: hopSeq
        NumberAnimation {
            target: root; property: "hop"
            from: 0; to: -17; duration: 190
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root; property: "hop"
            from: -17; to: 0; duration: 300
            easing.type: Easing.InQuad
        }
    }

    ParallelAnimation {
        id: hopSquash
        NumberAnimation {
            target: root; property: "squash"
            from: 1; to: 1.1; duration: 190
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root; property: "squash"
            from: 1.1; to: 1; duration: 300
            easing.type: Easing.InQuad
        }
    }

    function hopNow() {
        hopSeq.stop()
        hopSquash.stop()
        squash = 1
        hopSeq.start()
        hopSquash.start()
    }

    // ---- the side flip ---------------------------------------------------
    NumberAnimation {
        id: flipAnim
        target: root
        property: "flip"
        duration: 160
        easing.type: Easing.OutCubic
    }

    onFlipTargetChanged: {
        flipAnim.from = flip
        flipAnim.to = flipTarget
        flipAnim.restart()
    }

    // ---- helpers ----------------------------------------------------------
    function applyTheme(content) {
        var text = String(content || "")
        var pick = function (key, fallback) {
            var match = text.match(new RegExp("^" + key + "\\s*=\\s*\"(#[0-9a-fA-F]{3,8})\"", "m"))
            return match ? match[1] : fallback
        }
        accent = pick("accent", accent)
        bgColor = pick("background", bgColor)
        fgColor = pick("foreground", fgColor)
        mutedColor = pick("muted", mutedColor)
        selectionColor = pick("selection", selectionColor)
    }

    // Work out which artwork to use: character.png is the base, and
    // character-<mood>.png gives that mood its own face.
    function applyArtwork(listing) {
        var base = ""
        var moods = {}
        var lines = String(listing || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
            var path = lines[i].trim()
            if (path === "")
                continue
            // The listing has full paths in it; only the file name matters.
            var name = path.split("/").pop()
            var stem = name.replace(/\.[^.]+$/, "")
            if (stem === "character") {
                base = path
            } else if (stem.indexOf("character-") === 0) {
                moods[stem.substring("character-".length).toLowerCase()] = path
            }
        }
        customMoods = moods
        customCharacter = base
    }

    // The artwork for the mood she is in, falling back to the base.
    function artworkFor(mood) {
        var specific = customMoods[mood]
        return specific || customCharacter
    }

    // Which file is on screen right now ("" means the drawn chibi).
    readonly property string currentArt: artworkFor(mood)

    function applyConfig(content) {
        var text = String(content || "").trim()
        if (text === "")
            return
        try {
            var config = JSON.parse(text)
            if (typeof config.voice === "boolean")
                voiceEnabled = config.voice
            if (typeof config.typeSpeed === "number")
                charInterval = Math.max(10, config.typeSpeed)
            if (typeof config.voiceRate === "number")
                voiceRate = Math.max(3, config.voiceRate)
            if (typeof config.voicePitch === "number")
                voicePitch = Math.max(0.4, config.voicePitch)
            if (typeof config.voiceBase === "string")
                voiceBase = config.voiceBase
            if (typeof config.clickSound === "string" && config.clickSound.trim() !== "")
                clickSound = config.clickSound.trim()
            // seconds of quiet before the bubble drifts away
            if (typeof config.bubbleIdle === "number")
                bubbleIdle = Math.max(3, config.bubbleIdle) * 1000
        } catch (err) {
            // ignore a malformed config file
        }
    }

    function applyPosition(content) {
        var text = String(content || "").trim()
        if (text === "") {
            // First run: park her in the bottom right, clear of the bar.
            root.charX = root.screenW - root.charWidth - 160
            root.charBottom = root.screenH - 24
            root.monitorName = targetScreen ? targetScreen.name : ""
            root.savePosition()
            return
        }
        try {
            var state = JSON.parse(text)
            if (state.version === 2) {
                if (typeof state.x === "number") charX = state.x
            } else {
                // v1 stored the panel's left edge; v2 stores the character.
                if (typeof state.x === "number")
                    charX = state.x + (state.right ? (root.panelWidth - root.charWidth) : 0)
            }
            if (typeof state.y === "number") charBottom = root.screenH - state.y
            if (typeof state.right === "boolean") {
                flipTarget = state.right ? 1 : 0
                flip = flipTarget
            }
            if (typeof state.monitor === "string" && state.monitor !== monitorName)
                monitorName = state.monitor
            if (state.version !== 2)
                root.savePosition()
        } catch (err) {
            // ignore a malformed state file
        }
    }

    function savePosition() {
        posProc.command = ["oc-companion", "position",
                           String(Math.round(charX)),
                           String(Math.round(screenH - charBottom)),
                           flipTarget >= 0.5 ? "right" : "left",
                           targetScreen ? targetScreen.name : ""]
        posProc.running = true
    }

    // The character and the bubble both have to stay on screen. The bubble
    // hangs off the opposite end of the panel, so the character's travel
    // depends on which side it is on.
    function clampPosition(x, bottom) {
        var side = flipTarget >= 0.5 ? (panelWidth - charWidth) : 0
        var margin = 4
        var minX = side + margin
        var maxX = screenW - panelWidth + side - margin
        charX = Math.max(minX, Math.min(maxX, x))
        // charBottom is the y of the character's lower edge, measured from the
        // top of the screen. She may sit right on the bottom edge; the bubble
        // gives way instead.
        charBottom = Math.max(charHeight + margin, Math.min(screenH - margin, bottom))
    }

    function beginDrag() {
        dragging = true
    }

    function endDrag() {
        dragging = false
        pressArmed = false
        cursorProc.running = false
        savePosition()
    }

    // New cursor position from hyprctl, in screen coordinates.
    function onCursor(buffer) {
        cursorBuf += String(buffer || "")
        var index
        while ((index = cursorBuf.indexOf("\n")) !== -1) {
            var line = cursorBuf.substring(0, index)
            cursorBuf = cursorBuf.substring(index + 1)
            handleCursorLine(line)
        }
    }

    function handleCursorLine(line) {
        line = String(line || "").trim()
        if (line === "")
            return
        var parts = line.split(",")
        var cx = parseFloat(parts[0])
        var cy = parseFloat(parts[1])
        if (isNaN(cx) || isNaN(cy))
            return

        var lx = cx - monitorX
        var ly = cy - monitorY
        lastCursorX = lx
        lastCursorY = ly

        if (!dragging)
            return

        // Put her so that the point the pointer grabbed is still under it.
        // The grab point is measured in her own coordinates, so this is exact
        // whichever part of her you took hold of.
        var topLeftX = lx - grabLocalX
        var topLeftY = ly - grabLocalY

        // Which side of the screen are we on? That decides which way the
        // bubble opens.
        flipTarget = lx > screenW / 2 ? 1 : 0
        clampPosition(topLeftX, topLeftY + charHeight)
    }

    // ---- text and voice ---------------------------------------------------
    Timer {
        id: moodTimer
        interval: 4000
        onTriggered: root.mood = "idle"
    }

    function setMood(value, ms) {
        // Any mood is allowed. If you drew character-<mood>.png she wears it;
        // otherwise she falls back to her base art, and with no art at all she
        // keeps her drawn face. So a mood you invented needs no code.
        var name = String(value || "").trim().toLowerCase()
        if (!/^[a-z0-9_-]+$/.test(name))
            return
        mood = name
        moodTimer.interval = ms || 4000
        moodTimer.restart()
    }

    function playSound(name) {
        if (!sfxEnabled)
            return
        sfxProc.command = ["oc-voice", "--sfx", name]
        sfxProc.running = true
    }

    // The agent can say how it feels, in a tag that never reaches the screen.
    function parseDirectives(text) {
        var clean = String(text || "")
        var mood = null
        var action = null

        var moodMatch = clean.match(/\[mood:\s*([a-z0-9_-]+)\]/i)
        if (moodMatch) {
            mood = moodMatch[1].toLowerCase()
            clean = clean.replace(moodMatch[0], "")
        }
        var actionMatch = clean.match(/\[action:\s*([a-z]+)\]/i)
        if (actionMatch) {
            action = actionMatch[1].toLowerCase()
            clean = clean.replace(actionMatch[0], "")
        }

        // Without a tag, guess from the tone of the reply.
        if (!mood) {
            var lower = clean.toLowerCase()
            if (lower.indexOf("❤") !== -1 || lower.indexOf("♥") !== -1)
                mood = "love"
            else if (lower.indexOf("haha") !== -1 || lower.indexOf("lol") !== -1
                     || lower.indexOf("happy") !== -1)
                mood = "happy"
            else if (lower.indexOf("oh no") !== -1 || lower.indexOf("sad") !== -1
                     || lower.indexOf("sorry") !== -1)
                mood = "sad"
            else if (clean.indexOf("!") !== -1)
                mood = "surprised"
        }

        return { mood: mood, action: action, text: clean.trim() }
    }

    function runAction(action) {
        if (!action)
            return
        if (action === "jump" || action === "bounce")
            root.hopNow()
        else if (action === "happy" || action === "cheer")
            root.setMood("happy", 3000)
        else if (action === "love")
            root.setMood("love", 3000)
    }

    Timer {
        id: answerTimer
        interval: 900
        onTriggered: {
            if (root.pendingAnswer !== "") {
                root.say(root.pendingAnswer)
                root.pendingAnswer = ""
            }
        }
    }

    function say(text) {
        bubbleVisible = true
        bubbleIdleTimer.restart()
        replyText = String(text || "")
        shownChars = 0
        startVoice()
        typer.interval = voiceEnabled ? charInterval : 22
        typer.restart()
    }

    function revealNext() {
        if (shownChars >= replyText.length) {
            typer.stop()
            // The text is fully typed, so the speech stops with it: anything
            // still queued would be talking over the end of the sentence.
            stopSpeech()
            // She has finished talking: let the microphone back in.
            micProc.command = ["agentvoice", "unlock"]
            micProc.running = true
            return
        }
        shownChars += 1
        if (voiceEnabled && root.shown) {
            var ch = replyText.charAt(shownChars - 1)
            if (ch.trim() !== "")
                speakChunk(ch)
        }
    }

    function startVoice() {
        if (!voiceEnabled || !root.shown)
            return
        // Close the microphone for as long as she is talking.
        micProc.command = ["agentvoice", "lock"]
        micProc.running = true
        micLockTimer.restart()
        if (!voiceProc.running) {
            voiceProc.running = true
            voiceReady = false
            voicePending = []
            // Give the process a moment to attach its pipes.
            voiceReadyTimer.restart()
        }
    }

    // Stop the speech but leave the typing alone.
    function stopSpeech() {
        voicePending = []
        if (voiceProc.running)
            voiceProc.running = false
    }

    // Stop both.
    function stopVoice() {
        typer.stop()
        stopSpeech()
        micLockTimer.stop()
        micProc.command = ["agentvoice", "unlock"]
        micProc.running = true
    }

    Timer {
        id: voiceReadyTimer
        interval: 120
        onTriggered: root.flushVoice()
    }

    property bool voiceReady: false
    property var voicePending: []

    function flushVoice() {
        voiceReady = true
        for (var i = 0; i < voicePending.length; i++)
            voiceProc.write(voicePending[i] + "\n")
        voicePending = []
    }

    function speakChunk(chunk) {
        if (!voiceProc.running) {
            voiceProc.running = true
            voiceReady = false
            voicePending = []
            voiceReadyTimer.restart()
            voicePending.push(chunk)
            return
        }
        if (!voiceReady) {
            voicePending.push(chunk)
            return
        }
        voiceProc.write(chunk + "\n")
    }

    function toggleVoice() {
        voiceCfgProc.command = ["oc-companion", "voice", "toggle"]
        voiceCfgProc.running = true
        configProc.running = true
    }

    function openSettings() {
        Quickshell.execDetached(["omarchy-launch-editor", root.home + "/.config/oc-companion/config.json"])
    }

    function showError(message) {
        lastError = message
        replyText = "⚠ " + message
        shownChars = replyText.length
        busy = false
        typer.stop()
    }

    function sendText(text) {
        bubbleVisible = true
        bubbleIdleTimer.restart()
        var message = String(text || "").trim()
        if ((message === "" && pendingImage === "") || busy)
            return
        root.panelItem.inputField.text = ""
        root.inputOpen = false
        root.pendingPrompt = message
        root.consumed = 0
        root.lastError = ""
        root.permission = null
        root.replyText = ""
        root.shownChars = 0
        root.busy = true
        root.shown = true
        // A picture rides along with the message, so you can say what is
        // about it before or after attaching it.
        var command = ["oc-ask", "--jsonl"]
        if (root.pendingImage !== "")
            command = command.concat(["--attach", root.pendingImage])
        askProc.command = command.concat([message])
        root.pendingImage = ""
        askProc.running = true
    }

    function copyReply() {
        if (replyText === "")
            return
        // Qt's own clipboard path: wl-copy would need its stdin closed, which
        // Quickshell's Process cannot do.
        clipboard.text = replyText
        clipboard.selectAll()
        clipboard.copy()
    }

    // Parse the JSONL stream coming back from oc-ask.
    function consume(buffer) {
        var text = String(buffer || "")
        if (text.length <= consumed)
            return
        var chunk = text.substring(consumed)
        var lines = chunk.split("\n")
        var tail = lines.pop()
        consumed = text.length - tail.length
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line === "")
                continue
            var event
            try {
                event = JSON.parse(line)
            } catch (err) {
                continue
            }
            handleEvent(event)
        }
    }

    function handleEvent(event) {
        if (event.type === "status") {
            busy = true
        } else if (event.type === "reply") {
            busy = false
            var parsed = root.parseDirectives(event.text || "")
            if (parsed.mood)
                root.setMood(parsed.mood, 6000)
            root.runAction(parsed.action)
            if (root.shown) {
                say(parsed.text)
            } else {
                // Stay quiet while hidden; the answer waits for the next show.
                replyText = parsed.text
                shownChars = 0
                pendingReveal = true
            }
        } else if (event.type === "permission") {
            permission = event
        } else if (event.type === "error") {
            showError(event.message || "something went wrong")
        }
    }

    // Off-screen text area used purely as a clipboard helper.
    TextEdit {
        id: clipboard
        visible: false
        width: 0
        height: 0
    }

    Component.onCompleted: {
        themeProc.running = true
        charProc.running = true
        configProc.running = true
        say("Hi! Click me and say something.  (Esc closes the box.)")
    }
}
