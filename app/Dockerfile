# ─────────────────────────────────────────────────────────
# Dockerfile for the Flask application
# ─────────────────────────────────────────────────────────
#
# Think of this as a recipe:
# "Here is how to package our app so it runs the same everywhere"
#
# Docker reads this file top to bottom and builds a 'image'.
# An image is like a lunchbox - everything the app needs, packed inside.
# A container is a running lunchbox.
# ─────────────────────────────────────────────────────────

# Step 1: Start from the official Python 3.11 image
# 'slim' = smaller size (removes things we don't need)
# This is like starting with a clean computer that already has Python installed
FROM python:3.11-slim

# Step 2: Set the working directory inside the container
# All our files will go into /app
WORKDIR /app

# Step 3: Copy requirements.txt FIRST (before the rest of the code)
# Why? Docker caches each step. If requirements don't change,
# Docker skips re-installing packages on the next build = faster builds
COPY requirements.txt .
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Step 4: Install our Python packages
# --no-cache-dir = don't save download cache (keeps image smaller)
RUN pip install --no-cache-dir -r requirements.txt

# Step 5: Copy the application source code
COPY src/ .

# Step 6: Create a non-root user for security
# Real servers never run apps as root - too dangerous
RUN useradd --create-home --shell /bin/bash appuser
USER appuser

# Step 7: Tell Docker our app listens on port 5000
# This is documentation - doesn't actually open the port
EXPOSE 5000

# Step 8: The command that starts our app
# gunicorn = production-grade web server (better than flask's built-in)
# --workers 2 = handle 2 requests at a time
# --bind 0.0.0.0:5000 = listen on all network interfaces, port 5000
CMD ["gunicorn", "--workers", "2", "--bind", "0.0.0.0:5000", "app:app"]
