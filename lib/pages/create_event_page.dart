import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class CreateEventPage extends StatefulWidget {
  final Function(Event) onEventCreated;
  const CreateEventPage({super.key, required this.onEventCreated});
  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _n = TextEditingController();
  final _l = TextEditingController();
  final _c = TextEditingController();
  final _p = TextEditingController();
  final _d = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));

  _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF9333EA),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (d != null) {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_date),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF9333EA),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
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
                      const Color(0xFF9333EA).withOpacity(0.2),
                      const Color(0xFF3B82F6).withOpacity(0.2),
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

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Nama Event
                      _buildLabel('Nama Event'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _n,
                        hint: 'Contoh: Tech Conference 2025',
                        icon: Icons.event,
                        validator: (v) => v?.isEmpty ?? true ? 'Nama event harus diisi' : null,
                      ),
                      const SizedBox(height: 20),

                      // Lokasi
                      _buildLabel('Lokasi'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _l,
                        hint: 'Contoh: Jakarta Convention Center',
                        icon: Icons.location_on,
                        validator: (v) => v?.isEmpty ?? true ? 'Lokasi harus diisi' : null,
                      ),
                      const SizedBox(height: 20),

                      // Tanggal & Waktu
                      _buildLabel('Tanggal & Waktu'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                              Icon(Icons.edit, color: Colors.white.withOpacity(0.5), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Kapasitas & Harga
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
                                  validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
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
                                  validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Deskripsi
                      _buildLabel('Deskripsi'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: TextFormField(
                          controller: _d,
                          maxLines: 5,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Jelaskan detail acara Anda di sini...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Deskripsi harus diisi' : null,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Button Simpan
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA).withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              widget.onEventCreated(Event(
                                id: DateTime.now().millisecondsSinceEpoch,
                                name: _n.text,
                                date: _date,
                                location: _l.text,
                                capacity: int.parse(_c.text),
                                price: double.parse(_p.text),
                                description: _d.text,
                              ));
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 12),
                                      Text('Event berhasil dibuat!'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
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
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
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