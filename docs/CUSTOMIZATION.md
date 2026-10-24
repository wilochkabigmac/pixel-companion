# Pixel — the opencode desktop companion

A little character who lives on your screen and talks to the same opencode
server your terminal and web UI use.

She is a **thin client**. All the intelligence is opencode's own server
(`opencode serve --service`, the one already running on this machine); the
widget just talks to its HTTP API and draws what comes back.

```
~/.config/quickshell/companion/
  shell.qml        the layer-shell panel: input box, plumbing, moods, drag
  Character.qml    the drawn chibi and her faces
  Particles.qml    the emoji that burst out of her
  Bubble.qml       the speech bubble, typewriter, permission buttons
  README.md        this file
  character*.png   optional artwork (you add these, nobody needs them)
```

Everything else lives in `~/.config/oc-companion/` (config, voice samples,
saved position) and `~/.local/bin/` (the helper commands).

---

## Using her

| | |
| --- | --- |
| click the character | open the input box; she hops and clicks |
| drag the character | move her anywhere; the point you grabbed stays under the cursor |
| right click her | menu: ask, new chat, copy reply, mute, settings, hide, quit |
| `SUPER + ALT + C` | summon the assistant |
| `SUPER + ALT + A` | ask about the current selection |
| `SUPER + ALT + I` | attach a picture to your next message |
| `F8` (hold) | push to talk — agentvoice listens, she answers out loud |
| "hey pixel" | the same, hands free |
| Omarchy menu | Trigger → Assistant AI |
| tray icon | the little head in the tray drawer: left click summons, right click opens the menu |

The bubble drifts away after a stretch of quiet and comes back when you tap
her. She stays on the monitor you put her on instead of chasing focus, and
the bubble always has room: she slides to the other end of the panel when
space runs out.

---

## Customising her — cheat sheet

| I want to… | do this |
| --- | --- |
| change her personality | edit `persona` in `~/.config/oc-companion/config.json` |
| use my own artwork | drop `character.png` into `~/.config/quickshell/companion/` |
| give a mood its own art | add `character-love.png`, `character-happy.png`, … |
| invent an expression | `character-angry.png`, then `[mood:angry]` — see *Expressions of your own* |
| preview an expression | `oc-companion mood angry` |
| change the tap sound | drop `click.wav` into `~/.config/oc-companion/sfx/` |
| make her bigger | `charWidth`/`charHeight` (and `panelWidth`) in `shell.qml` — see *Size and place* |
| change her voice | `voiceBase`, `voiceRate`, `voicePitch` in the config |
| use real samples instead of the synth | WAVs in `~/.config/oc-companion/voice/` |
| talk slower / faster | `typeSpeed` (ms per character) in the config |
| keep the bubble longer | `bubbleIdle` (seconds) in the config |
| change the emoji she throws | `emojiFor` in `Particles.qml` |
| change her hotkeys | `~/.config/hypr/bindings.lua` |
| change the tray menu | `MENU_ITEMS` in `~/.local/bin/oc-tray` |
| start a fresh conversation | tray menu → New conversation, or `oc-ask --reset` |

Details for each of those are below.

---

## The config file

`~/.config/oc-companion/config.json` (the tray's *Settings* item opens it).

| key | meaning | default |
| --- | --- | --- |
| `persona` | who she is; written into her session as an instruction | the built-in text |
| `agent` | which opencode agent answers (display name or id) | `Build` |
| `server` | `shared` reuses the opencode server you already run; `dedicated` starts a private one | `shared` |
| `directory` | the workspace the agent works in | `~/.local/state/oc-companion/workspace` |
| `model` | optional `provider/model` override | the agent's own |
| `timeout` | seconds to wait for a reply | `300` |
| `voice` | `false` mutes her (the menu has Mute/Unmute too) | `true` |
| `voiceRate` | syllables per second | `15` |
| `voicePitch` | multiplier on the pitch | `1.0` |
| `voiceBase` | `bright`, `soft`, `deep`, `chip`, `robot` | `bright` |
| `clickSound` | which sound effect plays when you tap her (a name from `sfx/`, or a built-in) | `click` |
| `typeSpeed` | milliseconds per character while she types | `65` |
| `bubbleIdle` | seconds of quiet before the bubble fades | `25` |
| `visionModel` | the model that can see, used for pictures | `opencode/nemotron-3.5-super-vl-free` |

**When changes apply.** `persona`, `agent`, `model`, `visionModel`,
`timeout` and `directory` are read fresh for every message, so editing them
takes effect on her next reply. The look-and-feel keys (`voice*`,
`clickSound`, `typeSpeed`, `bubbleIdle`, `voice`) and new artwork are applied
whenever you ask her to re-read them:

```sh
oc-companion reload
```

A full restart (`oc-companion stop && oc-companion start`) is only needed
after editing the `.qml` files themselves.

A malformed JSON file is ignored as a whole (she keeps the previous values),
so keep it valid — trailing commas are the usual culprit.

---

## Who she is

The `persona` string is sent to her opencode session as an instruction
before every message. It is where her character, her capabilities and her
hotkeys are described:

```json
{
  "persona": "You are Pixel, a small character who lives in the corner of the user's desktop. ..."
}
```

What is worth keeping in it:

- **tone** — short, conversational, warm, speaks your language.
- **what she can do** — the helper commands below, so she does not invent
  tools she does not have.
- **her hotkeys** — so "what is your shortcut?" has an answer.
- **the mood tags** — otherwise she stops wearing expressions.

### Moods and actions

She shows feelings in three ways: her face, emoji particles, and little
movements. The agent drives all of it with tags that are stripped before the
text reaches the bubble.

```
[mood:happy] That is genuinely good news.
[mood:love] You are welcome.
[action:jump] Look what I found.
```

| mood | face | emoji |
| --- | --- | --- |
| `idle` | neutral, blinking | none |
| `talking` | mouth moves with the typewriter | 💬 |
| `happy` | closed-arc eyes, big grin | ✨ 🎉 😄 ⭐ 🌟 🎊 😃 💫 |
| `love` | heart eyes, blush | 💖 💕 💗 🥰 💘 💝 💞 🫶 |
| `sad` | droopy eyes, a tear | 💧 😢 🥺 💔 😞 💦 🌧️ ☁️ |
| `surprised` | wide eyes, round mouth | ❗ 😮 💫 ❓ ❕ 😲 |
| `thinking` | half-lidded eyes | 💭 🤔 💡 🧠 ❔ |

Actions: `jump` (and `bounce`) hop; `cheer` and `happy` switch her to the
happy mood for a moment; `love` does the same for love.

If the reply has no tag she guesses from the tone: a ❤ means love, "haha" /
"lol" / "happy" means happy, "oh no" / "sorry" means sad, and an exclamation
mark means surprised. She also returns to `idle` on her own after a few
seconds.

Those seven are just the ones she ships with. Any name you have artwork for
works as a mood too — see *Expressions of your own*.

To change what a mood looks like, edit `Character.qml`; to change the emoji,
edit `Particles.qml`. To try one out immediately:

```sh
oc-companion mood happy
oc-companion mood angry      # any expression name
```

---

## How she looks

### Your own artwork

Drop files next to `shell.qml` in `~/.config/quickshell/companion/`:

```
character.png            the base art
character-happy.png      the art for a mood
character-love.png
character-sad.png
character-surprised.png
character-thinking.png
character-talking.png
character-idle.png
```

- `.png`, `.gif` (animated, loops) and `.webp` all work. If you keep several
  files with different extensions for the same name, the last one in
  alphabetical order wins (`.webp` over `.png` over `.gif`).
- Each mood looks for `character-<mood>.<ext>` first and falls back to
  `character.<ext>` when you have not drawn that one.
- The art is drawn in a 132 × 168 box, scaled to fit, anchored at the bottom
  and clipped — so keep roughly a 3:4 portrait shape and leave a little air
  around the edges.
- She still blinks, hops, squashes, throws emoji and fades in and out; only
  the body comes from the file.
- The names are matched **exactly**: `character-happy.png` works,
  `character_happy.png` does not.
- Delete the files and the drawn chibi comes back. There is nothing else to
  undo. Run `oc-companion reload` and the new set is live — no restart.

### Expressions of your own

The list above is only the set she ships with. Any name works:

```sh
cd ~/.config/quickshell/companion
cp character.png character-angry.png      # then draw over it
oc-companion reload
oc-companion mood angry                   # see it
```

That is the whole recipe. `[mood:angry]` now puts her in that face, and
`oc-companion mood angry` previews it for six seconds so you can check your
drawing without waiting for the right moment. Names may use letters, digits,
`-` and `_`; they are lower-cased for you.

She also learns about them: whenever `oc-ask` sends a message it scans this
folder and adds a line to her instruction telling her which extra expressions
she owns, so she will reach for `[mood:angry]` herself. No persona edit needed.

What a custom expression inherits:

- **Art** — `character-angry.png`; if that file is gone she uses
  `character.png`, and with no art at all she shows the drawn chibi.
- **Emoji** — add an entry to `emojiFor` in `Particles.qml` to give it a
  burst. Until then it throws `fallbackEmoji` (`✨💫`), which you can set to
  `[]` for a quiet expression.
- **The drawn chibi** only has faces for the built-in moods; an invented mood
  with no art gets her neutral face.
- **Timing** — moods set by a tag last six seconds, then she goes back to
  `idle`.

### The drawn chibi

`Character.qml` draws her from ellipses. Her colour comes from the accent of
the current Omarchy theme
(`~/.local/state/omarchy/current/theme/colors.toml`, also used for the panel
background, the bubble and the selection), so she follows a theme switch
without editing anything.

If you want her in a fixed colour regardless of theme, give `accentColor` a
literal in `shell.qml`:

```qml
accentColor: root.accent        // theme — the default
accentColor: "#f38d70"          // always this
```

### Size and place

`shell.qml` has the geometry at the top:

```qml
property int panelWidth: 330    // the whole panel
property int charWidth: 132     // she is drawn in this box
property int charHeight: 168
```

She can be made larger, but the panel is a fixed layer surface — growing the
character (and the bubble) means growing `panelWidth` too. Do **not** try to
resize the surface after it is mapped; the compositor drops it. If a bigger
character is what you want, raise `panelWidth`, `charWidth` and
`charHeight` together and restart.

Her position is remembered in `~/.local/state/oc-companion/position.json`
and restored per monitor. It can be set from the shell as well:

```sh
oc-companion position 1600 1040 left DP-1
oc-companion position 760 940 right DP-1     # bubble on the other side
```

---

## Particles

`Particles.qml` decides what flies out of her. The emoji are a plain map:

```qml
property var emojiFor: ({
    "happy": ["✨", "🎉", "😄", "⭐", "🌟", "🎊", "😃", "💫"],
    "love":  ["💖", "💕", "💗", "🥰", "💘", "💝", "💞", "🫶"],
    ...
})
```

and the burst itself is tuned by three numbers:

| property | meaning | default |
| --- | --- | --- |
| `poolSize` | how many particles exist at once | `18` |
| `burstSize` | how many she throws per mood change | `9` |
| `stagger` | milliseconds between them | `65` |

Add symbols you like, or make a mood throw none by giving it an empty list.
The mood must exist in the map or nothing happens.

---

## Her voice

Not text-to-speech: `oc-voice` is a small formant synth. Each syllable is a
glottal pulse train pushed through two vowel formants, pitched along a
pentatonic melody, and the widget feeds it characters as the typewriter
reveals them — so the blips follow the text and stop when the typing stops.
A sentence comes out as "a-a-a-a".

| setting | what it does |
| --- | --- |
| `voice` | `false` silences her completely |
| `voiceBase` | the timbre |
| `voiceRate` | syllables per second (higher = faster, choppier) |
| `voicePitch` | multiplier on the base pitch |
| `typeSpeed` | ms per character; also the speed of the blips |

The presets:

| preset | character |
| --- | --- |
| `bright` | the default: 305 Hz, clear |
| `soft` | higher and breathy |
| `deep` | lower, larger |
| `chip` | very high, 8-bit |
| `robot` | flat, mechanical formants |

```json
{
  "voice": true,
  "voiceBase": "soft",
  "voiceRate": 12,
  "voicePitch": 1.15,
  "typeSpeed": 55
}
```

Muting is also on the right-click menu, and it writes `voice` back to the
config so the choice survives a restart.

### Your own samples

Put 16-bit 48 kHz mono WAVs in `~/.config/oc-companion/voice/`:

- **`a.wav`, `b.wav`, `c.wav` …** are played for that letter, every time it
  appears. One file per sound you actually use is enough — she only picks
  samples for letters that have one.
- **any other name** (`squeak.wav`, `blip2.wav`) becomes a pool, picked at
  random for the letters that have no file of their own.

When a letter has a sample, the sample replaces the synth for that letter;
everything else keeps singing. Delete the folder and she is synthetic again.

### Sound effects

Short tones that are not speech, used for taps and reactions:

```sh
oc-voice --sfx click        # click | happy | love | sad | surprised | thinking
oc-voice "hello there"      # say a line in her voice, e.g. from a script
```

They are synthesised, but you can replace any of them with a file of your
own. Put it in `~/.config/oc-companion/sfx/` and name it after the effect:

```
~/.config/oc-companion/sfx/click.wav      replaces the tap sound
~/.config/oc-companion/sfx/happy.mp3      replaces the happy sound
~/.config/oc-companion/sfx/love.ogg
```

`.wav`, `.ogg`, `.flac` and `.mp3` all work and need no conversion — the
file is played as-is through `pw-play`. Missing effects keep their synth
tone, so you can replace just the one you care about. Keep them short
(under a second is plenty) or the tap will lag behind the hop.

To use a different effect for taps without renaming anything, point
`clickSound` at another name:

```json
{ "clickSound": "pop" }
```

That plays `sfx/pop.wav` if it exists, otherwise the built-in sound of that
name. Apply it with `oc-companion reload`.

`oc-voice --sfx <name>` uses the same folder, so your files also work from
scripts and hotkeys.

---

## Timing and manners

| behaviour | where | default |
| --- | --- | --- |
| bubble fades | `bubbleIdle` (config, seconds) | `25` |
| hop on click | `hopNow()` in `shell.qml` | — |
| typewriter | `typeSpeed` (config, ms) | `65` |
| drag | `CompanionDrag` in `shell.qml` | — |

The bubble comes back on a tap, on summon, and whenever there is something
new to say. While the input box is open or she is thinking, it will not fade.

Dragging keeps the point you grabbed under the cursor rather than snapping
her centre to it, and a plain click never turns into a drag — a click just
hops her and plays the click sound.

---

## Her brain

opencode does the thinking; these keys decide which part of it answers.

| key | use it when |
| --- | --- |
| `agent` | you want a different opencode agent (e.g. a read-only one) |
| `model` | pin a specific `provider/model` for her |
| `visionModel` | the model used for the turn when a picture is attached |
| `timeout` | long tool runs need a bigger number |
| `directory` | she should work in a particular project instead of the scratch workspace |
| `server` | `dedicated` keeps a TUI from attaching to her session |

### Pictures

`SUPER + ALT + I` grabs the clipboard image, or a screenshot when the
clipboard has none. It waits in the input box as a thumbnail so you can type
— or speak — what you want to know about it. Not every model can see: when
an image is attached the session is pointed at `visionModel` for that turn
and then put back. Without a `visionModel` the picture is still delivered,
but a text-only model will tell you it cannot see it.

### Sessions

She keeps one conversation in `~/.local/state/oc-companion/session.json`, so
she remembers what you said. The tray menu's *New conversation* (or
`oc-ask --reset`) starts over.

Because a `shared` server is the same one your TUI uses, opencode may resume
her session in a terminal too — handy, but you would be sharing one
conversation. `"server": "dedicated"` avoids that at the cost of a second
copy of the MCP servers.

---

## Hotkeys

They are ordinary Hyprland bindings in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + ALT + C", "Assistant AI", "oc-companion show")
o.bind("SUPER + ALT + A", "Ask AI about selection", "oc-quick")
o.bind("SUPER + ALT + I", "Attach a picture to the assistant", "oc-companion attach")
```

Change the key, or point it at another helper, and run `hyprctl reload`.

`oc-companion` itself understands:

```sh
oc-companion            # toggle
oc-companion start|stop|status
oc-companion show       # bring her up        (hide: send her away)
oc-companion reload     # re-read config.json and the artwork
oc-companion mood happy # preview an expression
oc-companion ask "..."  # put words in her mouth
oc-companion result "..."   # show a result in the bubble
oc-companion voice toggle   # mute / unmute
oc-companion attach     # start the picture flow
oc-companion position X Y left|right MONITOR
```

---

## The tray icon

`oc-tray` registers a StatusNotifierItem with a real DBusMenu, so the icon
sits in the tray drawer with everything else and the host draws its menu in
the right place.

- **The icon** is `~/.local/share/icons/hicolor/128x128/apps/oc-companion.png`.
  Draw your own over it — a square PNG — and refresh the caches:
  `gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor` (some hosts pick
  it up without that). `oc-tray --icon` regenerates the default head.
- **The menu** is the `MENU_ITEMS` list near the top of `~/.local/bin/oc-tray`:

  ```python
  MENU_ITEMS = [
      (1, "Ask something...", "summon"),
      (2, "New conversation", "reset"),
      (3, "Copy last reply", "copy"),
      (4, "Hide companion", "dismiss"),
      (5, "Settings", "settings"),
  ]
  ```

  The third field is the function called on the widget: `summon`, `dismiss`,
  `copy`, `toggle`, `poke`, `menu` — anything the `companion` IPC target
  offers. `reset` and `settings` are handled by the tray itself (`reset`
  starts a new conversation, `settings` opens the config). Restart the tray
  to apply: `oc-companion stop && oc-companion start`.

The tray starts with the companion (from `~/.config/hypr/autostart.lua`), and
waits for the bar if it is not up yet — so a slow login no longer loses it.

---

## Hooking her into the rest of the machine

These exist so she can answer questions about your desktop rather than guess:

```sh
oc-now-playing            # what is playing (MPRIS: any player)
oc-now-playing --json
oc-steam list             # the Steam games installed here
oc-steam play <name>      # start one
oc-attach                 # the picture grabber behind SUPER + ALT + I
```

They are listed in her persona, which is what lets her use them without being
told each time. Add your own helper, mention it in the persona, and she will
reach for it.

---

## Her ears (agentvoice)

agentvoice does the listening. It is pointed at `oc-voice-bridge`, a tiny
local endpoint that hands what you said to her opencode session and streams
the answer back in the shape agentvoice expects. agentvoice's own TTS is off,
so there is only one voice.

```sh
omarchy bar set duaneoca.agentvoice endpointUrl ""    # stop routing to her
omarchy bar set duaneoca.agentvoice phrase "hey pixel"
omarchy bar set duaneoca.agentvoice model small       # multilingual whisper
```

Two different models are involved:

- **Your speech** is transcribed by faster-whisper, which is multilingual. The
  dropdown's `tiny.en`, `base.en`, `small.en` are English-only; drop the `.en`
  for the multilingual model (about ninety languages, slower on CPU, first run
  downloads a few hundred MB).
- **The wake phrase** is matched by Vosk with `vosk-model-small-en-us`, which
  only knows English. In another language, hold **F8** instead — that path
  skips the wake word. To get a wake phrase in another language, drop a Vosk
  model into `~/.local/share/agentvoice/models/vosk-model-<name>`.

---

## Command reference

```sh
oc-ask "what is up"          # send a message, print the reply
oc-ask --jsonl "..."         # stream events (the widget uses this)
oc-ask --session             # the current session id
oc-ask --reset               # start a fresh conversation
oc-ask --attach <file> "..." # send a picture with the message
oc-ask --permissions         # pending permission requests
oc-ask --reply <id> once     # answer one

oc-quick                     # selection -> AI -> clipboard
oc-quick translate to russian
oc-quick --task "fix the grammar"

oc-voice "hello there"       # speak (no TTS)
oc-voice --stream            # speak each line as it arrives on stdin
oc-voice --rate 14 --pitch 1.2 --base soft
oc-voice --sfx click         # click | happy | love | sad | surprised | thinking

oc-attach                    # clipboard image, or a screenshot
oc-now-playing               # what is playing
oc-steam list|play <name>

oc-companion                 # toggle the widget
oc-companion start|stop|status
oc-companion show|hide
oc-companion reload          # re-read config.json and the artwork
oc-companion mood happy      # preview an expression for six seconds
oc-companion ask "..."       # make the widget say something
oc-companion result "..."    # show a result in the bubble
oc-companion voice toggle
oc-companion attach
oc-companion position X Y left|right MONITOR

oc-tray                      # the tray icon (started for you)
oc-tray --icon               # regenerate the default icon
oc-voice-bridge              # the endpoint agentvoice talks to
```

---

## Files at a glance

| path | what it is |
| --- | --- |
| `~/.config/oc-companion/config.json` | persona, voice, models, timing |
| `~/.config/oc-companion/voice/` | your WAV samples (optional) |
| `~/.config/oc-companion/sfx/` | your sound effects (optional) |
| `~/.config/quickshell/companion/shell.qml` | the widget |
| `~/.config/quickshell/companion/Character.qml` | the drawn chibi |
| `~/.config/quickshell/companion/Particles.qml` | the emoji |
| `~/.config/quickshell/companion/Bubble.qml` | the bubble |
| `~/.config/quickshell/companion/character*.png` | your artwork (optional) |
| `~/.local/state/oc-companion/position.json` | where she sits |
| `~/.local/state/oc-companion/session.json` | her conversation id |
| `~/.local/state/oc-companion/server.json` | the opencode server it found |
| `~/.local/state/oc-companion/workspace/` | her default working directory |
| `~/.local/share/icons/hicolor/128x128/apps/oc-companion.png` | the tray icon |
| `~/.local/bin/oc-*` | the helper commands |

---

## Troubleshooting

**She is not there.**
`oc-companion status` then `oc-companion start`. Look at the log Quickshell
writes under `/run/user/1000/quickshell/by-id/*/log.qslog` — QML errors
appear there, and a QML error usually shows an empty panel.

**The tray icon is missing.**
The icon is started by `oc-companion start`, and waits for the bar; check the
watcher with
`gdbus call --session --dest org.kde.StatusNotifierWatcher --object-path /StatusNotifierWatcher --method org.freedesktop.DBus.Properties.Get org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems`.

**The tray menu is empty or does nothing.**
The host reads the menu through `com.canonical.dbusmenu` (the libdbusmenu
name) — `oc-tray` exports both that and `org.freedesktop.DBusMenu`. If a menu
stops working after an edit, restart the tray and check that
`gdbus introspect --session --dest <the name oc-tray printed> --object-path /MenuBar`
lists both interfaces.

**My artwork is ignored.**
The base file must be exactly `character.<ext>` and moods exactly
`character-<mood>.<ext>` — an underscore or a capital letter will not match.
Run `oc-companion reload` after copying files in.

**My custom expression does nothing.**
Check the name with `oc-companion mood <name>`; if she stays the chibi, the
file is not being seen. Run `oc-companion reload` and look for
`character-<name>.png` in `~/.config/quickshell/companion/`. A mood with no
art falls back to `character.png`, and with no art at all to the drawn chibi —
so remove the base file while testing if you want to be sure.

**My tap sound does not play.**
It must be `~/.config/oc-companion/sfx/click.wav` (or `.ogg`, `.flac`,
`.mp3`). Check it directly with `oc-voice --sfx click`. If you set
`clickSound` to another name, the file has to match that name.

**She is silent.**
`"voice": false` in the config, or the menu is set to Unmute voice. Voice
settings need `oc-companion reload` to apply.

**She cannot see the picture.**
Set `visionModel` to a model that accepts images. `oc-ask` only swaps the
model for the turn and restores yours afterwards.

**A terminal is talking to her session.**
opencode resumes the most recent session; that is the same conversation.
Switch to `"server": "dedicated"` if you would rather keep them apart.
