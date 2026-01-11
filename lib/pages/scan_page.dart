import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models.dart';
import '../database/hive_service.dart';

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
  bool _isCameraActive = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _scanTicket(String ticketCode) async {
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

    final updatedTicket = Ticket(
      id: ticket.id,
      eventId: ticket.eventId,
      code: ticket.code,
      buyerName: ticket.buyerName,
      buyerEmail: ticket.buyerEmail,
      purchaseDate: ticket.purchaseDate,
      isScanned: true,
      scannedAt: DateTime.now(),
    );

    try {
      await HiveService.createTicket(updatedTicket);

      final updatedTickets = List<Ticket>.from(widget.tickets);
      updatedTickets[ticketIndex] = updatedTicket;
      widget.onTicketsChanged(updatedTickets);

      if (mounted) {
        setState(() {
          _scanResult = ScanResult(
            isValid: true,
            message: 'Check-in Berhasil!',
            ticket: updatedTicket,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanResult = ScanResult(
            isValid: false,
            message: 'Gagal memperbarui database: $e',
            ticket: null,
          );
        });
      }
    }
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
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _isScanning = false);
          }
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
            _buildUpperStats(totalTickets, scannedTickets, remainingTickets),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildManualInputSection(),
                    const SizedBox(height: 20),
                    _buildScannerSection(),
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

  Widget _buildUpperStats(int total, int hadir, int sisa) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_scanner, color: Color(0xFFFBBF24), size: 32),
              SizedBox(width: 12),
              Text('Validasi Tiket', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('$total', 'Total', Icons.confirmation_number, const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              _buildStatCard('$hadir', 'Hadir', Icons.check_circle, const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _buildStatCard('$sisa', 'Sisa', Icons.pending, const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1), // PERBAIKAN BIRU: Ganti withOpacity ke withValues
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Input Manual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualCodeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Masukkan kode tiket...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(color: const Color(0xFF9333EA), borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  onPressed: _handleManualScan,
                  icon: const Icon(Icons.check, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScannerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1), // PERBAIKAN BIRU
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Scan QR Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Switch(
                value: _isCameraActive,
                activeTrackColor: const Color(0xFFC4B5FD).withValues(alpha: 0.5), // PERBAIKAN BIRU
                onChanged: (val) {
                  setState(() {
                    _isCameraActive = val;
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
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _isCameraActive ? const Color(0xFF9333EA) : Colors.grey, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _isCameraActive
                  ? MobileScanner(controller: _scannerController, onDetect: _handleQRScan)
                  : Container(
                      color: Colors.black45,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_off, color: Colors.white24, size: 50),
                          SizedBox(height: 8),
                          Text('Kamera Tidak Aktif', style: TextStyle(color: Colors.white24)),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15), // PERBAIKAN BIRU
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)), // PERBAIKAN BIRU
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))), // PERBAIKAN BIRU
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _scanResult!;
    final baseColor = result.isValid ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.15), // PERBAIKAN BIRU
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withValues(alpha: 0.3)), // PERBAIKAN BIRU
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(result.isValid ? Icons.check_circle : Icons.error, color: baseColor, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.isValid ? 'BERHASIL' : 'GAGAL', style: TextStyle(color: baseColor, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(result.message, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          if (result.ticket != null) ...[
            const Divider(color: Colors.white12, height: 24),
            _buildResultRow('Pembeli', result.ticket!.buyerName),
            _buildResultRow('Kode', result.ticket!.code),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _scanResult = null),
            child: const Text('TUTUP', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class ScanResult {
  final bool isValid;
  final String message;
  final Ticket? ticket;
  ScanResult({required this.isValid, required this.message, this.ticket});
}