# Setup Checklist

Use this to verify your installation is complete.

## Required Files

- [ ] Scripts in `~/.local/bin/`:
  - [ ] `oc-companion`
  - [ ] `oc-ask`
  - [ ] `oc-voice`
  - [ ] `oc-attach`
  - [ ] `oc-tray`
  - [ ] `oc-voice-bridge`
  - [ ] `oc-now-playing`
  - [ ] `oc-steam`
  - [ ] `oc-quick`

- [ ] Widget in `~/.config/quickshell/companion/`:
  - [ ] `shell.qml`
  - [ ] `Character.qml`
  - [ ] `Bubble.qml`
  - [ ] `Particles.qml`
  - [ ] `qmldir`

- [ ] Config file: `~/.config/oc-companion/config.json`
- [ ] Tray icon: `~/.local/share/icons/hicolor/128x128/apps/oc-companion.png`

## Configuration

- [ ] Edited `~/.config/oc-companion/config.json`
- [ ] Replaced `YOUR_PERSONA_HERE` with actual persona text
- [ ] Set `agent` name (default: `Build`)
- [ ] Set `server` mode (`shared` or `dedicated`)
- [ ] Configured voice settings if desired

## Hotkeys

- [ ] Added keybindings to window manager config
- [ ] `SUPER+ALT+C` → summon companion
- [ ] `SUPER+ALT+A` → ask about selection
- [ ] `SUPER+ALT+I` → attach image
- [ ] Reloaded window manager config

## Testing

Run these commands to verify everything works:

```bash
# Check installation
which oc-companion oc-ask oc-voice  # Should show paths

# Check companion status
oc-companion status  # Should show "running" or "not running"

# Start if needed
oc-companion start

# Test basic functionality
oc-companion ask "hello"  # She should respond

# Test voice (you'll hear a brief sound)
oc-voice --sfx click

# Test OpenCode connection
oc-ask "what is 2+2"  # Should get a response

# Preview an expression
oc-companion mood happy  # She should smile for 6 seconds
```

## Optional Setup

- [ ] Added custom artwork to `~/.config/quickshell/companion/`
- [ ] Added custom sound effects to `~/.config/oc-companion/sfx/`
- [ ] Added voice samples to `~/.config/oc-companion/voice/`
- [ ] Configured agentvoice integration (if using voice input)

## Troubleshooting

If something doesn't work, check:

1. **OpenCode server running**: `ps aux | grep "opencode serve"`
2. **Quickshell logs**: `tail -f ~/.local/share/quickshell/by-id/*/log.qslog`
3. **Companion state**: `ls ~/.local/state/oc-companion/`
4. **Config syntax**: `python3 -m json.tool ~/.config/oc-companion/config.json`

See full troubleshooting guide in README.md.
