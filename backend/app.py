import os
import datetime

from flask import Flask, jsonify, request
from flask_cors import CORS
from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError, PyMongoError
from dotenv import load_dotenv

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
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
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
# REGISTER API (包含密保字段)
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
            "password": password,  
            "fullName": data.get("fullName"),
            "houseNo": data.get("houseNo"),
            "contactNo": data.get("contactNo"),
            "profileImage": data.get("profileImage", ""),
            "question1": data.get("question1", ""),
            "answer1": str(data.get("answer1", "")).strip().lower(),
            "question2": data.get("question2", ""),
            "answer2": str(data.get("answer2", "")).strip().lower()
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
# VERIFY SECURITY QUESTIONS API
# ============================

@app.route("/api/verify-security", methods=["POST"])
def verify_security():
    data = request.get_json(silent=True) or {}

    username = str(data.get("username") or "").strip()
    q1 = data.get("question1")
    a1 = str(data.get("answer1") or "").strip().lower()
    q2 = data.get("question2")
    a2 = str(data.get("answer2") or "").strip().lower()

    if not username or not q1 or not a1 or not q2 or not a2:
        return jsonify({
            "success": False,
            "message": "All fields are required"
        }), 400

    try:
        user = users_collection.find_one({"username": username})
        if not user:
            return jsonify({
                "success": False,
                "message": "User not found"
            }), 404

        stored_q1 = user.get("question1", "")
        stored_a1 = str(user.get("answer1", "")).strip().lower()
        stored_q2 = user.get("question2", "")
        stored_a2 = str(user.get("answer2", "")).strip().lower()

        if (stored_q1 == q1 and stored_a1 == a1 and stored_q2 == q2 and stored_a2 == a2):
            return jsonify({
                "success": True,
                "message": "Verification successful!"
            }), 200
        else:
            return jsonify({
                "success": False,
                "message": "Incorrect security questions or answers!"
            }), 401

    except PyMongoError:
        return jsonify({
            "success": False,
            "message": "Database operation failed"
        }), 503


# ============================
# RESET PASSWORD API
# ============================

@app.route("/api/reset-password", methods=["POST"])
def reset_password():
    data = request.get_json(silent=True) or {}

    username = str(data.get("username") or "").strip()
    new_password = data.get("newPassword")

    if not username or not new_password:
        return jsonify({
            "success": False,
            "message": "Username and new password are required"
        }), 400

    if len(new_password) < 8:
        return jsonify({
            "success": False,
            "message": "Password must be at least 8 characters"
        }), 400

    try:
        result = users_collection.update_one(
            {"username": username},
            {"$set": {"password": new_password}}
        )

        if result.matched_count == 0:
            return jsonify({
                "success": False,
                "message": "User not found"
            }), 404

        return jsonify({
            "success": True,
            "message": "Password reset successfully!"
        }), 200

    except PyMongoError:
        return jsonify({
            "success": False,
            "message": "Database operation failed"
        }), 503


# ============================
# LOGIN API (明文比对)
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

    if not user or stored_password != password:
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
# HISTORY API
# ============================

@app.route("/api/history/<username>", methods=["GET"])
def get_history(username):
    try:
        user_history = list(
            db["history"]
            .find({"username": username}, {"_id": 0})
            .sort("createdAt", -1)
        )

        return jsonify({
            "success": True,
            "history": user_history
        }), 200

    except PyMongoError:
        app.logger.exception("Failed to fetch history")
        return jsonify({
            "success": False,
            "message": "Database operation failed"
        }), 503


# ============================
# DELETE HISTORY ITEM API
# ============================

@app.route("/api/history/<username>/<int:delivery_id>", methods=["DELETE"])
def delete_history_item(username, delivery_id):
    try:
        result = db["history"].delete_one({"username": username, "id": delivery_id})

        if result.deleted_count == 0:
            return jsonify({
                "success": False,
                "message": "History item not found in database"
            }), 404

        return jsonify({
            "success": True,
            "message": "History item deleted successfully"
        }), 200

    except PyMongoError:
        app.logger.exception("Failed to delete history item")
        return jsonify({
            "success": False,
            "message": "Database operation failed"
        }), 503


# ============================
# GET USER PROFILE API
# ============================

@app.route("/api/user/<username>", methods=["GET"])
def get_user_profile(username):
    try:
        user = users_collection.find_one({"username": username}, {"_id": 0, "password": 0})
        
        if not user:
            return jsonify({
                "success": False,
                "message": "User not found"
            }), 404
            
        return jsonify({
            "success": True,
            "user": user
        }), 200
        
    except Exception as e:
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500


# ============================
# UPDATE USER PROFILE API
# ============================

@app.route("/api/user/<username>", methods=["PUT"])
def update_user_profile(username):
    try:
        data = request.get_json(silent=True) or {}

        allowed_fields = ["fullName", "contactNo", "houseNo", "profileImage"]
        updates = {}

        for field in allowed_fields:
            if field in data:
                value = data[field]

                if not isinstance(value, str):
                    return jsonify({
                        "success": False,
                        "message": f"{field} must be a string"
                    }), 400

                updates[field] = value.strip()

        if not updates:
            return jsonify({
                "success": False,
                "message": "No valid profile fields provided"
            }), 400

        result = users_collection.update_one(
            {"username": username},
            {"$set": updates}
        )

        if result.matched_count == 0:
            return jsonify({
                "success": False,
                "message": "User not found"
            }), 404

        updated_user = users_collection.find_one(
            {"username": username},
            {"_id": 0, "password": 0}
        )

        return jsonify({
            "success": True,
            "message": "Profile updated successfully",
            "user": updated_user
        }), 200

    except PyMongoError:
        return jsonify({
            "success": False,
            "message": "Database error while updating profile"
        }), 500

    except Exception:
        app.logger.exception("Failed to update user profile")
        return jsonify({
            "success": False,
            "message": "Failed to update profile"
        }), 500


# ============================
# CREATE ROBOT REQUEST API
# ============================

@app.route("/api/requests", methods=["POST"])
def create_robot_request():
    # ✨ 修复：删除了错误的 Thread 变量
    data = request.get_json(silent=True) or {}

    username = str(data.get("username") or "").strip()
    try:
        delivery_id = int(data.get("id"))
    except (TypeError, ValueError):
        return jsonify({
            "success": False,
            "message": "A valid delivery id is required"
        }), 400

    locker = str(data.get("locker") or "").strip()
    destination = str(data.get("destination") or "").strip()
    pickup = str(data.get("pickup") or "").strip()
    items = data.get("items")
    scheduled = data.get("scheduled", False)

    if not username or not locker or not destination or not pickup:
        return jsonify({
            "success": False,
            "message": "Missing required request fields"
        }), 400

    if not isinstance(items, list) or not items:
        return jsonify({
            "success": False,
            "message": "At least one delivery item is required"
        }), 400

    if not isinstance(scheduled, bool):
        return jsonify({
            "success": False,
            "message": "scheduled must be true or false"
        }), 400

    for item in items:
        if not isinstance(item, dict) or not item.get("type") or not item.get("size"):
            return jsonify({
                "success": False,
                "message": "Each item must contain type and size"
            }), 400

    try:
        user_exists = users_collection.count_documents({"username": username}) > 0
        if not user_exists:
            return jsonify({
                "success": False,
                "message": "User not found"
            }), 404

        created_at_str = datetime.datetime.now(datetime.timezone.utc).isoformat()
        clean_items = [
            {"type": str(item["type"]), "size": str(item["size"])}
            for item in items
        ]

        order_doc = {
            "username": username,
            "id": delivery_id,
            "items": clean_items,
            "locker": locker,
            "destination": destination,
            "pickup": pickup,
            "scheduled": scheduled,
            "status": "Pending",
            "createdAt": created_at_str
        }

        db["history"].insert_one(order_doc)

        response_order = {
            "username": username,
            "id": delivery_id,
            "items": clean_items,
            "locker": locker,
            "destination": destination,
            "pickup": pickup,
            "scheduled": scheduled,
            "status": "Pending",
            "createdAt": created_at_str
        }

        return jsonify({
            "success": True,
            "message": "Robot request saved successfully",
            "order": response_order
        }), 201

    except PyMongoError as e:
        app.logger.error(f"Failed to save robot request: {str(e)}")
        return jsonify({
            "success": False,
            "message": "Database operation failed"
        }), 503


# ============================
# RUN FLASK
# ============================

if __name__ == "__main__":
    app.run(
        host="127.0.0.1",
        port=5000,
        debug=False
    )