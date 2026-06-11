import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:otp/otp.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const SocialMediaManagerApp());
}

class SocialMediaManagerApp extends StatelessWidget {
  const SocialMediaManagerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Media Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9), // Latar belakang abu-abu sangat lembut
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C4DFF),
          primary: const Color(0xFF6C4DFF),
        ),
        fontFamily: 'Roboto',
      ),
      home: const DashboardScreen(),
    );
  }
}

// --- DATABASE HELPER ---
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('social_media_manager_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        identifier TEXT NOT NULL,
        password TEXT NOT NULL,
        a2f INTEGER NOT NULL,
        secret_key TEXT,
        updated_at TEXT,
        custom_icon_path TEXT,
        dob TEXT,
        account_year TEXT
      )
    ''');
  }

  Future<int> insertAccount(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('accounts', row);
  }

  Future<int> updateAccount(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('accounts', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> fetchAllAccounts() async {
    final db = await instance.database;
    return await db.query('accounts', orderBy: 'updated_at DESC');
  }

  Future<List<Map<String, dynamic>>> searchAccounts(String query) async {
    final db = await instance.database;
    return await db.query(
      'accounts',
      where: 'name LIKE ? OR identifier LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await instance.database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }
}

// --- KOMPONEN REUSABLE: SECTION CARD ---
class SectionCard extends StatelessWidget {
  final Widget child;
  final String? title;

  const SectionCard({Key? key, required this.child, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.black.withOpacity(0.03)),
          ),
          child: child,
        ),
      ],
    );
  }
}

// --- SCREEN 1: DASHBOARD ---
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _accounts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshAccounts();
  }

  Future<void> _refreshAccounts() async {
    final data = await DatabaseHelper.instance.fetchAllAccounts();
    if (mounted) setState(() { _accounts = data; });
  }

  Future<void> _searchAccounts(String query) async {
    if (query.isEmpty) {
      _refreshAccounts();
      return;
    }
    final data = await DatabaseHelper.instance.searchAccounts(query);
    if (mounted) setState(() { _accounts = data; });
  }

  IconData _getPlatformIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('instagram')) return Icons.camera_alt;
    if (lowerName.contains('facebook')) return Icons.facebook;
    if (lowerName.contains('x') || lowerName.contains('twitter')) return Icons.close;
    if (lowerName.contains('google')) return Icons.g_mobiledata;
    if (lowerName.contains('tiktok')) return Icons.music_note;
    if (lowerName.contains('linkedin')) return Icons.work;
    if (lowerName.contains('github')) return Icons.code;
    if (lowerName.contains('discord')) return Icons.chat_bubble;
    if (lowerName.contains('reddit')) return Icons.forum;
    if (lowerName.contains('pinterest')) return Icons.push_pin;
    return Icons.lock;
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Tidak diketahui';
    final date = DateTime.parse(isoString);
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text('Social Media Manager', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              const Text('Kelola semua akun sosial media Anda', style: TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: Colors.black.withOpacity(0.02)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchAccounts,
                  decoration: const InputDecoration(
                    hintText: 'Cari platform atau username...',
                    hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _accounts.isEmpty
                    ? const Center(child: Text('Belum ada akun yang disimpan', style: TextStyle(color: Colors.black38)))
                    : ListView.builder(
                        itemCount: _accounts.length,
                        itemBuilder: (context, index) {
                          final acc = _accounts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AccountDetailScreen(account: acc)));
                                if (result == true) _refreshAccounts();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.black.withOpacity(0.02)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6C4DFF).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: acc['custom_icon_path'] != null && acc['custom_icon_path'].toString().isNotEmpty
                                          ? Image.file(File(acc['custom_icon_path']), fit: BoxFit.cover)
                                          : Icon(_getPlatformIcon(acc['name']), color: const Color(0xFF6C4DFF), size: 26),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(acc['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87)),
                                          const SizedBox(height: 4),
                                          Text(acc['identifier'], style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 6),
                                          Text('Diperbarui: ${_formatDate(acc['updated_at'])}', style: const TextStyle(color: Colors.black38, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    if (acc['a2f'] == 1)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('A2F', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w800)),
                                      ),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.black12, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C4DFF),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountFormScreen()));
          if (result == true) _refreshAccounts();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// --- SCREEN 2: ADD / EDIT ACCOUNT FORM ---
class AccountFormScreen extends StatefulWidget {
  final Map<String, dynamic>? account;
  const AccountFormScreen({Key? key, this.account}) : super(key: key);

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  bool isA2fEnabled = false;
  bool isPasswordVisible = false;
  String? customIconPath;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _secretKeyController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!['name'];
      _identifierController.text = widget.account!['identifier'];
      _passwordController.text = widget.account!['password'];
      isA2fEnabled = widget.account!['a2f'] == 1;
      _secretKeyController.text = widget.account!['secret_key'] ?? '';
      customIconPath = widget.account!['custom_icon_path'];
      _dobController.text = widget.account!['dob'] ?? '';
      _yearController.text = widget.account!['account_year'] ?? '';
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() { customIconPath = image.path; });
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF6C4DFF), onPrimary: Colors.white, onSurface: Colors.black87),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() { _dobController.text = DateFormat('yyyy-MM-dd').format(picked); });
  }

  Future<void> _saveAccount() async {
    final name = _nameController.text.trim();
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();
    String secretKey = _secretKeyController.text.trim().replaceAll(' ', '');

    if (name.isEmpty || identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama, Username/Email, dan Password wajib diisi')));
      return;
    }

    final row = {
      'name': name,
      'identifier': identifier,
      'password': password,
      'a2f': isA2fEnabled ? 1 : 0,
      'secret_key': isA2fEnabled ? secretKey : null,
      'updated_at': DateTime.now().toIso8601String(),
      'custom_icon_path': customIconPath,
      'dob': _dobController.text.trim(),
      'account_year': _yearController.text.trim(),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(isEdit ? 'Edit Akun' : 'Tambah Akun', style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                        border: Border.all(color: Colors.black.withOpacity(0.02)),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: customIconPath != null
                          ? Image.file(File(customIconPath!), fit: BoxFit.cover)
                          : const Icon(Icons.camera_alt_outlined, size: 36, color: Color(0xFF6C4DFF)),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C4DFF),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 14),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            SectionCard(
              title: 'INFORMASI UTAMA',
              child: Column(
                children: [
                  _buildTextField(controller: _nameController, hint: 'Nama Platform (Instagram, Github, dll)'),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _identifierController, hint: 'Username atau Email'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SectionCard(
              title: 'KEAMANAN',
              child: Column(
                children: [
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Password Akun',
                    isPassword: true,
                    isVisible: isPasswordVisible,
                    onVisibilityToggle: () => setState(() { isPasswordVisible = !isPasswordVisible; }),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Aktifkan A2F (TOTP)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                      Switch(
                        value: isA2fEnabled,
                        activeColor: const Color(0xFF6C4DFF),
                        onChanged: (val) => setState(() { isA2fEnabled = val; }),
                      ),
                    ],
                  ),
                  if (isA2fEnabled) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.black12)),
                    _buildTextField(controller: _secretKeyController, hint: 'Masukkan Secret Key (Base32)'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            SectionCard(
              title: 'DATA OPSIONAL',
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(child: _buildTextField(controller: _dobController, hint: 'Tgl Lahir', icon: Icons.calendar_today_outlined)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(controller: _yearController, hint: 'Tahun Akun', keyboardType: TextInputType.number),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C4DFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _saveAccount,
                child: Text(isEdit ? 'Simpan Perubahan' : 'Tambahkan Akun', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, bool isPassword = false, bool isVisible = false, VoidCallback? onVisibilityToggle, IconData? icon, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 14, fontWeight: FontWeight.normal),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: icon != null ? Icon(icon, color: Colors.black38, size: 20) : null,
          suffixIcon: isPassword
              ? IconButton(icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black38, size: 20), onPressed: onVisibilityToggle)
              : null,
        ),
      ),
    );
  }
}

// --- SCREEN 3: ACCOUNT DETAIL ---
class AccountDetailScreen extends StatefulWidget {
  final Map<String, dynamic> account;
  const AccountDetailScreen({Key? key, required this.account}) : super(key: key);

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  Timer? _timer;
  int _secondsRemaining = 30;
  String _currentTotp = '000000';
  bool _isPasswordVisible = false;
  late Map<String, dynamic> currentAccount;

  @override
  void initState() {
    super.initState();
    currentAccount = widget.account;
    _checkA2f();
  }

  void _checkA2f() {
    if (currentAccount['a2f'] == 1 && currentAccount['secret_key'] != null) {
      _generateTotp();
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateTotp() {
    try {
      final String code = OTP.generateTOTPCodeString(currentAccount['secret_key'], DateTime.now().millisecondsSinceEpoch, length: 6, interval: 30, algorithm: Algorithm.SHA1, isGoogle: true);
      if (mounted) setState(() { _currentTotp = code; });
    } catch (e) {
      if (mounted) setState(() { _currentTotp = 'ERROR'; });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          int epochSeconds = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
          _secondsRemaining = 30 - (epochSeconds % 30);
          if (_secondsRemaining == 30) _generateTotp();
        });
      }
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label berhasil disalin', style: const TextStyle(fontWeight: FontWeight.w500))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20), onPressed: () => Navigator.pop(context, true)),
        title: Text(currentAccount['name'], style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF6C4DFF)),
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AccountFormScreen(account: currentAccount)));
              if (result == true) {
                final updatedData = await DatabaseHelper.instance.fetchAllAccounts();
                final updatedAccount = updatedData.firstWhere((element) => element['id'] == currentAccount['id']);
                setState(() {
                  currentAccount = updatedAccount;
                  _checkA2f();
                });
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              title: 'KREDENSIAL UTAMA',
              child: Column(
                children: [
                  _buildDetailRow('Username / Email', currentAccount['identifier']),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.black12)),
                  _buildPasswordRow('Password', currentAccount['password']),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (currentAccount['dob'] != null && currentAccount['dob'].toString().isNotEmpty || 
                currentAccount['account_year'] != null && currentAccount['account_year'].toString().isNotEmpty) ...[
              SectionCard(
                title: 'INFORMASI TAMBAHAN',
                child: Column(
                  children: [
                    if (currentAccount['dob'] != null && currentAccount['dob'].toString().isNotEmpty) ...[
                      _buildDetailRow('Tanggal Lahir', currentAccount['dob']),
                    ],
                    if (currentAccount['account_year'] != null && currentAccount['account_year'].toString().isNotEmpty) ...[
                      if (currentAccount['dob'] != null && currentAccount['dob'].toString().isNotEmpty)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.black12)),
                      _buildDetailRow('Tahun Pembuatan Akun', currentAccount['account_year']),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (currentAccount['a2f'] == 1) ...[
              SectionCard(
                title: 'KODE AUTENTIKASI',
                child: Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 70,
                            height: 70,
                            child: CircularProgressIndicator(
                              value: _secondsRemaining / 30,
                              strokeWidth: 5,
                              backgroundColor: Colors.black.withOpacity(0.04),
                              color: const Color(0xFF6C4DFF),
                            ),
                          ),
                          Text('${_secondsRemaining}s', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6C4DFF), fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _currentTotp.padLeft(6, '0').replaceAllMapped(RegExp(r".{3}"), (match) => "${match.group(0)} "),
                        style: const TextStyle(fontSize: 42, letterSpacing: 6, fontWeight: FontWeight.w800, color: Color(0xFF6C4DFF)),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6C4DFF),
                          side: const BorderSide(color: Color(0xFF6C4DFF), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Salin Token', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _copyToClipboard(_currentTotp, 'Token'),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF0F0),
                  foregroundColor: const Color(0xFFE53935),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus Akun secara Permanen', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await DatabaseHelper.instance.deleteAccount(currentAccount['id']);
                  if (mounted) Navigator.pop(context, true);
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.black38),
          onPressed: () => _copyToClipboard(value, label),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        )
      ],
    );
  }

  Widget _buildPasswordRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                _isPasswordVisible ? value : '••••••••••••',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, size: 20, color: Colors.black38),
              onPressed: () => setState(() { _isPasswordVisible = !_isPasswordVisible; }),
              padding: const EdgeInsets.only(right: 12),
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.black38),
              onPressed: () => _copyToClipboard(value, label),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        )
      ],
    );
  }
}
