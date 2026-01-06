import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class ScanPage extends StatefulWidget {
  final List<Ticket> tickets;
  final List<Event> events;
  final Function(List<Ticket>) onTicketsChanged;

  const ScanPage({
    super.key,
    required this.tickets,
    required this.events,
    required this.onTicketsChanged,
  });

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();
  bool _isScanning = false;
  ScanResult? _scanResult;
  bool _isCameraActive = true;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _scanTicket(String ticketCode) {
    final searchCode = ticketCode.trim().toUpperCase();
    
    final ticketIndex = widget.tickets.indexWhere(
      (t) => t.code.toUpperCase() == searchCode,
    );

    if (ticketIndex == -1) {
      setState(() {
        _scanResult = ScanResult(
          isValid: false,
          message: 'Tiket tidak ditemukan!',
          ticket: null,
        );
      });
      return;
    }

    final ticket = widget.tickets[ticketIndex];

    if (ticket.isScanned) {
      setState(() {
        _scanResult = ScanResult(
          isValid: false,
          message: 'Tiket sudah pernah digunakan!',
          ticket: ticket,
        );
      });
      return;
    }

    final updatedTickets = List<Ticket>.from(widget.tickets);
    updatedTickets[ticketIndex] = Ticket(
      id: ticket.id,
      eventId: ticket.eventId,
      code: ticket.code,
      buyerName: ticket.buyerName,
      buyerEmail: ticket.buyerEmail,
      purchaseDate: ticket.purchaseDate,
      isScanned: true,
      scannedAt: DateTime.now(),
    );

    widget.onTicketsChanged(updatedTickets);

    setState(() {
      _scanResult = ScanResult(
        isValid: true,
        message: 'Check-in Berhasil!',
        ticket: updatedTickets[ticketIndex],
      );
    });
  }

  void _handleManualScan() {
    if (_manualCodeController.text.isNotEmpty) {
      _scanTicket(_manualCodeController.text);
      _manualCodeController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _handleQRScan(BarcodeCapture capture) {
    if (!_isScanning && capture.barcodes.isNotEmpty) {
      final barcode = capture.barcodes.first;
      if (barcode.rawValue != null) {
        setState(() => _isScanning = true);
        _scanTicket(barcode.rawValue!);
        
        // Jeda 2 detik agar tidak scanning berkali-kali untuk tiket yang sama
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isScanning = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalTickets = widget.tickets.length;
    final scannedTickets = widget.tickets.where((t) => t.isScanned).length;
    final remainingTickets = totalTickets - scannedTickets;

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
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF9333EA).withValues(alpha: 0.2), // PERBAIKAN: withValues
                    const Color(0xFF3B82F6).withValues(alpha: 0.2), // PERBAIKAN: withValues
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: Color(0xFFFBBF24), size: 32),
                      SizedBox(width: 12),
                      Text(
                        'Scan QR Tiket',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        '$totalTickets',
                        'Total',
                        Icons.confirmation_number,
                        const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        '$scannedTickets',
                        'Hadir',
                        Icons.check_circle,
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        '$remainingTickets',
                        'Sisa',
                        Icons.pending,
                        const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Manual Input
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1), // PERBAIKAN
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.keyboard, color: Color(0xFFC4B5FD)),
                              SizedBox(width: 12),
                              Text(
                                'Input Manual',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _manualCodeController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'monospace',
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Ketik kode tiket...',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.4),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                    onSubmitted: (_) => _handleManualScan(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: _handleManualScan,
                                  icon: const Icon(Icons.send, color: Colors.white),
                                  iconSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // QR Scanner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.qr_code_2, color: Color(0xFFC4B5FD)),
                                  SizedBox(width: 12),
                                  Text(
                                    'Scan QR Code',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(
                                  _isCameraActive ? Icons.videocam : Icons.videocam_off,
                                  color: _isCameraActive
                                      ? const Color(0xFF10B981)
                                      : Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isCameraActive = !_isCameraActive;
                                    if (_isCameraActive) {
                                      _scannerController.start();
                                    } else {
                                      _scannerController.stop();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF9333EA),
                                width: 3,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: _isCameraActive
                                  ? MobileScanner(
                                      controller: _scannerController,
                                      onDetect: _handleQRScan,
                                    )
                                  : Container(
                                      color: Colors.black,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.videocam_off,
                                              size: 64,
                                              color: Colors.white.withValues(alpha: 0.5),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Kamera Dimatikan',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.5),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'Arahkan kamera ke QR Code tiket',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scan Result
                    if (_scanResult != null) ...[
                      const SizedBox(height: 20),
                      _buildResultCard(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _scanResult!;
    final event = result.ticket != null
        ? widget.events.firstWhere(
            (e) => e.id == result.ticket!.eventId,
            orElse: () => Event(
              id: 0,
              name: 'Unknown Event',
              date: DateTime.now(),
              location: '',
              capacity: 0,
              price: 0,
              description: '',
            ),
          )
        : null;

    final baseColor = result.isValid ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: result.isValid
              ? [const Color(0xFF10B981), const Color(0xFF14B8A6)]
              : [const Color(0xFFEF4444), const Color(0xFFF87171)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  result.isValid ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.isValid ? 'BERHASIL!' : 'GAGAL!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.message,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.ticket != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (result.isValid) ...[
                    Text(
                      'Selamat Datang! 🎉',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: baseColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildInfoRow(Icons.person, 'Nama', result.ticket!.buyerName),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.confirmation_number,
                    'Kode',
                    result.ticket!.code,
                  ),
                  const SizedBox(height: 8),
                  if (event != null)
                    _buildInfoRow(Icons.event, 'Event', event.name),
                  if (result.ticket!.scannedAt != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.access_time,
                      'Check-in',
                      DateFormat('HH:mm:ss').format(result.ticket!.scannedAt!),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() => _scanResult = null),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: baseColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner),
                  SizedBox(width: 12),
                  Text(
                    'SCAN LAGI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class ScanResult {
  final bool isValid;
  final String message;
  final Ticket? ticket;
  
  ScanResult({
    required this.isValid,
    required this.message,
    this.ticket,
  });
}