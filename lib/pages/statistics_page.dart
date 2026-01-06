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

  int get totalTicketsSold =>
      events.fold(0, (sum, event) => sum + event.ticketsSold);

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
            // Header
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
              child: const Row(
                children: [
                  Icon(Icons.analytics, color: Color(0xFFFBBF24), size: 32),
                  SizedBox(width: 12),
                  Text(
                    'Statistik & Analitik',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Summary Cards Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildStatCard(
                        'Tiket Terjual',
                        totalTicketsSold.toString(),
                        Icons.confirmation_number,
                        const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                      ),
                      _buildStatCard(
                        'Total Omzet',
                        _formatShortCurrency(totalRevenue),
                        Icons.payments,
                        const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                      ),
                      _buildStatCard(
                        'Check-in',
                        totalScanned.toString(),
                        Icons.how_to_reg,
                        const LinearGradient(
                          colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                        ),
                      ),
                      _buildStatCard(
                        'Kehadiran',
                        '${scanRate.toStringAsFixed(1)}%',
                        Icons.analytics,
                        const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Event Performance Section
                  _buildSectionHeader('Performa per Event'),
                  const SizedBox(height: 16),
                  if (events.isEmpty)
                    _buildEmptyState('Belum ada data event', Icons.event_busy)
                  else
                    ...events.map((event) => _buildEventCard(event)),

                  const SizedBox(height: 32),

                  // Recent Activity Section
                  _buildSectionHeader('Check-in Terbaru'),
                  const SizedBox(height: 16),
                  _buildRecentScansCard(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatShortCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}Jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}Rb';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final eventTickets = tickets.where((t) => t.eventId == event.id).toList();
    final eventScans = eventTickets.where((t) => t.isScanned).length;
    final salePercentage =
        event.capacity > 0 ? (event.ticketsSold / event.capacity) : 0.0;
    final revenue = event.ticketsSold * event.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(event.date),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(salePercentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: salePercentage,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEventStat(
                  Icons.confirmation_number,
                  'Terjual',
                  '${event.ticketsSold}/${event.capacity}',
                ),
              ),
              Expanded(
                child: _buildEventStat(
                  Icons.how_to_reg,
                  'Check-in',
                  '$eventScans',
                ),
              ),
              Expanded(
                child: _buildEventStat(
                  Icons.payments,
                  'Pendapatan',
                  _formatShortCurrency(revenue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFC4B5FD), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentScansCard() {
    if (recentScans.isEmpty) {
      return _buildEmptyState('Belum ada aktivitas check-in', Icons.qr_code_scanner);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentScans.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: Colors.white.withOpacity(0.1),
        ),
        itemBuilder: (context, index) {
          final scan = recentScans[index];
          final event = events.firstWhere(
            (e) => e.id == scan.eventId,
            orElse: () => Event(
              id: -1,
              name: 'Unknown Event',
              date: DateTime.now(),
              location: '',
              capacity: 0,
              price: 0,
              description: '',
            ),
          );

          return Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scan.buyerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        scan.code,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(scan.scannedAt!),
                      style: const TextStyle(
                        color: Color(0xFFC4B5FD),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM').format(scan.scannedAt!),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}