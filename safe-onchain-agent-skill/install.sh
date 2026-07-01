#!/bin/bash
# Simple Installation Script for Safe On-Chain Agent Skill
# This script installs the skill into the default ~/.claude/skills directory.

set -e

SKILL_NAME="safe-onchain-agent-skill"
REPO_URL="https://github.com/Cryptojigi/safe-onchain-agent-skill.git"
INSTALL_DIR="$HOME/.claude/skills/$SKILL_NAME"
RULES_DIR="$HOME/.claude/rules"

echo "🛡️ Installing Safe On-Chain Agent Skill..."

# Create target directories
mkdir -p "$HOME/.claude/skills"
mkdir -p "$RULES_DIR"

# Clone or update the repository
if [ -d "$INSTALL_DIR" ]; then
    echo "🔄 Updating existing installation at $INSTALL_DIR..."
    git -C "$INSTALL_DIR" pull origin main
else
    echo "📥 Cloning repository to $INSTALL_DIR..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Install global rules if they exist in the repo
if [ -d "$INSTALL_DIR/.claude/rules" ]; then
    echo "📜 Installing global safety rules..."
    cp -r "$INSTALL_DIR/.claude/rules/"* "$RULES_DIR/"
fi

echo "✅ Installation complete! The Safe On-Chain Agent Skill is now ready."
echo "Restart your AI agent to apply the new safety constraints."
