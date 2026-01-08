import 'package:flutter/material.dart';
import '../models.dart';
import '../database/hive_service.dart';
import 'create_event_page.dart';
import 'event_detail_page.dart';
import 'scan_page.dart';
import 'statistics_page.dart';

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
      // Hapus tiket terkait di Hive
      final ticketsToDelete = tickets.where((t) => t.eventId == eventId).toList();
      for (var ticket in ticketsToDelete) {
        await HiveService.deleteTicket(ticket.id);
      }
      await _loadData();
    } catch (e) {
      debugPrint('Gagal hapus: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // LIST HALAMAN
    final List<Widget> pages = [
      // HALAMAN 1: Events (Gunakan widget internal di bawah)
      _buildEventsTab(), 
      
      // HALAMAN 2: Scan
      ScanPage(
        tickets: tickets,
        events: events,
        onTicketsChanged: (updatedTickets) async {
          setState(() => tickets = updatedTickets);
        },
      ),
      
      // HALAMAN 3: Statistik
      StatisticsPage(events: events, tickets: tickets),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          boxShadow: [
            BoxShadow(
              // PERBAIKAN: Gunakan .withValues untuk menghindari deprecation
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
            BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Scan"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Statistik"),
          ],
        ),
      ),
    );
  }

  // Widget Builder untuk menggantikan 'EventsPage' yang error
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
                child: events.isEmpty 
                  ? const Center(child: Text("Belum ada event", style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return Card(
                          color: Colors.white.withValues(alpha: 0.1),
                          child: ListTile(
                            title: Text(event.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(event.location, style: const TextStyle(color: Colors.white70)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EventDetailPage(
                                event: event, 
                                tickets: tickets,
                                onTicketsChanged: (t) => setState(() => tickets = t),
                                onEventChanged: (e) => _loadData(),
                                onEventDeleted: (e) => _handleDeleteEvent(e.id),
                              ))
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Halo, ${widget.user.name} 👋', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('Kelola tiket event Anda', style: TextStyle(color: Color(0xFFC4B5FD))),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF9333EA), size: 32),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateEventPage(onEventCreated: (e) => _loadData()))),
          )
        ],
      ),
    );
  }
}