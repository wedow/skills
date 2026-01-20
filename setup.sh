#!/usr/bin/env bash
# Setup script for claude-skills
# Creates symlinks for global config and tools

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure ~/.local/bin exists
mkdir -p ~/.local/bin

# Create symlinks
ln -s "$SCRIPT_DIR/CLAUDE.md.global" ~/CLAUDE.md
ln -s "$SCRIPT_DIR/autonomous-development/scripts/autonomous-dev-loop.sh" ~/.local/bin/ai

echo "Setup complete:"
echo "  ~/CLAUDE.md      → PRIME DIRECTIVE and agent coordination rules"
echo "  ~/.local/bin/ai  → autonomous development loop"
echo ""
echo "Make sure ~/.local/bin is in your PATH:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
echo "For ticket management (tk), install separately from:"
echo "  https://github.com/wedow/ticket"
