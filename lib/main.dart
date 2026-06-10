import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:otp/otp.dart';

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
    _database = await _initDB('social_media_manager_v2.db'); // Menggunakan DB baru
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
      where: 'name LIKE ? OR identifier LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
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
    if (mounted) {
      setState(() {
        _accounts = data;
      });
    }
  }

  Future<void> _searchAccounts(String query) async {
    if (query.isEmpty) {
      _refreshAccounts();
      return;
    }
    final data = await DatabaseHelper.instance.searchAccounts(query);
    if (mounted) {
      setState(() {
        _accounts = data;
      });
    }
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
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => AccountDetailScreen(account: acc)),
                                );
                                if (result == true) {
                                  _refreshAccounts();
                                }
                              },
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
                                  subtitle: Text(acc['identifier'], style: const TextStyle(color: Colors.black54, fontSize: 13)),
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
                                      const Icon(Icons.chevron_right, color: Colors.black26),
                                    ],
                                  ),
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
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _secretKeyController = TextEditingController();

  Future<void> _saveAccount() async {
    final name = _nameController.text.trim();
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();
    String secretKey = _secretKeyController.text.trim().replaceAll(' ', '');

    if (name.isEmpty || identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama, Username/Email, dan Password wajib diisi')),
      );
      return;
    }

    if (isA2fEnabled && secretKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Secret Key wajib diisi jika A2F aktif')),
      );
      return;
    }

    final row = {
      'name': name,
      'identifier': identifier,
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
            _buildLabel('Nama Akun (Platform)'),
            _buildTextField(controller: _nameController, hint: 'Contoh: Instagram'),
            const SizedBox(height: 20),

            _buildLabel('Username / Email'),
            _buildTextField(controller: _identifierController, hint: 'johndoe_99 atau email@domain.com'),
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
                      const Text('Masukkan Secret Key untuk menghasilkan kode', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 16),
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

// --- SCREEN 3: ACCOUNT DETAIL & TOTP GENERATOR ---
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

  @override
  void initState() {
    super.initState();
    if (widget.account['a2f'] == 1 && widget.account['secret_key'] != null) {
      _generateTotp();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateTotp() {
    try {
      final String code = OTP.generateTOTPCodeString(
        widget.account['secret_key'],
        DateTime.now().millisecondsSinceEpoch,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      if (mounted) {
        setState(() {
          _currentTotp = code;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentTotp = 'ERROR';
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          int epochSeconds = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
          _secondsRemaining = 30 - (epochSeconds % 30);
          if (_secondsRemaining == 30) {
            _generateTotp();
          }
        });
      }
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label berhasil disalin')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.account;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(acc['name'], style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detail Kredensial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    _buildDetailRow('Username / Email', acc['identifier']),
                    const Divider(height: 30),
                    _buildPasswordRow('Password', acc['password']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (acc['a2f'] == 1) ...[
              const Text('Autentikasi Dua Faktor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 16),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: _secondsRemaining / 30,
                                strokeWidth: 6,
                                backgroundColor: Colors.black.withOpacity(0.05),
                                color: const Color(0xFF6C4DFF),
                              ),
                            ),
                            Text(
                              '${_secondsRemaining}s',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C4DFF), fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _currentTotp.padLeft(6, '0').replaceAllMapped(RegExp(r".{3}"), (match) => "${match.group(0)} "),
                          style: const TextStyle(fontSize: 40, letterSpacing: 4, fontWeight: FontWeight.bold, color: Color(0xFF6C4DFF)),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6C4DFF),
                            side: const BorderSide(color: Color(0xFF6C4DFF)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Salin Token'),
                          onPressed: () => _copyToClipboard(_currentTotp, 'Token'),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus Akun', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await DatabaseHelper.instance.deleteAccount(acc['id']);
                  if (mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20, color: Colors.black38),
          onPressed: () => _copyToClipboard(value, label),
        )
      ],
    );
  }

  Widget _buildPasswordRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(
              _isPasswordVisible ? value : '••••••••••••',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, size: 20, color: Colors.black38),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 20, color: Colors.black38),
              onPressed: () => _copyToClipboard(value, label),
            ),
          ],
        )
      ],
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
