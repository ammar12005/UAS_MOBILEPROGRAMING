import 'package:flutter/material.dart';
import '../models.dart';
// 1. Ubah import dari DatabaseHelper ke HiveService
import '../database/hive_service.dart';

class EditEventPage extends StatefulWidget {
  final Event event;
  final Function(Event) onEventUpdated;

  const EditEventPage({
    super.key,
    required this.event,
    required this.onEventUpdated,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  // 2. Hapus variabel DatabaseHelper, kita gunakan HiveService secara statis
  
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _capacityController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event.name);
    _locationController = TextEditingController(text: widget.event.location);
    _capacityController = TextEditingController(text: widget.event.capacity.toString());
    _priceController = TextEditingController(text: widget.event.price.toString());
    _descriptionController = TextEditingController(text: widget.event.description);
    _selectedDate = widget.event.date;
    _selectedTime = TimeOfDay.fromDateTime(widget.event.date);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ... Metode _selectDate dan _selectTime tetap sama ...

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final capacity = int.tryParse(_capacityController.text) ?? 0;
      
      // Validasi agar kapasitas tidak lebih kecil dari tiket yang sudah terjual
      if (capacity < widget.event.ticketsSold) {
        _showErrorSnackBar('Kapasitas tidak boleh kurang dari tiket terjual (${widget.event.ticketsSold})');
        return;
      }

      setState(() => _isSaving = true);

      try {
        final updatedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        // Buat objek event baru dengan data yang diperbarui
        final updatedEvent = widget.event.copyWith(
          name: _nameController.text.trim(),
          date: updatedDate,
          location: _locationController.text.trim(),
          capacity: capacity,
          price: double.tryParse(_priceController.text) ?? 0,
          description: _descriptionController.text.trim(),
        );

        // 3. Simpan ke Hive menggunakan HiveService
        await HiveService.updateEvent(updatedEvent);

        // Update callback UI
        widget.onEventUpdated(updatedEvent);

        if (mounted) {
          Navigator.pop(context, updatedEvent);
          _showSuccessSnackBar('Event berhasil diperbarui di database Hive');
        }
      } catch (e) {
        if (mounted) _showErrorSnackBar('Gagal memperbarui Hive: $e');
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  // === UI Build tetap menggunakan desain Gradient Anda yang sudah bagus ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /* ... sisa kode build UI Anda ... */
      appBar: AppBar(
        title: const Text('Edit Event'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF581C87), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(controller: _nameController, hint: "Nama", icon: Icons.event),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _locationController, hint: "Lokasi", icon: Icons.location_on),
                    const SizedBox(height: 16),
                    // ... sisipkan elemen input lainnya ...
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      child: const Text("Simpan Perubahan"),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon}) {
     return TextFormField(
       controller: controller,
       style: const TextStyle(color: Colors.white),
       decoration: InputDecoration(
         labelText: hint,
         prefixIcon: Icon(icon, color: Colors.purpleAccent),
         filled: true,
         fillColor: Colors.white.withValues(alpha: 0.1),
         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
       ),
     );
  }
}