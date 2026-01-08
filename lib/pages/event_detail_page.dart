import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models.dart';
import '../database/hive_service.dart';
import 'edit_event_page.dart';

class EventDetailPage extends StatefulWidget {
  final Event event;
  final List<Ticket> tickets;
  final Function(List<Ticket>) onTicketsChanged;
  final Function(Event) onEventChanged;
  final Function(Event)? onEventDeleted;

  const EventDetailPage({
    super.key,
    required this.event,
    required this.tickets,
    required this.onTicketsChanged,
    required this.onEventChanged,
    this.onEventDeleted,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final _buyerNameController = TextEditingController();
  final _buyerEmailController = TextEditingController();
  
  Ticket? _generatedTicket;
  late Event _currentEvent;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerEmailController.dispose();
    super.dispose();
  }

  List<Ticket> get eventTickets =>
      widget.tickets.where((t) => t.eventId == _currentEvent.id).toList();

  void _resetForm() {
    setState(() {
      _generatedTicket = null;
      _buyerNameController.clear();
      _buyerEmailController.clear();
    });
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _generateTicket() async {
    if (_buyerNameController.text.trim().isEmpty) {
      _showSnackBar('Mohon isi nama pembeli', Colors.red, Icons.error_outline);
      return;
    }

    if (_currentEvent.ticketsSold >= _currentEvent.capacity) {
      _showSnackBar('Event sudah penuh!', Colors.orange, Icons.warning_amber);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ticketCode = 'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      final newTicket = Ticket(
        id: DateTime.now().millisecondsSinceEpoch,
        eventId: _currentEvent.id,
        code: ticketCode,
        buyerName: _buyerNameController.text.trim(),
        buyerEmail: _buyerEmailController.text.trim(),
        purchaseDate: DateTime.now(),
      );

      await HiveService.createTicket(newTicket);

      final updatedEvent = _currentEvent.copyWith(
        ticketsSold: _currentEvent.ticketsSold + 1,
      );

      await HiveService.updateEvent(updatedEvent);

      final updatedTickets = [...widget.tickets, newTicket];
      widget.onTicketsChanged(updatedTickets);
      widget.onEventChanged(updatedEvent);

      if (mounted) {
        setState(() {
          _generatedTicket = newTicket;
          _currentEvent = updatedEvent;
        });
        _showSnackBar('Tiket QR berhasil dibuat!', Colors.green, Icons.check_circle);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Gagal: $e', Colors.red, Icons.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTicket(Ticket ticket) async {
    setState(() => _isLoading = true);
    try {
      await HiveService.deleteTicket(ticket.id);

      final updatedEvent = _currentEvent.copyWith(
        ticketsSold: _currentEvent.ticketsSold > 0 ? _currentEvent.ticketsSold - 1 : 0,
      );

      await HiveService.updateEvent(updatedEvent);

      final updatedTickets = widget.tickets.where((t) => t.id != ticket.id).toList();
      widget.onTicketsChanged(updatedTickets);
      widget.onEventChanged(updatedEvent);

      if (mounted) {
        setState(() => _currentEvent = updatedEvent);
        _showSnackBar('Tiket dihapus', Colors.green, Icons.delete);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Gagal hapus: $e', Colors.red, Icons.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeleteEvent() async {
    setState(() => _isLoading = true);
    try {
      await HiveService.deleteEvent(_currentEvent.id);
      
      // Batch delete tiket terkait di Hive
      for (var t in eventTickets) {
        await HiveService.deleteTicket(t.id);
      }

      if (widget.onEventDeleted != null) {
        widget.onEventDeleted!(_currentEvent);
      }
      
      if (mounted) {
        Navigator.pop(context); // Tutup Detail Page
      }
    } catch (e) {
      if (mounted) _showSnackBar('Gagal hapus event', Colors.red, Icons.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildEventInfoCard(),
                        const SizedBox(height: 20),
                        _buildGenerateTicketSection(),
                        const SizedBox(height: 20),
                        _buildTicketList(),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFF9333EA))),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              _currentEvent.name,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditEventPage(
                event: _currentEvent, 
                onEventUpdated: (e) {
                  setState(() => _currentEvent = e);
                  widget.onEventChanged(e);
                }
              )),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _showDeleteEventDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfoCard() {
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(Icons.calendar_today, DateFormat('dd MMM yyyy').format(_currentEvent.date)),
            const SizedBox(height: 8),
            _infoRow(Icons.location_on, _currentEvent.location),
            const SizedBox(height: 8),
            _infoRow(Icons.people, '${_currentEvent.ticketsSold} / ${_currentEvent.capacity} Tiket Terjual'),
            const SizedBox(height: 8),
            _infoRow(Icons.money, 'Rp ${NumberFormat('#,###').format(_currentEvent.price)}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.purpleAccent, size: 20),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildGenerateTicketSection() {
    if (_generatedTicket != null) {
      return Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              QrImageView(data: _generatedTicket!.code, size: 150),
              Text(_generatedTicket!.code, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(_generatedTicket!.buyerName),
              TextButton(onPressed: _resetForm, child: const Text("Buat Tiket Baru"))
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        TextField(
          controller: _buyerNameController,
          decoration: _inputDeco("Nama Pembeli", Icons.person),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _generateTicket,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text("Generate Tiket QR"),
          ),
        )
      ],
    );
  }

  Widget _buildTicketList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Daftar Tiket", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...eventTickets.map((t) => ListTile(
          tileColor: Colors.white10,
          title: Text(t.buyerName, style: const TextStyle(color: Colors.white)),
          subtitle: Text(t.code, style: const TextStyle(color: Colors.white54)),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteTicket(t),
          ),
        )),
      ],
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.purpleAccent), borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showDeleteEventDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Hapus Event', style: TextStyle(color: Colors.white)),
        content: const Text('Semua data tiket akan ikut terhapus.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _handleDeleteEvent();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}