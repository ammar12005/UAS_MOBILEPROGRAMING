import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import halaman
import 'pages/create_event_page.dart';
import 'pages/event_detail_page.dart';
import 'pages/scan_page.dart';
import 'pages/statistics_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi locale Indonesia untuk format tanggal
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9333EA)),
        // Font global
        fontFamily: 'Roboto',
      ),
      home: const AuthCheck(),
    );
  }
}

// --- MODELS ---
class User {
  final int id;
  final String name, email, password;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
  };
  
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    password: json['password'],
  );
}

class Event {
  final int id;
  final String name, location, description;
  final DateTime date;
  final int capacity;
  final double price;
  int ticketsSold;
  
  Event({
    required this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.capacity,
    required this.price,
    required this.description,
    this.ticketsSold = 0,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'date': date.toIso8601String(),
    'location': location,
    'capacity': capacity,
    'price': price,
    'description': description,
    'ticketsSold': ticketsSold,
  };
  
  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'],
    name: json['name'],
    date: DateTime.parse(json['date']),
    location: json['location'],
    capacity: json['capacity'],
    price: json['price'].toDouble(),
    description: json['description'],
    ticketsSold: json['ticketsSold'] ?? 0,
  );
}

class Ticket {
  final int id, eventId;
  final String code, buyerName, buyerEmail;
  final DateTime purchaseDate;
  bool isScanned;
  DateTime? scannedAt;
  
  Ticket({
    required this.id,
    required this.eventId,
    required this.code,
    required this.buyerName,
    required this.buyerEmail,
    required this.purchaseDate,
    this.isScanned = false,
    this.scannedAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'code': code,
    'buyerName': buyerName,
    'buyerEmail': buyerEmail,
    'purchaseDate': purchaseDate.toIso8601String(),
    'isScanned': isScanned,
    'scannedAt': scannedAt?.toIso8601String(),
  };
  
  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    id: json['id'],
    eventId: json['eventId'],
    code: json['code'],
    buyerName: json['buyerName'],
    buyerEmail: json['buyerEmail'],
    purchaseDate: DateTime.parse(json['purchaseDate']),
    isScanned: json['isScanned'] ?? false,
    scannedAt: json['scannedAt'] != null ? DateTime.parse(json['scannedAt']) : null,
  );
}

// --- STORAGE SERVICE ---
class StorageService {
  static const String _prefix = 'emp_v2_';
  
  static Future<SharedPreferences> _prefs() async => await SharedPreferences.getInstance();

  // Users Management
  static Future<List<User>> getUsers() async {
    final prefs = await _prefs();
    final data = prefs.getString('${_prefix}users');
    if (data == null) return [];
    return (json.decode(data) as List).map((u) => User.fromJson(u)).toList();
  }

  static Future<void> saveUsers(List<User> users) async {
    final prefs = await _prefs();
    await prefs.setString('${_prefix}users', json.encode(users.map((u) => u.toJson()).toList()));
  }

  // Session Management
  static Future<void> setSession(User user) async {
    final prefs = await _prefs();
    await prefs.setString('${_prefix}current_user', json.encode(user.toJson()));
    await prefs.setBool('${_prefix}is_logged_in', true);
  }

  static Future<User?> getSession() async {
    final prefs = await _prefs();
    final isLoggedIn = prefs.getBool('${_prefix}is_logged_in') ?? false;
    if (!isLoggedIn) return null;
    
    final data = prefs.getString('${_prefix}current_user');
    return data != null ? User.fromJson(json.decode(data)) : null;
  }

  static Future<void> logout() async {
    final prefs = await _prefs();
    await prefs.remove('${_prefix}current_user');
    await prefs.setBool('${_prefix}is_logged_in', false);
  }

  // Events Management
static Future<List<Event>> getEvents(int userId) async {
  final prefs = await _prefs();
  final data = prefs.getString('${_prefix}events_$userId');
  print('🟢 LOAD Events untuk user $userId: ${data != null ? "Ada data" : "Kosong"}');
  if (data == null) return [];
  final events = (json.decode(data) as List).map((e) => Event.fromJson(e)).toList();
  print('🟢 Total events loaded: ${events.length}');
  return events;
}

static Future<void> saveEvents(int userId, List<Event> events) async {
  final prefs = await _prefs();
  await prefs.setString('${_prefix}events_$userId', json.encode(events.map((e) => e.toJson()).toList()));
  print('🔵 SAVE Events untuk user $userId: ${events.length} events');
  
  // Verifikasi data tersimpan
  final saved = prefs.getString('${_prefix}events_$userId');
  print('🔵 Verifikasi: ${saved != null ? "Data tersimpan!" : "GAGAL SIMPAN!"}');
}

  // Tickets Management
  static Future<List<Ticket>> getTickets(int userId) async {
    final prefs = await _prefs();
    final data = prefs.getString('${_prefix}tickets_$userId');
    if (data == null) return [];
    return (json.decode(data) as List).map((t) => Ticket.fromJson(t)).toList();
  }

  static Future<void> saveTickets(int userId, List<Ticket> tickets) async {
    final prefs = await _prefs();
    await prefs.setString('${_prefix}tickets_$userId', json.encode(tickets.map((t) => t.toJson()).toList()));
  }
}

// --- AUTH CHECK ---
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});
  
  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }
  
  Future<void> _checkAuthentication() async {
    // Delay untuk splash screen effect
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = await StorageService.getSession();
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user != null ? DashboardPage(user: user) : const LoginPage(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF581C87), Color(0xFF0F172A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 32),
              const Text(
                'Event Manager Pro',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- LOGIN PAGE ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!isLogin && _passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Password tidak cocok");
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final users = await StorageService.getUsers();
      final email = _emailController.text.trim().toLowerCase();
      
      if (isLogin) {
        // Login
        final user = users.cast<User?>().firstWhere(
          (u) => u?.email == email && u?.password == _passwordController.text,
          orElse: () => null,
        );
        
        if (user != null) {
          await StorageService.setSession(user);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DashboardPage(user: user)),
            );
          }
        } else {
          setState(() => _errorMessage = "Email atau password salah");
        }
      } else {
        // Register
        if (users.any((u) => u.email == email)) {
          setState(() => _errorMessage = "Email sudah terdaftar");
          return;
        }
        
        final newUser = User(
          id: DateTime.now().millisecondsSinceEpoch,
          name: _nameController.text.trim(),
          email: email,
          password: _passwordController.text,
        );
        
        users.add(newUser);
        await StorageService.saveUsers(users);
        await StorageService.setSession(newUser);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DashboardPage(user: newUser)),
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "Terjadi kesalahan: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: Color(0xFF9333EA)),
            SizedBox(width: 12),
            Text('Lupa Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan email Anda untuk menampilkan password'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim().toLowerCase();
              final users = await StorageService.getUsers();
              final user = users.cast<User?>().firstWhere(
                (u) => u?.email == email,
                orElse: () => null,
              );
              
              Navigator.pop(context);
              
              if (user != null) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 12),
                        Text('Password Ditemukan'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Password Anda adalah:'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.password,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9333EA),
                        ),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Email tidak terdaftar'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cari Password'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF581C87), Color(0xFF0F172A)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 20,
              shadowColor: const Color(0xFF9333EA).withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 20),
                      
                      // Title
                      Text(
                        isLogin ? "Selamat Datang!" : "Buat Akun Baru",
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLogin ? "Login ke Event Manager Pro" : "Daftar untuk memulai",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      
                      // Error Message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Name Field (Register only)
                      if (!isLogin) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: "Nama Lengkap",
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (v) => v?.isEmpty ?? true ? "Nama harus diisi" : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return "Email harus diisi";
                          if (!v!.contains('@')) return "Email tidak valid";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        obscureText: !_showPassword,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return "Password harus diisi";
                          if (v!.length < 6) return "Password minimal 6 karakter";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Confirm Password Field (Register only)
                      if (!isLogin) ...[
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: "Konfirmasi Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          obscureText: !_showConfirmPassword,
                          validator: (v) => v?.isEmpty ?? true ? "Konfirmasi password harus diisi" : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Forgot Password (Login only)
                      if (isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text('Lupa Password?'),
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9333EA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isLogin ? "Login" : "Daftar",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Toggle Login/Register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLogin ? "Belum punya akun?" : "Sudah punya akun?",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isLogin = !isLogin;
                                _errorMessage = null;
                              });
                            },
                            child: Text(
                              isLogin ? "Daftar" : "Login",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- DASHBOARD PAGE ---
class DashboardPage extends StatefulWidget {
  final User user;
  
  const DashboardPage({super.key, required this.user});
  
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  List<Event> events = [];
  List<Ticket> tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final loadedEvents = await StorageService.getEvents(widget.user.id);
    final loadedTickets = await StorageService.getTickets(widget.user.id);
    
    if (mounted) {
      setState(() {
        events = loadedEvents;
        tickets = loadedTickets;
        _isLoading = false;
      });
    }
  }

  // Tambahan fungsi untuk menghapus event
  void _handleDeleteEvent(int eventId) {
    final updatedEvents = events.where((e) => e.id != eventId).toList();
    // Juga hapus tiket yang terkait dengan event tersebut
    final updatedTickets = tickets.where((t) => t.eventId != eventId).toList();
    
    setState(() {
      events = updatedEvents;
      tickets = updatedTickets;
    });
    
    StorageService.saveEvents(widget.user.id, updatedEvents);
    StorageService.saveTickets(widget.user.id, updatedTickets);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF581C87), Color(0xFF0F172A)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }
    
    final pages = [
      EventsPage(
        user: widget.user,
        events: events,
        tickets: tickets,
        onEventsChanged: (updatedEvents) {
          setState(() => events = updatedEvents);
          StorageService.saveEvents(widget.user.id, updatedEvents);
        },
        onTicketsChanged: (updatedTickets) {
          setState(() => tickets = updatedTickets);
          StorageService.saveTickets(widget.user.id, updatedTickets);
        },
        onEventDeleted: _handleDeleteEvent, // Pass fungsi hapus
      ),
      ScanPage(
        tickets: tickets,
        events: events,
        onTicketsChanged: (updatedTickets) {
          setState(() => tickets = updatedTickets);
          StorageService.saveTickets(widget.user.id, updatedTickets);
        },
      ),
      StatisticsPage(events: events, tickets: tickets),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: const Color(0xFF9333EA),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.event),
              label: "Events",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: "Scan",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: "Statistik",
            ),
          ],
        ),
      ),
    );
  }
}

// --- EVENTS PAGE ---
class EventsPage extends StatelessWidget {
  final User user;
  final List<Event> events;
  final List<Ticket> tickets;
  final Function(List<Event>) onEventsChanged;
  final Function(List<Ticket>) onTicketsChanged;
  final Function(int) onEventDeleted; // Callback baru

  const EventsPage({
    super.key,
    required this.user,
    required this.events,
    required this.tickets,
    required this.onEventsChanged,
    required this.onTicketsChanged,
    required this.onEventDeleted, // Diperlukan di konstruktor
  });

  // Dialog konfirmasi hapus
  void _showDeleteDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Event'),
        content: Text('Apakah Anda yakin ingin menghapus "${event.name}"? Semua tiket terkait juga akan terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              onEventDeleted(event.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Event ${event.name} berhasil dihapus')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradients = [
      const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF9333EA)]),
      const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF43F5E)]),
      const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF14B8A6)]),
      const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF581C87), Color(0xFF0F172A)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF9333EA).withOpacity(0.2),
                    const Color(0xFF3B82F6).withOpacity(0.2),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 32),
                            SizedBox(width: 12),
                            Text(
                              'Event Manager Pro',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Halo, ${user.name} 👋',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFFC4B5FD),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateEventPage(
                                onEventCreated: (event) {
                                  onEventsChanged([...events, event]);
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Buat Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9333EA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFF9333EA).withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Konfirmasi Logout'),
                              content: const Text('Apakah Anda yakin ingin keluar?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true) {
                            await StorageService.logout();
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Events List
            Expanded(
              child: events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada event',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Buat event pertama Anda!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final gradient = gradients[index % gradients.length];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onLongPress: () => _showDeleteDialog(context, event), // Tekan lama untuk hapus
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventDetailPage(
                                      event: event,
                                      tickets: tickets,
                                      onTicketsChanged: onTicketsChanged,
                                      onEventChanged: (updated) {
                                        final updatedEvents = [...events];
                                        updatedEvents[index] = updated;
                                        onEventsChanged(updatedEvents);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: gradient,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: gradient.colors.first
                                                    .withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.calendar_today,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                event.name,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.access_time,
                                                    color: Color(0xFFC4B5FD),
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    DateFormat('dd MMM yyyy')
                                                        .format(event.date),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFFC4B5FD),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Tombol hapus langsung di kartu
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () => _showDeleteDialog(context, event),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: Color(0xFFC4B5FD),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              event.location,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFFC4B5FD),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: gradient,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${event.ticketsSold}/${event.capacity}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
    );
  }
}