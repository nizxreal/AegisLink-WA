import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WA Node Auth',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Dark navy
        primaryColor: const Color(0xFFF97316), // Vibrant orange
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFF97316),
          secondary: const Color(0xFF38BDF8),
          surface: const Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// 1. Google Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;

  void _loginWithGoogle() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate OAuth
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('google_email', 'user@gmail.com');

    setState(() => isLoading = false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TokenScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 80, color: Color(0xFFF97316)),
              const SizedBox(height: 20),
              const Text('WA Node Auth', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Login dengan Akun Google untuk melanjutkan', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _loginWithGoogle,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.g_mobiledata, size: 30),
                          SizedBox(width: 10),
                          Text('Masuk dengan Google', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. Token Input Screen (Locked until token valid)
class TokenScreen extends StatefulWidget {
  const TokenScreen({super.key});

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  final _tokenController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';

  // Ganti dengan URL backend Anda (misal ngrok atau server deploy)
  final String backendUrl = 'http://10.0.2.2:3000/api';

  void _verifyAndBindToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => errorMessage = 'Token tidak boleh kosong');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('google_email') ?? 'user@gmail.com';

      final response = await http.post(
        Uri.parse('$backendUrl/user/bind'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'google_email': email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await prefs.setString('active_token', token);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
        );
      } else {
        setState(() => errorMessage = data['error'] ?? 'Gagal memvalidasi token');
      }
    } catch (e) {
      setState(() => errorMessage = 'Koneksi server gagal: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktivasi Token')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Masukkan Token Akses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Menu utama dan pairing WA terkunci sebelum token dimasukkan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'Token Unik',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
              ),
            ),
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                    onPressed: _verifyAndBindToken,
                    child: const Text('Aktifkan & Masuk', style: TextStyle(color: Colors.white)),
                  ),
            const TextButton(
              onPressed: null, // Buka admin view atau info
              child: Text('Hubungi Admin untuk Token', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. Main Menu Screen (Pair / Start Node)
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Utama - WA Node'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen())),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: Terhubung 🟢', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  SizedBox(height: 8),
                  Text('Google: user@gmail.com'),
                  Text('Token Aktif: Valid (1 Token = 1 Sesi)'),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Node WA Started & Pairing Active')));
              },
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('Start Node & Pair WhatsApp', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (!context.mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout / Reset Sesi', style: TextStyle(color: Colors.red)),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// 4. Admin Screen (Token Management)
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List tokens = [];
  bool isLoading = true;
  final _newTokenController = TextEditingController();
  final String backendUrl = 'http://10.0.2.2:3000/api';

  @override
  void initState() {
    super.initState();
    _fetchTokens();
  }

  void _fetchTokens() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/admin/tokens'));
      if (response.statusCode == 200) {
        setState(() => tokens = jsonDecode(response.body));
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _addToken() async {
    final token = _newTokenController.text.trim();
    if (token.isEmpty) return;
    await http.post(
      Uri.parse('$backendUrl/admin/tokens'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );
    _newTokenController.clear();
    _fetchTokens();
  }

  void _deleteToken(String token) async {
    await http.delete(Uri.parse('$backendUrl/admin/tokens/$token'));
    _fetchTokens();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel - Token Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTokenController,
                    decoration: const InputDecoration(labelText: 'Token Baru', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                  onPressed: _addToken,
                  child: const Text('Tambah', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: tokens.length,
                      itemBuilder: (context, index) {
                        final t = tokens[index];
                        return Card(
                          color: const Color(0xFF1E293B),
                          child: ListTile(
                            title: Text(t['token'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Google: ${t['google_email'] ?? 'Belum terikat'}\nStatus: ${t['status']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteToken(t['token']),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
