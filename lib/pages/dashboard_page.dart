import 'package:flutter/material.dart';
import '../models.dart';
import '../database/hive_service.dart';
import 'create_event_page.dart';
import 'event_detail_page.dart';
import 'scan_page.dart';
import 'statistics_page.dart';
import 'login_page.dart'; // Import login page

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
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final loadedEvents = await HiveService.getAllEvents();
      final loadedTickets = await HiveService.getAllTickets();

      if (mounted) {
        setState(() {
          events = loadedEvents;
          tickets = loadedTickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeleteEvent(int eventId) async {
    try {
      await HiveService.deleteEvent(eventId);
      final ticketsToDelete = tickets.where((t) => t.eventId == eventId).toList();
      for (var ticket in ticketsToDelete) {
        await HiveService.deleteTicket(ticket.id);
      }
      await _loadData();
    } catch (e) {
      debugPrint('Gagal hapus: $e');
    }
  }

  // Method untuk menampilkan dialog logout
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.deepPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Konfirmasi Logout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx); // Tutup dialog
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method untuk handle logout
  void _handleLogout() async {
    // Hapus session dari Hive
    await HiveService.clearCurrentUser();
    
    if (!mounted) return;
    
    // Navigasi ke Login Page dan hapus semua route sebelumnya
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false, // Hapus semua route history
    );

    // Tampilkan snackbar sukses
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Berhasil logout'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final List<Widget> pages = [
      _buildEventsTab(),
      ScanPage(
        tickets: tickets,
        events: events,
        onTicketsChanged: (updatedTickets) async {
          setState(() => tickets = updatedTickets);
        },
      ),
      StatisticsPage(events: events, tickets: tickets),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: const Color(0xFFC4B5FD),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
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

  Widget _buildEventsTab() {
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
            _buildDashboardHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF9333EA),
                backgroundColor: Colors.white,
                child: events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Belum ada event",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Tap + untuk membuat event baru",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9333EA).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.event,
                                    color: Color(0xFFC4B5FD),
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  event.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  event.location,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white54,
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventDetailPage(
                                      event: event,
                                      tickets: tickets,
                                      onTicketsChanged: (t) =>
                                          setState(() => tickets = t),
                                      onEventChanged: (e) => _loadData(),
                                      onEventDeleted: (e) =>
                                          _handleDeleteEvent(e.id),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User Info Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${widget.user.name} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kelola tiket event Anda',
                  style: TextStyle(
                    color: Color(0xFFC4B5FD),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons Section
          Row(
            children: [
              // Logout Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                  tooltip: 'Logout',
                  onPressed: _showLogoutDialog,
                ),
              ),
              const SizedBox(width: 8),
              
              // Add Event Button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xFF9333EA),
                    size: 32,
                  ),
                  tooltip: 'Tambah Event',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateEventPage(
                        onEventCreated: (e) => _loadData(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}