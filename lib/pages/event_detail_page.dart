import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models.dart';
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

  String _generateTicketCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return 'TKT-${chars[(random ~/ 1000000) % chars.length]}${chars[(random ~/ 100000) % chars.length]}${chars[(random ~/ 10000) % chars.length]}${chars[(random ~/ 1000) % chars.length]}${chars[(random ~/ 100) % chars.length]}${chars[(random ~/ 10) % chars.length]}${chars[random % chars.length]}';
  }

  void _generateTicket() {
    if (_buyerNameController.text.trim().isEmpty || 
        _buyerEmailController.text.trim().isEmpty) {
      _showSnackBar('Mohon isi nama dan email pembeli', Colors.red, Icons.error_outline);
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_buyerEmailController.text.trim())) {
      _showSnackBar('Format email tidak valid', Colors.red, Icons.error_outline);
      return;
    }

    if (_currentEvent.ticketsSold >= _currentEvent.capacity) {
      _showSnackBar('Event sudah penuh!', Colors.orange, Icons.warning_amber);
      return;
    }

    final ticketCode = _generateTicketCode();
    final newTicket = Ticket(
      id: DateTime.now().millisecondsSinceEpoch,
      eventId: _currentEvent.id,
      code: ticketCode,
      buyerName: _buyerNameController.text.trim(),
      buyerEmail: _buyerEmailController.text.trim(),
      purchaseDate: DateTime.now(),
    );

    setState(() => _generatedTicket = newTicket);

    final updatedTickets = [...widget.tickets, newTicket];
    widget.onTicketsChanged(updatedTickets);

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
    
    setState(() => _currentEvent = updatedEvent);
    widget.onEventChanged(updatedEvent);
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _generatedTicket = null;
      _buyerNameController.clear();
      _buyerEmailController.clear();
    });
  }

  void _deleteTicket(Ticket ticket) {
    final updatedTickets = widget.tickets.where((t) => t.id != ticket.id).toList();
    widget.onTicketsChanged(updatedTickets);

    final updatedEvent = Event(
      id: _currentEvent.id,
      name: _currentEvent.name,
      date: _currentEvent.date,
      location: _currentEvent.location,
      capacity: _currentEvent.capacity,
      price: _currentEvent.price,
      description: _currentEvent.description,
      ticketsSold: _currentEvent.ticketsSold - 1,
    );
    
    setState(() => _currentEvent = updatedEvent);
    widget.onEventChanged(updatedEvent);
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
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9333EA).withValues(alpha: 0.2), // Perbaikan withOpacity
                      const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_currentEvent.ticketsSold}/${_currentEvent.capacity} tiket terjual',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFC4B5FD),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditEventPage(
                              event: _currentEvent,
                              onEventUpdated: (updatedEvent) {
                                setState(() => _currentEvent = updatedEvent);
                                widget.onEventChanged(updatedEvent);
                              },
                            ),
                          ),
                        );
                        if (result != null && result is Event) {
                          setState(() => _currentEvent = result);
                        }
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
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
              ),

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
        ),
      ),
    );
  }

  Widget _buildEventInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1), // Perbaikan withOpacity
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Event',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today, DateFormat('dd MMM yyyy • HH:mm').format(_currentEvent.date)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, _currentEvent.location),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.people, '${_currentEvent.capacity} orang'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.payments, 'Rp ${NumberFormat('#,###').format(_currentEvent.price)}'),
          if (_currentEvent.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _currentEvent.description,
                style: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 14),
              ),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_2, color: Color(0xFFFBBF24), size: 24),
              SizedBox(width: 12),
              Text(
                'Generate Tiket',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_generatedTicket == null) ...[
            _buildTextField(controller: _buyerNameController, hint: 'Nama Pembeli', icon: Icons.person),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _buyerEmailController, 
              hint: 'Email Pembeli', 
              icon: Icons.email, 
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _generateTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, size: 24, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Generate Tiket QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF3B82F6)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9333EA).withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.confirmation_number, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text('E-TICKET', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                QrImageView(
                  data: _generatedTicket!.code,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(_generatedTicket!.code, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('Scan QR code di pintu masuk', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildTicketInfoContainer(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _resetForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF9333EA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Generate Tiket Lagi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfoContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTicketInfo('Nama', _generatedTicket!.buyerName),
          const SizedBox(height: 8),
          _buildTicketInfo('Email', _generatedTicket!.buyerEmail),
          const SizedBox(height: 8),
          _buildTicketInfo('Tanggal', DateFormat('dd MMM yyyy').format(_currentEvent.date)),
          const SizedBox(height: 8),
          _buildTicketInfo('Lokasi', _currentEvent.location),
        ],
      ),
    );
  }

  Widget _buildTicketList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daftar Tiket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              _buildTicketBadge(),
            ],
          ),
          const SizedBox(height: 16),
          if (eventTickets.isEmpty) _buildEmptyTickets() else ...eventTickets.map((t) => _buildTicketItem(t)),
        ],
      ),
    );
  }

  Widget _buildTicketBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF3B82F6)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('${eventTickets.length} Tiket', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildEmptyTickets() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.confirmation_number_outlined, size: 60, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Belum ada tiket', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketItem(Ticket ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _buildTicketStatusIcon(ticket.isScanned),
          const SizedBox(width: 16),
          Expanded(child: _buildTicketDetails(ticket)),
          _buildTicketStatusBadge(ticket.isScanned),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => _showDeleteTicketDialog(ticket),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketStatusIcon(bool scanned) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: scanned ? [Colors.green, Colors.green.shade700] : [Colors.orange, Colors.orange.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(scanned ? Icons.check_circle : Icons.confirmation_number, color: Colors.white, size: 24),
    );
  }

  Widget _buildTicketDetails(Ticket ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ticket.code, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
        const SizedBox(height: 4),
        Text(ticket.buyerName, style: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 13)),
        Text(ticket.buyerEmail, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
      ],
    );
  }

  Widget _buildTicketStatusBadge(bool scanned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (scanned ? Colors.green : Colors.orange).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        scanned ? 'Scanned' : 'Belum',
        style: TextStyle(color: scanned ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF3B82F6)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 14))),
      ],
    );
  }

  Widget _buildTicketInfo(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text('$label:', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: Icon(icon, color: const Color(0xFFC4B5FD)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _showDeleteTicketDialog(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tiket'),
        content: Text('Yakin ingin menghapus tiket ${ticket.code}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              _deleteTicket(ticket);
              Navigator.pop(context);
              _showSnackBar('Tiket ${ticket.code} dihapus', Colors.red, Icons.delete);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showDeleteEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yakin ingin menghapus event "${_currentEvent.name}"?'),
            const SizedBox(height: 12),
            const Text('Event dan semua tiket akan dihapus permanen!'),
            const SizedBox(height: 8),
            Text('${eventTickets.length} tiket akan terhapus', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final updatedTickets = widget.tickets.where((t) => t.eventId != _currentEvent.id).toList();
              widget.onTicketsChanged(updatedTickets);
              if (widget.onEventDeleted != null) widget.onEventDeleted!(_currentEvent);
              Navigator.pop(context);
              Navigator.pop(context);
              _showSnackBar('Event "${_currentEvent.name}" berhasil dihapus', Colors.red, Icons.delete);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}