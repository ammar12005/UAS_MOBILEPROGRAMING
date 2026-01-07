import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'storage_service.dart';
import 'database/database_helper.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SQLite Database
  await _initializeDatabase();
  
  // Buat akun default jika belum ada
  await _createDefaultAccount();
  
  // Cek session
  final user = await StorageService.getSession();
  
  runApp(MyApp(initialUser: user));
}

/// Fungsi untuk initialize SQLite Database
Future<void> _initializeDatabase() async {
  try {
    final dbHelper = DatabaseHelper();
    // Trigger database initialization
    await dbHelper.database;
    
    if (kDebugMode) {
      debugPrint('✅ SQLite Database initialized successfully');
      debugPrint('   Database: event_manager.db');
      debugPrint('   Tables: users, events, tickets');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Error initializing database: $e');
    }
  }
}

/// Fungsi untuk membuat akun default
Future<void> _createDefaultAccount() async {
  try {
    final users = await StorageService.getUsers();
    
    if (kDebugMode) {
      debugPrint('📊 Checking existing users in SQLite...');
      debugPrint('   Total users in database: ${users.length}');
    }
    
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
      
      // Simpan setiap user ke SQLite
      int successCount = 0;
      for (var user in defaultUsers) {
        final success = await StorageService.saveUser(user);
        if (success) successCount++;
      }
      
      if (kDebugMode) {
        debugPrint('✅ Akun default berhasil dibuat ($successCount/3):');
        debugPrint('   1. Email: admin@gmail.com  | Password: 123456');
        debugPrint('   2. Email: user@gmail.com   | Password: user123');
        debugPrint('   3. Email: ammar@gmail.com  | Password: ammar123');
        debugPrint('');
        debugPrint('💡 Tip: Gunakan akun di atas untuk login');
      }
    } else {
      if (kDebugMode) {
        debugPrint('ℹ️  Akun sudah ada di database:');
        for (var user in users) {
          debugPrint('   - ${user.email} (${user.name})');
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Error membuat akun default: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  final User? initialUser;
  
  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    // Debug info saat app start
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🚀 Event Manager Pro Starting...');
      debugPrint('═══════════════════════════════════════');
      debugPrint('📦 Storage System:');
      debugPrint('   - Main Storage: SQLite (event_manager.db)');
      debugPrint('   - Session: SharedPreferences');
      debugPrint('');
      debugPrint('👤 User Session:');
      debugPrint('   - Auto-login: ${initialUser != null}');
      if (initialUser != null) {
        debugPrint('   - Logged in as: ${initialUser!.name}');
        debugPrint('   - Email: ${initialUser!.email}');
      } else {
        debugPrint('   - Status: Not logged in');
      }
      debugPrint('═══════════════════════════════════════\n');
    }
    
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