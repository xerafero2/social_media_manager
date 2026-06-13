import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:otp/otp.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const AccountManagerApp());
}

class AccountManagerApp extends StatelessWidget {
  const AccountManagerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AccountManager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1D3B),
          primary: const Color(0xFF1A1D3B),
          secondary: const Color(0xFFFF9F43),
          surface: Colors.white,
        ),
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1D3B)),
          bodyLarge: TextStyle(color: Color(0xFF2D3047)),
          bodyMedium: TextStyle(color: Color(0xFF5D6072)),
          labelLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFF9F43),
          foregroundColor: Colors.white,
          elevation: 12,
          shape: CircleBorder(),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

// ===================== DATABASE =====================
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('account_manager_premium.db');
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
        created_at TEXT,
        updated_at TEXT,
        custom_icon_path TEXT,
        dob TEXT,
        account_year TEXT,
        tags TEXT
      )
    ''');
  }

  Future<int> insertAccount(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('accounts', row);
  }

  Future<int> updateAccount(Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('accounts', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<List<Map<String, dynamic>>> fetchAccounts({
    String query = '',
    String sortOption = 'terbaru',
  }) async {
    final db = await database;
    String orderBy = 'updated_at DESC';
    if (sortOption == 'terlama') {
      orderBy = 'updated_at ASC';
    } else if (sortOption == 'a-z') {
      orderBy = 'name COLLATE NOCASE ASC';
    }

    if (query.isEmpty) {
      return await db.query('accounts', orderBy: orderBy);
    } else {
      return await db.query(
        'accounts',
        where: 'name LIKE ? OR identifier LIKE ? OR tags LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: orderBy,
      );
    }
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }
}

// ===================== DASHBOARD =====================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _accounts = [];
  Timer? _globalTimer;
  int _secondsRemaining = 30;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'terbaru';
  late AnimationController _fadeController;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _refreshAccounts();
    _startGlobalTimer();
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startGlobalTimer() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          int epochSeconds =
              (DateTime.now().millisecondsSinceEpoch / 1000).floor();
          _secondsRemaining = 30 - (epochSeconds % 30);
        });
      }
    });
  }

  Future<void> _refreshAccounts() async {
    final data = await DatabaseHelper.instance.fetchAccounts(
      query: _searchQuery,
      sortOption: _sortOption,
    );
    if (mounted) setState(() => _accounts = data);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: 160,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildPremiumHeader(),
              ),
            ),
          ],
          body: _accounts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 64,
                            color: const Color(0xFF1A1D3B).withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Belum ada akun yang disimpan'
                              : 'Tidak ada hasil untuk "$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF1A1D3B).withOpacity(0.4),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeController,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: _accounts.length,
                    itemBuilder: (context, index) {
                      final acc = _accounts[index];
                      return AccountCard(
                        key: ValueKey(
                            'card_${acc['id']}_${acc['updated_at']}'),
                        account: acc,
                        secondsRemaining: _secondsRemaining,
                        onRefresh: _refreshAccounts,
                      );
                    },
                  ),
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const AccountFormScreen(),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
            if (result == true) _refreshAccounts();
          },
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1D3B), Color(0xFF2A2D4A)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.security, color: Color(0xFFFF9F43), size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'AccountManager',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.vpn_key_rounded,
                            color: Color(0xFFFF9F43), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${_accounts.length} akun',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Search & Sort Row
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            _searchQuery = value;
                            _refreshAccounts();
                          },
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Cari platform, username, atau tag...',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: Icon(Icons.search,
                                color: Colors.grey.shade400, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 2,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.sort_rounded,
                            color: Color(0xFFFF9F43)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        onSelected: (value) {
                          setState(() => _sortOption = value);
                          _refreshAccounts();
                        },
                        itemBuilder: (_) => [
                          _buildSortItem(
                              'terbaru', 'Terbaru', Icons.access_time),
                          _buildSortItem(
                              'terlama', 'Terlama', Icons.history),
                          _buildSortItem(
                              'a-z', 'A-Z', Icons.sort_by_alpha),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(
      String value, String label, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: _sortOption == value
                  ? const Color(0xFFFF9F43)
                  : Colors.grey),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontWeight:
                      _sortOption == value ? FontWeight.bold : FontWeight.w500,
                  color: _sortOption == value
                      ? const Color(0xFFFF9F43)
                      : Colors.black87)),
        ],
      ),
    );
  }
}

// ===================== ACCOUNT CARD =====================
class AccountCard extends StatefulWidget {
  final Map<String, dynamic> account;
  final int secondsRemaining;
  final VoidCallback onRefresh;

  const AccountCard({
    Key? key,
    required this.account,
    required this.secondsRemaining,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard>
    with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin',
            style: const TextStyle(fontWeight: FontWeight.w500)),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF1A1D3B),
      ),
    );
  }

  String _getTotp() {
    try {
      return OTP.generateTOTPCodeString(
        widget.account['secret_key'],
        DateTime.now().millisecondsSinceEpoch,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
    } catch (e) {
      return 'ERROR ';
    }
  }

  String _relativeTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Tidak diketahui';
    final date = DateTime.tryParse(isoString);
    if (date == null) return 'Tidak diketahui';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd/MM/yy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.account;
    final List<String> tags = (acc['tags'] ?? '')
        .toString()
        .split(',')
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return SizeTransition(
      sizeFactor: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1D3B).withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF1A1D3B).withOpacity(0.03),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            splashColor: const Color(0xFFFF9F43).withOpacity(0.1),
            onTap: () async {
              final result = await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                      AccountFormScreen(account: acc),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
              if (result == true) widget.onRefresh();
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Row(
                    children: [
                      _buildPlatformAvatar(acc['name'], acc['custom_icon_path']),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1D3B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              acc['identifier'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (acc['account_year'] != null &&
                          acc['account_year'].toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9F43), Color(0xFFFF6B6B)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            acc['account_year'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Password Row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _isPasswordVisible
                                  ? acc['password']
                                  : '••••••••',
                              key: ValueKey(_isPasswordVisible),
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'monospace',
                                letterSpacing: _isPasswordVisible ? 0 : 2,
                                color: const Color(0xFF1A1D3B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        _buildCircleButton(
                          icon: _isPasswordVisible
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          onTap: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        const SizedBox(width: 8),
                        _buildCircleButton(
                          icon: Icons.copy_rounded,
                          onTap: () =>
                              _copyToClipboard(acc['password'], 'Password'),
                        ),
                      ],
                    ),
                  ),
                  // DOB & Tags
                  if ((acc['dob'] != null &&
                          acc['dob'].toString().isNotEmpty) ||
                      tags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (acc['dob'] != null &&
                            acc['dob'].toString().isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.cake_rounded,
                                size: 16, color: Color(0xFFFF9F43)),
                            label: Text(acc['dob'],
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            backgroundColor:
                                const Color(0xFFFF9F43).withOpacity(0.1),
                            side: BorderSide.none,
                          ),
                        ...tags.map((tag) => Chip(
                              label: Text(tag.trim(),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              backgroundColor:
                                  const Color(0xFF1A1D3B).withOpacity(0.05),
                              side: BorderSide.none,
                            )),
                      ],
                    ),
                  ],
                  // 2FA Section
                  if (acc['a2f'] == 1 && acc['secret_key'] != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF9F43).withOpacity(0.05),
                            const Color(0xFFFF6B6B).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFF9F43).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'KODE 2-FACTOR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF5D6072),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _getTotp(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1D3B),
                                    letterSpacing: 4,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: widget.secondsRemaining / 30,
                                    backgroundColor: Colors.grey.shade200,
                                    color: const Color(0xFFFF9F43),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildCircleButton(
                            icon: Icons.copy_rounded,
                            onTap: () => _copyToClipboard(
                                _getTotp().replaceAll(' ', ''),
                                'Token 2FA'),
                            size: 44,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Bottom actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Diperbarui ${_relativeTime(acc['updated_at'])}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Row(
                        children: [
                          _buildCircleButton(
                            icon: Icons.edit_rounded,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) =>
                                      AccountFormScreen(account: acc),
                                  transitionsBuilder:
                                      (_, animation, __, child) {
                                    return FadeTransition(
                                        opacity: animation, child: child);
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                ),
                              );
                              if (result == true) widget.onRefresh();
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildCircleButton(
                            icon: Icons.delete_rounded,
                            color: const Color(0xFFE11D48),
                            bgColor: const Color(0xFFFFE4E6),
                            onTap: () async {
                              await DatabaseHelper.instance
                                  .deleteAccount(acc['id']);
                              widget.onRefresh();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = const Color(0xFF1A1D3B),
    Color bgColor = const Color(0xFFF5F6FA),
    double size = 36,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: color, size: size * 0.55),
        ),
      ),
    );
  }

  Widget _buildPlatformAvatar(String name, String? iconPath) {
    if (iconPath != null && iconPath.isNotEmpty) {
      if (iconPath.startsWith('assets/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(iconPath, width: 42, height: 42, fit: BoxFit.cover),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(iconPath), width: 42, height: 42, fit: BoxFit.cover),
        );
      }
    }
    // Fallback: lingkaran dengan huruf pertama
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1D3B), Color(0xFF2A2D4A)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

// ===================== FORM =====================
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
  String? createdAt;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _secretKeyController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      final acc = widget.account!;
      _nameController.text = acc['name'];
      _identifierController.text = acc['identifier'];
      _passwordController.text = acc['password'];
      isA2fEnabled = acc['a2f'] == 1;
      _secretKeyController.text = acc['secret_key'] ?? '';
      _dobController.text = acc['dob'] ?? '';
      _yearController.text = acc['account_year'] ?? '';
      _tagsController.text = acc['tags'] ?? '';
      selectedIconPath = acc['custom_icon_path'];
      createdAt = acc['created_at'];
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => selectedIconPath = image.path);
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();
    String secretKey = _secretKeyController.text.trim().replaceAll(' ', '');

    // Validasi khusus 2FA
    if (isA2fEnabled && secretKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Secret Key wajib diisi saat 2FA aktif'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Akun' : 'Tambah Akun',
          style: const TextStyle(
              color: Color(0xFF1A1D3B),
              fontWeight: FontWeight.w700,
              fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1D3B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            children: [
              // Icon selector
              _buildIconSelector(),
              const SizedBox(height: 28),
              _buildTextField(
                controller: _nameController,
                hint: 'Platform (contoh: Facebook)',
                icon: Icons.public_rounded,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Nama platform wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _identifierController,
                hint: 'Email atau Username',
                icon: Icons.person_outline_rounded,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Identifier wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                isVisible: isPasswordVisible,
                onVisibilityToggle: () =>
                    setState(() => isPasswordVisible = !isPasswordVisible),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Password wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _dobController,
                      hint: 'Tanggal Lahir (10 Okt 1980)',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _yearController,
                      hint: 'Tahun Akun',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _tagsController,
                hint: 'Tag (pisahkan dengan koma)',
                icon: Icons.sell_outlined,
              ),
              const SizedBox(height: 24),
              // 2FA toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Aktifkan 2-Factor Code',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1D3B),
                          ),
                        ),
                        Switch(
                          value: isA2fEnabled,
                          activeColor: const Color(0xFFFF9F43),
                          onChanged: (val) =>
                              setState(() => isA2fEnabled = val),
                        ),
                      ],
                    ),
                    if (isA2fEnabled) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _secretKeyController,
                        hint: 'Secret Key Base32',
                        icon: Icons.vpn_key_rounded,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Secret key tidak boleh kosong'
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9F43),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: const Color(0xFFFF9F43).withOpacity(0.4),
                  ),
                  onPressed: _saveAccount,
                  child: Text(
                    isEdit ? 'Simpan Perubahan' : 'Tambah Akun Baru',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconSelector() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1D3B).withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                    color: const Color(0xFF1A1D3B).withOpacity(0.05)),
              ),
              child: selectedIconPath != null && selectedIconPath!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: selectedIconPath!.startsWith('assets/')
                          ? Image.asset(selectedIconPath!,
                              fit: BoxFit.cover)
                          : Image.file(File(selectedIconPath!),
                              fit: BoxFit.cover),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined,
                      size: 36, color: Color(0xFF5D6072)),
            ),
          ),
          if (selectedIconPath != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(() => selectedIconPath = null),
              icon: const Icon(Icons.close, size: 16, color: Color(0xFFE11D48)),
              label: const Text('Hapus ikon',
                  style: TextStyle(
                      color: Color(0xFFE11D48),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1D3B)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF5D6072), size: 20)
            : null,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: const Color(0xFF5D6072),
                  size: 20,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF9F43), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
