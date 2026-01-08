import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'database/hive_service.dart'; 
import 'models.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  User? initialUser;
  
  try {
    // 1. Inisialisasi Hive
    await HiveService.init(); 
    
    // 2. Buat akun default
    await _createDefaultAccount();
    
    // 3. Cek sesi login (PERBAIKAN BIRU: Hapus await jika getCurrentUserEmail bukan Future)
    // Berdasarkan peringatan di image_311463.jpg, fungsi ini mengembalikan String langsung.
    final email = HiveService.getCurrentUserEmail(); 
    
    if (email != null) {
      initialUser = await HiveService.getUserByEmail(email);
    }
    
    if (kDebugMode) {
      _printStartupInfo(initialUser);
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Critical Error during app initialization: $e');
    }
  }
  
  runApp(MyApp(initialUser: initialUser));
}

/// Membuat akun default jika database kosong
Future<void> _createDefaultAccount() async {
  try {
    final admin = await HiveService.getUserByEmail('admin@gmail.com');
    
    if (admin == null) {
      final defaultUsers = [
        User(id: 1, name: 'Admin', email: 'admin@gmail.com', password: '123456', role: 'admin', createdAt: DateTime.now(), phone: ''),
        User(id: 2, name: 'User Test', email: 'user@gmail.com', password: 'user123', role: 'user', createdAt: DateTime.now(), phone: ''),
        User(id: 3, name: 'Ammar', email: 'ammar@gmail.com', password: 'ammar123', role: 'user', createdAt: DateTime.now(), phone: ''),
      ];
      
      for (var user in defaultUsers) {
        await HiveService.createUser(user);
      }
      
      if (kDebugMode) {
        debugPrint('✅ Default accounts created in Hive');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Error creating default accounts: $e');
    }
  }
}

void _printStartupInfo(User? user) {
  debugPrint('═══════════════════════════════════════');
  debugPrint('🚀 Event Manager Pro Starting...');
  debugPrint('═══════════════════════════════════════');
  debugPrint('📦 Storage System: Hive (NoSQL)');
  debugPrint('👤 Session Status: ${user != null ? "Logged In" : "Not Logged In"}');
  if (user != null) debugPrint('   - Active User: ${user.name}');
  debugPrint('═══════════════════════════════════════\n');
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9333EA)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: initialUser != null 
          ? DashboardPage(user: initialUser!) 
          : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}