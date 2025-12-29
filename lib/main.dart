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
  
  User({required this.id, required this.name, required this.email, required this.password});
  
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'password': password};
  
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
    required this.id, required this.name, required this.date, required this.location,
    required this.capacity, required this.price, required this.description, this.ticketsSold = 0,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'date': date.toIso8601String(), 'location': location,
    'capacity': capacity, 'price': price, 'description': description, 'ticketsSold': ticketsSold,
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
    required this.id, required this.eventId, required this.code, required this.buyerName,
    required this.buyerEmail, required this.purchaseDate, this.isScanned = false, this.scannedAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id, 'eventId': eventId, 'code': code, 'buyerName': buyerName, 'buyerEmail': buyerEmail,
    'purchaseDate': purchaseDate.toIso8601String(), 'isScanned': isScanned, 'scannedAt': scannedAt?.toIso8601String(),
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

  static Future<List<User>> getUsers() async {
    final prefs = await _prefs();
    final data = prefs.getString('${_prefix}users');
    if (data == null || data.isEmpty) return [];
    try {
      List<dynamic> decoded = json.decode(data);
      return decoded.map((u) => User.fromJson(u)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveUsers(List<User> users) async {
    final prefs = await _prefs();
    String encoded = json.encode(users.map((u) => u.toJson()).toList());
    await prefs.setString('${_prefix}users', encoded);
  }

  static Future<void> setSession(User user) async {
    final prefs = await _prefs();
    await prefs.setString('${_prefix}current_user', json.encode(user.toJson()));
    await prefs.setBool('${_prefix}is_logged_in', true);
  }

  static Future<User?> getSession() async {
    final prefs = await _prefs();
    if (!(prefs.getBool('${_prefix}is_logged_in') ?? false)) return null;
    final data = prefs.getString('${_prefix}current_user');
    return data != null ? User.fromJson(json.decode(data)) : null;
  }

  static Future<void> logout() async {
    final prefs = await _prefs();
    await prefs.remove('${_prefix}current_user');
    await prefs.setBool('${_prefix}is_logged_in', false);
  }

  static Future<List<Event>> getEvents(int userId) async {
    final prefs = await _prefs();
    final data = prefs.getString('${_prefix}events_$userId');
    if (data == null) return [];
    return (json.decode(data) as List).map((e) => Event.fromJson(e)).toList();
  }

  static Future<void> saveEvents(int userId, List<Event> events) async {
    final prefs = await _prefs();
    await prefs.setString('${_prefix}events_$userId', json.encode(events.map((e) => e.toJson()).toList()));
  }

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
    await Future.delayed(const Duration(milliseconds: 500));
    final user = await StorageService.getSession();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => user != null ? DashboardPage(user: user) : const LoginPage()));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF581C87), Color(0xFF0F172A)])),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
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
  bool _isLoading = false, _showPassword = false, _showConfirmPassword = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!isLogin && _passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Password tidak cocok"); return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      List<User> users = await StorageService.getUsers();
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      if (isLogin) {
        final user = users.where((u) => u.email == email && u.password == password).firstOrNull;
        if (user != null) {
          await StorageService.setSession(user);
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardPage(user: user)));
        } else {
          setState(() => _errorMessage = "Email atau password salah");
        }
      } else {
        if (users.any((u) => u.email == email)) {
          setState(() => _errorMessage = "Email sudah terdaftar");
          return;
        }
        final newUser = User(
          id: DateTime.now().millisecondsSinceEpoch,
          name: _nameController.text.trim(),
          email: email,
          password: password,
        );
        users.add(newUser);
        await StorageService.saveUsers(users); // Simpan ke list permanen
        await StorageService.setSession(newUser);
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardPage(user: newUser)));
      }
    } catch (e) { setState(() => _errorMessage = "Terjadi kesalahan sistem"); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lupa Password'),
        content: TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Masukkan Email')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim().toLowerCase();
              final users = await StorageService.getUsers();
              final user = users.where((u) => u.email == email).firstOrNull;
              Navigator.pop(context);
              if (user != null) {
                showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Ditemukan'), content: Text('Password Anda: ${user.password}'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email tidak ditemukan'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF581C87), Color(0xFF0F172A)])),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF9333EA), size: 40),
                      const SizedBox(height: 20),
                      Text(isLogin ? "Login" : "Daftar", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      if (_errorMessage != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                      const SizedBox(height: 24),
                      if (!isLogin) ...[
                        TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Nama Lengkap", prefixIcon: Icon(Icons.person)), validator: (v) => v!.isEmpty ? "Isi nama" : null),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email)), validator: (v) => !v!.contains('@') ? "Email tidak valid" : null),
                      const SizedBox(height: 16),
                      TextFormField(controller: _passwordController, obscureText: !_showPassword, decoration: InputDecoration(labelText: "Password", prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _showPassword = !_showPassword)))),
                      if (!isLogin) ...[
                        const SizedBox(height: 16),
                        TextFormField(controller: _confirmPasswordController, obscureText: !_showConfirmPassword, decoration: const InputDecoration(labelText: "Konfirmasi Password")),
                      ],
                      if (isLogin) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _showForgotPasswordDialog, child: const Text('Lupa Password?'))),
                      const SizedBox(height: 24),
                      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9333EA), foregroundColor: Colors.white), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isLogin ? "Login" : "Daftar"))),
                      TextButton(onPressed: () => setState(() { isLogin = !isLogin; _errorMessage = null; }), child: Text(isLogin ? "Belum punya akun? Daftar" : "Sudah punya akun? Login")),
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
  void initState() { super.initState(); _loadData(); }
  
  Future<void> _loadData() async {
    final loadedEvents = await StorageService.getEvents(widget.user.id);
    final loadedTickets = await StorageService.getTickets(widget.user.id);
    if (mounted) setState(() { events = loadedEvents; tickets = loadedTickets; _isLoading = false; });
  }

  void _handleDeleteEvent(int eventId) {
    setState(() {
      events.removeWhere((e) => e.id == eventId);
      tickets.removeWhere((t) => t.eventId == eventId);
    });
    StorageService.saveEvents(widget.user.id, events);
    StorageService.saveTickets(widget.user.id, tickets);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final pages = [
      EventsPage(
        user: widget.user, events: events, tickets: tickets,
        onEventsChanged: (updated) { setState(() => events = updated); StorageService.saveEvents(widget.user.id, updated); },
        onTicketsChanged: (updated) { setState(() => tickets = updated); StorageService.saveTickets(widget.user.id, updated); },
        onEventDeleted: _handleDeleteEvent,
      ),
      ScanPage(tickets: tickets, events: events, onTicketsChanged: (updated) { setState(() => tickets = updated); StorageService.saveTickets(widget.user.id, updated); }),
      StatisticsPage(events: events, tickets: tickets),
    ];
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF9333EA),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Scan"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Statistik"),
        ],
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
  final Function(int) onEventDeleted;

  const EventsPage({
    super.key, required this.user, required this.events, required this.tickets,
    required this.onEventsChanged, required this.onTicketsChanged, required this.onEventDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF581C87), Color(0xFF0F172A)])),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Event Manager Pro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Halo, ${user.name} 👋', style: const TextStyle(color: Color(0xFFC4B5FD))),
                  ]),
                  Row(
                    children: [
                      IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateEventPage(onEventCreated: (e) => onEventsChanged([...events, e])))), icon: const Icon(Icons.add_circle, color: Colors.white, size: 30)),
                      IconButton(
                        onPressed: () async {
                          await StorageService.logout();
                          if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                        },
                        icon: const Icon(Icons.logout, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: events.isEmpty 
                ? const Center(child: Text("Belum ada event", style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Card(
                        color: Colors.white.withOpacity(0.1),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(event.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat('dd MMM yyyy').format(event.date), style: const TextStyle(color: Colors.white70)),
                          trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => onEventDeleted(event.id)),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(event: event, tickets: tickets, onTicketsChanged: onTicketsChanged, onEventChanged: (u) {
                            final list = [...events]; list[index] = u; onEventsChanged(list);
                          }))),
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