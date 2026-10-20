
import os

from flask import Flask, jsonify, request
from flask_cors import CORS
from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError, PyMongoError
from dotenv import load_dotenv
from werkzeug.security import generate_password_hash, check_password_hash

# ============================
# ENVIRONMENT VARIABLES
# ============================

load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

app = Flask(__name__)

# CORS - Local Flutter Web development
CORS(
    app,
    resources={
        r"/api/*": {
            "origins": [
                r"http://localhost:\d+",
                r"http://127\.0\.0\.1:\d+"
            ],
            "methods": ["GET", "POST", "OPTIONS"],
            "allow_headers": ["Content-Type"]
        }
    }
)

# ============================
# MONGODB CONNECTION
# ============================

MONGO_URI = os.getenv("MONGO_URI")

if not MONGO_URI:
    raise RuntimeError("MONGO_URI is missing from backend/.env")

client = MongoClient(
    MONGO_URI,
    serverSelectionTimeoutMS=5000
)

db = client["convy_db"]
users_collection = db["users"]


# ============================
# HOME
# ============================

@app.route("/")
def home():
    return jsonify({
        "message": "CONVY Backend is running!"
    })


# ============================
# HEALTH CHECK
# ============================

@app.route("/api/health", methods=["GET"])
def health():
    try:
        client.admin.command("ping")

        return jsonify({
            "success": True,
            "database": "connected"
        }), 200

    except PyMongoError:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 503


# ============================
# REGISTER API
# ============================

@app.route("/api/register", methods=["POST"])
def register():
    data = request.get_json(silent=True) or {}

    username = str(data.get("username") or "").strip()
    password = data.get("password")

    if not username or not isinstance(password, str) or not password:
        return jsonify({
            "success": False,
            "message": "Username and password are required"
        }), 400

    if len(password) < 8:
        return jsonify({
            "success": False,
            "message": "Password must be at least 8 characters"
        }), 400

    try:
        if users_collection.find_one({"username": username}):
            return jsonify({
                "success": False,
                "message": "Username already exists"
            }), 409

        new_user = {
            "username": username,
            "password": generate_password_hash(password),
            "fullName": data.get("fullName"),
            "houseNo": data.get("houseNo"),
            "contactNo": data.get("contactNo"),
            "profileImage": data.get("profileImage", "")
        }

        users_collection.insert_one(new_user)

    except DuplicateKeyError:
        return jsonify({
            "success": False,
            "message": "Username already exists"
        }), 409

    except PyMongoError:
        return jsonify({
            "success": False,
            "message": "Database operation failed"
        }), 503

    return jsonify({
        "success": True,
        "message": "Registration successful!"
    }), 201


# ============================
# LOGIN API
# ============================

@app.route("/api/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}

    username = str(data.get("username") or "").strip()
    password = data.get("password")

    if not username or not isinstance(password, str) or not password:
        return jsonify({
            "success": False,
            "message": "Username and password are required"
        }), 400

    try:
        user = users_collection.find_one({"username": username})

    except PyMongoError:
        return jsonify({
            "success": False,
            "message": "Database operation failed"
        }), 503

    stored_password = user.get("password") if user else None

    if (
        not isinstance(stored_password, str)
        or not stored_password.startswith(("scrypt:", "pbkdf2:"))
        or not check_password_hash(stored_password, password)
    ):
        return jsonify({
            "success": False,
            "message": "Invalid username or password"
        }), 401

    return jsonify({
        "success": True,
        "message": "Login successful!",
        "fullName": user.get("fullName"),
        "houseNo": user.get("houseNo"),
        "contactNo": user.get("contactNo")
    }), 200


# ============================
# RUN FLASK
# ============================

if __name__ == "__main__":
    app.run(
        host="127.0.0.1",
        port=5000,
        debug=False
    )
