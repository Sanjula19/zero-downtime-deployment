#!/bin/bash
# ─────────────────────────────────────────────────────────────
# cleanup.sh — Remove old Docker images and containers
# ─────────────────────────────────────────────────────────────
#
# WHAT THIS SCRIPT DOES:
#   Removes dangling Docker images to free disk space.
#   Run this periodically or after several deployments.
#   Safe to run — does NOT remove running containers.
#
# ─────────────────────────────────────────────────────────────

echo "═══════════════════════════════════════"
echo "  CLEANUP STARTING"
echo "  Time: $(date)"
echo "═══════════════════════════════════════"
echo ""

# Show disk usage before cleanup
echo "► Disk usage before cleanup:"
df -h / | tail -1

echo ""

# Remove stopped containers
echo "► Removing stopped containers..."
docker container prune -f
echo "  Done"

# Remove dangling images (untagged, not used by any container)
echo "► Removing unused Docker images..."
docker image prune -f
echo "  Done"

echo ""

# Show disk usage after cleanup
echo "► Disk usage after cleanup:"
df -h / | tail -1

echo ""
echo "═══════════════════════════════════════"
echo "  CLEANUP COMPLETE"
echo "═══════════════════════════════════════"
