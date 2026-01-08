import 'package:flutter/material.dart';
import 'database/hive_service.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'models.dart';

void main() async {
  // Pastikan Flutter binding sudah siap
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Hive SEBELUM runApp
  await HiveService.init();
  
  // Buat user default untuk testing (jika belum ada)
  await _createDefaultUser();
  
  runApp(const MyApp());
}

// Fungsi untuk membuat user default
Future<void> _createDefaultUser() async {
  try {
    final existingUser = await HiveService.getUserByEmail('user@gmail.com');
    if (existingUser == null) {
      await HiveService.createUser(User(
        id: 1,
        name: 'User',
        email: 'user@gmail.com',
        password: '123456',
      ));
      debugPrint('✅ Default user created: user@gmail.com');
    } else {
      debugPrint('✅ User already exists: ${existingUser.email}');
    }
  } catch (e) {
    debugPrint('❌ Error creating default user: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      // Gunakan FutureBuilder untuk cek session
      home: const AuthChecker(),
    );
  }
}

// Widget untuk cek apakah user sudah login atau belum
class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  Future<User?> _checkLoginStatus() async {
    try {
      // Cek apakah ada session tersimpan
      final email = HiveService.getCurrentUserEmail();
      
      if (email != null && email.isNotEmpty) {
        // Ambil data user dari Hive
        final user = await HiveService.getUserByEmail(email);
        debugPrint('✅ Auto-login: ${user?.email}');
        return user;
      }
      
      debugPrint('ℹ️ No saved session');
      return null;
    } catch (e) {
      debugPrint('❌ Error checking login status: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF9333EA),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Event Manager Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Error state (jarang terjadi, tapi safety first)
        if (snapshot.hasError) {
          debugPrint('❌ AuthChecker error: ${snapshot.error}');
          return const LoginPage();
        }

        // Decision: Login atau Dashboard
        final user = snapshot.data;
        
        if (user != null) {
          // User sudah login, langsung ke Dashboard
          debugPrint('✅ Redirecting to Dashboard for: ${user.name}');
          return DashboardPage(user: user);
        } else {
          // Belum login, ke Login Page
          debugPrint('ℹ️ Redirecting to Login Page');
          return const LoginPage();
        }
      },
    );
  }
}