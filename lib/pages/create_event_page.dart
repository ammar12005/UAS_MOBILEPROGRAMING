import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../database/database_helper.dart';

class CreateEventPage extends StatefulWidget {
  final Function(Event) onEventCreated;
  const CreateEventPage({super.key, required this.onEventCreated});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  final _n = TextEditingController();
  final _l = TextEditingController();
  final _c = TextEditingController();
  final _p = TextEditingController();
  final _d = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  
  bool _isSaving = false;

  @override
  void dispose() {
    _n.dispose();
    _l.dispose();
    _c.dispose();
    _p.dispose();
    _d.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9333EA),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (d != null) {
      if (!mounted) return;
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_date),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF9333EA),
                onPrimary: Colors.white,
                surface: Color(0xFF1E293B),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (t != null) {
        setState(() => _date = DateTime(d.year, d.month, d.day, t.hour, t.minute));
      }
    }
  }

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        // Buat event baru
        final newEvent = Event(
          id: DateTime.now().millisecondsSinceEpoch,
          name: _n.text.trim(),
          date: _date,
          location: _l.text.trim(),
          capacity: int.tryParse(_c.text) ?? 0,
          price: double.tryParse(_p.text) ?? 0.0,
          description: _d.text.trim(),
          ticketsSold: 0,
        );
        
        // Simpan ke database SQLite
        await _dbHelper.insertEvent(newEvent);
        
        // Kirim ke callback untuk update UI
        widget.onEventCreated(newEvent);
        
        if (mounted) {
          // Kembali ke halaman sebelumnya
          Navigator.pop(context, newEvent);
          
          // Tampilkan notifikasi sukses
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Event berhasil dibuat dan disimpan!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Gagal menyimpan event: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9333EA).withValues(alpha: 0.2),
                      const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Event Baru',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Isi detail event Anda',
                          style: TextStyle(fontSize: 14, color: Color(0xFFC4B5FD)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildLabel('Nama Event'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _n,
                        hint: 'Contoh: Tech Conference 2026',
                        icon: Icons.event,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nama event harus diisi' : null,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Lokasi'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _l,
                        hint: 'Contoh: Jakarta Convention Center',
                        icon: Icons.location_on,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Lokasi harus diisi' : null,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Tanggal & Waktu'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _isSaving ? null : _pickDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  DateFormat('dd MMM yyyy • HH:mm').format(_date),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(Icons.edit, color: Colors.white.withValues(alpha: 0.5), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Kapasitas'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _c,
                                  hint: '100',
                                  icon: Icons.people,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                                    final capacity = int.tryParse(v);
                                    if (capacity == null || capacity <= 0) return 'Tidak valid';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Harga (Rp)'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _p,
                                  hint: '50000',
                                  icon: Icons.payments,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                                    final price = double.tryParse(v);
                                    if (price == null || price < 0) return 'Tidak valid';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Deskripsi'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: TextFormField(
                          controller: _d,
                          maxLines: 5,
                          enabled: !_isSaving,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Jelaskan detail acara Anda di sini...',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Deskripsi harus diisi' : null,
                        ),
                      ),
                      const SizedBox(height: 32),

                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA).withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _createEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      'Simpan Event',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: !_isSaving,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}