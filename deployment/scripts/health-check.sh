#!/bin/bash
# ─────────────────────────────────────────────────────────────
# health-check.sh — Validates the newly deployed container
# ─────────────────────────────────────────────────────────────
#
# WHAT THIS SCRIPT DOES:
#   Hits the /health endpoint of the newly deployed container
#   every 5 seconds, for up to 60 seconds.
#   If /health returns 200 → exit 0 (success → Jenkins continues)
#   If /health never returns 200 → exit 1 (failure → Jenkins triggers rollback)
#
# CALLED BY: Jenkins pipeline Stage "Health Check"
#
# ─────────────────────────────────────────────────────────────

set -e

# ── Read which color was just deployed ───────────────────────
NEW_COLOR_FILE="/tmp/new_color"
NEW_PORT_FILE="/tmp/new_port"

if [ ! -f "$NEW_COLOR_FILE" ]; then
    echo "ERROR: Cannot find new color file at $NEW_COLOR_FILE"
    echo "Did deploy.sh run before this script?"
    exit 1
fi

NEW_COLOR=$(cat "$NEW_COLOR_FILE")
NEW_PORT=$(cat "$NEW_PORT_FILE")
HEALTH_URL="http://localhost:$NEW_PORT/health"

# ── Configuration ─────────────────────────────────────────────
MAX_ATTEMPTS=12        # 12 attempts × 5 seconds = 60 seconds max wait
WAIT_SECONDS=5         # seconds between each attempt
ATTEMPT=0

echo "═══════════════════════════════════════"
echo "  HEALTH CHECK STARTING"
echo "  Target: $NEW_COLOR slot"
echo "  URL: $HEALTH_URL"
echo "  Timeout: $((MAX_ATTEMPTS * WAIT_SECONDS)) seconds"
echo "  Time: $(date)"
echo "═══════════════════════════════════════"
echo ""

# ── Health check loop ────────────────────────────────────────
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    echo "► Attempt $ATTEMPT/$MAX_ATTEMPTS — checking $HEALTH_URL ..."

    # curl flags:
    #   -s = silent (no progress bar)
    #   -o /dev/null = throw away the response body
    #   -w "%{http_code}" = print only the HTTP status code
    #   --connect-timeout 5 = give up connecting after 5 seconds
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 5 \
        "$HEALTH_URL" 2>/dev/null || echo "000")

    echo "  HTTP response: $HTTP_CODE"

    if [ "$HTTP_CODE" = "200" ]; then
        echo ""
        echo "═══════════════════════════════════════"
        echo "  HEALTH CHECK PASSED ✓"
        echo "  $NEW_COLOR slot is healthy!"
        echo "  HTTP 200 received on attempt $ATTEMPT"
        echo "═══════════════════════════════════════"
        exit 0   # ← Success! Jenkins pipeline continues to Switch Traffic
    else
        echo "  Not healthy yet (got $HTTP_CODE, need 200)"
        if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
            echo "  Waiting $WAIT_SECONDS seconds before next attempt..."
            sleep $WAIT_SECONDS
        fi
    fi
done

# ── If we get here, all attempts failed ──────────────────────
echo ""
echo "═══════════════════════════════════════"
echo "  HEALTH CHECK FAILED ✗"
echo "  $NEW_COLOR slot did not become healthy"
echo "  after $((MAX_ATTEMPTS * WAIT_SECONDS)) seconds"
echo "  Rollback will be triggered."
echo "═══════════════════════════════════════"
exit 1   # ← Failure! Jenkins triggers rollback
