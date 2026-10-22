import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'login_page.dart'; // 确保引入了登录页以便精准跳转

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // 控制各项输入
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _contactNoController = TextEditingController();

  final TextEditingController _answer1Controller = TextEditingController();
  final TextEditingController _answer2Controller = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false; // 加载状态

  // 头像相关变量
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // 选择头像方法
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 5个密保问题选项
  final List<String> _allQuestions = [
    'What is your mother\'s maiden name?',
    'What was the name of your first pet?',
    'What was your first car?',
    'What elementary school did you attend?',
    'In what city were you born?',
  ];

  // 记录用户选择的两个问题
  String? _selectedQuestion1;
  String? _selectedQuestion2;

  // 异步提交注册请求到 Flask 后端
  Future<void> _handleRegister() async {
    // 基础前端校验
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 如果上传了头像，可以将其转换为 Base64 字符串传给后端
      String base64Image = '';
      if (_imageFile != null) {
        List<int> imageBytes = await _imageFile!.readAsBytes();
        base64Image = base64Encode(imageBytes);
      }

<<<<<<< Updated upstream:SImeDarby/simedarby_hackathon/lib/Frontend/register_page.dart
      // 注意：如果是 Android 模拟器，请用 'http://10.0.2.2:5000/api/register'
      final url = Uri.parse('http://10.0.2.2:5000/api/register');
=======
      final url = Uri.parse('$apiBaseUrl/api/register');
>>>>>>> Stashed changes:lib/auth/register_page.dart

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
          'fullName': _nameController.text.trim(),
          'houseNo': _houseNoController.text.trim(),
          'contactNo': _contactNoController.text.trim(),
          'question1': _selectedQuestion1 ?? '',
          'answer1': _answer1Controller.text.trim(),
          'question2': _selectedQuestion2 ?? '',
          'answer2': _answer2Controller.text.trim(),
          'profileImage': base64Image, // 传给后端的头像数据
        }),
      );

      Map<String, dynamic> responseData = {};
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {}

      if (response.statusCode == 200) {
        if (!mounted) return;

        // 弹出成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: Color(0xFF2C6B56),
          ),
        );

        // 成功后使用路由跳转回登录页并清空堆栈
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Registration failed'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: Color(0xFF0F382B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE2EBE5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F382B)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F0EC), Color(0xFFD4E4DC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F382B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- 头像选择区域 ---
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleImageOrPlaceholder(_imageFile),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2C6B56),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Username
                    _buildTextField(
                      _usernameController,
                      'Username',
                      Icons.person,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Color(0xFF0F382B)),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Color(0xFF2C6B56),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black45,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF2F6F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF2C6B56),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    _buildTextField(_nameController, 'Full Name', Icons.badge),
                    const SizedBox(height: 16),

                    // House No.
                    _buildTextField(
                      _houseNoController,
                      'House No.',
                      Icons.home,
                    ),
                    const SizedBox(height: 16),

                    // Contact No.
                    _buildTextField(
                      _contactNoController,
                      'Contact No.',
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // --- 密保问题部分 ---
                    const Text(
                      'Security Questions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F382B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '(For forgot password purpose)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 问题 1 下拉框
                    _buildQuestionDropdown(
                      label: 'Security Question 1',
                      value: _selectedQuestion1,
                      items: _allQuestions
                          .where((q) => q != _selectedQuestion2)
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedQuestion1 = val;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      _answer1Controller,
                      'Answer for Question 1',
                      Icons.question_answer,
                    ),
                    const SizedBox(height: 16),

                    // 问题 2 下拉框
                    _buildQuestionDropdown(
                      label: 'Security Question 2',
                      value: _selectedQuestion2,
                      items: _allQuestions
                          .where((q) => q != _selectedQuestion1)
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedQuestion2 = val;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      _answer2Controller,
                      'Answer for Question 2',
                      Icons.question_answer,
                    ),
                    const SizedBox(height: 30),

                    // Register 按钮
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F382B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 辅助组件：显示选中的头像或默认占位图
  Widget CircleImageOrPlaceholder(File? imageFile) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF2F6F4),
        border: Border.all(color: const Color(0xFF2C6B56), width: 2),
        image: imageFile != null
            ? DecorationImage(image: FileImage(imageFile), fit: BoxFit.cover)
            : null,
      ),
      child: imageFile == null
          ? const Icon(Icons.person, size: 50, color: Color(0xFF0F382B))
          : null,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF0F382B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: const Color(0xFF2C6B56)),
        filled: true,
        fillColor: const Color(0xFFF2F6F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2C6B56), width: 2),
        ),
      ),
    );
  }

  Widget _buildQuestionDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<String>(
        value: value, // 修复初始值属性名为 value
        hint: Text(label, style: const TextStyle(color: Colors.black54)),
        dropdownColor: const Color(0xFFE8F0EC),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2C6B56)),
        style: const TextStyle(color: Color(0xFF0F382B)),
        decoration: const InputDecoration(border: InputBorder.none),
        items: items.map((String question) {
          return DropdownMenuItem<String>(
            value: question,
            child: Text(
              question,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F382B)),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
