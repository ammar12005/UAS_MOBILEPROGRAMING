import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../database/database_helper.dart';
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
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
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
      // Load data dari SQLite
      final loadedEvents = await _dbHelper.getAllEvents();
      final loadedTickets = await _dbHelper.getAllTickets();

      if (mounted) {
        setState(() {
          events = loadedEvents;
          tickets = loadedTickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDeleteEvent(int eventId) async {
    try {
      // Hapus dari database
      await _dbHelper.deleteEvent(eventId);
      
      // Hapus tiket terkait
      final ticketsToDelete = tickets.where((t) => t.eventId == eventId).toList();
      for (var ticket in ticketsToDelete) {
        await _dbHelper.deleteTicket(ticket.id);
      }

      // Update UI
      setState(() {
        events.removeWhere((e) => e.id == eventId);
        tickets.removeWhere((t) => t.eventId == eventId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Event berhasil dihapus'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Gagal menghapus event: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleCreateEvent() async {
    final result = await Navigator.push<Event>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEventPage(
          onEventCreated: (event) {
            // Event sudah disimpan di CreateEventPage
            // Return event ke halaman ini
          },
        ),
      ),
    );

    // Jika ada event baru yang dikembalikan, reload data
    if (result != null) {
      await _loadData(); // Reload semua data dari database
    }
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
        },
        onTicketsChanged: (updatedTickets) async {
          setState(() => tickets = updatedTickets);
        },
        onEventDeleted: _handleDeleteEvent,
        onRefresh: _loadData,
        onCreateEvent: _handleCreateEvent,
      ),
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
            BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner), label: "Scan"),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), label: "Statistik"),
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
  final Future<void> Function() onRefresh;
  final Future<void> Function() onCreateEvent;

  const EventsPage({
    super.key,
    required this.user,
    required this.events,
    required this.tickets,
    required this.onEventsChanged,
    required this.onTicketsChanged,
    required this.onEventDeleted,
    required this.onRefresh,
    required this.onCreateEvent,
  });

  void _showDeleteDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Event', style: TextStyle(color: Colors.white)),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${event.name}"? Semua tiket terkait juga akan terhapus.',
          style: const TextStyle(color: Color(0xFFC4B5FD)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onEventDeleted(event.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Yakin ingin keluar?',
          style: TextStyle(color: Color(0xFFC4B5FD)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    
    if (confirm == true && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
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
                            Icon(Icons.auto_awesome,
                                color: Color(0xFFFBBF24), size: 32),
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
                        onPressed: onCreateEvent,
                        icon: const Icon(Icons.add_circle,
                            color: Color(0xFF9333EA), size: 32),
                        tooltip: 'Buat Event Baru',
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () => _showLogoutDialog(context),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                color: const Color(0xFF9333EA),
                backgroundColor: const Color(0xFF1E293B),
                child: events.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.event_busy,
                                    size: 80,
                                    color: Colors.white.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada event',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color:
                                          Colors.white.withValues(alpha: 0.7)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap tombol + untuk membuat event baru',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          Colors.white.withValues(alpha: 0.5)),
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
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onLongPress: () =>
                                    _showDeleteDialog(context, event),
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
                                  await onRefresh();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient: gradient,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: gradient.colors.first
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                                Icons.calendar_today,
                                                color: Colors.white,
                                                size: 28),
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
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.access_time,
                                                        color:
                                                            Color(0xFFC4B5FD),
                                                        size: 16),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      DateFormat('dd MMM yyyy')
                                                          .format(event.date),
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Color(
                                                              0xFFC4B5FD)),
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
                                          color: Colors.white
                                              .withValues(alpha: 0.05),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.location_on,
                                                color: Color(0xFFC4B5FD),
                                                size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                event.location,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFFC4B5FD)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                gradient: gradient,
                                                borderRadius:
                                                    BorderRadius.circular(8),
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