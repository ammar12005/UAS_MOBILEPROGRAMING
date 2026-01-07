import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models.dart';
import '../storage_service.dart';
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
        duration: const Duration(seconds: 2),
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

      // Simpan ticket ke SQLite
      await StorageService.saveTicket(newTicket);

      // Update event ticketsSold
      final updatedEvent = Event(
        id: _currentEvent.id,
        name: _currentEvent.name,
        date: _currentEvent.date,
        location: _currentEvent.location,
        capacity: _currentEvent.capacity,
        price: _currentEvent.price,
        description: _currentEvent.description,
        ticketsSold: _currentEvent.ticketsSold + 1,
      );

      // Update event di SQLite
      await StorageService.updateEvent(updatedEvent);

      // Update UI
      final updatedTickets = [...widget.tickets, newTicket];
      widget.onTicketsChanged(updatedTickets);
      widget.onEventChanged(updatedEvent);

      if (mounted) {
        setState(() {
          _generatedTicket = newTicket;
          _currentEvent = updatedEvent;
        });
        _showSnackBar('Tiket berhasil dibuat!', Colors.green, Icons.check_circle);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal membuat tiket: $e', Colors.red, Icons.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTicket(Ticket ticket) async {
    setState(() => _isLoading = true);

    try {
      // Hapus ticket dari SQLite
      await StorageService.deleteTicket(ticket.id);

      // Update event ticketsSold
      final updatedEvent = Event(
        id: _currentEvent.id,
        name: _currentEvent.name,
        date: _currentEvent.date,
        location: _currentEvent.location,
        capacity: _currentEvent.capacity,
        price: _currentEvent.price,
        description: _currentEvent.description,
        ticketsSold: _currentEvent.ticketsSold > 0 ? _currentEvent.ticketsSold - 1 : 0,
      );

      // Update event di SQLite
      await StorageService.updateEvent(updatedEvent);

      // Update UI
      final updatedTickets = widget.tickets.where((t) => t.id != ticket.id).toList();
      widget.onTicketsChanged(updatedTickets);
      widget.onEventChanged(updatedEvent);

      if (mounted) {
        setState(() => _currentEvent = updatedEvent);
        _showSnackBar('Tiket berhasil dihapus', Colors.green, Icons.check_circle);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal menghapus tiket: $e', Colors.red, Icons.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                    child: CircularProgressIndicator(
                      color: Color(0xFF9333EA),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _isLoading ? null : () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentEvent.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_currentEvent.ticketsSold}/${_currentEvent.capacity} terjual',
                  style: const TextStyle(fontSize: 14, color: Color(0xFFC4B5FD)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _isLoading
                ? null
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEventPage(
                          event: _currentEvent,
                          onEventUpdated: (updatedEvent) {
                            widget.onEventChanged(updatedEvent);
                            if (!mounted) return;
                            setState(() => _currentEvent = updatedEvent);
                          },
                        ),
                      ),
                    );
                    if (!mounted) return;
                    if (result != null && result is Event) {
                      setState(() => _currentEvent = result);
                    }
                  },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            enabled: !_isLoading,
            onSelected: (value) {
              if (value == 'delete') _showDeleteEventDialog();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus Event'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.calendar_today, DateFormat('dd MMM yyyy • HH:mm').format(_currentEvent.date)),
          const SizedBox(height: 12),
          _infoRow(Icons.location_on, _currentEvent.location),
          const SizedBox(height: 12),
          _infoRow(Icons.payments, 'Rp ${NumberFormat('#,###').format(_currentEvent.price)}'),
          if (_currentEvent.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            const Text(
              'Deskripsi:',
              style: TextStyle(
                color: Color(0xFFC4B5FD),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentEvent.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerateTicketSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          if (_generatedTicket == null) ...[
            const Row(
              children: [
                Icon(Icons.qr_code_2, color: Color(0xFFFBBF24)),
                SizedBox(width: 12),
                Text(
                  'Generate Tiket',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _buyerNameController,
              hint: 'Nama Pembeli',
              icon: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _buyerEmailController,
              hint: 'Email Pembeli (Opsional)',
              icon: Icons.email,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA),
                  disabledBackgroundColor: Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Buat Tiket QR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ] else
            _buildGeneratedTicketCard(),
        ],
      ),
    );
  }

  Widget _buildGeneratedTicketCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              QrImageView(data: _generatedTicket!.code, size: 160),
              const SizedBox(height: 12),
              Text(
                _generatedTicket!.code,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _generatedTicket!.buyerName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _resetForm,
          child: const Text(
            'Buat Tiket Lagi',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tiket Terjual',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${eventTickets.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (eventTickets.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Belum ada tiket terjual',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          )
        else
          ...eventTickets.map((t) => _buildTicketItem(t)),
      ],
    );
  }

  Widget _buildTicketItem(Ticket ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ticket.isScanned ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              ticket.isScanned ? Icons.check_circle : Icons.confirmation_number,
              color: ticket.isScanned ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.buyerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  ticket.code,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
            onPressed: _isLoading ? null : () => _showDeleteTicketDialog(ticket),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFC4B5FD), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      enabled: !_isLoading,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showDeleteTicketDialog(Ticket ticket) {
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tiket', style: TextStyle(color: Colors.white)),
        content: Text(
          'Hapus tiket ${ticket.code}?\nPembeli: ${ticket.buyerName}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => navigator.pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () async {
                    navigator.pop();
                    await _deleteTicket(ticket);
                  },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteEventDialog() {
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Event', style: TextStyle(color: Colors.white)),
        content: Text(
          'Hapus event "${_currentEvent.name}" dan semua tiket (${eventTickets.length}) secara permanen?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => navigator.pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (widget.onEventDeleted != null) {
                      widget.onEventDeleted!(_currentEvent);
                    }
                    if (!mounted) return;
                    navigator.pop(); // Tutup dialog
                    navigator.pop(); // Kembali ke Dashboard
                  },
            child: const Text('Hapus Permanen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}