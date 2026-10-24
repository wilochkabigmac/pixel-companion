# Pixel Companion - GitHub Release Package

## Package Contents

```
pixel-companion/
├── README.md              Main documentation
├── INSTALL.md             Installation guide
├── LICENSE                MIT license
├── .gitignore             Git ignore rules
├── install.sh             Quick install script
├── bin/                   Helper scripts (9 files)
│   ├── oc-companion       Main wrapper
│   ├── oc-ask             OpenCode client
│   ├── oc-voice           Voice synthesizer
│   ├── oc-attach          Image capture
│   ├── oc-tray            System tray icon
│   ├── oc-voice-bridge    Agentvoice endpoint
│   ├── oc-now-playing     Media query
│   ├── oc-steam           Steam integration
│   └── oc-quick           Selection helper
├── quickshell/companion/  Widget files (5 files)
│   ├── shell.qml          Main widget
│   ├── Character.qml      Drawn chibi
│   ├── Bubble.qml         Speech bubble
│   ├── Particles.qml      Emoji system
│   └── qmldir             Module definition
├── config/
│   ├── config.example.json Example config
│   └── oc-companion.png   Tray icon
└── docs/
    ├── CUSTOMIZATION.md   Full customization guide
    ├── CHECKLIST.md       Setup verification
    └── screenshot-placeholder.txt

```

## Ready for GitHub

This package is ready to push to GitHub. All paths are generalized and all scripts work independently.

## Where to Add Your Information

### 1. **config/config.example.json** - Replace persona placeholder

**Current state:**
```json
{
  "persona": "YOUR_PERSONA_HERE",
  ...
}
```

**What to do:**
Replace `YOUR_PERSONA_HERE` with your default persona. Users will copy this file and can customize it, but provide a good starting point.

**Suggested default:**
```json
{
  "persona": "You are Pixel, a helpful desktop assistant who lives in the corner of the user's screen. Keep replies short and conversational - a couple of sentences unless asked for detail. You are warm, friendly, and never lecture.",
  ...
}
```

Or use the full persona from the current `config.example.json` in the package (which already has comprehensive instructions).

### 2. **docs/screenshot.png** - Add a screenshot

Replace `screenshot-placeholder.txt` with an actual screenshot showing:
- Pixel in the corner
- A speech bubble with text
- Emoji particles (if visible)
- The tray icon

Take it with:
```bash
grim -g "X,Y WxH" docs/screenshot.png
```

Then update README.md line 5:
```markdown
![Pixel companion screenshot](docs/screenshot.png)
```

### 3. **README.md** - Optional: Add your info

At the end of README.md, you can add:
- Your name/handle in the Credits section
- Links to your other projects
- A badge for GitHub stars
- Contact information

### 4. **LICENSE** - Update copyright holder (optional)

Current: `Copyright (c) 2026 Pixel Contributors`

Change to your name if you prefer single ownership, or leave as-is for community contributions.

## Publishing to GitHub

```bash
cd pixel-companion

# Initialize repo
git init
git add .
git commit -m "Initial release"

# Create GitHub repo (via web UI or gh CLI)
gh repo create pixel-companion --public --source=. --remote=origin

# Push
git push -u origin main

# Create first release
git tag -a v1.0.0 -m "First release"
git push origin v1.0.0
gh release create v1.0.0 --title "Pixel v1.0.0" --notes "First public release"
```

## Post-Release Checklist

- [ ] Add topics to GitHub repo: `linux`, `desktop-assistant`, `ai`, `quickshell`, `opencode`
- [ ] Enable Issues and Discussions
- [ ] Add README sections: Installation, Usage, Contributing
- [ ] Create a GIF demo (optional but highly recommended)
- [ ] Add to your GitHub profile README
- [ ] Share on Reddit/Discord/Forums if desired

## What Users Need to Fill In

When users install, they must:

1. **Edit `~/.config/oc-companion/config.json`**
   - Replace `YOUR_PERSONA_HERE` with their desired personality
   - Or use the provided default if you filled it in

2. **Add hotkeys to their window manager**
   - The install guide shows Hyprland examples
   - Users adapt to their WM (i3, sway, etc.)

3. **Ensure OpenCode server is running**
   - Either shared (`opencode serve`) or dedicated mode

Everything else is automatic via `install.sh`.

## Notes

- All paths use `~/.config/`, `~/.local/bin/`, etc. (standard Linux locations)
- No hardcoded usernames or system-specific paths
- Scripts detect dependencies and provide helpful errors
- Config file uses JSON (easy to parse and edit)
- Works on any Wayland compositor with Quickshell support
- MIT license allows anyone to modify and redistribute

The package is production-ready. Add your screenshot and optionally customize the example persona, then it's ready to publish.
