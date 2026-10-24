#!/usr/bin/env bash
# Quick install script for Pixel companion

set -e

echo "Installing Pixel companion..."

# Check dependencies
echo "Checking dependencies..."
if ! command -v quickshell &> /dev/null; then
    echo "Error: quickshell not found. Install it first:"
    echo "  https://quickshell.outfoxxed.me/"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "Error: python3 not found"
    exit 1
fi

if ! command -v pw-play &> /dev/null && ! command -v paplay &> /dev/null; then
    echo "Warning: No audio player found (pw-play/paplay). Voice will not work."
fi

echo "✓ Dependencies OK"

# Install scripts
echo "Installing scripts to ~/.local/bin/..."
mkdir -p ~/.local/bin
cp bin/* ~/.local/bin/
chmod +x ~/.local/bin/oc-*
echo "✓ Scripts installed"

# Install widget
echo "Installing Quickshell widget..."
mkdir -p ~/.config/quickshell
cp -r quickshell/companion ~/.config/quickshell/
echo "✓ Widget installed"

# Install config
echo "Setting up config..."
mkdir -p ~/.config/oc-companion
if [ -f ~/.config/oc-companion/config.json ]; then
    echo "! Config already exists, not overwriting"
    echo "  See config.example.json for reference"
else
    cp config/config.example.json ~/.config/oc-companion/config.json
    echo "✓ Config installed"
    echo ""
    echo "IMPORTANT: Edit ~/.config/oc-companion/config.json"
    echo "Replace 'YOUR_PERSONA_HERE' with your desired personality."
fi

# Install icon
echo "Installing tray icon..."
mkdir -p ~/.local/share/icons/hicolor/128x128/apps/
cp config/oc-companion.png ~/.local/share/icons/hicolor/128x128/apps/
echo "✓ Icon installed"

# Create state directory
mkdir -p ~/.local/state/oc-companion

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Edit ~/.config/oc-companion/config.json (set your persona)"
echo "  2. Add hotkeys to your window manager (see INSTALL.md)"
echo "  3. Start: oc-companion start"
echo ""
echo "For Hyprland, add to ~/.config/hypr/bindings.lua:"
echo '  bind("SUPER ALT", "C", function() os.execute("oc-companion show &") end)'
echo '  bind("SUPER ALT", "A", function() os.execute("oc-quick &") end)'
echo '  bind("SUPER ALT", "I", function() os.execute("oc-companion attach &") end)'
