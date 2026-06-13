import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'backup_service.dart';
import 'account_form_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.loadTheme();
  runApp(const SocialMediaManagerApp());
}

class SocialMediaManagerApp extends StatelessWidget {
  const SocialMediaManagerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: ThemeManager.appColor,
      builder: (context, color, child) {
        return MaterialApp(
          title: 'AccountManager',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF4F6F9),
            colorScheme: ColorScheme.fromSeed(seedColor: color, primary: color),
            fontFamily: 'Roboto',
          ),
          home: const DashboardScreen(),
        );
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _accounts = [];
  Timer? _globalTimer;
  int _secondsRemaining = 30;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'terbaru';

  @override
  void initState() {
    super.initState();
    _refreshAccounts();
    _startGlobalTimer();
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startGlobalTimer() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          int epochSeconds = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
          _secondsRemaining = 30 - (epochSeconds % 30);
        });
      }
    });
  }

  Future<void> _refreshAccounts() async {
    final data = await DatabaseHelper.instance.fetchAccounts(query: _searchQuery, sortOption: _sortOption);
    if (mounted) setState(() { _accounts = data; });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildCleanHeader(context),
              Expanded(
                child: _accounts.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'Belum ada akun yang disimpan' : 'Tidak ada akun yang cocok',
                          style: const TextStyle(color: Colors.black38, fontWeight: FontWeight.w500),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _accounts.length,
                        itemBuilder: (context, index) {
                          final acc = _accounts[index];
                          return AccountCard(
                            key: ValueKey('card_${acc['id']}_${acc['name']}_${acc['identifier']}_${acc['password']}_${acc['custom_icon_path']}_${acc['avatar_path']}_${acc['tags']}_${acc['updated_at']}'),
                            account: acc,
                            index: index + 1,
                            secondsRemaining: _secondsRemaining,
                            onRefresh: _refreshAccounts,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Akun', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountFormScreen()));
            if (result == true) _refreshAccounts();
          },
        ),
      ),
    );
  }

  Widget _buildCleanHeader(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [themeColor, themeColor.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                ),
                child: const Icon(Icons.security_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AccountManager', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text('${_accounts.length} Akun tersimpan', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF8F9FA), border: Border.all(color: Colors.black.withOpacity(0.05)), borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 22, color: Colors.black87),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                    _refreshAccounts();
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.06))),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _searchQuery = value;
                      _refreshAccounts();
                    },
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      hintText: 'Cari platform, username, atau tag...',
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.black38, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 48,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.1))),
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.tune, color: themeColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  position: PopupMenuPosition.under,
                  onSelected: (value) {
                    setState(() { _sortOption = value; });
                    _refreshAccounts();
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(value: 'terbaru', child: Text('Terbaru Ditambahkan')),
                    PopupMenuItem<String>(value: 'terlama', child: Text('Terlama Ditambahkan')),
                    PopupMenuItem<String>(value: 'a-z', child: Text('Abjad (A - Z)')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _importController = TextEditingController();
  String _importType = 'json';

  final List<Map<String, dynamic>> themes = [
    {'name': 'Biru Profesional', 'color': const Color(0xFF1E40AF)},
    {'name': 'Ungu Modern', 'color': const Color(0xFF6C4DFF)},
    {'name': 'Hijau Emerald', 'color': const Color(0xFF059669)},
    {'name': 'Hitam Elegan', 'color': const Color(0xFF1F2937)},
  ];

  void _triggerFileImport() async {
    bool success = await BackupService.importFromFile();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: success ? Colors.green : Colors.redAccent,
        content: Text(success ? 'Berkas berhasil diimpor ke database lokal!' : 'Gagal: Struktur berkas salah atau rusak!'),
      ));
    }
  }

  void _triggerEncryptedStringImport() async {
    String text = _importController.text.trim();
    if (text.isEmpty) return;
    bool success = await BackupService.importFromEncryptedString(text);
    if (mounted) {
      _importController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: success ? Colors.green : Colors.redAccent,
        content: Text(success ? 'String enkripsi berhasil didekripsi dan disimpan!' : 'Gagal: Kode rusak atau tidak valid!'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan & Backup', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TEMA APLIKASI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: themes.map((t) {
                  bool isSelected = ThemeManager.appColor.value.value == t['color'].value;
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: t['color'], radius: 14),
                    title: Text(t['name'], style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    trailing: isSelected ? Icon(Icons.check_circle, color: t['color']) : null,
                    onTap: () {
                      ThemeManager.setTheme(t['color']);
                      (context as Element).markNeedsBuild();
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),
            const Text('EKSPOR DATA (BACKUP BERKAS / SHARE)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildActionBtn('Ekspor .json (File)', () => BackupService.exportJsonFile()),
                _buildActionBtn('Ekspor raw (File)', () => BackupService.exportRawFile()),
                _buildActionBtn('Ekspor CSV', () => BackupService.exportCsvFile()),
                _buildActionBtn('Salin String Enkripsi', () async {
                  await BackupService.copyEncryptedString();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('String enkripsi berhasil disalin ke clipboard!')));
                }),
              ],
            ),
            const SizedBox(height: 28),
            const Text('IMPOR DATA (RESTORE)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.file_open_outlined),
                      label: const Text('Pilih Berkas (.json / .csv)', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _triggerFileImport,
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.black12)),
                  const Text('Impor via Teks Enkripsi:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: _importController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      decoration: const InputDecoration(hintText: 'Tempelkan string enkripsi di sini...', border: InputBorder.none, contentPadding: EdgeInsets.all(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary, side: BorderSide(color: Theme.of(context).colorScheme.primary), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.vpn_key_outlined),
                      label: const Text('Dekripsi & Impor Teks', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _triggerEncryptedStringImport,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12))),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
}

class AccountCard extends StatefulWidget {
  final Map<String, dynamic> account;
  final int index;
  final int secondsRemaining;
  final VoidCallback onRefresh;

  const AccountCard({Key? key, required this.account, required this.index, required this.secondsRemaining, required this.onRefresh}) : super(key: key);

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  bool _isPasswordVisible = false;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label tersalin'), duration: const Duration(seconds: 1)));
  }

  String _getTotp() {
    try {
      return OTP.generateTOTPCodeString(widget.account['secret_key'], DateTime.now().millisecondsSinceEpoch, length: 6, interval: 30, algorithm: Algorithm.SHA1, isGoogle: true);
    } catch (e) {
      return 'ERROR ';
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Tidak tersedia';
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(isoString));
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.account;
    final List<String> tags = (acc['tags'] ?? '').toString().split(',').where((e) => e.trim().isNotEmpty).toList();
    final String displayName = (acc['name'] == null || acc['name'].toString().trim().isEmpty) ? 'AKUN' : acc['name'].toString().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(0.08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildBadge(widget.index.toString(), isOutline: true),
                if (acc['account_year'] != null && acc['account_year'].toString().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildBadge(acc['account_year'], bgColor: Theme.of(context).colorScheme.primary.withOpacity(0.1), textColor: Theme.of(context).colorScheme.primary),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                  child: Row(
                    children: [
                      if (acc['custom_icon_path'] != null && acc['custom_icon_path'].toString().isNotEmpty)
                        ClipRRect(borderRadius: BorderRadius.circular(4), child: acc['custom_icon_path'].toString().startsWith('assets/') ? Image.asset(acc['custom_icon_path'], width: 16, height: 16, fit: BoxFit.cover) : Image.file(File(acc['custom_icon_path']), width: 16, height: 16, fit: BoxFit.cover))
                      else
                        const Icon(Icons.public, color: Colors.black54, size: 16),
                      const SizedBox(width: 6),
                      Text(displayName, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)),
                  clipBehavior: Clip.hardEdge,
                  child: acc['avatar_path'] != null && acc['avatar_path'].toString().isNotEmpty ? Image.file(File(acc['avatar_path']), fit: BoxFit.cover) : Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(acc['identifier'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87))),
                          IconButton(icon: const Icon(Icons.copy_outlined, size: 18, color: Colors.black54), onPressed: () => _copyToClipboard(acc['identifier'], 'Username/Email'), constraints: const BoxConstraints(), padding: const EdgeInsets.all(4)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black.withOpacity(0.05))),
                        child: Row(
                          children: [
                            Expanded(child: Text(_isPasswordVisible ? acc['password'] : '••••••••', style: const TextStyle(fontSize: 14, fontFamily: 'monospace', letterSpacing: 2, color: Colors.black87))),
                            IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: Colors.black54), onPressed: () => setState(() { _isPasswordVisible = !_isPasswordVisible; }), constraints: const BoxConstraints(), padding: const EdgeInsets.all(8)),
                            IconButton(icon: const Icon(Icons.copy_outlined, size: 18, color: Colors.black54), onPressed: () => _copyToClipboard(acc['password'], 'Password'), constraints: const BoxConstraints(), padding: const EdgeInsets.all(8)),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.black12)),
          if ((acc['dob'] != null && acc['dob'].toString().isNotEmpty) || tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (acc['dob'] != null && acc['dob'].toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cake_outlined, color: Colors.white, size: 14), const SizedBox(width: 6), Text(acc['dob'], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))]),
                    ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [const Icon(Icons.sports_esports_outlined, color: Colors.black45, size: 18), ...tags.map((t) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(6)), child: Text(t.trim(), style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500)))).toList()]),
                  ]
                ],
              ),
            ),
          if (acc['a2f'] == 1 && acc['secret_key'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFF93C5FD), width: 1.5), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('2-FACTOR CODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text(_getTotp(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFDC2626), letterSpacing: 4)),
                          const SizedBox(height: 8),
                          ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: widget.secondsRemaining / 30, backgroundColor: Colors.black12, color: const Color(0xFFDC2626), minHeight: 3))
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.copy_outlined, color: Colors.black54), onPressed: () => _copyToClipboard(_getTotp().replaceAll(' ', ''), 'Token 2FA'))
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.black87, side: BorderSide(color: Colors.black.withOpacity(0.1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 12)),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AccountFormScreen(account: acc)));
                          if (result == true) widget.onRefresh();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(8)),
                      child: IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFE11D48)), onPressed: () async { await DatabaseHelper.instance.deleteAccount(acc['id']); widget.onRefresh(); }),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Dibuat: ${_formatDate(acc['created_at'])}', style: const TextStyle(fontSize: 10, color: Colors.black38)),
                    Text('Update: ${_formatDate(acc['updated_at'])}', style: const TextStyle(fontSize: 10, color: Colors.black38)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBadge(String text, {bool isOutline = false, Color? bgColor, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: isOutline ? Colors.transparent : (bgColor ?? Colors.white), border: Border.all(color: isOutline ? Colors.black12 : Colors.transparent), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor ?? Colors.black54)),
    );
  }
}
