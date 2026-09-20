#!/bin/bash
# ─────────────────────────────────────────────────────────────
# deploy.sh — Main Deployment Script
# ─────────────────────────────────────────────────────────────
#
# WHAT THIS SCRIPT DOES:
#   1. Figures out which color (Blue/Green) is currently live
#   2. Starts the OPPOSITE color with the new Docker image
#   3. Saves which color is now the "new" one (for health-check.sh to use)
#
# CALLED BY: Jenkins pipeline Stage "Deploy"
#
# INPUTS (from Jenkins environment):
#   APP_VERSION — the version string (e.g. "2.0.0")
#
# ─────────────────────────────────────────────────────────────

set -e  # Stop immediately if any command fails

# ── Paths ────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCKER_DIR="$PROJECT_ROOT/deployment/docker"
STATE_FILE="/tmp/active_color"         # Records which color is currently live
NEW_COLOR_FILE="/tmp/new_color"        # Records which color we just deployed

# ── Version ──────────────────────────────────────────────────
APP_VERSION="${APP_VERSION:-1.0.0}"

echo "═══════════════════════════════════════"
echo "  DEPLOY SCRIPT STARTING"
echo "  Version: $APP_VERSION"
echo "  Time: $(date)"
echo "═══════════════════════════════════════"

# ── Step 1: Detect which color is currently active ───────────
if [ -f "$STATE_FILE" ]; then
    ACTIVE_COLOR=$(cat "$STATE_FILE")
else
    # No state file = first ever deployment, assume Blue is active
    # (even if nothing is running yet)
    ACTIVE_COLOR="blue"
fi

echo ""
echo "► Current active slot: $ACTIVE_COLOR"

# ── Step 2: Choose the opposite color for new deployment ─────
if [ "$ACTIVE_COLOR" = "blue" ]; then
    NEW_COLOR="green"
    NEW_PORT="5002"
    COMPOSE_FILE="docker-compose.green.yml"
else
    NEW_COLOR="blue"
    NEW_PORT="5001"
    COMPOSE_FILE="docker-compose.blue.yml"
fi

echo "► Deploying new version to: $NEW_COLOR slot (port $NEW_PORT)"

# ── Step 3: Stop the new slot if it's already running ────────
echo ""
echo "► Stopping any existing $NEW_COLOR container..."
docker stop "flask-$NEW_COLOR" 2>/dev/null || echo "  (No existing $NEW_COLOR container - that's fine)"
docker rm   "flask-$NEW_COLOR" 2>/dev/null || echo "  (Nothing to remove - that's fine)"

# ── Step 4: Start the new slot ───────────────────────────────
echo ""
echo "► Starting $NEW_COLOR container with version $APP_VERSION..."

APP_VERSION="$APP_VERSION" docker compose \
    -f "$DOCKER_DIR/$COMPOSE_FILE" \
    up -d

echo "► $NEW_COLOR container started"

# ── Step 5: Save which color we just deployed ────────────────
echo "$NEW_COLOR" > "$NEW_COLOR_FILE"
echo "$NEW_PORT"  > /tmp/new_port

echo ""
echo "═══════════════════════════════════════"
echo "  DEPLOY COMPLETE"
echo "  New slot: $NEW_COLOR (port $NEW_PORT)"
echo "  Health check will now validate it..."
echo "═══════════════════════════════════════"
