import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

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
        scaffoldBackgroundColor: const Color(0xFFF8F9FC),
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
    _database = await _initDB('social_media_manager.db');
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
        username TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        a2f INTEGER NOT NULL,
        secret_key TEXT
      )
    ''');
  }

  Future<int> insertAccount(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('accounts', row);
  }

  Future<List<Map<String, dynamic>>> fetchAllAccounts() async {
    final db = await instance.database;
    return await db.query('accounts', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> searchAccounts(String query) async {
    final db = await instance.database;
    return await db.query(
      'accounts',
      where: 'name LIKE ? OR username LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'id DESC',
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await instance.database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
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
    setState(() {
      _accounts = data;
    });
  }

  Future<void> _searchAccounts(String query) async {
    if (query.isEmpty) {
      _refreshAccounts();
      return;
    }
    final data = await DatabaseHelper.instance.searchAccounts(query);
    setState(() {
      _accounts = data;
    });
  }

  IconData _getPlatformIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('instagram')) return Icons.camera_alt;
    if (lowerName.contains('facebook')) return Icons.facebook;
    if (lowerName.contains('x') || lowerName.contains('twitter')) return Icons.close;
    if (lowerName.contains('google')) return Icons.g_mobiledata;
    if (lowerName.contains('tiktok')) return Icons.music_note;
    return Icons.lock;
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
              const Text(
                'Social Media Manager',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kelola semua akun sosial media Anda',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchAccounts,
                  decoration: const InputDecoration(
                    hintText: 'Cari akun...',
                    hintStyle: TextStyle(color: Colors.black38),
                    prefixIcon: Icon(Icons.search, color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // List of Accounts
              Expanded(
                child: _accounts.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada akun yang disimpan',
                          style: TextStyle(color: Colors.black38),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _accounts.length,
                        itemBuilder: (context, index) {
                          final acc = _accounts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: GlassCard(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C4DFF).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_getPlatformIcon(acc['name']), color: const Color(0xFF6C4DFF)),
                                ),
                                title: Text(acc['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(acc['username'], style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (acc['a2f'] == 1)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('A2F', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () async {
                                        await DatabaseHelper.instance.deleteAccount(acc['id']);
                                        _refreshAccounts();
                                      },
                                    ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAccountScreen()),
          );
          if (result == true) {
            _refreshAccounts();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF6C4DFF),
        unselectedItemColor: Colors.black38,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Kategori'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }
}

// --- SCREEN 2: ADD ACCOUNT FORM ---
class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({Key? key}) : super(key: key);

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  bool isA2fEnabled = false;
  bool isPasswordVisible = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _secretKeyController = TextEditingController();

  Future<void> _saveAccount() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final secretKey = _secretKeyController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama, Email, dan Password wajib diisi')),
      );
      return;
    }

    final row = {
      'name': name,
      'username': username.isEmpty ? email : username,
      'email': email,
      'password': password,
      'a2f': isA2fEnabled ? 1 : 0,
      'secret_key': isA2fEnabled ? secretKey : null,
    };

    await DatabaseHelper.instance.insertAccount(row);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tambah Akun', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveAccount,
            child: const Text('Simpan', style: TextStyle(color: Color(0xFF6C4DFF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt, size: 40, color: Color(0xFF6C4DFF)),
                  ),
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFF6C4DFF), shape: BoxShape.circle),
                      child: const Icon(Icons.edit, color: Colors.white, size: 14),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Pilih Ikon', style: TextStyle(color: Colors.black54, fontSize: 12))),
            const SizedBox(height: 32),

            _buildLabel('Nama Akun'),
            _buildTextField(controller: _nameController, hint: 'Instagram'),
            const SizedBox(height: 20),

            _buildLabel('Username'),
            _buildTextField(controller: _usernameController, hint: 'johndoe_99'),
            const SizedBox(height: 20),

            _buildLabel('Email (wajib)'),
            _buildTextField(controller: _emailController, hint: 'johndoe@gmail.com'),
            const SizedBox(height: 20),

            _buildLabel('Password (wajib)'),
            _buildTextField(
              controller: _passwordController,
              hint: '••••••••••••',
              isPassword: true,
              isVisible: isPasswordVisible,
              onVisibilityToggle: () {
                setState(() {
                  isPasswordVisible = !isPasswordVisible;
                });
              },
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('A2F (TOTP) - Opsional', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Switch(
                  value: isA2fEnabled,
                  activeColor: const Color(0xFF6C4DFF),
                  onChanged: (val) {
                    setState(() {
                      isA2fEnabled = val;
                    });
                  },
                ),
              ],
            ),
            if (isA2fEnabled) ...[
              const SizedBox(height: 16),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Scan QR atau masukkan secret key', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C4DFF).withOpacity(0.1),
                                foregroundColor: const Color(0xFF6C4DFF),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.qr_code_scanner, size: 18),
                              label: const Text('Scan QR'),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: const BorderSide(color: Colors.black12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {},
                              child: const Text('Manual Key'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Secret Key (Base32)'),
                      _buildTextField(controller: _secretKeyController, hint: 'JBSWY3DPEHPK3PXP'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C4DFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                onPressed: _saveAccount,
                child: const Text('Simpan Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, bool isPassword = false, bool isVisible = false, VoidCallback? onVisibilityToggle}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black38),
                  onPressed: onVisibilityToggle,
                )
              : null,
        ),
      ),
    );
  }
}

// --- KOMPONEN REUSABLE: GLASS CARD ---
class GlassCard extends StatelessWidget {
  final Widget child;

  const GlassCard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
