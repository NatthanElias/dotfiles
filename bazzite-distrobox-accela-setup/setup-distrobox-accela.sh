#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
#  ACCELA Distrobox Setup Script
#  Sets up ACCELA + SLSsteam in an isolated container on Bazzite,
#  keeping the host Steam clean.
#
#  Usage: bash setup-distrobox-accela.sh
#         (run from HOST terminal, not inside a distrobox)
# =============================================================================

CONTAINER_NAME="brother-steambox"
CONTAINER_IMAGE="ghcr.io/ublue-os/steambox"
CONTAINER_HOME="$HOME/distrobox-homes/$CONTAINER_NAME"
ENTER_THE_WIRED_URL="https://raw.githubusercontent.com/ciscosweater/enter-the-wired/main/enter-the-wired"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Sanity checks ---
if [ -f /run/.containerenv ]; then
    echo -e "${YELLOW}[ERROR] Run this from the HOST terminal, not inside a container.${NC}"
    exit 1
fi

# --- Step 1: Create the container ---
echo -e "\n${CYAN}=== Creating distrobox container ===${NC}"

if distrobox list 2>/dev/null | grep -q "$CONTAINER_NAME"; then
    echo -e "${YELLOW}Container '$CONTAINER_NAME' already exists. Remove it first with:${NC}"
    echo "  distrobox rm $CONTAINER_NAME --force"
    exit 1
fi

distrobox create \
    --unshare-netns \
    --nvidia \
    --image "$CONTAINER_IMAGE" \
    --name "$CONTAINER_NAME" \
    --home "$CONTAINER_HOME" \
    -Y

echo -e "${GREEN}Container created ✓${NC}"

# --- Step 2: Initialize + install deps ---
echo -e "\n${CYAN}=== Initializing container ===${NC}"
distrobox enter "$CONTAINER_NAME" -- bash -c '
    sudo dnf install -y xterm git 2>/dev/null || true
'
echo -e "${GREEN}Container ready ✓${NC}"

# --- Step 3: Launch Steam once ---
echo -e "\n${CYAN}=== Launch Steam inside the container ===${NC}"
echo "Log in, let it initialize, then CLOSE Steam."
read -p "Press Enter to launch Steam... " < /dev/tty
distrobox enter "$CONTAINER_NAME" -- steam || true

# --- Step 4: Install enter-the-wired ---
echo -e "\n${CYAN}=== Installing ACCELA + SLSsteam ===${NC}"
distrobox enter "$CONTAINER_NAME" -- bash -c "curl -fsSL '$ENTER_THE_WIRED_URL' | bash"
echo -e "${GREEN}Installation complete ✓${NC}"

# --- Step 5: Fix PATH + export ACCELA ---
echo -e "\n${CYAN}=== Final setup ===${NC}"
distrobox enter "$CONTAINER_NAME" -- bash -c '
    grep -q "HOME/.local/bin" ~/.bashrc 2>/dev/null || \
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
    distrobox-export --app accela 2>/dev/null || \
        distrobox-export --app ACCELA 2>/dev/null || true
    distrobox-export --app steam 2>/dev/null || true
'
echo -e "${GREEN}ACCELA + Steam exported to host app menu ✓${NC}"

# --- Done ---
echo ""
echo -e "${GREEN}=== SETUP COMPLETE ===${NC}"
echo ""
echo "  Container:  $CONTAINER_NAME (home: $CONTAINER_HOME)"
echo "  ACCELA:     available in app menu or 'distrobox enter $CONTAINER_NAME -- accela'"
echo "  Steam:      distrobox enter $CONTAINER_NAME -- steam"
echo "  Update:     distrobox enter $CONTAINER_NAME -- ~/enter-the-wired/accela"
echo "  Uninstall:  distrobox enter $CONTAINER_NAME -- ~/enter-the-wired/uninstall"
echo "  Nuke all:   distrobox rm $CONTAINER_NAME --force && rm -rf $CONTAINER_HOME"
echo ""
