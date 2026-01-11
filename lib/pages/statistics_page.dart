import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class StatisticsPage extends StatelessWidget {
  final List<Event> events;
  final List<Ticket> tickets;

  const StatisticsPage({
    super.key,
    required this.events,
    required this.tickets,
  });

  // === LOGIKA PERHITUNGAN (FIX NULL SAFETY) ===
  
  int get totalTicketsSold =>
      events.fold(0, (sum, event) => sum + (event.ticketsSold));

  double get totalRevenue =>
      events.fold(0.0, (sum, event) => sum + (event.ticketsSold * event.price));

  int get totalScanned => tickets.where((t) => t.isScanned).length;

  double get scanRate =>
      totalTicketsSold > 0 ? (totalScanned / totalTicketsSold * 100) : 0;

  List<Ticket> get recentScans {
    final scannedTickets =
        tickets.where((t) => t.isScanned && t.scannedAt != null).toList();
    scannedTickets.sort((a, b) => b.scannedAt!.compareTo(a.scannedAt!));
    return scannedTickets.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
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
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSummaryGrid(),
                  const SizedBox(height: 32),
                  const _SectionHeader(title: 'Performa per Event'),
                  const SizedBox(height: 16),
                  _buildEventPerformanceList(),
                  const SizedBox(height: 32),
                  const _SectionHeader(title: 'Aktivitas Check-in Terbaru'),
                  const SizedBox(height: 16),
                  _buildRecentScansList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS (FIX DEPRECATED & CONST) ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // PERBAIKAN: Ganti withOpacity ke withValues (Gbr image_309999.jpg)
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: const Row(
        children: [
          Icon(Icons.analytics, color: Color(0xFFFBBF24), size: 32),
          SizedBox(width: 12),
          Text(
            'Statistik & Analitik',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard('Tiket Terjual', totalTicketsSold.toString(), Icons.confirmation_number, [const Color(0xFF3B82F6), const Color(0xFF2563EB)]),
        _buildStatCard('Total Omzet', _formatShortCurrency(totalRevenue), Icons.payments, [const Color(0xFF10B981), const Color(0xFF059669)]),
        _buildStatCard('Check-in', totalScanned.toString(), Icons.how_to_reg, [const Color(0xFF9333EA), const Color(0xFF7C3AED)]),
        _buildStatCard('Kehadiran', '${scanRate.toStringAsFixed(1)}%', Icons.pie_chart, [const Color(0xFFF59E0B), const Color(0xFFEF4444)]),
      ],
    );
  }

  Widget _buildEventPerformanceList() {
    if (events.isEmpty) return const _EmptyState(msg: 'Belum ada data event', icon: Icons.event_busy);
    return Column(children: events.map((event) => _buildEventCard(event)).toList());
  }

  Widget _buildStatCard(String label, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // PERBAIKAN: Ganti withOpacity ke withValues
            color: colors.first.withValues(alpha: 0.3), 
            blurRadius: 12, 
            offset: const Offset(0, 6)
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          FittedBox(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final eventTickets = tickets.where((t) => t.eventId == event.id).toList();
    final eventScans = eventTickets.where((t) => t.isScanned).length;
    final salePercentage = event.capacity > 0 ? (event.ticketsSold / event.capacity) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(event.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Text('${(salePercentage * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: salePercentage,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _smallInfo(Icons.people, '$eventScans Hadir'),
              _smallInfo(Icons.money, _formatShortCurrency(event.ticketsSold * event.price)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecentScansList() {
    if (recentScans.isEmpty) return const _EmptyState(msg: 'Belum ada check-in', icon: Icons.history);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(20)
      ),
      child: Column(
        children: recentScans.map((scan) {
          return ListTile(
            leading: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
            title: Text(scan.buyerName, style: const TextStyle(color: Colors.white, fontSize: 14)),
            trailing: Text(
              DateFormat('HH:mm').format(scan.scannedAt ?? DateTime.now()), 
              style: const TextStyle(color: Colors.white54, fontSize: 12)
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _smallInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.5)), 
        const SizedBox(width: 4), 
        Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12))
      ]
    );
  }

  String _formatShortCurrency(double value) {
    if (value >= 1000000) return 'Rp ${(value / 1000000).toStringAsFixed(1)}Jt';
    if (value >= 1000) return 'Rp ${(value / 1000).toStringAsFixed(0)}Rb';
    return 'Rp ${value.toStringAsFixed(0)}';
  }
}

// --- SUB-WIDGETS UNTUK MENGHILANGKAN GARIS KUNING (Const Optimization) ---

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white));
  }
}

class _EmptyState extends StatelessWidget {
  final String msg;
  final IconData icon;
  const _EmptyState({required this.msg, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.white.withValues(alpha: 0.2)), 
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: Colors.white.withValues(alpha: 0.2)))
        ]
      )
    );
  }
}