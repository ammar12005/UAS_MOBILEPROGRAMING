import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
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

  // Konfigurasi kontak untuk fitur inovatif
  // PENTING: Format nomor WhatsApp harus 62XXXXXXXXX (kode negara + nomor tanpa 0)
  // Contoh: 081234567890 -> 6281234567890
  final String organizerPhone = '087837007684';
  final String organizerWhatsApp = '6287837007684';
  final String organizerEmail = 'organizer@eventpro.com';

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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ===== FITUR INOVATIF =====

  // Fitur 1: Launch WhatsApp
  Future<void> _launchWhatsApp() async {
    final phoneNumber = organizerWhatsApp.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (phoneNumber.length < 10) {
      if (mounted) {
        _showSnackBar('Nomor WhatsApp tidak valid', Colors.red, Icons.error);
      }
      return;
    }
    
    final message = Uri.encodeComponent(
      'Halo, saya tertarik dengan event "${_currentEvent.name}" pada ${DateFormat('dd MMM yyyy').format(_currentEvent.date)}. '
      'Bisakah Anda memberikan informasi lebih lanjut?'
    );
    
    final url = 'https://wa.me/$phoneNumber?text=$message';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          _showSnackBar('Membuka WhatsApp...', Colors.green, Icons.check_circle);
        }
      } else {
        if (mounted) {
          _showSnackBar('WhatsApp tidak terinstal', Colors.orange, Icons.warning);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', Colors.red, Icons.error);
      }
    }
  }

  // Fitur 2: Launch Phone
  Future<void> _launchPhone() async {
    final url = 'tel:$organizerPhone';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (mounted) {
          _showSnackBar('Membuka aplikasi telepon...', Colors.blue, Icons.phone);
        }
      } else {
        if (mounted) {
          _showSnackBar('Tidak dapat membuka aplikasi telepon', Colors.red, Icons.error);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', Colors.red, Icons.error);
      }
    }
  }

  // Fitur 3: Launch Email
  Future<void> _launchEmail() async {
    final subject = Uri.encodeComponent('Pertanyaan tentang Event: ${_currentEvent.name}');
    final body = Uri.encodeComponent(
      'Halo,\n\nSaya ingin menanyakan tentang event "${_currentEvent.name}" yang akan diadakan pada ${DateFormat('dd MMM yyyy').format(_currentEvent.date)}.\n\n'
      'Lokasi: ${_currentEvent.location}\n'
      'Harga: Rp ${NumberFormat('#,###').format(_currentEvent.price)}\n\n'
      'Terima kasih.'
    );
    final url = 'mailto:$organizerEmail?subject=$subject&body=$body';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (mounted) {
          _showSnackBar('Membuka aplikasi email...', Colors.purple, Icons.email);
        }
      } else {
        if (mounted) {
          _showSnackBar('Tidak dapat membuka aplikasi email', Colors.red, Icons.error);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', Colors.red, Icons.error);
      }
    }
  }

  // Fitur 4: Share Event
  Future<void> _shareEvent() async {
    try {
      final shareText = 
        '🎉 ${_currentEvent.name}\n\n'
        '📅 ${DateFormat('dd MMM yyyy').format(_currentEvent.date)}\n'
        '📍 ${_currentEvent.location}\n'
        '💰 Rp ${NumberFormat('#,###').format(_currentEvent.price)}\n'
        '🎫 ${_currentEvent.capacity - _currentEvent.ticketsSold} tiket tersisa!\n\n'
        'Pesan sekarang di Event Manager Pro!';
      
      await Share.share(shareText, subject: _currentEvent.name);
      if (mounted) {
        _showSnackBar('Membagikan event...', Colors.teal, Icons.share);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal membagikan event', Colors.red, Icons.error);
      }
    }
  }

  // Fitur 5: Open Location in Maps
  Future<void> _openInMaps() async {
    final query = Uri.encodeComponent(_currentEvent.location);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          _showSnackBar('Membuka Google Maps...', Colors.blue, Icons.map);
        }
      } else {
        if (mounted) {
          _showSnackBar('Tidak dapat membuka Maps', Colors.red, Icons.error);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', Colors.red, Icons.error);
      }
    }
  }

  // Fitur 6: Show Contact Options Bottom Sheet
  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hubungi Penyelenggara',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildContactOptionButton(
              icon: Icons.chat,
              label: 'WhatsApp',
              color: Colors.green,
              onPressed: () {
                Navigator.pop(ctx);
                _launchWhatsApp();
              },
            ),
            const SizedBox(height: 12),
            _buildContactOptionButton(
              icon: Icons.phone,
              label: 'Telepon',
              color: Colors.blue,
              onPressed: () {
                Navigator.pop(ctx);
                _launchPhone();
              },
            ),
            const SizedBox(height: 12),
            _buildContactOptionButton(
              icon: Icons.email,
              label: 'Email',
              color: Colors.purple,
              onPressed: () {
                Navigator.pop(ctx);
                _launchEmail();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== END FITUR INOVATIF =====

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
                        _buildActionButtons(),
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
                      if (mounted) {
                        setState(() {
                          _currentEvent = updatedEvent;
                        });
                        widget.onEventChanged(updatedEvent);
                      }
                    },
                  ),
                ),
              );
              
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
      color: const Color.fromRGBO(255, 255, 255, 0.1),
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

  Widget _buildActionButtons() {
    return Card(
      color: const Color.fromRGBO(255, 255, 255, 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fitur Event',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.contact_support,
                    label: 'Hubungi',
                    onPressed: _showContactOptions,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share,
                    label: 'Bagikan',
                    onPressed: _shareEvent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.map,
                    label: 'Maps',
                    onPressed: _openInMaps,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(255, 255, 255, 0.15),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
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
            fillColor: const Color.fromRGBO(255, 255, 255, 0.1),
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
          color: const Color.fromRGBO(255, 255, 255, 0.05),
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
              color: const Color.fromRGBO(255, 255, 255, 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.1),
              ),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(192, 132, 252, 0.2),
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