import '../api_config.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'resetpass_page.dart'; // 确保导入了重置密码页面

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _answer1Controller = TextEditingController();
  final TextEditingController _answer2Controller = TextEditingController();

  bool _isLoading = false;

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

  // 验证密保的请求方法
  Future<void> _handleVerifySecurity() async {
    final String username = _usernameController.text.trim();
    final String answer1 = _answer1Controller.text.trim();
    final String answer2 = _answer2Controller.text.trim();

    if (username.isEmpty ||
        _selectedQuestion1 == null ||
        answer1.isEmpty ||
        _selectedQuestion2 == null ||
        answer2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$apiBaseUrl/api/verify-security');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'question1': _selectedQuestion1,
          'answer1': answer1,
          'question2': _selectedQuestion2,
          'answer2': answer2,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Verification successful!'),
          ),
        );

        // 验证通过，跳转去重置新密码页面，并把 username 传过去
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(username: username),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Verification failed!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Connection error: $e')));
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
          'Forgot Password',
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
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Reset Password",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F382B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        "Please verify your identity using your security questions.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Username 输入框
                    _buildTextField(
                      _usernameController,
                      'Username',
                      Icons.person,
                    ),
                    const SizedBox(height: 24),

                    // Security Questions 标题提示
                    const Text(
                      'Security Questions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F382B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '(For forgot password purpose)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 第一个密保问题下拉框
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
                    const SizedBox(height: 18),

                    // 第二个密保问题下拉框
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

                    // 验证并下一步按钮
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
                        onPressed: _isLoading ? null : _handleVerifySecurity,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Verify & Next',
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
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
        value: value, // ✨ 修复：改成了正确的 value 属性
        hint: Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
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
