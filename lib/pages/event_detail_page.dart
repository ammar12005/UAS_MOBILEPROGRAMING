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
      
      for (var t in eventTickets) {
        await HiveService.deleteTicket(t.id);
      }

      if (widget.onEventDeleted != null) {
        widget.onEventDeleted!(_currentEvent);
      }
      
      if (mounted) {
        Navigator.pop(context);
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
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF9333EA)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit Event',
            onPressed: () async {
              final result = await Navigator.push<Event>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditEventPage(
                    event: _currentEvent,
                    onEventUpdated: (updatedEvent) {
                      // Update state lokal
                      if (mounted) {
                        setState(() {
                          _currentEvent = updatedEvent;
                        });
                        // Notify parent widget
                        widget.onEventChanged(updatedEvent);
                      }
                    },
                  ),
                ),
              );
              
              // Update dari result Navigator.pop
              if (result != null && mounted) {
                setState(() {
                  _currentEvent = result;
                });
                widget.onEventChanged(result);
              }
            },
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
      color: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(
              Icons.calendar_today,
              DateFormat('dd MMM yyyy').format(_currentEvent.date),
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.location_on, _currentEvent.location),
            const SizedBox(height: 8),
            _infoRow(
              Icons.people,
              '${_currentEvent.ticketsSold} / ${_currentEvent.capacity} Tiket Terjual',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.money,
              'Rp ${NumberFormat('#,###').format(_currentEvent.price)}',
            ),
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
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateTicketSection() {
    if (_generatedTicket != null) {
      return Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Tiket Berhasil Dibuat!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: _generatedTicket!.code,
                size: 150,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                _generatedTicket!.code,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _generatedTicket!.buyerName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Buat Tiket Baru'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // TextField Nama Pembeli - FIXED
        TextField(
          controller: _buyerNameController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: "Nama Pembeli",
            labelStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            hintText: "Masukkan nama pembeli",
            hintStyle: const TextStyle(
              color: Colors.white38,
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.person, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.purpleAccent, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Button Generate Tiket - FIXED
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _generateTicket,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE879F9),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: const Text(
              "Pesan Tiket Ini",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketList() {
    if (eventTickets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.confirmation_number_outlined, 
                color: Colors.white30, 
                size: 48
              ),
              SizedBox(height: 12),
              Text(
                'Belum ada tiket',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Daftar Tiket",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        ...eventTickets.map(
          (t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.confirmation_number,
                  color: Colors.purpleAccent,
                  size: 24,
                ),
              ),
              title: Text(
                t.buyerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                t.code,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _showDeleteTicketDialog(t),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteTicketDialog(Ticket ticket) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Tiket',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Hapus tiket atas nama ${ticket.buyerName}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteTicket(ticket);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showDeleteEventDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Event',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Semua data tiket akan ikut terhapus. Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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