import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../database/hive_service.dart';

class CreateEventPage extends StatefulWidget {
  final Function(Event) onEventCreated;
  const CreateEventPage({super.key, required this.onEventCreated});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final newEvent = Event(
          id: DateTime.now().millisecondsSinceEpoch,
          name: _nameController.text.trim(),
          date: _selectedDate,
          location: _locationController.text.trim(),
          capacity: int.tryParse(_capacityController.text) ?? 0,
          price: double.tryParse(_priceController.text) ?? 0.0,
          description: _descriptionController.text.trim(),
          ticketsSold: 0,
        );
        
        await HiveService.createEvent(newEvent);
        widget.onEventCreated(newEvent);
        
        if (mounted) {
          Navigator.pop(context, newEvent);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar( // PERBAIKAN: Tambahkan const
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Event berhasil disimpan!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Buat Event Baru',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Informasi Dasar', icon: Icons.info_outline), // PERBAIKAN: Extracted to const class
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              label: 'Nama Event',
              hint: 'Contoh: Konser Musik',
              icon: Icons.celebration,
              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _locationController,
              label: 'Lokasi',
              hint: 'Contoh: Gedung Serbaguna',
              icon: Icons.location_on,
              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Jadwal', icon: Icons.schedule), // PERBAIKAN: Extracted to const class
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeCard(
                    title: 'Tanggal',
                    value: DateFormat('dd MMM yyyy').format(_selectedDate),
                    icon: Icons.calendar_today,
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateTimeCard(
                    title: 'Waktu',
                    value: _selectedTime.format(context),
                    icon: Icons.access_time,
                    onTap: () => _selectTime(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Detail Tiket', icon: Icons.confirmation_number),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _capacityController,
                    label: 'Kapasitas',
                    hint: '0',
                    icon: Icons.people,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'Isi 0 jika tidak ada' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Harga (Rp)',
                    hint: '0',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'Isi 0 jika gratis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Deskripsi', icon: Icons.description),
            const SizedBox(height: 12),
            _buildDescriptionField(),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detail Event',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Lengkapi informasi event Anda',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14), // PERBAIKAN: Gunakan .withValues
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.deepPurple),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: 'Deskripsi Event',
        labelStyle: const TextStyle(color: Colors.deepPurple),
        hintText: 'Jelaskan detail event Anda...',
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade100,
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDateTimeCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveEvent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text('Simpan Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// PERBAIKAN: Extracted Section Title to a const Widget class to remove blue lines
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }
}