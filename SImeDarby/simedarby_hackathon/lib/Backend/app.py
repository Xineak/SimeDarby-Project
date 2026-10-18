from flask import Flask, request, jsonify
from pymongo import MongoClient

app = Flask(__name__)

# 1. 已配置好你的数据库凭证和集群地址
MONGO_URI = "mongodb+srv://siewkaexin_db_user:cdmTpg7uGduG9hqM@cluster0.uahrfxh.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
client = MongoClient(MONGO_URI)

# 指定数据库和集合
db = client['convy_db']
users_collection = db['users']

# ==================== 1. 注册接口 ====================
@app.route('/api/register', methods=['POST'])
def register():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    
    if not username or not password:
        return jsonify({'success': False, 'message': 'Username and password are required'}), 400
    
    if users_collection.find_one({'username': username}):
        return jsonify({'success': False, 'message': 'Username already exists'}), 400
    
    users_collection.insert_one({
        'username': username,
        'password': password,
        'fullName': data.get('fullName'),
        'houseNo': data.get('houseNo'),
        'contactNo': data.get('contactNo'),
        'question1': data.get('question1'),
        'answer1': data.get('answer1'),
        'question2': data.get('question2'),
        'answer2': data.get('answer2'),
        'profileImage': data.get('profileImage', '')
    })
    
    return jsonify({'success': True, 'message': 'Registration successful!'}), 200


# ==================== 2. 登录接口 ====================
@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    
    if not username or not password:
        return jsonify({'success': False, 'message': 'Username and password are required!'}), 400
    
    user = users_collection.find_one({'username': username})
    
    if not user:
        return jsonify({'success': False, 'message': 'User not found!'}), 404
    
    if user.get('password') != password:
        return jsonify({'success': False, 'message': 'Incorrect password!'}), 401
    
    return jsonify({
        'success': True,
        'message': 'Login successful!',
        'fullName': user.get('fullName'),
        'houseNo': user.get('houseNo'),
        'contactNo': user.get('contactNo')
    }), 200


# ==================== 3. 验证密保问题接口 ====================
@app.route('/api/verify-security', methods=['POST'])
def verify_security():
    data = request.json
    username = data.get('username')
    q1 = data.get('question1')
    a1 = data.get('answer1')
    q2 = data.get('question2')
    a2 = data.get('answer2')
    
    if not username or not q1 or not a1 or not q2 or not a2:
        return jsonify({'success': False, 'message': 'All fields are required!'}), 400
    
    user = users_collection.find_one({'username': username})
    
    if not user:
        return jsonify({'success': False, 'message': 'User not found!'}), 404
    
    stored_q1 = user.get('question1')
    stored_a1 = user.get('answer1')
    stored_q2 = user.get('question2')
    stored_a2 = user.get('answer2')
    
    if stored_q1 == q1 and stored_a1 == a1 and stored_q2 == q2 and stored_a2 == a2:
        return jsonify({'success': True, 'message': 'Verification successful!'}), 200
    else:
        return jsonify({'success': False, 'message': 'Security answers are incorrect!'}), 400


# ==================== 4. 重置密码接口 ====================
@app.route('/api/reset-password', methods=['POST'])
def reset_password():
    data = request.json
    username = data.get('username')
    new_password = data.get('newPassword')
    
    if not username or not new_password:
        return jsonify({'success': False, 'message': 'Username and new password are required!'}), 400
    
    result = users_collection.update_one(
        {'username': username},
        {'$set': {'password': new_password}}
    )
    
    if result.matched_count == 0:
        return jsonify({'success': False, 'message': 'User not found!'}), 404
        
    return jsonify({'success': True, 'message': 'Password reset successful!'}), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)