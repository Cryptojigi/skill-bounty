#!/bin/bash
# Custom Installation Script for Safe On-Chain Agent Skill
# Allows the user to select the installation path (global or project-local)

set -e

SKILL_NAME="safe-onchain-agent-skill"
REPO_URL="https://github.com/Cryptojigi/safe-onchain-agent-skill.git"

echo "🛡️ Safe On-Chain Agent Skill - Custom Installer"
echo "------------------------------------------------"

# Prompt for installation type
echo "Where would you like to install the skill?"
echo "1) Global (Default: ~/.claude/skills)"
echo "2) Project-local (Current directory: ./.claude/skills)"
read -p "Select option [1/2]: " INSTALL_TYPE

if [ "$INSTALL_TYPE" = "2" ]; then
    BASE_DIR="$(pwd)/.claude"
    echo "📂 Selected Project-local installation."
else
    BASE_DIR="$HOME/.claude"
    echo "🌍 Selected Global installation."
fi

INSTALL_DIR="$BASE_DIR/skills/$SKILL_NAME"
RULES_DIR="$BASE_DIR/rules"

echo "Creating directories..."
mkdir -p "$BASE_DIR/skills"
mkdir -p "$RULES_DIR"

if [ -d "$INSTALL_DIR" ]; then
    read -p "⚠️ Directory $INSTALL_DIR already exists. Update it? [Y/n]: " UPDATE_CHOICE
    UPDATE_CHOICE=${UPDATE_CHOICE:-Y}
    if [[ "$UPDATE_CHOICE" =~ ^[Yy]$ ]]; then
        echo "🔄 Updating..."
        git -C "$INSTALL_DIR" pull origin main
    else
        echo "⏭️ Skipping repository update."
    fi
else
    echo "📥 Cloning repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Prompt for rules installation
read -p "📜 Do you want to copy the safety rules to $RULES_DIR? [Y/n]: " RULES_CHOICE
RULES_CHOICE=${RULES_CHOICE:-Y}

if [[ "$RULES_CHOICE" =~ ^[Yy]$ ]]; then
    if [ -d "$INSTALL_DIR/.claude/rules" ]; then
        cp -r "$INSTALL_DIR/.claude/rules/"* "$RULES_DIR/"
        echo "✅ Rules installed successfully."
    else
        echo "⚠️ No rules found in the repository to install."
    fi
else
    echo "⏭️ Skipping rules installation."
fi

echo "------------------------------------------------"
echo "🎉 Installation complete! Installed at: $INSTALL_DIR"
