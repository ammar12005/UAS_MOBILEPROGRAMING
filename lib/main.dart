import 'package:flutter/material.dart';
import 'models.dart';
import 'storage_service.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Buat akun default jika belum ada
  await _createDefaultAccount();
  
  // Cek session
  final user = await StorageService.getSession();
  
  runApp(MyApp(initialUser: user));
}

// Fungsi untuk membuat akun default
Future<void> _createDefaultAccount() async {
  try {
    final users = await StorageService.getUsers();
    
    // Jika belum ada user, buat akun default
    if (users.isEmpty) {
      final defaultUsers = [
        User(
          id: 1,
          name: 'Admin',
          email: 'admin@gmail.com',
          password: '123456',
        ),
        User(
          id: 2,
          name: 'User Test',
          email: 'user@gmail.com',
          password: 'user123',
        ),
        User(
          id: 3,
          name: 'Ammar',
          email: 'ammar@gmail.com',
          password: 'ammar123',
        ),
      ];
      
      await StorageService.saveUsers(defaultUsers);
      // Debug mode only - akan otomatis hilang di production build
      assert(() {
        debugPrint('✅ Akun default berhasil dibuat:');
        debugPrint('   1. Email: admin@gmail.com  | Password: 123456');
        debugPrint('   2. Email: user@gmail.com   | Password: user123');
        debugPrint('   3. Email: ammar@gmail.com  | Password: ammar123');
        return true;
      }());
    }
  } catch (e) {
    // Debug mode only
    assert(() {
      debugPrint('⚠️ Error membuat akun default: $e');
      return true;
    }());
  }
}

class MyApp extends StatelessWidget {
  final User? initialUser;
  
  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9333EA),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      // Auto login jika ada session
      home: initialUser != null 
          ? DashboardPage(user: initialUser!)
          : const LoginPage(),
    );
  }
}