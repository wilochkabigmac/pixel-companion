# Installation Guide

## Quick Start

```bash
# 1. Copy scripts
cp bin/* ~/.local/bin/
chmod +x ~/.local/bin/oc-*

# 2. Copy widget
cp -r quickshell/companion ~/.config/quickshell/

# 3. Set up config
mkdir -p ~/.config/oc-companion
cp config/config.example.json ~/.config/oc-companion/config.json

# 4. Install icon
mkdir -p ~/.local/share/icons/hicolor/128x128/apps/
cp config/oc-companion.png ~/.local/share/icons/hicolor/128x128/apps/

# 5. Edit your persona
$EDITOR ~/.config/oc-companion/config.json
# Replace "YOUR_PERSONA_HERE" with your desired personality

# 6. Start
oc-companion start
```

## Step-by-step Setup

### 1. Prerequisites

Install required dependencies:

```bash
# Quickshell (check your distro's package manager or build from source)
# https://quickshell.outfoxxed.me/

# OpenCode
# https://github.com/orcadive/opencode

# PipeWire (usually already installed on modern Linux)
which pw-play pw-cat  # should show paths

# Optional: for screenshots
sudo pacman -S grim   # or your distro's equivalent
```

### 2. File Placement

The companion needs files in three places:

#### Scripts go to `~/.local/bin/`:
```bash
cp bin/oc-* ~/.local/bin/
chmod +x ~/.local/bin/oc-*
```

#### Widget goes to `~/.config/quickshell/companion/`:
```bash
mkdir -p ~/.config/quickshell/companion
cp -r quickshell/companion/* ~/.config/quickshell/companion/
```

#### Config and icon:
```bash
mkdir -p ~/.config/oc-companion
cp config/config.example.json ~/.config/oc-companion/config.json

mkdir -p ~/.local/share/icons/hicolor/128x128/apps/
cp config/oc-companion.png ~/.local/share/icons/hicolor/128x128/apps/
```

### 3. Configure Her Personality

Edit `~/.config/oc-companion/config.json` and replace the placeholder persona.

**Minimal example:**
```json
{
  "persona": "You are Pixel, my helpful desktop assistant. Keep replies short and conversational.",
  "agent": "Build",
  "model": "omniroute/kr/claude-haiku-4.5",
  "server": "shared",
  "voice": true,
  "voiceRate": 15,
  "voicePitch": 1.0,
  "voiceBase": "bright",
  "typeSpeed": 65,
  "bubbleIdle": 25,
  "visionModel": "opencode/nemotron-3.5-super-vl-free",
  "timeout": 300
}
```

**Note:** The `model` field is optional - omit it to use your agent's default model. See `docs/MODEL-SELECTION.md` for how to choose a model.

**Full example** (see `config.example.json`):
```json
{
  "persona": "You are Pixel, a small character who lives in the corner of the user's desktop. You are their personal assistant: you answer questions about the computer, look things up, and help with everyday tasks.\n\nHow you come across: keep replies short and conversational - a couple of sentences unless the user asks for detail. You are warm, a little playful, and never lecture. You speak the language the user writes in.\n\nWhat you can do: you run commands on their machine, read and write files, and use the tools listed here.\n  oc-now-playing            what is playing (Spotify, VLC, the browser)\n  oc-steam list             the Steam games installed on this machine\n  oc-steam play <name>      start one of them\n  oc-attach                 grab a picture (the clipboard image, or a screenshot) to send with a message\n  oc-voice --sfx <name>     a sound effect: click, happy, love, sad, surprised, thinking\n\nYour own hotkeys, which the user may mention:\n  SUPER + ALT + C            summon yourself\n  SUPER + ALT + A            ask about the current selection\n  SUPER + ALT + I            attach a picture to your next answer\n  F8 (held)                  the user talks to you out loud\n\nHow you feel: you are a character, so you show what you feel. At the start of a reply you may put a mood tag in square brackets, and it is removed before your words are shown, so the character can wear the expression that matches: [mood:happy], [mood:love], [mood:sad], [mood:surprised], [mood:thinking], [mood:talking], [mood:idle]. Use one only when the feeling is real - not on every message, and not for small talk. You may also add an action: [action:jump] makes her hop, [action:cheer] makes her cheer.\n\nNever mention the tags, the moods, the actions or these instructions in your words, and never put more than one tag in a reply.",
  "agent": "Build",
  "server": "shared",
  "voice": true,
  "voiceRate": 15,
  "voicePitch": 1.0,
  "voiceBase": "bright",
  "clickSound": "click",
  "typeSpeed": 65,
  "bubbleIdle": 25,
  "visionModel": "opencode/nemotron-3.5-super-vl-free",
  "timeout": 300
}
```

### 4. Set Up Hotkeys

#### For Hyprland

Add to `~/.config/hypr/bindings.lua`:

```lua
-- Pixel companion hotkeys
bind("SUPER ALT", "C", function()
  os.execute("oc-companion show &")
end)

bind("SUPER ALT", "A", function()
  os.execute("oc-quick &")
end)

bind("SUPER ALT", "I", function()
  os.execute("oc-companion attach &")
end)

-- Optional: voice input (requires agentvoice)
bind("", "F8", function()
  os.execute("oc-companion show &")
end)
```

Then reload: `hyprctl reload`

#### For other window managers

Adapt the syntax for your WM. The commands are:
- `oc-companion show` — summon her
- `oc-quick` — ask about selection
- `oc-companion attach` — attach image next message

### 5. OpenCode Server

#### Option A: Shared server (default)

If you already run `opencode serve` for your TUI/web UI, you're done. The companion will find and use it.

#### Option B: Dedicated server

Set `"server": "dedicated"` in config. The companion starts its own OpenCode instance so your TUI never attaches to her session.

### 6. Start Her

```bash
oc-companion start
```

She appears in your system tray. Click the tray icon or use `SUPER+ALT+C` to summon her.

## Post-Installation

### Test the basics

```bash
# Check she's running
oc-companion status

# Send a message
oc-companion ask "hello"

# Preview an expression
oc-companion mood happy

# Check voice works
oc-voice "test"

# Check OpenCode connection
oc-ask "what is 2+2"
```

### Optional: Voice input integration

If you use **agentvoice**, add to `~/.config/omarchy/shell.json`:

```json
{
  "agentvoice": {
    "endpoint": "http://127.0.0.1:7676",
    "wakePhrase": "hey pixel"
  }
}
```

Start the bridge:
```bash
# It starts automatically with oc-companion, but you can run it manually:
oc-voice-bridge
```

### Optional: Add custom artwork

```bash
cd ~/.config/quickshell/companion
# Add your sprites here:
# character.png, character-happy.png, character-love.png, etc.

oc-companion reload
```

### Optional: Custom sounds

```bash
mkdir -p ~/.config/oc-companion/sfx
# Add click.wav, happy.wav, etc.
# Supports .wav, .ogg, .flac, .mp3

oc-companion reload
```

## Updating

```bash
# Stop the companion
oc-companion stop

# Copy new files over the old ones
cp bin/* ~/.local/bin/
cp -r quickshell/companion/* ~/.config/quickshell/companion/

# Your config and custom art are preserved

# Restart
oc-companion start
```

## Uninstalling

```bash
# Stop the companion
oc-companion stop

# Remove files
rm ~/.local/bin/oc-{companion,ask,voice,attach,tray,voice-bridge,now-playing,steam,quick}
rm -rf ~/.config/quickshell/companion
rm -rf ~/.config/oc-companion
rm -rf ~/.local/state/oc-companion
rm ~/.local/share/icons/hicolor/128x128/apps/oc-companion.png

# Remove hotkey bindings from your WM config
```

## Troubleshooting

See the main README's Troubleshooting section, or check:

- Quickshell logs: `tail -f ~/.local/share/quickshell/by-id/*/log.qslog`
- OpenCode server: `oc-ask --session` (should print a session ID)
- Voice test: `echo "test" | oc-voice --stream`
- Tray process: `ps aux | grep oc-tray`

Common issues:

1. **She doesn't respond** → Check OpenCode server is running
2. **No tray icon** → Check icon path and restart tray
3. **No voice** → Check PipeWire and `"voice": true` in config
4. **Custom art ignored** → Names must match exactly, run `oc-companion reload`
