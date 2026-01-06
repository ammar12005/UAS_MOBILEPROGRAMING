import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../storage_service.dart';
import 'create_event_page.dart';
import 'event_detail_page.dart';
import 'scan_page.dart';
import 'statistics_page.dart';
import 'login_page.dart';

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
    
    // Memuat data berdasarkan ID user
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

  Future<void> _handleDeleteEvent(int eventId) async {
    final updatedEvents = events.where((e) => e.id != eventId).toList();
    final updatedTickets = tickets.where((t) => t.eventId != eventId).toList();
    
    setState(() {
      events = updatedEvents;
      tickets = updatedTickets;
    });
    
    // Simpan perubahan secara permanen
    await StorageService.saveEvents(widget.user.id, updatedEvents);
    await StorageService.saveTickets(widget.user.id, updatedTickets);
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
        onEventsChanged: (updatedEvents) async {
          setState(() => events = updatedEvents);
          await StorageService.saveEvents(widget.user.id, updatedEvents);
        },
        onTicketsChanged: (updatedTickets) async {
          setState(() => tickets = updatedTickets);
          await StorageService.saveTickets(widget.user.id, updatedTickets);
        },
        onEventDeleted: _handleDeleteEvent,
        // Tambahkan refresh callback untuk memastikan data tetap sinkron
        onRefresh: _loadData, 
      ),
      ScanPage(
        tickets: tickets,
        events: events,
        onTicketsChanged: (updatedTickets) async {
          setState(() => tickets = updatedTickets);
          await StorageService.saveTickets(widget.user.id, updatedTickets);
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Scan"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Statistik"),
          ],
        ),
      ),
    );
  }
}

class EventsPage extends StatelessWidget {
  final User user;
  final List<Event> events;
  final List<Ticket> tickets;
  final Function(List<Event>) onEventsChanged;
  final Function(List<Ticket>) onTicketsChanged;
  final Function(int) onEventDeleted;
  final Future<void> Function() onRefresh; // New refresh callback

  const EventsPage({
    super.key,
    required this.user,
    required this.events,
    required this.tickets,
    required this.onEventsChanged,
    required this.onTicketsChanged,
    required this.onEventDeleted,
    required this.onRefresh,
  });

  void _showDeleteDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Hapus Event', style: TextStyle(color: Colors.white)),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${event.name}"? Semua tiket terkait juga akan terhapus.',
          style: const TextStyle(color: Color(0xFFC4B5FD)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              onEventDeleted(event.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF9333EA).withValues(alpha: 0.2),
                    const Color(0xFF3B82F6).withValues(alpha: 0.2),
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
                                fontSize: 22,
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
                      IconButton(
                        onPressed: () async {
                          // Gunakan await untuk menunggu kembali dari halaman create
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
                          // Paksa load ulang setelah kembali
                          await onRefresh(); 
                        },
                        icon: const Icon(Icons.add_circle, color: Color(0xFF9333EA), size: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1E293B),
                              title: const Text('Logout', style: TextStyle(color: Colors.white)),
                              content: const Text('Yakin ingin keluar?', style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                  child: const Text('Keluar'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await StorageService.logout();
                            if (context.mounted) {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: events.isEmpty
                    ? ListView( // Gunakan listview agar RefreshIndicator bekerja
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.event_busy, size: 80, color: Colors.white.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada event',
                                  style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onLongPress: () => _showDeleteDialog(context, event),
                                onTap: () async {
                                  await Navigator.push(
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
                                  // Sinkronisasi data saat kembali dari detail
                                  await onRefresh(); 
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
                                                  color: gradient.colors.first.withValues(alpha: 0.3),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(Icons.calendar_today, color: Colors.white, size: 28),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  event.name,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.access_time, color: Color(0xFFC4B5FD), size: 16),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      DateFormat('dd MMM yyyy').format(event.date),
                                                      style: const TextStyle(fontSize: 14, color: Color(0xFFC4B5FD)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.location_on, color: Color(0xFFC4B5FD), size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                event.location,
                                                style: const TextStyle(fontSize: 14, color: Color(0xFFC4B5FD)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                gradient: gradient,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${event.ticketsSold}/${event.capacity}',
                                                style: const TextStyle(
                                                  fontSize: 12,
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
            ),
          ],
        ),
      ),
    );
  }
}