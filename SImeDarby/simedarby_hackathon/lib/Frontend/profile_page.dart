import 'dart:io'; // 用于处理本地图片文件
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 引入选择相册的插件
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String _username = 'Xineak';
  String _name = 'SKX';
  String _contactNo = '+60 12-345 6789';
  String _houseNo = 'House A-12';

  // 存储用户选择的本地头像文件（如果为 null 则显示默认 asset 图片）
  File? _imageFile;
  final String _defaultAvatarPath = 'assets/app_logo.jpg';
  final ImagePicker _picker = ImagePicker();

  // 弹出选择来源（相册 / 相机）并选取图片
  Future<void> _pickImage(StateSetter setDialogState) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery, // 从手机相册中选择
      imageQuality: 80, // 压缩质量
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      // 同时更新弹出框内的状态
      setDialogState(() {});
    }
  }

  // 点击放大头像
  void _showFullAvatar() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: InteractiveViewer(
            child: _imageFile != null
                ? Image.file(_imageFile!, fit: BoxFit.cover)
                : Image.asset(
                    _defaultAvatarPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(40),
                      child: const Icon(
                        Icons.person,
                        size: 100,
                        color: Color(0xFF0F382B),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // 弹窗式 Edit Profile 对话框
  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(
      text: _name,
    );
    final TextEditingController contactController = TextEditingController(
      text: _contactNo,
    );
    final TextEditingController houseController = TextEditingController(
      text: _houseNo,
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.white,
              title: const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Color(0xFF0F382B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 头像及带铅笔的编辑按钮（点击可触发相册选择）
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFFE8F0EC),
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!) as ImageProvider
                              : AssetImage(_defaultAvatarPath),
                        ),
                        InkWell(
                          onTap: () => _pickImage(setDialogState), // 点击直接拉起相册
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F382B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Username (只读)
                    TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Username (Cannot be edited)',
                        labelStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF2F6F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      controller: TextEditingController(text: _username),
                    ),
                    const SizedBox(height: 12),

                    // Name
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Color(0xFF0F382B)),
                      decoration: _dialogInputDecoration(
                        'Full Name',
                        Icons.badge,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Contact No.
                    TextField(
                      controller: contactController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Color(0xFF0F382B)),
                      decoration: _dialogInputDecoration(
                        'Contact No.',
                        Icons.phone,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // House No.
                    TextField(
                      controller: houseController,
                      style: const TextStyle(color: Color(0xFF0F382B)),
                      decoration: _dialogInputDecoration(
                        'House No.',
                        Icons.home,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F382B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _name = nameController.text;
                      _contactNo = contactController.text;
                      _houseNo = houseController.text;
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Update successful!'),
                        backgroundColor: Color(0xFF2C6B56),
                      ),
                    );
                  },
                  child: const Text(
                    'Confirm',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 底部 Log Out 确认框
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(
            color: Color(0xFF0F382B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      prefixIcon: Icon(icon, color: const Color(0xFF2C6B56)),
      filled: true,
      fillColor: const Color(0xFFF2F6F4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2C6B56), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF0F382B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE2EBE5),
        elevation: 0,
        centerTitle: true,
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
                  children: [
                    // 1. 头像（点击放大）
                    Center(
                      child: GestureDetector(
                        onTap: _showFullAvatar,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF2C6B56),
                                  width: 3,
                                ),
                                image: DecorationImage(
                                  image: _imageFile != null
                                      ? FileImage(_imageFile!) as ImageProvider
                                      : AssetImage(_defaultAvatarPath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F382B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.zoom_in,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 名字与用户名
                    Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F382B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$_username',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. 信息展示
                    _buildInfoTile(Icons.person_outline, 'Username', _username),
                    _buildInfoTile(Icons.badge_outlined, 'Full Name', _name),
                    _buildInfoTile(
                      Icons.phone_outlined,
                      'Contact No.',
                      _contactNo,
                    ),
                    _buildInfoTile(Icons.home_outlined, 'House No.', _houseNo),
                    const SizedBox(height: 24),

                    // 3. Edit Profile 按钮
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F382B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _showEditProfileDialog,
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. Log Out 按钮
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _showLogoutDialog,
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.redAccent,
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

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2C6B56), size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F382B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 💡 独立运行预览入口
// ==========================================
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Profile Page Preview',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const ProfilePage(),
    );
  }
}
