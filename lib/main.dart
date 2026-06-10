import 'dart:ui';
import 'package:flutter/material.dart';

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
        fontFamily: 'Roboto', // Menggunakan font bawaan yang bersih
      ),
      home: const DashboardScreen(),
    );
  }
}

// --- SCREEN 1: DASHBOARD ---

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> accounts = [
      {'name': 'Instagram', 'user': 'johndoe_99', 'a2f': true, 'icon': Icons.camera_alt},
      {'name': 'Facebook', 'user': 'johndoe.fb', 'a2f': true, 'icon': Icons.facebook},
      {'name': 'X (Twitter)', 'user': 'johndoe_x', 'a2f': false, 'icon': Icons.close},
      {'name': 'Google', 'user': 'johndoe@gmail.com', 'a2f': true, 'icon': Icons.g_mobiledata},
      {'name': 'TikTok', 'user': 'johndoe.tiktok', 'a2f': false, 'icon': Icons.music_note},
    ];

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
                  decoration: InputDecoration(
                    hintText: 'Cari akun...',
                    hintStyle: const TextStyle(color: Colors.black38),
                    prefixIcon: const Icon(Icons.search, color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // List of Accounts
              Expanded(
                child: ListView.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final acc = accounts[index];
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
                            child: Icon(acc['icon'], color: const Color(0xFF6C4DFF)),
                          ),
                          title: Text(acc['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(acc['user'], style: const TextStyle(color: Colors.black54, fontSize: 13)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (acc['a2f'])
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
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddAccountScreen()));
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
            onPressed: () {},
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
            _buildTextField(hint: 'Instagram'),
            const SizedBox(height: 20),

            _buildLabel('Username / Email'),
            _buildTextField(hint: 'johndoe_99'),
            const SizedBox(height: 20),

            _buildLabel('Email'),
            _buildTextField(hint: 'johndoe@gmail.com'),
            const SizedBox(height: 20),

            _buildLabel('Password (wajib)'),
            _buildTextField(
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
                      Center(
                        child: Column(
                          children: [
                            const Text('Current Token', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 12),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    value: 0.8, // Representasi 24 detik dari 30
                                    strokeWidth: 4,
                                    backgroundColor: Colors.black.withOpacity(0.05),
                                    color: const Color(0xFF6C4DFF),
                                  ),
                                ),
                                const Text('24s', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C4DFF))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('123 456', style: TextStyle(fontSize: 28, letterSpacing: 4, fontWeight: FontWeight.bold, color: Color(0xFF6C4DFF))),
                          ],
                        ),
                      )
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
                onPressed: () {},
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

  Widget _buildTextField({required String hint, bool isPassword = false, bool isVisible = false, VoidCallback? onVisibilityToggle}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
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
