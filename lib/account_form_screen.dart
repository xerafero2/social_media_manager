import 'dart:io';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';

class AccountFormScreen extends StatefulWidget {
  final Map<String, dynamic>? account;
  const AccountFormScreen({Key? key, this.account}) : super(key: key);

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  bool isA2fEnabled = false;
  bool isPasswordVisible = false;
  String? selectedIconPath;
  String? selectedAvatarPath;
  String? createdAt;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _secretKeyController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  final List<String> _builtInIcons = [
    'assets/icons/facebook.png',
    'assets/icons/instagram.png',
    'assets/icons/google.png',
    'assets/icons/x.png',
    'assets/icons/tiktok.png',
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!['name'] ?? '';
      _identifierController.text = widget.account!['identifier'];
      _passwordController.text = widget.account!['password'];
      isA2fEnabled = widget.account!['a2f'] == 1;
      _secretKeyController.text = widget.account!['secret_key'] ?? '';
      _dobController.text = widget.account!['dob'] ?? '';
      _yearController.text = widget.account!['account_year'] ?? '';
      _tagsController.text = widget.account!['tags'] ?? '';
      selectedIconPath = widget.account!['custom_icon_path'];
      selectedAvatarPath = widget.account!['avatar_path'];
      createdAt = widget.account!['created_at'];
    }
  }

  Future<void> _pickImage(bool isAvatar) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isAvatar) {
          selectedAvatarPath = image.path;
        } else {
          selectedIconPath = image.path;
        }
      });
    }
  }

  Future<void> _saveAccount() async {
    final name = _nameController.text.trim();
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();
    String secretKey = _secretKeyController.text.trim().replaceAll(' ', '');

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username/Email dan Password wajib diisi')));
      return;
    }

    if (isA2fEnabled) {
      if (secretKey.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal: Secret Key tidak boleh kosong saat A2F aktif!')));
        return;
      }
      try {
        OTP.generateTOTPCodeString(secretKey, DateTime.now().millisecondsSinceEpoch, algorithm: Algorithm.SHA1, isGoogle: true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal: Secret Key 2FA tidak valid!')));
        return;
      }
    }

    final nowIso = DateTime.now().toIso8601String();
    final row = {
      'name': name,
      'identifier': identifier,
      'password': password,
      'a2f': isA2fEnabled ? 1 : 0,
      'secret_key': isA2fEnabled ? secretKey : null,
      'created_at': createdAt ?? nowIso,
      'updated_at': nowIso,
      'custom_icon_path': selectedIconPath,
      'avatar_path': selectedAvatarPath,
      'dob': _dobController.text.trim(),
      'account_year': _yearController.text.trim(),
      'tags': _tagsController.text.trim(),
    };

    if (widget.account == null) {
      await DatabaseHelper.instance.insertAccount(row);
    } else {
      row['id'] = widget.account!['id'];
      await DatabaseHelper.instance.updateAccount(row);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.account != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.close, color: Colors.black87), onPressed: () => Navigator.pop(context)),
          title: Text(isEdit ? 'Edit Akun' : 'Tambah Akun', style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700)),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _saveAccount,
                child: Text('Simpan', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: selectedIconPath != null && selectedIconPath!.isNotEmpty
                      ? (selectedIconPath!.startsWith('assets/') ? Image.asset(selectedIconPath!, fit: BoxFit.cover) : Image.file(File(selectedIconPath!), fit: BoxFit.cover))
                      : Icon(Icons.public, size: 36, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: () => _pickImage(false),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 50,
                        decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                        child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.black54),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() { selectedIconPath = null; }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selectedIconPath == null ? Theme.of(context).colorScheme.primary : Colors.black12, width: selectedIconPath == null ? 2 : 1),
                        ),
                        child: const Icon(Icons.public, color: Colors.black54, size: 24),
                      ),
                    ),
                    ..._builtInIcons.map((path) => GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIconPath = path;
                          String platformName = path.split('/').last.split('.').first;
                          platformName = platformName == 'x' ? 'X (Twitter)' : platformName[0].toUpperCase() + platformName.substring(1);
                          _nameController.text = platformName;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(6),
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selectedIconPath == path ? Theme.of(context).colorScheme.primary : Colors.black12, width: selectedIconPath == path ? 2 : 1),
                        ),
                        child: Image.asset(path),
                      ),
                    )).toList()
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(controller: _nameController, hint: 'Singkatan / Platform (Opsional)', icon: Icons.public),
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), shape: BoxShape.circle, border: Border.all(color: Colors.black12)),
                      clipBehavior: Clip.hardEdge,
                      child: selectedAvatarPath != null
                          ? Image.file(File(selectedAvatarPath!), fit: BoxFit.cover)
                          : const Icon(Icons.add_a_photo_outlined, color: Colors.black38, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(controller: _identifierController, hint: 'Email atau Username')),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                hint: 'Password Akun',
                icon: Icons.lock_outline,
                isPassword: true,
                isVisible: isPasswordVisible,
                onVisibilityToggle: () => setState(() { isPasswordVisible = !isPasswordVisible; }),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildTextField(controller: _dobController, hint: 'Tgl Lahir')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(controller: _yearController, hint: 'Tahun Buat', keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(controller: _tagsController, hint: 'Kategori / Game (pisahkan koma)', icon: Icons.sports_esports_outlined),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.05))),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Aktifkan 2-Factor Code', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        Switch(value: isA2fEnabled, activeColor: Theme.of(context).colorScheme.primary, onChanged: (val) => setState(() { isA2fEnabled = val; })),
                      ],
                    ),
                    if (isA2fEnabled) ...[
                      const Divider(height: 24),
                      _buildTextField(controller: _secretKeyController, hint: 'Masukkan Secret Key Base32'),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, IconData? icon, bool isPassword = false, bool isVisible = false, VoidCallback? onVisibilityToggle, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.1))),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: icon != null ? Icon(icon, color: Colors.black38, size: 20) : null,
          suffixIcon: isPassword
              ? IconButton(icon: Icon(isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.black38, size: 20), onPressed: onVisibilityToggle)
              : null,
        ),
      ),
    );
  }
}
