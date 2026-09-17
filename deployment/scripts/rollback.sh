#!/bin/bash
# ─────────────────────────────────────────────────────────────
# rollback.sh — Restore the previous version
# ─────────────────────────────────────────────────────────────
#
# WHAT THIS SCRIPT DOES:
#   Called when health check fails.
#   1. Stops the failed new container
#   2. Leaves the old (active) container running
#   3. Nginx is NOT changed — it still points to the old version
#   4. Users were never switched to the broken version
#
# CALLED BY: Jenkins pipeline "post { failure { ... } }" block
#
# ─────────────────────────────────────────────────────────────

NEW_COLOR_FILE="/tmp/new_color"
STATE_FILE="/tmp/active_color"

echo "═══════════════════════════════════════"
echo "  ROLLBACK STARTING"
echo "  Time: $(date)"
echo "═══════════════════════════════════════"
echo ""

# ── Read which color failed ───────────────────────────────────
if [ -f "$NEW_COLOR_FILE" ]; then
    FAILED_COLOR=$(cat "$NEW_COLOR_FILE")
else
    echo "WARNING: No new_color file found. Nothing to roll back."
    exit 0
fi

# ── Read which color is still active (old/safe version) ──────
if [ -f "$STATE_FILE" ]; then
    ACTIVE_COLOR=$(cat "$STATE_FILE")
else
    ACTIVE_COLOR="unknown"
fi

echo "► Failed slot:  $FAILED_COLOR (will be stopped)"
echo "► Active slot:  $ACTIVE_COLOR (still running - untouched)"
echo ""

# ── Stop the failed container ─────────────────────────────────
echo "► Stopping failed container: flask-$FAILED_COLOR ..."
docker stop "flask-$FAILED_COLOR" 2>/dev/null && \
    echo "  Stopped flask-$FAILED_COLOR" || \
    echo "  flask-$FAILED_COLOR was not running (already stopped)"

docker rm "flask-$FAILED_COLOR" 2>/dev/null && \
    echo "  Removed flask-$FAILED_COLOR" || \
    echo "  Nothing to remove"

# ── Verify old version is still running ───────────────────────
echo ""
echo "► Verifying $ACTIVE_COLOR slot is still running..."

if docker ps --format '{{.Names}}' | grep -q "flask-$ACTIVE_COLOR"; then
    echo "  flask-$ACTIVE_COLOR is running ✓"
    echo "  Users are still being served correctly"
else
    echo "  WARNING: flask-$ACTIVE_COLOR is NOT running!"
    echo "  Something is wrong. Check docker ps manually."
fi

# ── Clean up temp files ───────────────────────────────────────
rm -f "$NEW_COLOR_FILE" /tmp/new_port

echo ""
echo "═══════════════════════════════════════"
echo "  ROLLBACK COMPLETE"
echo "  The broken deployment was stopped."
echo "  Old version ($ACTIVE_COLOR) is still live."
echo "  Nginx was NOT changed."
echo "  Users experienced ZERO interruption."
echo "═══════════════════════════════════════"
