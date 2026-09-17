"""
Zero-Downtime Deployment System - Flask Application
----------------------------------------------------
This is a simple Flask web app.
The DEPLOYMENT SYSTEM is the main project - not this app.
But this app has two important routes:
  /        → shows which version is running (visual proof)
  /health  → Jenkins checks this after every deployment
"""

from flask import Flask, jsonify
import os

app = Flask(__name__)

# These values come from environment variables set in docker-compose
# That way we can tell which version and color (Blue/Green) is running
VERSION = os.environ.get("APP_VERSION", "1.0.0")
APP_COLOR = os.environ.get("APP_COLOR", "blue")


@app.route("/")
def home():
    """
    Main page - shows version and color.
    When you switch from Blue to Green, you can see it change here.
    """
    color_hex = "#4A90D9" if APP_COLOR == "blue" else "#27AE60"
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Zero-Downtime Deployment</title>
        <style>
            body {{
                font-family: Arial, sans-serif;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                background-color: #f5f5f5;
            }}
            .card {{
                background: white;
                padding: 40px;
                border-radius: 12px;
                box-shadow: 0 4px 20px rgba(0,0,0,0.1);
                text-align: center;
                border-top: 8px solid {color_hex};
            }}
            .version {{ font-size: 48px; font-weight: bold; color: {color_hex}; }}
            .color {{ font-size: 20px; color: #666; margin-top: 8px; }}
            .label {{ font-size: 14px; color: #999; margin-top: 24px; }}
        </style>
    </head>
    <body>
        <div class="card">
            <div class="label">Zero-Downtime Container Deployment System</div>
            <div class="version">v{VERSION}</div>
            <div class="color">Running on: {APP_COLOR.upper()} slot</div>
            <div class="label">Deployment is working correctly ✓</div>
        </div>
    </body>
    </html>
    """


@app.route("/health")
def health():
    """
    Health check endpoint.
    Jenkins hits this URL after every deployment.
    Returns 200 = healthy (deployment succeeds)
    Returns anything else = unhealthy (rollback triggers)
    """
    return jsonify({
        "status": "healthy",
        "version": VERSION,
        "color": APP_COLOR
    }), 200


@app.route("/version")
def version():
    """
    Simple version endpoint - returns plain JSON.
    Useful for scripted checks.
    """
    return jsonify({
        "version": VERSION,
        "color": APP_COLOR
    }), 200


if __name__ == "__main__":
    print(f"Starting app version {VERSION} on {APP_COLOR} slot")
    app.run(host="0.0.0.0", port=5000, debug=False)
