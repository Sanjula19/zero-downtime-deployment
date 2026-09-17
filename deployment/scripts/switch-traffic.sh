#!/bin/bash
# ─────────────────────────────────────────────────────────────
# switch-traffic.sh — Switch Nginx to the new healthy container
# ─────────────────────────────────────────────────────────────
#
# WHAT THIS SCRIPT DOES:
#   Called AFTER health check passes.
#   1. Updates nginx.conf to point to the new (healthy) container
#   2. Reloads Nginx — takes effect instantly, zero downtime
#   3. Stops the old container (now it's the standby)
#   4. Updates the state file (new color is now "active")
#
# CALLED BY: Jenkins pipeline Stage "Switch Traffic"
#
# ─────────────────────────────────────────────────────────────

set -e

# ── Paths ─────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
NGINX_CONF="$PROJECT_ROOT/deployment/nginx/nginx.conf"
NGINX_LIVE="/etc/nginx/sites-available/flask-app"
STATE_FILE="/tmp/active_color"
NEW_COLOR_FILE="/tmp/new_color"

# ── Read colors ───────────────────────────────────────────────
NEW_COLOR=$(cat "$NEW_COLOR_FILE")
NEW_PORT=$(cat /tmp/new_port)
OLD_COLOR=$(cat "$STATE_FILE" 2>/dev/null || echo "unknown")

echo "═══════════════════════════════════════"
echo "  TRAFFIC SWITCH STARTING"
echo "  Switching FROM: $OLD_COLOR"
echo "  Switching TO:   $NEW_COLOR (port $NEW_PORT)"
echo "  Time: $(date)"
echo "═══════════════════════════════════════"
echo ""

# ── Step 1: Update nginx.conf ─────────────────────────────────
echo "► Updating Nginx config to point to port $NEW_PORT..."

# Replace the upstream server port in nginx.conf
# sed changes the active port line to the new port
sudo sed -i "s|server localhost:[0-9]*;|server localhost:$NEW_PORT;|g" \
    "$NGINX_LIVE"

echo "  Nginx config updated"

# ── Step 2: Test Nginx config before reloading ────────────────
echo "► Testing Nginx config for errors..."
sudo nginx -t
echo "  Config test passed ✓"

# ── Step 3: Reload Nginx (zero downtime — does NOT restart) ───
echo "► Reloading Nginx..."
sudo nginx -s reload
echo "  Nginx reloaded. Traffic now going to $NEW_COLOR (port $NEW_PORT)"

# ── Step 4: Update state file ─────────────────────────────────
echo "$NEW_COLOR" > "$STATE_FILE"
echo "► State updated: $NEW_COLOR is now the active slot"

# ── Step 5: Stop old container ────────────────────────────────
if [ "$OLD_COLOR" != "unknown" ]; then
    echo ""
    echo "► Stopping old container: flask-$OLD_COLOR..."
    docker stop "flask-$OLD_COLOR" 2>/dev/null && \
        echo "  flask-$OLD_COLOR stopped" || \
        echo "  flask-$OLD_COLOR was already stopped"
    docker rm "flask-$OLD_COLOR" 2>/dev/null || true
fi

# ── Step 6: Clean up temp files ───────────────────────────────
rm -f "$NEW_COLOR_FILE" /tmp/new_port

echo ""
echo "═══════════════════════════════════════"
echo "  TRAFFIC SWITCH COMPLETE ✓"
echo "  Active slot: $NEW_COLOR (port $NEW_PORT)"
echo "  Users are now on the new version!"
echo "═══════════════════════════════════════"
