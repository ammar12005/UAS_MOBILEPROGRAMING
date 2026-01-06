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

  void _handleDeleteEvent(int eventId) {
    final updatedEvents = events.where((e) => e.id != eventId).toList();
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
        onEventDeleted: _handleDeleteEvent,
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
            BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Scan"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Statistik"),
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
  final Function(int) onEventDeleted;

  const EventsPage({
    super.key,
    required this.user,
    required this.events,
    required this.tickets,
    required this.onEventsChanged,
    required this.onTicketsChanged,
    required this.onEventDeleted,
  });

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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
                                MaterialPageRoute(builder: (_) => const LoginPage()),
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
            Expanded(
              child: events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 80, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada event',
                            style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Buat event pertama Anda!',
                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
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
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onLongPress: () => _showDeleteDialog(context, event),
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
                                                color: gradient.colors.first.withOpacity(0.3),
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
                                                  fontSize: 20,
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
                                          const Icon(Icons.location_on, color: Color(0xFFC4B5FD), size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              event.location,
                                              style: const TextStyle(fontSize: 14, color: Color(0xFFC4B5FD)),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              gradient: gradient,
                                              borderRadius: BorderRadius.circular(8),
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