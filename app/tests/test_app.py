"""
Tests for the Flask application.
Jenkins runs these automatically before every deployment.
If any test fails → deployment stops. Nothing broken gets deployed.
"""

import pytest
import sys
import os

# Add the src folder to Python path so we can import app.py
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from app import app


@pytest.fixture
def client():
    """
    Creates a test client for our Flask app.
    This is like a fake browser that can make requests to the app.
    """
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


# ─────────────────────────────────────────────
# Test 1: Home page loads correctly
# ─────────────────────────────────────────────
def test_home_page_loads(client):
    """Home page should return 200 OK."""
    response = client.get("/")
    assert response.status_code == 200, "Home page should return 200"


def test_home_page_shows_version(client):
    """Home page should show the version number."""
    response = client.get("/")
    assert b"1.0.0" in response.data or b"version" in response.data.lower(), \
        "Home page should mention version"


# ─────────────────────────────────────────────
# Test 2: Health check endpoint
# ─────────────────────────────────────────────
def test_health_returns_200(client):
    """
    Health endpoint MUST return 200.
    This is what Jenkins checks after every deployment.
    If this test fails → health check logic is broken.
    """
    response = client.get("/health")
    assert response.status_code == 200, "Health endpoint must return 200"


def test_health_returns_json(client):
    """Health endpoint should return JSON with 'status' field."""
    response = client.get("/health")
    data = response.get_json()
    assert data is not None, "Health endpoint should return JSON"
    assert "status" in data, "Health JSON should have 'status' field"
    assert data["status"] == "healthy", "Status should be 'healthy'"


def test_health_returns_version(client):
    """Health endpoint should include version info."""
    response = client.get("/health")
    data = response.get_json()
    assert "version" in data, "Health JSON should include version"


# ─────────────────────────────────────────────
# Test 3: Version endpoint
# ─────────────────────────────────────────────
def test_version_endpoint(client):
    """Version endpoint should return 200 with version info."""
    response = client.get("/version")
    assert response.status_code == 200
    data = response.get_json()
    assert "version" in data
    assert "color" in data


# ─────────────────────────────────────────────
# Test 4: No 404s on known routes
# ─────────────────────────────────────────────
def test_unknown_route_returns_404(client):
    """Unknown routes should return 404."""
    response = client.get("/this-does-not-exist")
    assert response.status_code == 404
